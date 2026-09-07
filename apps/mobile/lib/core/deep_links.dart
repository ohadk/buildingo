import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Deep / Universal / App Links for Buildingo.
///
/// Supported URLs:
/// - https://HOST/open/payments
/// - buildingo://open/payments
/// - buildingo://payments
class DeepLinkController extends ChangeNotifier {
  DeepLinkController();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  /// Tab index in [MainShell] to open once the user is in the app.
  /// `1` = Payments.
  int? _pendingTab;
  int? get pendingTab => _pendingTab;

  Future<void> start() async {
    await _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(_onUri, onError: (Object e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DeepLink stream error: $e');
      }
    });
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _onUri(initial);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('DeepLink initial error: $e');
      }
    }
  }

  void _onUri(Uri uri) {
    if (_isFirebaseAuthCallback(uri)) return;
    final tab = tabForUri(uri);
    if (tab == null) return;
    if (kDebugMode) {
      // ignore: avoid_print
      print('DeepLink → tab $tab from $uri');
    }
    _pendingTab = tab;
    notifyListeners();
  }

  /// Returns and clears the pending tab (if any).
  int? takePendingTab() {
    final t = _pendingTab;
    _pendingTab = null;
    return t;
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  static bool _isFirebaseAuthCallback(Uri uri) {
    final s = uri.toString().toLowerCase();
    return s.contains('firebaseauth') ||
        s.contains('deep_link_id') ||
        uri.path.contains('/link');
  }

  /// Map a URI to a MainShell tab index, or null if not a Buildingo deep link.
  static int? tabForUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .map((s) => s.toLowerCase())
        .toList();

    final isCustom = scheme == 'buildingo';
    final isHttps = scheme == 'https' || scheme == 'http';
    if (!isCustom && !isHttps) return null;

    if (isHttps) {
      // Only claim our API / public web host (prod or whatever API_BASE_URL is).
      final allowed = _allowedHttpsHosts();
      if (!allowed.contains(host)) return null;
    }

    // buildingo://payments  OR  …/open/payments  OR  buildingo://open/payments
    if (segments.isEmpty) {
      return isCustom ? 0 : null;
    }
    if (segments.length == 1 && segments.first == 'payments') return 1;
    if (segments.length >= 2 &&
        segments[0] == 'open' &&
        segments[1] == 'payments') {
      return 1;
    }
    if (segments.length == 1 && segments.first == 'open') return 0;
    if (segments.length == 1 && segments.first == 'app') return 0;
    return null;
  }

  static Set<String> _allowedHttpsHosts() {
    final hosts = <String>{
      Uri.parse(kProductionApiBaseUrl).host.toLowerCase(),
    };
    try {
      final h = Uri.parse(ApiClient.baseUrl).host.toLowerCase();
      if (h.isNotEmpty) hosts.add(h);
    } catch (_) {}
    return hosts;
  }
}
