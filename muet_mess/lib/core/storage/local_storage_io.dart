import 'dart:convert';
import 'dart:io';

import '../constants/app_constants.dart';

/// JSON-file backed session store for mobile/desktop.
class LocalStorage {
  LocalStorage._();
  static final LocalStorage _instance = LocalStorage._();
  factory LocalStorage() => _instance;

  final Map<String, String> _memory = {};
  File? _file;

  Future<File?> _target() async {
    if (_file != null) return _file;
    try {
      final dir = await Directory.systemTemp.createTemp('mess_ledger_');
      _file = File('${dir.path}${Platform.pathSeparator}session.json');
      if (_file!.existsSync()) {
        final data = jsonDecode(_file!.readAsStringSync()) as Map<String, dynamic>;
        data.forEach((k, v) => _memory[k] = '$v');
      }
      return _file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist() async {
    final file = await _target();
    if (file != null) await file.writeAsString(jsonEncode(_memory));
  }

  Future<void> _set(String key, String value) async {
    _memory[key] = value;
    await _persist();
  }

  Future<String?> _get(String key) async {
    await _target();
    return _memory[key];
  }

  Future<void> saveToken(String token) => _set(AppConstants.tokenKey, token);
  Future<String?> readToken() => _get(AppConstants.tokenKey);
  Future<void> saveUserId(String id) => _set(AppConstants.userIdKey, id);
  Future<String?> readUserId() => _get(AppConstants.userIdKey);
  Future<void> saveRole(String role) => _set(AppConstants.userRoleKey, role);
  Future<String?> readRole() => _get(AppConstants.userRoleKey);
  Future<void> saveThemeMode(String mode) => _set('theme_mode', mode);
  Future<String?> readThemeMode() => _get('theme_mode');

  Future<void> clear() async {
    _memory.remove(AppConstants.tokenKey);
    _memory.remove(AppConstants.userIdKey);
    _memory.remove(AppConstants.userRoleKey);
    await _persist();
  }
}
