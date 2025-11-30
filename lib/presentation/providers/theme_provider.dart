import 'package:flutter/material.dart';

/// Theme settings provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> init() async {
    // TODO: Load theme setting from SharedPreferences
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    _saveThemeMode();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    _saveThemeMode();
  }

  Future<void> _saveThemeMode() async {
    // TODO: Save theme mode to SharedPreferences
  }
}
