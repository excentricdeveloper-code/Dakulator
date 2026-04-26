import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeSetting { light, dark, system }

class ThemeManager extends ValueNotifier<ThemeMode> {
  ThemeManager() : super(ThemeMode.dark);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_setting') ?? ThemeSetting.dark.index;
    final themeSetting = ThemeSetting.values[themeIndex];
    value = _getThemeMode(themeSetting);
  }

  Future<void> setTheme(ThemeSetting themeSetting) async {
    value = _getThemeMode(themeSetting);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_setting', themeSetting.index);
  }

  ThemeMode _getThemeMode(ThemeSetting setting) {
    switch (setting) {
      case ThemeSetting.light:
        return ThemeMode.light;
      case ThemeSetting.dark:
        return ThemeMode.dark;
      case ThemeSetting.system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeSetting get currentSetting {
    switch (value) {
      case ThemeMode.light:
        return ThemeSetting.light;
      case ThemeMode.dark:
        return ThemeSetting.dark;
      case ThemeMode.system:
      default:
        return ThemeSetting.system;
    }
  }
}

final themeManager = ThemeManager();
