import 'meal_item_model.dart';

/// Audit history entry for a meal update.
class MealUpdate {
  MealUpdate({
    required this.id,
    required this.updatedBy,
    required this.updatedAt,
    required this.reason,
    required this.oldItems,
    required this.newItems,
    required this.oldAmount,
    required this.newAmount,
  });

  final String id;
  final String updatedBy;
  final DateTime updatedAt;
  final String reason;
  final List<MealItem> oldItems;
  final List<MealItem> newItems;
  final int oldAmount;
  final int newAmount;

  String get oldDescription => oldItems.map((e) => e.describe()).join(' + ');
  String get newDescription => newItems.map((e) => e.describe()).join(' + ');
}