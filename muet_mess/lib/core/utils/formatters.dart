import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

String money(int amount) => 'Rs. ${NumberFormat('#,##0').format(amount)}';
String dateTimeText(DateTime value) => DateFormat('dd MMM yyyy, hh:mm a').format(value);
String dateText(DateTime value) => DateFormat('dd MMM yyyy').format(value);

bool isOverdue(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  return current.difference(dateTime) > AppConstants.overdueThreshold;
}

String shiftLabel(String shift) => switch (shift) {
      'breakfast' => 'Breakfast',
      'lunch' => 'Lunch',
      'dinner' => 'Dinner',
      _ => shift,
    };

String autoShift(DateTime time) {
  final hour = time.hour;
  if (hour >= 6 && hour < 11) return 'breakfast';
  if (hour >= 11 && hour < 17) return 'lunch';
  return 'dinner';
}
