import '../core/network/api_client.dart';
import '../models/payment_model.dart';
import '../models/meal_model.dart';
import '../models/meal_item_model.dart';
import '../models/enums.dart';

/// Payment service using backend FastAPI.
/// Calls /students/{id}/payments and /payments endpoints.
class ApiPaymentService {
  ApiPaymentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Record a payment for a student (manager only).
  Future<PaymentRecordResult> recordPayment({
    required String studentId,
    required int amount,
  }) async {
    final response = await _client.post('/students/$studentId/payments', data: {
      'amount': amount,
    });

    final paymentJson = response['payment'] as Map<String, dynamic>;
    final affectedEntriesJson = response['affectedEntries'] as List;
    final studentBalanceJson = response['studentBalance'] as Map<String, dynamic>;

    return PaymentRecordResult(
      payment: _parsePayment(paymentJson),
      affectedEntries: affectedEntriesJson
          .map((e) => _parseMeal(e as Map<String, dynamic>))
          .toList(),
      studentBalance: _parseStudentBalance(studentBalanceJson),
    );
  }

  /// Preview payment allocation (manager only).
  Future<PaymentPreview> previewPayment({
    required String studentId,
    required int amount,
  }) async {
    final response = await _client.get('/students/$studentId/payment-preview', query: {
      'amount': amount,
    });
    return PaymentPreview(
      fullySettledCount: (response['fullySettledCount'] as num).toInt(),
      partiallyPaidEntryId: response['partiallyPaidEntryId'] as String?,
      partiallyPaidAmount: (response['partiallyPaidAmount'] as num).toInt(),
    );
  }

  /// Get payments for a student (manager or self).
  Future<List<Payment>> getPayments({
    required String studentId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _client.get('/students/$studentId/payments', query: {
      'limit': limit,
      'offset': offset,
    });
    final items = response['items'] as List;
    return items.map((e) => _parsePayment(e as Map<String, dynamic>)).toList();
  }

  /// Undo a payment (manager only, within 5 minutes).
  Future<Payment> undoPayment(String paymentId) async {
    final response = await _client.post('/payments/$paymentId/undo', data: {});
    return _parsePayment(response as Map<String, dynamic>);
  }

  Payment _parsePayment(Map<String, dynamic> json) {
    final allocationsJson = json['allocations'] as List?;
    return Payment(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      amount: (json['amount'] as num).toInt(),
      recordedBy: json['recordedBy'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      isUndone: json['isUndone'] as bool? ?? false,
      undoneAt: json['undoneAt'] != null ? DateTime.parse(json['undoneAt'] as String) : null,
      allocations: allocationsJson
              ?.map((e) => PaymentAllocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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

  StudentBalance _parseStudentBalance(Map<String, dynamic> json) {
    return StudentBalance(
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

class PaymentRecordResult {
  final Payment payment;
  final List<Meal> affectedEntries;
  final StudentBalance studentBalance;

  PaymentRecordResult({
    required this.payment,
    required this.affectedEntries,
    required this.studentBalance,
  });
}

class PaymentPreview {
  final int fullySettledCount;
  final String? partiallyPaidEntryId;
  final int partiallyPaidAmount;

  PaymentPreview({
    required this.fullySettledCount,
    this.partiallyPaidEntryId,
    required this.partiallyPaidAmount,
  });
}

class StudentBalance {
  final String id;
  final String name;
  final String? rollNumber;
  final String? roomNumber;
  final int outstanding;
  final int overdueAmount;
  final int awaitingApproval;

  StudentBalance({
    required this.id,
    required this.name,
    this.rollNumber,
    this.roomNumber,
    required this.outstanding,
    required this.overdueAmount,
    required this.awaitingApproval,
  });
}