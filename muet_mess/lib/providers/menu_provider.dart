import 'package:flutter/foundation.dart';

import '../models/food_item_model.dart';
import '../models/enums.dart';
import '../services/api_menu_service.dart';

class MenuProvider extends ChangeNotifier {
  MenuProvider({ApiMenuService? service}) : _service = service ?? ApiMenuService();

  final ApiMenuService _service;

  bool loading = false;
  String? error;
  List<FoodItem> dishes = [];

  Future<void> load({Shift? shift, String? category, bool includeUnavailable = false}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      dishes = await _service.getDishes(
        shift: shift,
        category: category,
        includeUnavailable: includeUnavailable,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<FoodItem> create({
    required String name,
    required int price,
    required String category,
    required List<Shift> availableIn,
    bool isAvailable = true,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final dish = await _service.createDish(
        name: name,
        price: price,
        category: category,
        availableIn: availableIn,
        isAvailable: isAvailable,
      );
      dishes = [dish, ...dishes];
      return dish;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<FoodItem> update({
    required String id,
    String? name,
    int? price,
    String? category,
    List<Shift>? availableIn,
    bool? isAvailable,
  }) async {
    loading = true;
    notifyListeners();
    try {
      final dish = await _service.updateDish(
        id: id,
        name: name,
        price: price,
        category: category,
        availableIn: availableIn,
        isAvailable: isAvailable,
      );
      final i = dishes.indexWhere((d) => d.id == id);
      if (i >= 0) dishes[i] = dish;
      return dish;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<FoodItem>> getDishes() async {
    return _service.getDishes();
  }
}
