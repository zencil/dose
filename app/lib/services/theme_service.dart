import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() {
    return _instance;
  }

  ThemeService._internal();

  static const String _themeKey = 'app_theme_mode';
  late SharedPreferences _prefs;

  final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final String? themeString = _prefs.getString(_themeKey);
    if (themeString != null) {
      themeNotifier.value = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (mode == themeNotifier.value) return;
    themeNotifier.value = mode;
    await _prefs.setString(_themeKey, mode.toString());
  }
}
