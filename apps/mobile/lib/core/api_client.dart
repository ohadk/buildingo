import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// Production App Hosting backend. Release/TestFlight builds must hit this
/// (or an explicit `--dart-define=API_BASE_URL=…`), never localhost.
const String kProductionApiBaseUrl =
    'https://buildingo-api--buildingo-6ff54.us-central1.hosted.app';

bool _isSafeProductionOrigin(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return false;
  if (u.scheme != 'https') return false;
  final host = u.host.toLowerCase();
  if (host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '0.0.0.0' ||
      host.endsWith('.local')) {
    return false;
  }
  // Private / link-local LAN ranges — never ship these in release.
  if (host.startsWith('10.') ||
      host.startsWith('192.168.') ||
      host.startsWith('169.254.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(host)) {
    return false;
  }
  // Old Netlify marketing site — /join and the API are not hosted there.
  if (host == 'buildingo.com' || host == 'www.buildingo.com') {
    return false;
  }
  return true;
}

/// Thin wrapper around the Next.js backend. Every request carries the
/// caller's Firebase ID token as a Bearer header; the server verifies it
/// with the Admin SDK and enforces role/building scoping.
class ApiClient {
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Resolved API origin (no trailing slash).
  /// - Explicit `--dart-define=API_BASE_URL=…` wins in debug.
  /// - Release/profile always use a safe HTTPS origin (production default).
  ///   Stale Xcode `DART_DEFINES` with localhost/LAN are ignored.
  static String get baseUrl {
    final fromEnv = _envBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (kReleaseMode || kProfileMode) {
      if (fromEnv.isNotEmpty && _isSafeProductionOrigin(fromEnv)) {
        return fromEnv;
      }
      return kProductionApiBaseUrl;
    }
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:3000';
  }

  /// Origin used for user-facing links (join/share). Prefer the server
  /// `PUBLIC_WEB_URL` (loaded via [/api/config]); dart-define is a fallback
  /// for offline / pre-config builds. Never prefer a LAN API base URL.
  static const publicWebUrl = String.fromEnvironment(
    'PUBLIC_WEB_URL',
    defaultValue: '',
  );

  static String? _resolvedPublicWebUrl;

  /// Clears the cached share origin (e.g. after fixing PUBLIC_WEB_URL).
  static void clearResolvedPublicWebUrl() {
    _resolvedPublicWebUrl = null;
  }

  /// Shareable web origin (no trailing slash).
  static Future<String> resolvePublicWebUrl() async {
    if (_resolvedPublicWebUrl != null) return _resolvedPublicWebUrl!;
    try {
      final cfg = await api.get('/api/config');
      final fromServer = (cfg['publicWebUrl'] as String?)?.trim();
      if (fromServer != null &&
          fromServer.isNotEmpty &&
          _isSafeProductionOrigin(fromServer.replaceAll(RegExp(r'/+$'), ''))) {
        _resolvedPublicWebUrl = fromServer.replaceAll(RegExp(r'/+$'), '');
        return _resolvedPublicWebUrl!;
      }
    } catch (_) {
      /* fall through */
    }
    final fromDefine = publicWebUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (fromDefine.isNotEmpty && _isSafeProductionOrigin(fromDefine)) {
      _resolvedPublicWebUrl = fromDefine;
      return _resolvedPublicWebUrl!;
    }
    // Last resort: App Hosting origin (not the old Netlify buildingo.com site).
    _resolvedPublicWebUrl = kProductionApiBaseUrl;
    return _resolvedPublicWebUrl!;
  }

  /// Join / invite URL for a building code.
  static Future<String> joinLinkFor(String code) async {
    final origin = await resolvePublicWebUrl();
    return '$origin/join/$code';
  }

  /// Single download link that sends iOS → App Store, Android → Play.
  static Future<String> appDownloadLink() async {
    try {
      final cfg = await api.get('/api/config');
      final fromServer = (cfg['appDownloadUrl'] as String?)?.trim();
      if (fromServer != null && fromServer.isNotEmpty) return fromServer;
    } catch (_) {
      /* fall through */
    }
    final origin = await resolvePublicWebUrl();
    return '$origin/app';
  }

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw ApiException(
        res.statusCode,
        body['error']?.toString() ?? 'Request failed',
      );
    }
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(json: false),
        )
        .timeout(const Duration(seconds: 20));
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(json: false),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> uploadFile(
    String path, {
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(await _headers(json: false))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    final res = await http.Response.fromStream(await request.send());
    return _decode(res);
  }

  /// Authenticated binary download (e.g. `/api/files/content?…`).
  Future<({List<int> bytes, String contentType})> getBytes(String path) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(json: false),
    );
    if (res.statusCode >= 400) {
      String message = 'Request failed';
      try {
        final body = jsonDecode(res.body);
        message = body['error']?.toString() ?? message;
      } catch (_) {
        if (res.body.isNotEmpty) message = res.body;
      }
      throw ApiException(res.statusCode, message);
    }
    return (
      bytes: res.bodyBytes,
      contentType: res.headers['content-type'] ?? 'application/octet-stream',
    );
  }
}

final api = ApiClient();
