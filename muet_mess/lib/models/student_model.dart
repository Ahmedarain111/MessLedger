import 'user_model.dart';

class Student extends AppUser {
  Student({
    required super.id,
    required super.name,
    required super.username,
    required this.rollNumber,
    this.roomNumber,
  }) : super(role: UserRole.student);

  final String rollNumber;
  final String? roomNumber;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'rollNumber': rollNumber,
        'roomNumber': roomNumber,
      };
}
