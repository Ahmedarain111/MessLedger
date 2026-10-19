import 'enums.dart';
import 'meal_model.dart';

/// Manager dashboard summary (matches backend /dashboard/summary).
class ManagerDashboardSummary {
  const ManagerDashboardSummary({
    required this.todaySales,
    required this.totalOutstanding,
    required this.overdueAmount,
    required this.pendingApprovals,
    required this.disputedEntries,
    required this.todayByShift,
    required this.topDefaulters,
  });

  final int todaySales;
  final int totalOutstanding;
  final int overdueAmount;
  final int pendingApprovals;
  final int disputedEntries;
  final Map<Shift, int> todayByShift;
  final List<StudentSummary> topDefaulters;
}

/// Student dashboard summary (matches backend /dashboard/me/summary).
class StudentDashboardSummary {
  const StudentDashboardSummary({
    required this.outstanding,
    required this.awaitingApproval,
    required this.overdueCount,
    required this.recentEntries,
  });

  final int outstanding;
  final int awaitingApproval;
  final int overdueCount;
  final List<Meal> recentEntries;
}

/// Student summary for dashboard (matches backend StudentSummary).
class StudentSummary {
  const StudentSummary({
    required this.id,
    required this.name,
    this.rollNumber,
    this.roomNumber,
    required this.outstanding,
    required this.overdueAmount,
    required this.awaitingApproval,
  });

  final String id;
  final String name;
  final String? rollNumber;
  final String? roomNumber;
  final int outstanding;
  final int overdueAmount;
  final int awaitingApproval;
}

/// Legacy aliases for backward compatibility
@Deprecated('Use ManagerDashboardSummary instead')
class DashboardSummary {
  const DashboardSummary({
    required this.totalStudents,
    required this.pendingMeals,
    required this.approvedMeals,
    required this.rejectedMeals,
    required this.totalExpenditure,
    required this.totalPayments,
    required this.outstandingBalances,
  });

  final int totalStudents;
  final int pendingMeals;
  final int approvedMeals;
  final int rejectedMeals;
  final int totalExpenditure;
  final int totalPayments;
  final int outstandingBalances;
}

/// Per-month summary shown in reports.
class MonthlySummary {
  const MonthlySummary({
    required this.label,
    required this.expenditure,
    required this.payments,
    required this.approvedMeals,
  });

  final String label;
  final int expenditure;
  final int payments;
  final int approvedMeals;
}
