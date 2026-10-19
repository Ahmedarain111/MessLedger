import '../../models/enums.dart';
import '../../models/meal_model.dart';

/// Derives the public payment status from the amounts.
PaymentStatus paymentStatusFor(int totalAmount, int amountPaid) {
  if (amountPaid == 0) return PaymentStatus.unpaid;
  if (amountPaid < totalAmount) return PaymentStatus.partiallyPaid;
  return PaymentStatus.paid;
}

/// Sums approved-entry outstanding amounts only.
int outstandingBalance(List<Meal> entries, {String? studentId}) {
  return entries
      .where((entry) => entry.entryStatus == EntryStatus.approved)
      .where((entry) => studentId == null || entry.studentId == studentId)
      .fold(0, (sum, entry) => sum + entry.outstanding);
}

/// A payment allocation for a single entry.
class PaymentSettlement {
  /// The entry after allocation.
  final Meal entry;

  /// Rupees applied to this entry.
  final int applied;

  /// Whether this payment settled the entry completely.
  final bool settled;

  const PaymentSettlement({
    required this.entry,
    required this.applied,
    required this.settled,
  });
}

/// Result of applying a student's payment to their entries.
class PaymentAllocationResult {
  /// The entries that changed.
  final List<PaymentSettlement> settlements;

  /// A replacement entry list with all payments applied.
  final List<Meal> updatedEntries;

  const PaymentAllocationResult({
    required this.settlements,
    required this.updatedEntries,
  });
}

/// Applies a payment oldest-first across approved, non-paid entries.
///
/// The payment is deliberately allocated to the oldest outstanding meal first
/// so a partial payment cannot skip older liabilities.
PaymentAllocationResult allocatePayment({
  required List<Meal> entries,
  required int amount,
  required String managerId,
  required DateTime now,
}) {
  if (amount <= 0) {
    throw ArgumentError.value(amount, 'amount', 'Payment must be positive.');
  }

  final eligible = entries
      .where((entry) =>
          entry.entryStatus == EntryStatus.approved && entry.outstanding > 0)
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  final totalOutstanding =
      eligible.fold(0, (sum, entry) => sum + entry.outstanding);
  if (amount > totalOutstanding) {
    throw ArgumentError.value(
      amount,
      'amount',
      'Payment exceeds total outstanding ($totalOutstanding).',
    );
  }

  var remaining = amount;
  final updatedById = <String, Meal>{};
  final settlements = <PaymentSettlement>[];

  for (final entry in eligible) {
    if (remaining == 0) break;
    final applied = remaining >= entry.outstanding
        ? entry.outstanding
        : remaining;
    remaining -= applied;

    final isSettled = applied == entry.outstanding;
    final updated = entry.copyWith(
      amountPaid: entry.amountPaid + applied,
      paidAt: isSettled ? now : entry.paidAt,
      markedPaidBy: isSettled ? managerId : entry.markedPaidBy,
    );
    updatedById[entry.id] = updated;
    settlements.add(PaymentSettlement(
      entry: updated,
      applied: applied,
      settled: isSettled,
    ));
  }

  final updatedEntries = entries
      .map((entry) => updatedById[entry.id] ?? entry)
      .toList(growable: false);

  return PaymentAllocationResult(
    settlements: settlements,
    updatedEntries: updatedEntries,
  );
}
