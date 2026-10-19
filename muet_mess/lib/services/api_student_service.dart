import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/student_model.dart';

/// Student service using backend FastAPI.
/// Calls /students endpoints.
class ApiStudentService {
  ApiStudentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Get student by ID (manager or self).
  Future<Student?> getStudent(String id) async {
    try {
      final response = await _client.get('/students/$id');
      return _parseStudent(response as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// List students (manager only).
  Future<List<Student>> listStudents({
    String? search,
    String? sort,
    String? hostelId,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (search != null) query['search'] = search;
    if (sort != null) query['sort'] = sort;
    if (hostelId != null) query['hostelId'] = hostelId;

    final response = await _client.get('/students', query: query);
    final items = response['items'] as List;
    return items.map((e) => _parseStudent(e as Map<String, dynamic>)).toList();
  }

  /// Create a new student account (manager only).
  Future<Student> createStudent({
    required String name,
    required String rollNumber,
    String? roomNumber,
    String? username,
    String? password,
    String? hostelId,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'rollNumber': rollNumber.trim(),
    };
    if (roomNumber != null && roomNumber.trim().isNotEmpty) {
      data['roomNumber'] = roomNumber.trim();
    }
    if (username != null && username.trim().isNotEmpty) {
      data['username'] = username.trim();
    }
    if (password != null && password.trim().isNotEmpty) {
      data['password'] = password.trim();
    }
    if (hostelId != null && hostelId.trim().isNotEmpty) {
      data['hostelId'] = hostelId.trim();
    }

    final response = await _client.post('/students', data: data);
    return _parseStudent(response as Map<String, dynamic>);
  }

  Student _parseStudent(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String? ?? json['name'] as String,
      rollNumber: json['rollNumber'] as String? ?? 'N/A',
      roomNumber: json['roomNumber'] as String?,
      hostelId: json['hostelId'] as String?,
      hostelName: json['hostelName'] as String?,
    );
  }
}