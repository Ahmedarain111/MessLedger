/// Centralized API endpoint constants for FastAPI backend (/api/v1).
class ApiEndpoints {
  ApiEndpoints._();

  static const login = '/auth/login';
  static const me = '/auth/me';
  static const hostels = '/hostels';
  static const students = '/students';
  static const dishes = '/dishes';
  static const entries = '/entries';
  static const payments = '/payments';
  static const dashboardSummary = '/dashboard/summary';
  static const mySummary = '/dashboard/me/summary';

  static String entry(String id) => '/entries/$id';
  static String student(String id) => '/students/$id';
  static String studentPayments(String studentId) => '/students/$studentId/payments';
  static String studentPaymentPreview(String studentId) => '/students/$studentId/payment-preview';
}
