import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider();

  bool loading = false;
  List<AppNotification> items = [];

  int get unread => items.where((n) => !n.isRead).length;

  Future<void> load(String userId) async {
    loading = true;
    notifyListeners();
    // Notifications would come from API in a real implementation
    items = [];
    loading = false;
    notifyListeners();
  }

  Future<void> markAllRead(String userId) async {
    for (final item in items) {
      item.isRead = true;
    }
    notifyListeners();
  }

  void push(AppNotification n) {
    items = [n, ...items];
    notifyListeners();
  }
}
