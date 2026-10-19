/// Centralized API endpoint definitions (future Django REST API).
class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/auth/login/';
  static const register = '/auth/register/';
  static const logout = '/auth/logout/';
  static const hostels = '/hostels/';
  static const students = '/students/';
  static const managers = '/managers/';
  static const khatas = '/khatas/';
  static const menus = '/menus/';
  static const meals = '/meals/';
  static const payments = '/payments/';
  static const notifications = '/notifications/';
  static const reports = '/reports/';

  static String khata(String id) => '/khatas/$id/';
  static String meal(String id) => '/meals/$id/';
  static String student(String id) => '/students/$id/';
}
