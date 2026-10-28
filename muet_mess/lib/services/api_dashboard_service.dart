import '../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../models/meal_model.dart';
import '../models/meal_item_model.dart';
import '../models/enums.dart';

/// Dashboard service using backend FastAPI.
/// Calls /dashboard/summary and /dashboard/me/summary.
class ApiDashboardService {
  ApiDashboardService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Get full dashboard summary (manager only).
  Future<ManagerDashboardSummary> getManagerSummary() async {
    final response = await _client.get('/dashboard/summary');
    return ManagerDashboardSummary(
      todaySales: (response['todaySales'] as num).toInt(),
      totalOutstanding: (response['totalOutstanding'] as num).toInt(),
      overdueAmount: (response['overdueAmount'] as num).toInt(),
      pendingApprovals: (response['pendingApprovals'] as num).toInt(),
      disputedEntries: (response['disputedEntries'] as num).toInt(),
      todayByShift: {
        Shift.breakfast: (response['todayByShift']['breakfast'] as num? ?? 0).toInt(),
        Shift.lunch: (response['todayByShift']['lunch'] as num? ?? 0).toInt(),
        Shift.dinner: (response['todayByShift']['dinner'] as num? ?? 0).toInt(),
      },
      topDefaulters: (response['topDefaulters'] as List? ?? [])
          .map((e) => _parseStudentSummary(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get own dashboard summary (student only).
  Future<StudentDashboardSummary> getMySummary() async {
    final response = await _client.get('/dashboard/me/summary');
    final recentEntriesJson = response['recentEntries'] as List? ?? [];
    return StudentDashboardSummary(
      outstanding: (response['outstanding'] as num).toInt(),
      awaitingApproval: (response['awaitingApproval'] as num).toInt(),
      overdueCount: (response['overdueCount'] as num).toInt(),
      recentEntries: recentEntriesJson
          .map((e) => _parseMeal(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Meal _parseMeal(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List;
    final items = itemsJson.map((e) => MealItem.fromJson(e as Map<String, dynamic>)).toList();

    return Meal(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String?,
      studentRollNumber: json['studentRollNumber'] as String?,
      hostelId: json['hostelId'] as String?,
      hostelName: json['hostelName'] as String?,
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

  StudentSummary _parseStudentSummary(Map<String, dynamic> json) {
    return StudentSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      rollNumber: json['rollNumber'] as String?,
      roomNumber: json['roomNumber'] as String?,
      outstanding: (json['outstanding'] as num).toInt(),
      overdueAmount: (json['overdueAmount'] as num).toInt(),
      awaitingApproval: (json['awaitingApproval'] as num).toInt(),
    );
  }
}