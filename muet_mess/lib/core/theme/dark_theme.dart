import 'package:flutter/material.dart';

import 'app_theme_builder.dart';

class DarkTheme {
  DarkTheme._();

  static ThemeData get theme => buildAppTheme(Brightness.dark);
}
