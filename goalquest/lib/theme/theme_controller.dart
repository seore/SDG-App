import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Light / dark / follow-system setting, remembered between launches.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_mode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      mode.value = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {
      // Preferences unavailable (e.g. tests) – keep following the system.
    }
  }

  Future<void> setMode(ThemeMode value) async {
    mode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, value.name);
    } catch (_) {}
  }

  /// The palette to use for [mode] given the device's [platform] brightness.
  AppPalette paletteFor(Brightness platform) {
    final dark = switch (mode.value) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platform == Brightness.dark,
    };
    return dark ? AppPalette.dark : AppPalette.light;
  }
}

/// Marks every element below [context] for rebuild, so widgets that read
/// [AppColors] (including const ones) repaint with the new palette while
/// keeping their state, navigation stack and scroll positions.
void rebuildAllChildren(BuildContext context) {
  void mark(Element el) {
    el.markNeedsBuild();
    el.visitChildren(mark);
  }

  (context as Element).visitChildren(mark);
}
