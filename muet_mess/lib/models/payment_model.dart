/// A payment recorded by the manager.
/// Matches backend Payment model.
class Payment {
  const Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.recordedBy,
    required this.recordedAt,
    this.isUndone = false,
    this.undoneAt,
    this.allocations = const [],
  });

  final String id;
  final String studentId;
  final int amount;
  final String recordedBy;
  final DateTime recordedAt;
  final bool isUndone;
  final DateTime? undoneAt;
  final List<PaymentAllocation> allocations;

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'amount': amount,
        'recordedBy': recordedBy,
        'recordedAt': recordedAt.toIso8601String(),
        'isUndone': isUndone,
        'undoneAt': undoneAt?.toIso8601String(),
        'allocations': allocations.map((e) => e.toJson()).toList(),
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        amount: (json['amount'] as num).toInt(),
        recordedBy: json['recordedBy'] as String,
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        isUndone: json['isUndone'] as bool? ?? false,
        undoneAt: json['undoneAt'] != null ? DateTime.parse(json['undoneAt'] as String) : null,
        allocations: (json['allocations'] as List? ?? [])
            .map((e) => PaymentAllocation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Payment allocation to an entry.
class PaymentAllocation {
  const PaymentAllocation({
    required this.entryId,
    required this.amount,
  });

  final String entryId;
  final int amount;

  Map<String, dynamic> toJson() => {
        'entryId': entryId,
        'amount': amount,
      };

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) => PaymentAllocation(
        entryId: json['entryId'] as String,
        amount: (json['amount'] as num).toInt(),
      );
}
