import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../theme/app_tokens.dart';

/// Label + color + icon describing a status, resolved from theme tokens.
@immutable
class StatusStyle {
  const StatusStyle(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

StatusStyle entryStatusStyle(BuildContext context, EntryStatus status) {
  final t = context.tokens;
  return switch (status) {
    EntryStatus.pending => StatusStyle(status.label, t.pending, Icons.schedule),
    EntryStatus.approved => StatusStyle(status.label, t.success, Icons.check_circle_outline),
    EntryStatus.rejected => StatusStyle(status.label, t.danger, Icons.cancel_outlined),
  };
}

StatusStyle paymentStatusStyle(BuildContext context, PaymentStatus status) {
  final t = context.tokens;
  return switch (status) {
    PaymentStatus.unpaid => StatusStyle(status.label, t.warning, Icons.radio_button_unchecked),
    PaymentStatus.partiallyPaid => StatusStyle(status.label, t.info, Icons.timelapse),
    PaymentStatus.paid => StatusStyle(status.label, t.success, Icons.paid_outlined),
  };
}

StatusStyle overdueStyle(BuildContext context) =>
    StatusStyle('Overdue', context.tokens.overdue, Icons.warning_amber_rounded);

StatusStyle disputedStyle(BuildContext context) =>
    StatusStyle('Disputed', context.tokens.disputed, Icons.flag_outlined);
