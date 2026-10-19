import 'package:flutter/material.dart';

import '../core/storage/local_storage.dart';

/// Persists the selected theme mode.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({LocalStorage? storage}) : _storage = storage ?? LocalStorage();

  final LocalStorage _storage;

  ThemeMode mode = ThemeMode.light;

  Future<void> load() async {
    final saved = await _storage.readThemeMode();
    mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _storage.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
