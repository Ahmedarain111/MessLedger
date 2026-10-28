import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/status_style.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/food_image.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/shift_badge.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/user_avatar.dart';

class EntryDetailScreen extends StatefulWidget {
  final String id;
  const EntryDetailScreen({super.key, required this.id});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late Future<Meal> _entryFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _entryFuture = context.read<MealProvider>().getEntry(widget.id);
  }

  void _reload() {
    setState(() {
      _entryFuture = context.read<MealProvider>().getEntry(widget.id);
    });
  }

  void _leave({required bool manager}) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(manager ? RouteNames.managerApprovals : RouteNames.studentKhata);
    }
  }

  Future<void> _approve(Meal entry, {required bool manager}) async {
    final mealProvider = context.read<MealProvider>();
    setState(() => _busy = true);
    try {
      await mealProvider.approve(entry.id);
      if (!mounted) return;
      showSuccess(context, 'Entry approved.');
      _leave(manager: manager);
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject(Meal entry, {required bool manager}) async {
    final reason = await reasonDialog(
      context,
      title: 'Reject entry',
      message: 'The student will see this reason.',
      hint: 'Reason',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (reason == null || !mounted) return;
    final mealProvider = context.read<MealProvider>();
    setState(() => _busy = true);
    try {
      await mealProvider.reject(entry.id, reason: reason.isEmpty ? 'Rejected by manager' : reason);
      if (!mounted) return;
      showInfo(context, 'Entry rejected.');
      _leave(manager: manager);
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolveDispute(Meal entry) async {
    final mealProvider = context.read<MealProvider>();
    setState(() => _busy = true);
    try {
      await mealProvider.resolveDispute(entry.id);
      if (!mounted) return;
      showSuccess(context, 'Dispute resolved.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markPaid(Meal entry) async {
    final mealProvider = context.read<MealProvider>();
    setState(() => _busy = true);
    try {
      await mealProvider.markPaid(entry.id);
      if (!mounted) return;
      showSuccess(context, 'Entry marked as paid.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reopen(Meal entry) async {
    final confirm = await confirmDialog(
      context,
      title: 'Reopen Entry',
      message: 'This will reset the payment status to unpaid so it can be settled again.',
      confirmLabel: 'Reopen',
    );
    if (confirm != true || !mounted) return;
    final mealProvider = context.read<MealProvider>();
    setState(() => _busy = true);
    try {
      await mealProvider.reopen(entry.id);
      if (!mounted) return;
      showInfo(context, 'Entry reopened.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Meal>(
      future: _entryFuture,
      builder: (context, snapshot) {
        final appBar = AppBar(title: const Text('Entry Detail'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const ListSkeleton(itemCount: 3, itemHeight: 140));
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: appBar,
            body: ErrorState(title: 'Could not load entry', message: snapshot.error.toString(), onRetry: _reload),
          );
        }
        if (snapshot.data == null) {
          return Scaffold(
            appBar: appBar,
            body: const EmptyState(title: 'Entry not found', message: 'The requested entry could not be loaded.', icon: Icons.search_off),
          );
        }
        final entry = snapshot.data!;
        final auth = context.watch<AuthProvider>();
        final user = auth.user;
        final canManage = user?.role == UserRole.manager;
        final approved = entry.entryStatus == EntryStatus.approved;
        final overdue = approved && entry.outstanding > 0 && isOverdue(entry.dateTime);
        final scheme = Theme.of(context).colorScheme;
        final text = Theme.of(context).textTheme;
        final tokens = context.tokens;
        final progress = entry.totalAmount > 0 ? (entry.amountPaid / entry.totalAmount).clamp(0.0, 1.0).toDouble() : 0.0;

        return Scaffold(
          appBar: appBar,
          body: ContentList(
            maxWidth: 760,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              FadeSlideIn(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (entry.studentName != null) ...[
                        Row(children: [
                          UserAvatar(name: entry.studentName!, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(entry.studentName!, style: text.titleMedium),
                              if (entry.studentRollNumber != null) Text(entry.studentRollNumber!, style: text.bodySmall),
                            ]),
                          ),
                        ]),
                        const Divider(height: 28),
                      ],
                      Row(children: [
                        ShiftBadge(shift: entry.shift, size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(shiftLabel(entry.shift.name), style: text.titleMedium),
                            const SizedBox(height: 2),
                            Text(dateTimeText(entry.dateTime), style: text.bodySmall),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (entry.hostelName != null)
                          StatusChip(
                            label: '${entry.hostelName} Mess',
                            icon: Icons.apartment_rounded,
                            color: scheme.primary,
                          ),
                        StatusChip.style(entryStatusStyle(context, entry.entryStatus)),
                        if (approved) StatusChip.style(paymentStatusStyle(context, entry.paymentStatus)),
                        if (overdue) StatusChip.style(overdueStyle(context)),
                        if (entry.isDisputed) StatusChip.style(disputedStyle(context)),
                      ]),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Items', style: text.titleMedium),
                      const SizedBox(height: 12),
                      for (final i in entry.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            FoodImage(name: i.dishName, size: 48, radius: 14),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(i.dishName, style: text.titleSmall),
                                Text('${i.quantity} × ${money(i.unitPrice)}', style: text.bodySmall),
                              ]),
                            ),
                            AmountText(i.lineTotal, bold: true),
                          ]),
                        ),
                      const Divider(height: 24),
                      _TotalRow(label: 'Grand total', amount: entry.totalAmount, bold: true),
                      const SizedBox(height: 8),
                      _TotalRow(label: 'Paid', amount: entry.amountPaid),
                      const SizedBox(height: 8),
                      _TotalRow(
                        label: 'Outstanding',
                        amount: entry.outstanding,
                        bold: true,
                        color: entry.outstanding > 0 ? scheme.error : tokens.success,
                      ),
                      if (approved && entry.totalAmount > 0) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            color: tokens.success,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('${money(entry.amountPaid)} of ${money(entry.totalAmount)} paid', style: text.bodySmall),
                      ],
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(index: 2, child: _StatusTimeline(entry: entry)),
              if (entry.isDisputed || entry.rejectionReason != null || entry.disputeReason != null) ...[
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 3,
                  child: Column(children: [
                    if (entry.rejectionReason != null)
                      _CalloutCard(
                        icon: Icons.cancel_outlined,
                        color: tokens.danger,
                        title: 'Rejected',
                        message: entry.rejectionReason!,
                      ),
                    if (entry.disputeReason != null) ...[
                      if (entry.rejectionReason != null) const SizedBox(height: 12),
                      _CalloutCard(
                        icon: Icons.flag_outlined,
                        color: tokens.disputed,
                        title: 'Dispute raised',
                        message: entry.disputeReason!,
                      ),
                    ],
                  ]),
                ),
              ],
              if (entry.note != null) ...[
                const SizedBox(height: 12),
                _CalloutCard(icon: Icons.notes, color: scheme.primary, title: 'Note', message: entry.note!),
              ],
              if (entry.createdBy != entry.studentId ||
                  entry.paidAt != null ||
                  entry.markedPaidBy != null ||
                  entry.lastEditedAt != null ||
                  entry.lastEditedBy != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Audit trail', style: text.titleMedium),
                      const SizedBox(height: 10),
                      _InfoRow(icon: Icons.person_outline, label: 'Created by', value: entry.createdBy),
                      if (entry.markedPaidBy != null)
                        _InfoRow(icon: Icons.payments_outlined, label: 'Paid by', value: entry.markedPaidBy!),
                      if (entry.paidAt != null)
                        _InfoRow(icon: Icons.event_available, label: 'Paid at', value: dateTimeText(entry.paidAt!)),
                      if (entry.lastEditedBy != null)
                        _InfoRow(icon: Icons.edit_outlined, label: 'Edited by', value: entry.lastEditedBy!),
                    ]),
                  ),
                ),
              ],
              if (canManage && entry.entryStatus == EntryStatus.pending) ...[
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: scheme.error, side: BorderSide(color: scheme.error.withValues(alpha: 0.6))),
                      onPressed: _busy ? null : () => _reject(entry, manager: true),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: tokens.success, foregroundColor: tokens.onHero),
                      onPressed: _busy ? null : () => _approve(entry, manager: true),
                      icon: _busy
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: tokens.onHero))
                          : const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ]),
              ],
              if (canManage && entry.isDisputed) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: tokens.disputed, foregroundColor: tokens.onHero),
                  onPressed: _busy ? null : () => _resolveDispute(entry),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Resolve Dispute'),
                ),
              ],
              if (canManage && approved && entry.outstanding > 0) ...[
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _markPaid(entry),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Mark as Paid'),
                ),
              ],
              if (canManage && entry.paymentStatus == PaymentStatus.paid) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _reopen(entry),
                  icon: const Icon(Icons.replay),
                  label: const Text('Reopen Entry'),
                ),
              ],
              if (canManage && entry.paymentStatus != PaymentStatus.paid) ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => context.push('/entries/${entry.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Entry'),
                ),
              ],
              if (user?.role == UserRole.student &&
                  entry.studentId == user?.id &&
                  !entry.isDisputed &&
                  entry.entryStatus == EntryStatus.approved) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => context.push('/entries/${entry.id}/dispute'),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Raise dispute'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.amount, this.bold = false, this.color});

  final String label;
  final int amount;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(children: [
      Expanded(child: Text(label, style: bold ? text.titleSmall : text.bodyMedium)),
      AmountText(amount, bold: bold, color: color, size: bold ? 16 : null),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: text.bodyMedium),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.end, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _CalloutCard extends StatelessWidget {
  const _CalloutCard({required this.icon, required this.color, required this.title, required this.message});

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.titleSmall),
            const SizedBox(height: 2),
            Text(message, style: text.bodyMedium),
          ]),
        ),
      ]),
    );
  }
}

