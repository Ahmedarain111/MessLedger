/// Student balance summary for dashboard
class StudentBalance {
  const StudentBalance({
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