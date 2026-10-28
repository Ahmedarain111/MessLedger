import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/meal_item_model.dart';
import '../models/meal_model.dart';
import '../services/api_meal_service.dart';

class MealProvider extends ChangeNotifier {
  MealProvider({ApiMealService? service}) : _service = service ?? ApiMealService();

  final ApiMealService _service;

  bool loading = false;
  String? error;
  List<Meal> pending = [];
  List<Meal> mine = [];

  Future<void> loadPending() async {
    loading = true;
    notifyListeners();
    try {
      pending = await _service.getEntries(status: EntryStatus.pending);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine({required String studentId}) async {
    loading = true;
    notifyListeners();
    try {
      mine = await _service.getEntries(studentId: studentId);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Meal> submit({
    required List<MealItem> items,
    DateTime? dateTime,
    Shift? shift,
    String? note,
    String? studentId,
    String? hostelId,
  }) async {
    final m = await _service.createEntry(
      items: items,
      dateTime: dateTime,
      shift: shift,
      note: note,
      studentId: studentId,
      hostelId: hostelId,
    );
    mine = [m, ...mine];
    notifyListeners();
    return m;
  }

  Future<Meal> approve(String mealId) async {
    final m = await _service.approve(mealId);
    pending = pending.where((x) => x.id != mealId).toList();
    notifyListeners();
    return m;
  }

  Future<Meal> reject(String mealId, {required String reason}) async {
    final m = await _service.reject(mealId, reason: reason);
    pending = pending.where((x) => x.id != mealId).toList();
    notifyListeners();
    return m;
  }

  Future<Meal> edit({required String mealId, required List<MealItem> newItems, required String reason}) async {
    final m = await _service.updateEntry(id: mealId, items: newItems, note: reason);
    final i = mine.indexWhere((x) => x.id == mealId);
    if (i >= 0) mine[i] = m;
    notifyListeners();
    return m;
  }

  Future<Meal> dispute(String mealId, {required String reason}) async {
    final m = await _service.dispute(mealId, reason: reason);
    final i = mine.indexWhere((x) => x.id == mealId);
    if (i >= 0) mine[i] = m;
    notifyListeners();
    return m;
  }

  Future<Meal> resolveDispute(String mealId) async {
    final m = await _service.resolveDispute(mealId);
    final i = mine.indexWhere((x) => x.id == mealId);
    if (i >= 0) mine[i] = m;
    notifyListeners();
    return m;
  }

  Future<Meal> markPaid(String mealId) async {
    final m = await _service.markPaid(mealId);
    final i = mine.indexWhere((x) => x.id == mealId);
    if (i >= 0) mine[i] = m;
    notifyListeners();
    return m;
  }

  Future<Meal> reopen(String mealId) async {
    final m = await _service.reopen(mealId);
    final i = mine.indexWhere((x) => x.id == mealId);
    if (i >= 0) mine[i] = m;
    notifyListeners();
    return m;
  }

  Future<Meal> getEntry(String id) async {
    return _service.getEntry(id);
  }

  Future<List<Meal>> getAllEntries({
    EntryStatus? status,
    Shift? shift,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
    int offset = 0,
  }) async {
    return _service.getEntries(
      status: status,
      shift: shift,
      fromDate: fromDate,
      toDate: toDate,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Meal>> getEntriesForStudent(
    String studentId, {
    EntryStatus? status,
    int limit = 100,
    int offset = 0,
  }) async {
    return _service.getEntries(
      studentId: studentId,
      status: status,
      limit: limit,
      offset: offset,
    );
  }
}
