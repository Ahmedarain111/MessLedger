import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';

/// Reusable month dropdown (Jan 2026 .. current month).
class MonthFilter extends StatelessWidget {
  const MonthFilter({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final months = AppDateUtils.availableMonths(DateTime.now());
    final current = months.firstWhere(
      (m) => m.year == value.year && m.month == value.month,
      orElse: () => DateTime(value.year, value.month, 1),
    );
    return DropdownButtonHideUnderline(
      child: DropdownButton<DateTime>(
        value: current,
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(Icons.expand_more),
        items: months
            .map((m) => DropdownMenuItem<DateTime>(value: m, child: Text(AppDateUtils.monthLabel(m))))
            .toList(),
        onChanged: (m) {
          if (m != null) onChanged(m);
        },
      ),
    );
  }
}
