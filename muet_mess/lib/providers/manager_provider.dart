import 'package:flutter/foundation.dart';

import '../models/student_model.dart';
import '../services/api_student_service.dart';

class ManagerProvider extends ChangeNotifier {
  ManagerProvider({ApiStudentService? service}) : _service = service ?? ApiStudentService();

  final ApiStudentService _service;

  bool loading = false;
  String? error;
  List<Student> students = [];
  String query = '';

  Future<void> search(String q) async {
    query = q;
    loading = true;
    notifyListeners();
    try {
      students = await _service.listStudents(search: q);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
