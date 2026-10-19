import 'package:flutter/material.dart';

import 'light_theme.dart';
import 'dark_theme.dart';

/// Builds [ThemeData] from the centralized palette.
class AppTheme {
  AppTheme._();

  static ThemeData get light => LightTheme.theme;
  static ThemeData get dark => DarkTheme.theme;

  static ThemeMode modeFromString(String? value) =>
      value == 'dark' ? ThemeMode.dark : ThemeMode.light;
}
