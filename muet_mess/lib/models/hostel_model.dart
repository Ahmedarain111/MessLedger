/// University hostel model.
class Hostel {
  const Hostel({
    required this.id,
    required this.name,
    this.code,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? code;
  final bool isActive;

  factory Hostel.fromJson(Map<String, dynamic> json) {
    return Hostel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (code != null) 'code': code,
    'isActive': isActive,
  };
}
