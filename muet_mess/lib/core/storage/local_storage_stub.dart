import '../constants/app_constants.dart';

/// In-memory session store used on web and in tests.
class LocalStorage {
  LocalStorage._();
  static final LocalStorage _instance = LocalStorage._();
  factory LocalStorage() => _instance;

  final Map<String, String> _memory = {};

  Future<void> saveToken(String token) async => _memory[AppConstants.tokenKey] = token;
  Future<String?> readToken() async => _memory[AppConstants.tokenKey];
  Future<void> saveUserId(String id) async => _memory[AppConstants.userIdKey] = id;
  Future<String?> readUserId() async => _memory[AppConstants.userIdKey];
  Future<void> saveRole(String role) async => _memory[AppConstants.userRoleKey] = role;
  Future<String?> readRole() async => _memory[AppConstants.userRoleKey];
  Future<void> saveThemeMode(String mode) async => _memory['theme_mode'] = mode;
  Future<String?> readThemeMode() async => _memory['theme_mode'];

  Future<void> clear() async {
    _memory.remove(AppConstants.tokenKey);
    _memory.remove(AppConstants.userIdKey);
    _memory.remove(AppConstants.userRoleKey);
  }
}
