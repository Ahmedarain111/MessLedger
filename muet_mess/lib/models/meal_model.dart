import 'enums.dart';
import 'meal_item_model.dart';
import 'meal_update_model.dart';

/// A student's recorded meal entry. Only approved entries affect expenditure.
/// Matches backend Entry model.
class Meal {
  Meal({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentRollNumber,
    required this.dateTime,
    required this.shift,
    required this.items,
    this.amountPaid = 0,
    this.paidAt,
    this.markedPaidBy,
    required this.createdBy,
    this.note,
    this.entryStatus = EntryStatus.pending,
    this.isDisputed = false,
    this.disputeReason,
    this.rejectionReason,
    this.lastEditedAt,
    this.lastEditedBy,
    required this.createdAt,
    List<MealUpdate>? history,
  }) : history = history ?? [];

  final String id;
  final String studentId;
  final String? studentName;
  final String? studentRollNumber;
  final DateTime dateTime;
  final Shift shift;
  List<MealItem> items;
  int amountPaid;
  DateTime? paidAt;
  String? markedPaidBy;
  final String createdBy;
  final String? note;
  EntryStatus entryStatus;
  bool isDisputed;
  String? disputeReason;
  String? rejectionReason;
  DateTime? lastEditedAt;
  String? lastEditedBy;
  final DateTime createdAt;
  final List<MealUpdate> history;

  int get totalAmount => items.fold(0, (sum, i) => sum + i.lineTotal);
  int get outstanding => totalAmount - amountPaid;

  PaymentStatus get paymentStatus {
    if (amountPaid == 0) return PaymentStatus.unpaid;
    if (amountPaid >= totalAmount) return PaymentStatus.paid;
    return PaymentStatus.partiallyPaid;
  }

  bool get isOverdue {
    if (entryStatus != EntryStatus.approved) return false;
    if (amountPaid >= totalAmount) return false;
    final now = DateTime.now().toUtc();
    final diff = now.difference(dateTime.toUtc());
    return diff.inDays > 7;
  }

  String get itemsDescription => items.map((e) => e.describe()).join(' + ');

  Meal copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentRollNumber,
    DateTime? dateTime,
    Shift? shift,
    List<MealItem>? items,
    int? amountPaid,
    DateTime? paidAt,
    String? markedPaidBy,
    String? createdBy,
    String? note,
    EntryStatus? entryStatus,
    bool? isDisputed,
    String? disputeReason,
    String? rejectionReason,
    DateTime? lastEditedAt,
    String? lastEditedBy,
    DateTime? createdAt,
    List<MealUpdate>? history,
  }) {
    return Meal(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      dateTime: dateTime ?? this.dateTime,
      shift: shift ?? this.shift,
      items: items ?? this.items,
      amountPaid: amountPaid ?? this.amountPaid,
      paidAt: paidAt ?? this.paidAt,
      markedPaidBy: markedPaidBy ?? this.markedPaidBy,
      createdBy: createdBy ?? this.createdBy,
      note: note ?? this.note,
      entryStatus: entryStatus ?? this.entryStatus,
      isDisputed: isDisputed ?? this.isDisputed,
      disputeReason: disputeReason ?? this.disputeReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      lastEditedBy: lastEditedBy ?? this.lastEditedBy,
      createdAt: createdAt ?? this.createdAt,
      history: history ?? this.history,
    );
  }
}
