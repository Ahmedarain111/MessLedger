import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/manager_model.dart';

/// Authentication service using backend FastAPI.
/// Calls POST /auth/login and GET /auth/me.
class ApiAuthService {
  ApiAuthService({ApiClient? client, LocalStorage? storage})
      : _client = client ?? ApiClient(),
        _storage = storage ?? LocalStorage();

  final ApiClient _client;
  final LocalStorage _storage;

  Future<AuthSession> login(String username, String password) async {
    final response = await _client.post('/auth/login', data: {
      'username': username,
      'password': password,
    });

    final token = response['accessToken'] as String;
    final userJson = response['user'] as Map<String, dynamic>;

    final user = _parseUser(userJson);
    await _storage.saveToken(token);
    await _storage.saveUserId(user.id);
    await _storage.saveRole(user.role.name);

    return AuthSession(user: user, token: token);
  }

  Future<AppUser?> restoreSession() async {
    final token = await _storage.readToken();
    final userId = await _storage.readUserId();
    final roleStr = await _storage.readRole();
    if (token == null || userId == null || roleStr == null) return null;

    try {
      final userJson = await _client.get('/auth/me');
      return _parseUser(userJson as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storage.clear();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }

  AppUser _parseUser(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final username = json['username'] as String;
    final rollNumber = json['rollNumber'] as String?;
    final roomNumber = json['roomNumber'] as String?;
    final roleStr = json['role'] as String? ?? 'student';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.student,
    );

    final hostelId = json['hostelId'] as String?;
    final hostelName = json['hostelName'] as String?;

    if (role == UserRole.student) {
      return Student(
        id: id,
        name: name,
        username: username,
        rollNumber: rollNumber ?? 'N/A',
        roomNumber: roomNumber,
        hostelId: hostelId,
        hostelName: hostelName,
      );
    } else {
      return Manager(
        id: id,
        name: name,
        username: username,
        hostelId: hostelId,
        hostelName: hostelName,
      );
    }
  }
}