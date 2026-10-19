import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../services/api_dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({ApiDashboardService? service}) : _service = service ?? ApiDashboardService();

  final ApiDashboardService _service;

  bool loading = false;
  ManagerDashboardSummary? managerSummary;
  StudentDashboardSummary? mySummary;

  /// Legacy method for backward compatibility
  Future<void> load(String hostelId) async {
    await loadManager();
  }

  /// Legacy getter for backward compatibility
  DashboardSummary? get summary {
    if (managerSummary != null) {
      return DashboardSummary(
        totalStudents: managerSummary!.topDefaulters.length,
        pendingMeals: managerSummary!.pendingApprovals,
        approvedMeals: managerSummary!.todayByShift.values.reduce((a, b) => a + b),
        rejectedMeals: 0,
        totalExpenditure: managerSummary!.todaySales,
        totalPayments: 0,
        outstandingBalances: managerSummary!.totalOutstanding,
      );
    }
    return null;
  }

  /// Legacy getter for backward compatibility
  List<MonthlySummary> get months => [];

  Future<void> loadManager() async {
    loading = true;
    notifyListeners();
    try {
      managerSummary = await _service.getManagerSummary();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine() async {
    loading = true;
    notifyListeners();
    try {
      mySummary = await _service.getMySummary();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
