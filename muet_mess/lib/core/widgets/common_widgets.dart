import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/meal_item_model.dart';
import '../../models/meal_model.dart';
import '../../widgets/common/food_image.dart';
import '../../widgets/common/shift_badge.dart';
import '../../widgets/common/motion.dart';
import '../theme/app_tokens.dart';
import '../utils/formatters.dart';
import 'status_style.dart';

class AmountText extends StatelessWidget {
  final int amount;
  final bool bold;
  final Color? color;
  final double? size;
  const AmountText(this.amount, {super.key, this.bold = false, this.color, this.size});

  @override
  Widget build(BuildContext context) => Text(
        money(amount),
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: size,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
}

/// Compact status pill (tinted background, readable foreground in both
/// light and dark mode).
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const StatusChip({super.key, required this.label, required this.color, required this.icon});

  factory StatusChip.style(StatusStyle style, {Key? key}) =>
      StatusChip(key: key, label: style.label, color: style.color, icon: style.icon);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hsl = HSLColor.fromColor(color);
    final foreground = hsl
        .withLightness(dark ? math.max(hsl.lightness, 0.72) : math.min(hsl.lightness, 0.3))
        .toColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: foreground),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: foreground, height: 1.1),
        ),
      ]),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb(this.size, this.opacity);

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
      );
}

/// Gradient hero card showing a headline amount. Indigo by default, warm
/// coral when [warning] is set (the user owes money).
class BalanceCard extends StatelessWidget {
  final int amount;
  final String title;
  final String? subtitle;
  final bool warning;
  const BalanceCard({super.key, required this.amount, required this.title, this.subtitle, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final colors = warning ? tokens.owingGradient : tokens.heroGradient;
    final onHero = tokens.onHero;
    final animate = !reduceMotion(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          const Positioned(right: -34, top: -34, child: _Orb(150, 0.08)),
          const Positioned(right: 54, bottom: -64, child: _Orb(120, 0.06)),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: onHero.withValues(alpha: 0.16)),
                  child: Icon(
                    warning ? Icons.receipt_long : Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: onHero,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: text.labelLarge?.copyWith(color: onHero.withValues(alpha: 0.9))),
                ),
              ]),
              const SizedBox(height: 16),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: amount),
                duration: animate ? const Duration(milliseconds: 700) : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    money(value),
                    style: text.headlineLarge?.copyWith(
                      color: onHero,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: onHero.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(subtitle!, style: text.bodyMedium?.copyWith(color: onHero, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

class SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const SummaryStatCard({super.key, required this.title, required this.value, required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Overlapping dish thumbnails for an entry's items.
class _ItemThumbs extends StatelessWidget {
  const _ItemThumbs(this.items);

  final List<MealItem> items;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const step = 21.0;
    final scheme = Theme.of(context).colorScheme;
    final shown = items.take(3).toList();
    final more = items.length - shown.length;
    final count = shown.length + (more > 0 ? 1 : 0);
    if (count == 0) return const SizedBox.shrink();
    return SizedBox(
      width: size + (count - 1) * step + 4,
      height: size + 4,
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(
            left: i * step,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
              child: FoodImage(name: shown[i].dishName, size: size, radius: size / 2),
            ),
          ),
        if (more > 0)
          Positioned(
            left: shown.length * step,
            top: 0,
            child: Container(
              width: size + 4,
              height: size + 4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: Text('+$more', style: Theme.of(context).textTheme.labelSmall),
            ),
          ),
      ]),
    );
  }
}

class EntryCard extends StatelessWidget {
  final Meal entry;
  final String? studentName;
  final VoidCallback? onTap;
  final List<Widget> actions;

  const EntryCard({
    super.key,
    required this.entry,
    this.studentName,
    this.onTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final displayName = (studentName != null && studentName!.isNotEmpty)
        ? studentName!
        : (entry.studentName != null && entry.studentName!.isNotEmpty)
            ? entry.studentName!
            : entry.studentId;
    final approved = entry.entryStatus == EntryStatus.approved;
    final overdue = approved && entry.outstanding > 0 && isOverdue(entry.dateTime);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShiftBadge(shift: entry.shift),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: text.titleSmall?.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${dateText(entry.dateTime)} • ${shiftLabel(entry.shift.name)}${entry.hostelName != null ? ' • ${entry.hostelName}' : ''}',
                    style: text.bodySmall,
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              AmountText(entry.totalAmount, bold: true, size: 16),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _ItemThumbs(entry.items),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.items.map((i) => '${i.dishName} x${i.quantity}').join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (entry.hostelName != null)
                StatusChip(
                  label: '${entry.hostelName} Mess',
                  color: scheme.primary,
                  icon: Icons.apartment_outlined,
                ),
              StatusChip.style(entryStatusStyle(context, entry.entryStatus)),
              if (approved) StatusChip.style(paymentStatusStyle(context, entry.paymentStatus)),
              if (overdue) StatusChip.style(overdueStyle(context)),
              if (entry.isDisputed) StatusChip.style(disputedStyle(context)),
            ]),
            if (approved && entry.outstanding > 0) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.account_balance_wallet_outlined, size: 16, color: scheme.error),
                const SizedBox(width: 6),
                Text(
                  'Outstanding ${money(entry.outstanding)}',
                  style: text.labelLarge?.copyWith(color: scheme.error),
                ),
              ]),
            ] else if (entry.entryStatus == EntryStatus.pending) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.hourglass_empty, size: 15, color: context.tokens.pending),
                const SizedBox(width: 6),
                Text('Awaiting manager approval', style: text.bodySmall),
              ]),
            ],
            if (actions.isNotEmpty) ...[
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          ]),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.inbox_outlined, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.7), shape: BoxShape.circle),
              child: Icon(icon, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ]),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.title, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.errorContainer, shape: BoxShape.circle),
              child: Icon(Icons.cloud_off, size: 42, color: scheme.error),
            ),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
            ],
          ]),
        ),
      ),
    );
  }
}