enum _StepState { done, current, todo, error }

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.entry});

  final Meal entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final steps = <_TimelineStep>[
      _TimelineStep(title: 'Submitted', subtitle: dateTimeText(entry.createdAt), state: _StepState.done),
    ];
    switch (entry.entryStatus) {
      case EntryStatus.pending:
        steps.add(const _TimelineStep(title: 'Awaiting approval', subtitle: 'A manager will review this entry', state: _StepState.current));
        steps.add(const _TimelineStep(title: 'Payment', subtitle: 'Starts after approval', state: _StepState.todo));
      case EntryStatus.approved:
        steps.add(const _TimelineStep(title: 'Approved', state: _StepState.done));
        switch (entry.paymentStatus) {
          case PaymentStatus.paid:
            steps.add(_TimelineStep(
              title: 'Paid in full',
              subtitle: entry.paidAt != null ? dateTimeText(entry.paidAt!) : null,
              state: _StepState.done,
            ));
          case PaymentStatus.partiallyPaid:
            steps.add(_TimelineStep(
              title: 'Partially paid',
              subtitle: '${money(entry.amountPaid)} of ${money(entry.totalAmount)}',
              state: _StepState.current,
            ));
          case PaymentStatus.unpaid:
            steps.add(_TimelineStep(title: 'Payment due', subtitle: 'Outstanding ${money(entry.outstanding)}', state: _StepState.current));
        }
      case EntryStatus.rejected:
        steps.add(const _TimelineStep(title: 'Rejected', state: _StepState.error));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Progress', style: text.titleMedium),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++) _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
        ]),
      ),
    );
  }
}

class _TimelineStep {
  const _TimelineStep({required this.title, this.subtitle, required this.state});

  final String title;
  final String? subtitle;
  final _StepState state;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.isLast});

  final _TimelineStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = switch (step.state) {
      _StepState.done => tokens.success,
      _StepState.current => tokens.pending,
      _StepState.error => tokens.danger,
      _StepState.todo => scheme.outline,
    };
    final icon = switch (step.state) {
      _StepState.done => Icons.check,
      _StepState.current => Icons.schedule,
      _StepState.error => Icons.close,
      _StepState.todo => Icons.circle_outlined,
    };
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 26,
          child: Column(children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: step.state == _StepState.todo ? 0.0 : 0.15),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Icon(icon, size: 13, color: color),
            ),
            if (!isLast) Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                step.title,
                style: text.titleSmall?.copyWith(color: step.state == _StepState.todo ? scheme.onSurfaceVariant : null),
              ),
              if (step.subtitle != null) Text(step.subtitle!, style: text.bodySmall),
            ]),
          ),
        ),
      ]),
    );
  }
}
