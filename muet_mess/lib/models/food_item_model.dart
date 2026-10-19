import 'enums.dart';

/// Official food item. Prices come from the official university rate list
/// and are never editable in the UI. UIDs are unique even when names
/// repeat (e.g. two different "Beef Qourma" entries).
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.allowedMeals,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final String imagePath;
  final Set<Shift> allowedMeals;
  final bool isAvailable;

  bool serves(Shift type) => allowedMeals.contains(type);

  FoodItem copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    String? imagePath,
    Set<Shift>? allowedMeals,
    bool? isAvailable,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      allowedMeals: allowedMeals ?? this.allowedMeals,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}