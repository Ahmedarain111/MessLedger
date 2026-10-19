import 'package:flutter/material.dart';

import 'app_theme_builder.dart';

class LightTheme {
  LightTheme._();

  static ThemeData get theme => buildAppTheme(Brightness.light);
}
