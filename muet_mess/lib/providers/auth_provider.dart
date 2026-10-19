import 'package:flutter/foundation.dart';

import '../models/manager_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../services/api_auth_service.dart';

/// Holds the signed-in session and exposes login/logout to the UI.
class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiAuthService? service}) : _service = service ?? ApiAuthService();

  final ApiAuthService _service;

  bool loading = false;
  String? error;
  AppUser? user;
  String? token;

  bool get isAuthenticated => user != null;
  bool get isStudent => user is Student;
  bool get isManager => user is Manager;
  UserRole? get role => user?.role;

  Future<void> restore() async {
    loading = true;
    notifyListeners();
    try {
      user = await _service.restoreSession();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final session = await _service.login(username, password);
      user = session.user;
      token = session.token;
      return true;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    token = null;
    notifyListeners();
  }
}
