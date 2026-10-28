import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/user_avatar.dart';

class PaymentScreen extends StatefulWidget {
  final String studentId;
  const PaymentScreen({super.key, required this.studentId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final amount = TextEditingController();
  final note = TextEditingController();
  DateTime paidDate = DateTime.now();
  late Future<List<Meal>> _entriesFuture;
  late Future<Student?> _studentFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entriesFuture = context.read<MealProvider>().getEntriesForStudent(widget.studentId);
    _studentFuture = context.read<StudentProvider>().getStudent(widget.studentId);
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = context.read<MealProvider>().getEntriesForStudent(widget.studentId);
      _studentFuture = context.read<StudentProvider>().getStudent(widget.studentId);
    });
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _record(List<Meal> mine, int outstanding) async {
    final value = int.tryParse(amount.text.trim());
    if (value == null || value <= 0 || value > outstanding) {
      showError(context, 'Enter an amount between Rs. 1 and $outstanding.');
      return;
    }
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    
    final paymentProvider = context.read<PaymentProvider>();
    setState(() => _saving = true);
    try {
      await paymentProvider.record(
        studentId: widget.studentId,
        amount: value,
      );
      if (!mounted) return;
      showSuccess(context, 'Payment of Rs. $value recorded.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('Record Payment'));
    return FutureBuilder<List<Meal>>(
      future: _entriesFuture,
      builder: (context, entriesSnapshot) {
        if (entriesSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const ListSkeleton(itemCount: 3, itemHeight: 110));
        }
        if (entriesSnapshot.hasError) {
          return Scaffold(appBar: appBar, body: ErrorState(title: 'Could not load ledger', message: entriesSnapshot.error.toString(), onRetry: _refresh));
        }

        return FutureBuilder<Student?>(
          future: _studentFuture,
          builder: (context, studentSnapshot) {
            if (studentSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(appBar: appBar, body: const ListSkeleton(itemCount: 3, itemHeight: 110));
            }
            if (studentSnapshot.hasError) {
              return Scaffold(appBar: appBar, body: ErrorState(title: 'Could not load student', message: studentSnapshot.error.toString(), onRetry: _refresh));
            }

            final entries = entriesSnapshot.data ?? [];
            final student = studentSnapshot.data;
            if (student == null) {
              return Scaffold(appBar: appBar, body: const EmptyState(title: 'Student not found', message: 'Please go back and try again.', icon: Icons.person_off_outlined));
            }

            final mine = entries;
            final outstanding = mine.where((e) => e.entryStatus == EntryStatus.approved).fold(0, (sum, e) => sum + e.outstanding);
            if (amount.text.isEmpty) amount.text = outstanding.toString();
            final scheme = Theme.of(context).colorScheme;
            final text = Theme.of(context).textTheme;

            return Scaffold(
              appBar: appBar,
              body: ContentList(
                maxWidth: 640,
                children: [
                  Row(children: [
                    UserAvatar(name: student.name, radius: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(student.name, style: text.titleLarge),
                        Text('Roll No: ${student.rollNumber}  •  Room: ${student.roomNumber ?? '-'}', style: text.bodySmall),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  BalanceCard(
                    amount: outstanding,
                    title: 'Current outstanding',
                    subtitle: outstanding > 0 ? 'Across ${mine.where((e) => e.entryStatus == EntryStatus.approved && e.outstanding > 0).length} approved entries' : 'Nothing due',
                    warning: outstanding > 0,
                  ),
                  const SectionHeader('Payment amount'),
                  TextField(
                    controller: amount,
                    keyboardType: TextInputType.number,
                    style: text.titleLarge,
                    decoration: const InputDecoration(prefixText: 'Rs. '),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    ActionChip(
                      label: const Text('Full amount'),
                      onPressed: outstanding > 0 ? () => setState(() => amount.text = outstanding.toString()) : null,
                    ),
                    ActionChip(
                      label: const Text('Half'),
                      onPressed: outstanding > 1 ? () => setState(() => amount.text = (outstanding ~/ 2).toString()) : null,
                    ),
                  ]),
                  const SectionHeader('Payment date'),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                        initialDate: paidDate,
                      );
                      if (picked != null) setState(() => paidDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(dateText(paidDate)),
                  ),
                  const SectionHeader('Note'),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Partial payment for October'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: (outstanding == 0 || _saving) ? null : () => _record(mine, outstanding),
                    icon: _saving
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.onPrimary))
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Recording…' : 'Record payment'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
