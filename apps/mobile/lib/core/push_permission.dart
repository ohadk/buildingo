import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// iOS Guideline 4.5.4 — obtain notification consent before APNs registration.
class PushPermission {
  PushPermission._();

  static const _channel = MethodChannel('buildingo/apns');
  static const _askedKey = 'push_permission_prompted_v1';

  /// Re-register if the user already granted permission (no dialog).
  static Future<void> syncRegistration() async {
    try {
      await _channel.invokeMethod<void>('syncRegistration');
    } catch (_) {}
  }

  static Future<String> authorizationStatus() async {
    try {
      return await _channel.invokeMethod<String>('authorizationStatus') ??
          'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Shows a short in-app explanation, then the system permission dialog
  /// (once). Safe to call after the user is signed in.
  static Future<bool> ensureRequested(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final status = await authorizationStatus();
    if (status == 'authorized' ||
        status == 'provisional' ||
        status == 'ephemeral') {
      await syncRegistration();
      return true;
    }
    if (status == 'denied') {
      await prefs.setBool(_askedKey, true);
      return false;
    }
    if (prefs.getBool(_askedKey) == true) {
      return false;
    }

    if (!context.mounted) return false;
    final l10n = context.l10n;
    final want = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pushPermissionTitle),
        content: Text(l10n.pushPermissionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.pushPermissionNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.pushPermissionAllow),
          ),
        ],
      ),
    );
    await prefs.setBool(_askedKey, true);
    if (want != true) return false;

    try {
      final raw = await _channel.invokeMethod<Map>('requestPermission');
      final granted = raw?['granted'] == true;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Used from Settings / SMS login when enabling notifications.
  /// Always goes through the system permission dialog if not yet decided.
  static Future<bool> requestFromSettings() async {
    final status = await authorizationStatus();
    if (status == 'authorized' ||
        status == 'provisional' ||
        status == 'ephemeral') {
      await syncRegistration();
      return true;
    }
    if (status == 'denied') return false;
    try {
      final raw = await _channel.invokeMethod<Map>('requestPermission');
      return raw?['granted'] == true;
    } catch (_) {
      return false;
    }
  }
}
