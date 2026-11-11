import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nX on BuildContext {
  /// UI strings in the current language (English, Spanish or French).
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The app language: null follows the device, otherwise 'en', 'es' or 'fr'.
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _key = 'app_locale';

  /// Languages offered, named in their own language.
  static const languages = {'en': 'English', 'es': 'Español', 'fr': 'Français'};

  final ValueNotifier<Locale?> locale = ValueNotifier(null);

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      if (saved != null && languages.containsKey(saved)) locale.value = Locale(saved);
    } catch (_) {
      // Preferences unavailable (e.g. tests) – follow the device.
    }
  }

  Future<void> setLanguage(String? code) async {
    locale.value = code == null ? null : Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      code == null ? await prefs.remove(_key) : await prefs.setString(_key, code);
    } catch (_) {}
  }
}

/// Strings for code without a BuildContext (e.g. after an await), using the
/// chosen language or the device's, falling back to English.
AppLocalizations l10nNow() {
  final chosen = LocaleController.instance.locale.value;
  if (chosen != null) return lookupAppLocalizations(chosen);
  for (final l in WidgetsBinding.instance.platformDispatcher.locales) {
    if (LocaleController.languages.containsKey(l.languageCode)) {
      return lookupAppLocalizations(Locale(l.languageCode));
    }
  }
  return lookupAppLocalizations(const Locale('en'));
}
