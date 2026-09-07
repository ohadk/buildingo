import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../l10n/gen/app_localizations.dart';

/// Maps Firebase Auth failures to short, user-facing copy.
/// Technical details are logged for debugging — never shown in the UI.
String authErrorMessage(Object error, AppLocalizations l10n) {
  if (error is! FirebaseAuthException) {
    debugPrint('Auth error (non-Firebase): $error');
    return l10n.authErrorGeneric;
  }

  final e = error;
  debugPrint(
    'FirebaseAuthException code=${e.code} message=${e.message} '
    'plugin=${e.plugin} credential=${e.credential} '
    'email=${e.email} phoneNumber=${e.phoneNumber} '
    'tenantId=${e.tenantId}',
  );
  // ignore: avoid_print — flutter run console sometimes drops debugPrint on iOS
  print('FirebaseAuthException code=${e.code} message=${e.message}');
  print('FirebaseAuthException toString=$e');

  final detail = '${e.message ?? ''} $e'.toLowerCase();
  // Firebase backend "Error code: 39" = SMS blocked for this number/carrier/region
  // (quota, fraud defense, or temporary carrier unavailability) — not an app bug.
  if (detail.contains('error code: 39') || detail.contains('error code:39')) {
    return l10n.authErrorSmsUnavailable;
  }

  switch (e.code) {
    case 'invalid-phone-number':
    case 'missing-phone-number':
      return l10n.authErrorInvalidPhone;
    case 'too-many-requests':
    case 'quota-exceeded':
      return l10n.authErrorTooManyRequests;
    case 'network-request-failed':
      return l10n.authErrorNetwork;
    case 'invalid-verification-code':
    case 'invalid-verification-id':
      return l10n.authErrorInvalidCode;
    case 'session-expired':
    case 'code-expired':
      return l10n.authErrorSessionExpired;
    case 'operation-not-allowed':
      return l10n.authErrorNotEnabled;
    case 'captcha-check-failed':
    case 'missing-client-identifier':
    case 'missing-app-credential':
    case 'app-not-authorized':
    case 'web-context-cancelled':
    case 'internal-error':
    case 'unknown':
    default:
      return l10n.authErrorSmsSendFailed;
  }
}
