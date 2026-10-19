/// One food item selected in an entry, with quantity.
/// Matches backend EntryItem (dish_id, dish_name snapshot, unit_price snapshot, quantity).
class MealItem {
  const MealItem({
    required this.dishId,
    required this.dishName,
    required this.unitPrice,
    required this.quantity,
  });

  final String dishId;
  final String dishName;
  final int unitPrice;
  final int quantity;

  int get lineTotal => unitPrice * quantity;

  MealItem copyWith({int? quantity}) => MealItem(
        dishId: dishId,
        dishName: dishName,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'dishId': dishId,
        'dishName': dishName,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        dishId: json['dishId'] as String,
        dishName: json['dishName'] as String,
        unitPrice: (json['unitPrice'] as num).toInt(),
        quantity: (json['quantity'] as num? ?? 1).toInt(),
      );

  String describe() => quantity > 1 ? '$dishName x$quantity' : dishName;
}
