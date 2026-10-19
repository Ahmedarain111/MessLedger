// Core enums and types shared across the project

/// User roles in the system (exactly two, per spec).
enum UserRole { student, manager }

/// Shift types served by the mess (matches backend Shift enum).
enum Shift {
  breakfast,
  lunch,
  dinner;

  String get label {
    switch (this) {
      case Shift.breakfast:
        return 'Breakfast';
      case Shift.lunch:
        return 'Lunch';
      case Shift.dinner:
        return 'Dinner';
    }
  }
}

/// Lifecycle of an entry (matches backend EntryStatus enum).
enum EntryStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case EntryStatus.pending:
        return 'Pending';
      case EntryStatus.approved:
        return 'Approved';
      case EntryStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Payment status derived from amounts (matches backend PaymentStatus enum).
enum PaymentStatus {
  unpaid,
  partiallyPaid,
  paid;

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }
}