import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/skeleton.dart';

class RecordsScreen extends StatefulWidget {
  final bool studentOnly;
  final bool managerActions;
  final String? studentId;
  const RecordsScreen({
    super.key,
    required this.studentOnly,
    this.managerActions = false,
    this.studentId,
  });

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  static const _filters = <String, String>{
    'all': 'All',
    'pending': 'Pending',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'unpaid': 'Unpaid',
    'partiallyPaid': 'Partly paid',
    'paid': 'Paid',
  };

  String status = 'all';
  late Future<List<Meal>> _entriesFuture;
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = context.read<MealProvider>().getAllEntries();
    _studentsFuture = widget.studentOnly
        ? Future.value(<Student>[])
        : context.read<StudentProvider>().listStudents();
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = context.read<MealProvider>().getAllEntries();
      _studentsFuture = widget.studentOnly
          ? Future.value(<Student>[])
          : context.read<StudentProvider>().listStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final title = widget.studentOnly ? 'My Records' : 'All Records';

    return FutureBuilder<List<Meal>>(
      future: _entriesFuture,
      builder: (context, entriesSnapshot) {
        if (entriesSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(title: Text(title)), body: const ListSkeleton());
        }
        if (entriesSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: ErrorState(
              title: 'Could not load records',
              message: entriesSnapshot.error.toString(),
              onRetry: _refresh,
            ),
          );
        }

        return FutureBuilder<List<Student>>(
          future: _studentsFuture,
          builder: (context, studentsSnapshot) {
            final entries = entriesSnapshot.data ?? [];
            final students = studentsSnapshot.data ?? [];
            final studentNames = {for (final s in students) s.id: s.name};

            final source = widget.studentOnly
                ? entries.where((e) => (widget.studentId ?? user?.id) == e.studentId).toList()
                : entries;

            final filtered = source.where((e) {
              return status == 'all' ||
                  e.entryStatus.name == status ||
                  e.paymentStatus.name == status;
            }).toList()
              ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

            final outstanding = filtered.fold(0, (sum, e) => sum + e.outstanding);
            final scheme = Theme.of(context).colorScheme;
            final text = Theme.of(context).textTheme;

            return Scaffold(
              appBar: AppBar(title: Text(title)),
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: ContentList(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final filter in _filters.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(filter.value),
                                selected: status == filter.key,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => status = filter.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Entries', style: text.bodySmall),
                              const SizedBox(height: 2),
                              Text('${filtered.length}', style: text.titleLarge),
                            ]),
                          ),
                          Container(width: 1, height: 36, color: scheme.outlineVariant),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Outstanding in view', style: text.bodySmall),
                              const SizedBox(height: 2),
                              Text(
                                money(outstanding),
                                style: text.titleLarge?.copyWith(color: outstanding > 0 ? scheme.error : null),
                              ),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      const SizedBox(
                        height: 380,
                        child: EmptyState(
                          title: 'No records',
                          message: 'No entries match the selected filter.',
                          icon: Icons.receipt_long_outlined,
                        ),
                      )
                    else
                      for (var i = 0; i < filtered.length; i++)
                        FadeSlideIn(
                          index: i,
                          child: EntryCard(
                            entry: filtered[i],
                            studentName: widget.studentOnly ? (user?.name ?? 'My entry') : (filtered[i].studentName ?? studentNames[filtered[i].studentId]),
                            onTap: () => context.push('/entries/${filtered[i].id}'),
                            actions: widget.managerActions &&
                                    filtered[i].entryStatus == EntryStatus.approved &&
                                    filtered[i].outstanding > 0
                                ? [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                                      onPressed: () => _recordPayment(filtered[i]),
                                      icon: const Icon(Icons.payments_outlined),
                                      label: const Text('Record payment'),
                                    ),
                                  ]
                                : const [],
                          ),
                        ),
                  ],
                ),
              ),
              floatingActionButton: widget.studentOnly
                  ? FloatingActionButton.extended(
                      heroTag: 'student_records_add_entry',
                      onPressed: () => context.go(RouteNames.studentEnterMeal),
                      icon: const Icon(Icons.add),
                      label: const Text('Add entry'),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _recordPayment(Meal entry) async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => _AmountDialog(outstanding: entry.outstanding),
    );

    if (amount == null || !mounted) return;

    final mealProvider = context.read<MealProvider>();
    try {
      await mealProvider.markPaid(entry.id);
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
      return;
    }

    if (!mounted) return;
    showSuccess(context, 'Payment of ${money(amount)} recorded.');
    _refresh();
  }
}

class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.outstanding});

  final int outstanding;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.outstanding.toString());
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value != null && value > 0 && value <= widget.outstanding) {
      Navigator.pop(context, value);
    } else {
      setState(() => _error = 'Enter an amount between Rs. 1 and ${money(widget.outstanding)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Record payment'),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Outstanding: ${money(widget.outstanding)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(labelText: 'Amount paid', prefixText: 'Rs. ', errorText: _error),
          ),
        ]),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
