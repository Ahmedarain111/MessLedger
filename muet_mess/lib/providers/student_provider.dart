import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../models/student_model.dart';
import '../services/api_dashboard_service.dart';
import '../services/api_student_service.dart';

class StudentProvider extends ChangeNotifier {
  StudentProvider({ApiStudentService? service, ApiDashboardService? dashboardService})
      : _service = service ?? ApiStudentService(),
        _dashboardService = dashboardService ?? ApiDashboardService();

  final ApiStudentService _service;
  final ApiDashboardService _dashboardService;

  bool loading = false;
  String? error;
  Student? current;
  StudentDashboardSummary? balance;

  Future<void> load(String id) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      current = await _service.getStudent(id);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<StudentDashboardSummary?> loadBalance() async {
    try {
      final summary = await _dashboardService.getMySummary();
      balance = summary;
      return balance;
    } catch (e) {
      error = e.toString();
      return null;
    }
  }

  Future<Student?> getStudent(String id) async {
    try {
      return await _service.getStudent(id);
    } catch (e) {
      error = e.toString();
      return null;
    }
  }

  Future<List<Student>> listStudents({String? search, String? sort, String? hostelId}) async {
    try {
      return await _service.listStudents(search: search, sort: sort, hostelId: hostelId);
    } catch (e) {
      error = e.toString();
      return [];
    }
  }

  Future<Student?> createStudent({
    required String name,
    required String rollNumber,
    String? roomNumber,
    String? username,
    String? password,
    String? hostelId,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final student = await _service.createStudent(
        name: name,
        rollNumber: rollNumber,
        roomNumber: roomNumber,
        username: username,
        password: password,
        hostelId: hostelId,
      );
      return student;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
