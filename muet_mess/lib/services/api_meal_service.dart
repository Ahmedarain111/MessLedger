import '../core/network/api_client.dart';
import '../models/enums.dart';
import '../models/meal_item_model.dart';
import '../models/meal_model.dart';

/// Meal (Entry) service using backend FastAPI.
/// Calls /entries endpoints.
class ApiMealService {
  ApiMealService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Get entries for current student (or all if manager).
  Future<List<Meal>> getEntries({
    String? studentId,
    EntryStatus? status,
    Shift? shift,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (studentId != null) query['studentId'] = studentId;
    if (status != null) query['status'] = status.name;
    if (shift != null) query['shift'] = shift.name;
    if (fromDate != null) query['fromDate'] = fromDate.toUtc().toIso8601String();
    if (toDate != null) query['toDate'] = toDate.toUtc().toIso8601String();

    final response = await _client.get('/entries', query: query);
    final items = response['items'] as List;
    return items.map((e) => _parseMeal(e as Map<String, dynamic>)).toList();
  }

  /// Get single entry by ID.
  Future<Meal> getEntry(String id) async {
    final response = await _client.get('/entries/$id');
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Create a new entry (student creates pending, manager creates approved).
  Future<Meal> createEntry({
    required List<MealItem> items,
    DateTime? dateTime,
    Shift? shift,
    String? note,
    String? studentId, // Only for manager
  }) async {
    if (items.isEmpty) throw Exception('Select at least one food item');
    for (final i in items) {
      if (i.quantity < 1 || i.quantity > 20) throw Exception('Quantity must be between 1 and 20');
    }

    final data = <String, dynamic>{
      'items': items.map((e) => e.toJson()).toList(),
    };
    if (dateTime != null) data['dateTime'] = dateTime.toUtc().toIso8601String();
    if (shift != null) data['shift'] = shift.name;
    if (note != null) data['note'] = note;
    if (studentId != null) data['studentId'] = studentId;

    final response = await _client.post('/entries', data: data);
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Update an entry (manager only).
  Future<Meal> updateEntry({
    required String id,
    DateTime? dateTime,
    Shift? shift,
    List<MealItem>? items,
    String? note,
  }) async {
    if (items != null) {
      if (items.isEmpty) throw Exception('Select at least one food item');
      for (final i in items) {
        if (i.quantity < 1 || i.quantity > 20) throw Exception('Quantity must be between 1 and 20');
      }
    }

    final data = <String, dynamic>{};
    if (dateTime != null) data['dateTime'] = dateTime.toUtc().toIso8601String();
    if (shift != null) data['shift'] = shift.name;
    if (items != null) data['items'] = items.map((e) => e.toJson()).toList();
    if (note != null) data['note'] = note;

    final response = await _client.patch('/entries/$id', data: data);
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Approve a pending entry (manager only).
  Future<Meal> approve(String id) async {
    final response = await _client.post('/entries/$id/approve', data: {});
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Reject a pending entry (manager only).
  Future<Meal> reject(String id, {required String reason}) async {
    if (reason.trim().length < 3) throw Exception('A rejection reason is required');
    final response = await _client.post('/entries/$id/reject', data: {'reason': reason.trim()});
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Flag entry as disputed (student own).
  Future<Meal> dispute(String id, {required String reason}) async {
    if (reason.trim().length < 5) throw Exception('Dispute reason must be at least 5 characters');
    final response = await _client.post('/entries/$id/dispute', data: {'reason': reason.trim()});
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Resolve dispute (manager only).
  Future<Meal> resolveDispute(String id) async {
    final response = await _client.post('/entries/$id/resolve-dispute', data: {});
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Mark entry as paid (manager only).
  Future<Meal> markPaid(String id) async {
    final response = await _client.post('/entries/$id/mark-paid', data: {});
    return _parseMeal(response as Map<String, dynamic>);
  }

  /// Reopen a fully paid entry (manager only).
  Future<Meal> reopen(String id) async {
    final response = await _client.post('/entries/$id/reopen', data: {});
    return _parseMeal(response as Map<String, dynamic>);
  }

  Meal _parseMeal(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List;
    final items = itemsJson.map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList();

    return Meal(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String?,
      studentRollNumber: json['studentRollNumber'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      shift: Shift.values.firstWhere((s) => s.name == json['shift']),
      items: items,
      amountPaid: (json['amountPaid'] as num).toInt(),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      markedPaidBy: json['markedPaidBy'] as String?,
      createdBy: json['createdBy'] as String,
      note: json['note'] as String?,
      entryStatus: EntryStatus.values.firstWhere((s) => s.name == json['entryStatus']),
      isDisputed: json['isDisputed'] as bool? ?? false,
      disputeReason: json['disputeReason'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      lastEditedAt: json['lastEditedAt'] != null ? DateTime.parse(json['lastEditedAt'] as String) : null,
      lastEditedBy: json['lastEditedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}