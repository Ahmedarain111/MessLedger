/// Route path constants.
class RouteNames {
  RouteNames._();

  static const splash = '/splash';
  static const login = '/login';
  static const registerStudent = '/register/student';
  static const registerManager = '/register/manager';

  static const studentHome = '/student/home';
  static const studentKhatas = '/student/khatas';
  static const studentMenu = '/student/menu';
  static const studentNotifications = '/student/notifications';
  static const studentProfile = '/student/profile';
  static const studentEnterMeal = '/student/enter-meal';
  static const studentKhata = '/student/khata';
  static const studentMeal = '/student/meal/:id';
  static const studentMealDispute = '/student/meal/:id/dispute';
  static const studentPayments = '/student/payments';

  static const managerDashboard = '/manager/dashboard';
  static const managerStudents = '/manager/students';
  static const managerStudentDetails = '/manager/students/:id';
  static const managerStudentKhata = '/manager/students/:id/khata';
  static const managerStudentPayment = '/manager/students/:id/payment';
  static const managerApprovals = '/manager/approvals';
  static const managerMenu = '/manager/menu';
  static const managerReports = '/manager/reports';
  static const managerPayments = '/manager/payments';
  static const managerNotifications = '/manager/notifications';
  static const managerProfile = '/manager/profile';
  static const managerMeal = '/manager/meal/:id';
  static const managerEntryNew = '/manager/entry/new';
}
