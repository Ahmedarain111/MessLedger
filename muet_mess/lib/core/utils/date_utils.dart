import 'package:intl/intl.dart';

/// Date helpers shared across screens.
class AppDateUtils {
  AppDateUtils._();

  static final _day = DateFormat('dd MMM');
  static final _dayFull = DateFormat('dd MMM yyyy');
  static final _time = DateFormat('h:mm a');
  static final _month = DateFormat('MMMM yyyy');
  static final _monthYearShort = DateFormat('MMM yyyy');

  static String day(DateTime d) => _day.format(d);
  static String dayFull(DateTime d) => _dayFull.format(d);
  static String time(DateTime d) => _time.format(d);
  static String dateTime(DateTime d) => '${_dayFull.format(d)}, ${_time.format(d)}';
  static String monthLabel(DateTime d) => _month.format(d);
  static String monthYearShort(DateTime d) => _monthYearShort.format(d);
  static String key(DateTime d) => DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  static String dateText(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isInMonth(DateTime d, int year, int month) => d.year == year && d.month == month;

  /// Months starting January 2026 up to the current month (inclusive).
  static List<DateTime> availableMonths(DateTime now) {
    final start = DateTime(2026, 1, 1);
    var cur = DateTime(now.year, now.month, 1);
    final list = <DateTime>[];
    var cursor = start;
    while (!cursor.isAfter(cur)) {
      list.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    if (list.isEmpty) list.add(cur);
    return list.reversed.toList();
  }
}
