import 'package:flutter/foundation.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const appName = 'Mess Ledger';
  static const currencySymbol = 'Rs.';
  static const tokenKey = 'auth_token';
  static const userIdKey = 'auth_user_id';
  static const userRoleKey = 'auth_user_role';
  static const minReasonLength = 3;
  static String get apiBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000/api/v1";
    }
    return "http://localhost:8000/api/v1";
  }
  static const requestTimeoutSeconds = 30;
  static const overdueThreshold = Duration(days: 7);

  static const demoStudentUsername = 'ahmed';
  static const demoStudentPassword = 'student123';
  static const demoManagerUsername = 'manager';
  static const demoManagerPassword = 'manager123';
}
