import 'user_model.dart';

class Manager extends AppUser {
  Manager({
    required super.id,
    required super.name,
    required super.username,
  }) : super(role: UserRole.manager);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
      };
}
