import 'package:shared_preferences/shared_preferences.dart';

/// Local user preferences (device-side). Push delivery is not wired yet;
/// these flags are ready for when APNs/FCM is enabled, and document intent.
class UserPreferences {
  UserPreferences._(this._prefs);

  final SharedPreferences _prefs;

  static const _kTickets = 'pref_notify_tickets';
  static const _kAnnouncements = 'pref_notify_announcements';
  static const _kPayments = 'pref_notify_payments';
  static const _kMessages = 'pref_notify_messages';

  static Future<UserPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserPreferences._(prefs);
  }

  bool get notifyTickets => _prefs.getBool(_kTickets) ?? true;
  bool get notifyAnnouncements => _prefs.getBool(_kAnnouncements) ?? true;
  bool get notifyPayments => _prefs.getBool(_kPayments) ?? true;
  bool get notifyMessages => _prefs.getBool(_kMessages) ?? true;

  Future<void> setNotifyTickets(bool v) => _prefs.setBool(_kTickets, v);
  Future<void> setNotifyAnnouncements(bool v) =>
      _prefs.setBool(_kAnnouncements, v);
  Future<void> setNotifyPayments(bool v) => _prefs.setBool(_kPayments, v);
  Future<void> setNotifyMessages(bool v) => _prefs.setBool(_kMessages, v);
}
