import 'enums.dart';
export 'enums.dart' show UserRole;

/// Common fields shared by student and manager accounts.
abstract class AppUser {
  AppUser({required this.id, required this.name, required this.username, required this.role});

  final String id;
  final String name;
  final String username;
  final UserRole role;
}

class AuthSession {
  AuthSession({required this.user, required this.token});

  final AppUser user;
  final String token;
}
