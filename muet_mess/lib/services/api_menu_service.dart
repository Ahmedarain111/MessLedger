import '../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/food_item_model.dart';

/// Menu (Dishes) service using backend FastAPI.
/// Calls /dishes endpoints.
class ApiMenuService {
  ApiMenuService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Get dishes (menu) with optional filters.
  Future<List<FoodItem>> getDishes({
    Shift? shift,
    String? category,
    bool includeUnavailable = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (shift != null) query['shift'] = shift.name;
    if (category != null) query['category'] = category;
    if (includeUnavailable) query['includeUnavailable'] = true;

    final response = await _client.get('/dishes', query: query);
    final items = response['items'] as List;
    return items.map((e) => _parseDish(e as Map<String, dynamic>)).toList();
  }

  /// Create a dish (manager only).
  Future<FoodItem> createDish({
    required String name,
    required int price,
    required String category,
    required List<Shift> availableIn,
    bool isAvailable = true,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'price': price,
      'category': category,
      'availableIn': availableIn.map((s) => s.name).toList(),
      'isAvailable': isAvailable,
    };
    final response = await _client.post('/dishes', data: data);
    return _parseDish(response as Map<String, dynamic>);
  }

  /// Update a dish (manager only).
  Future<FoodItem> updateDish({
    required String id,
    String? name,
    int? price,
    String? category,
    List<Shift>? availableIn,
    bool? isAvailable,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (price != null) data['price'] = price;
    if (category != null) data['category'] = category;
    if (availableIn != null) data['availableIn'] = availableIn.map((s) => s.name).toList();
    if (isAvailable != null) data['isAvailable'] = isAvailable;

    final response = await _client.patch('/dishes/$id', data: data);
    return _parseDish(response as Map<String, dynamic>);
  }

  FoodItem _parseDish(Map<String, dynamic> json) {
    final availableInJson = json['availableIn'] as List;
    final availableIn = availableInJson
        .map((s) => Shift.values.firstWhere((e) => e.name == s))
        .toSet();

    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      category: json['category'] as String? ?? 'Main',
      imagePath: json['imageUrl'] as String? ?? 'assets/food/default.png',
      allowedMeals: availableIn,
    );
  }
}