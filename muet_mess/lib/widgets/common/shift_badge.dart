import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../models/enums.dart';

/// Icon for a shift (sunrise / sun / moon).
IconData shiftIcon(Shift shift) => switch (shift) {
      Shift.breakfast => Icons.wb_twilight,
      Shift.lunch => Icons.wb_sunny,
      Shift.dinner => Icons.nights_stay,
    };

/// Theme-aware accent color for a shift.
Color shiftColor(BuildContext context, Shift shift) {
  final t = context.tokens;
  return switch (shift) {
    Shift.breakfast => t.breakfast,
    Shift.lunch => t.lunch,
    Shift.dinner => t.dinner,
  };
}

/// Tinted rounded square with the shift icon.
class ShiftBadge extends StatelessWidget {
  const ShiftBadge({super.key, required this.shift, this.size = 44});

  final Shift shift;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = shiftColor(context, shift);
    return Tooltip(
      message: shift.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(shiftIcon(shift), color: color, size: size * 0.5),
      ),
    );
  }
}
