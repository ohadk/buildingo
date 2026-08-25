import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// App language: follows the device locale until the user picks one
/// explicitly; the choice is persisted across launches.
class LocaleController extends ChangeNotifier {
  static const _prefKey = 'app_locale';
  Locale? _override;

  Locale? get locale => _override;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      _override = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _override = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }

  /// he ↔ en toggle relative to what's currently displayed.
  Future<void> toggle(BuildContext context) async {
    final current = Localizations.localeOf(context).languageCode;
    await setLocale(Locale(current == 'he' ? 'en' : 'he'));
  }
}
