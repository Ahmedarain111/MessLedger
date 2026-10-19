import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/meal_model.dart';
import '../../models/student_model.dart';
import '../../providers/meal_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/user_avatar.dart';

class StudentLedgerScreen extends StatefulWidget {
  final String studentId;
  final bool readOnly;

  const StudentLedgerScreen({super.key, required this.studentId, this.readOnly = false});

  @override
  State<StudentLedgerScreen> createState() => _StudentLedgerScreenState();
}

class _StudentLedgerScreenState extends State<StudentLedgerScreen> {
  late Future<List<Meal>> _entriesFuture;
  late Future<List<Student>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = context.read<MealProvider>().getAllEntries();
    _studentsFuture = context.read<StudentProvider>().listStudents();
  }

  Future<void> _refresh() async {
    setState(() {
      _entriesFuture = context.read<MealProvider>().getAllEntries();
      _studentsFuture = context.read<StudentProvider>().listStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: Text(widget.readOnly ? 'Student Details' : 'Student Ledger'));
    return FutureBuilder<List<Meal>>(
      future: _entriesFuture,
      builder: (context, entriesSnapshot) {
        if (entriesSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar, body: const ListSkeleton(showHero: true));
        }
        if (entriesSnapshot.hasError) {
          return Scaffold(appBar: appBar, body: ErrorState(title: 'Could not load ledger', message: entriesSnapshot.error.toString(), onRetry: _refresh));
        }

        return FutureBuilder<List<Student>>(
          future: _studentsFuture,
          builder: (context, studentsSnapshot) {
            if (studentsSnapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(appBar: appBar, body: const ListSkeleton(showHero: true));
            }
            if (studentsSnapshot.hasError) {
              return Scaffold(appBar: appBar, body: ErrorState(title: 'Could not load student', message: studentsSnapshot.error.toString(), onRetry: _refresh));
            }

            final entries = entriesSnapshot.data ?? [];
            final students = studentsSnapshot.data ?? [];
            final student = students.where((s) => s.id == widget.studentId).firstOrNull;

            if (student == null) {
              return Scaffold(appBar: appBar, body: const EmptyState(title: 'Student not found', message: 'This student record could not be loaded.', icon: Icons.person_off_outlined));
            }

            final mine = entries.where((e) => e.studentId == widget.studentId).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
            final approved = mine.where((e) => e.entryStatus == EntryStatus.approved).toList();
            final totalMeals = approved.length;
            final totalPaid = approved.fold(0, (sum, e) => sum + e.amountPaid);
            final outstanding = approved.fold(0, (sum, e) => sum + e.outstanding);
            final tokens = context.tokens;
            final text = Theme.of(context).textTheme;

            return Scaffold(
              appBar: appBar,
              bottomNavigationBar: widget.readOnly
                  ? null
                  : Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: DecoratedBox(
                        decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Center(
                              heightFactor: 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 640),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: outstanding > 0 ? () => context.push('/manager/students/${widget.studentId}/payment') : null,
                                    icon: const Icon(Icons.payments_outlined),
                                    label: Text(outstanding > 0 ? 'Record payment' : 'Nothing outstanding'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: ContentList(
                  maxWidth: 820,
                  children: [
                    FadeSlideIn(
                      child: Row(children: [
                        UserAvatar(name: student.name, radius: 30),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(student.name, style: text.titleLarge),
                            const SizedBox(height: 2),
                            Text('Roll No: ${student.rollNumber}', style: text.bodySmall),
                            Text('Room No: ${student.roomNumber ?? '-'}', style: text.bodySmall),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 1,
                      child: BalanceCard(
                        amount: outstanding,
                        title: outstanding > 0 ? 'Outstanding balance' : 'Settled up',
                        subtitle: 'Paid so far: ${money(totalPaid)}',
                        warning: outstanding > 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      index: 2,
                      child: AdaptiveGrid(minItemWidth: 160, children: [
                        SummaryStatCard(title: 'Total meals', value: '$totalMeals', icon: Icons.restaurant, color: tokens.info),
                        SummaryStatCard(title: 'Total paid', value: money(totalPaid), icon: Icons.check_circle_outline, color: tokens.success),
                      ]),
                    ),
                    const SectionHeader('Recent entries'),
                    if (mine.isEmpty) const SizedBox(height: 260, child: EmptyState(title: 'No entries', message: 'This ledger is currently empty.', icon: Icons.receipt_long_outlined)),
                    for (var i = 0; i < mine.take(8).length; i++)
                      FadeSlideIn(
                        index: i,
                        child: EntryCard(entry: mine[i], studentName: student.name, onTap: () => context.push('/entries/${mine[i].id}')),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
