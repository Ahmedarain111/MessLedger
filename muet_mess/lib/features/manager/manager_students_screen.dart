import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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

class ManagerStudentsScreen extends StatefulWidget {
  const ManagerStudentsScreen({super.key});

  @override
  State<ManagerStudentsScreen> createState() => _ManagerStudentsScreenState();
}

class _ManagerStudentsScreenState extends State<ManagerStudentsScreen> {
  static const _sorts = <String, String>{
    'balance': 'Highest balance',
    'name': 'Name',
    'room': 'Room',
  };

  final search = TextEditingController();
  String sortBy = 'balance';
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
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('All Students'));
    return Scaffold(
      appBar: appBar,
      body: FutureBuilder<List<Meal>>(
        future: _entriesFuture,
        builder: (context, entriesSnapshot) {
          if (entriesSnapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton(itemHeight: 76);
          }
          if (entriesSnapshot.hasError) {
            return ErrorState(title: 'Could not load students', message: entriesSnapshot.error.toString(), onRetry: _refresh);
          }

          return FutureBuilder<List<Student>>(
            future: _studentsFuture,
            builder: (context, studentsSnapshot) {
              if (studentsSnapshot.connectionState == ConnectionState.waiting) {
                return const ListSkeleton(itemHeight: 76);
              }
              if (studentsSnapshot.hasError) {
                return ErrorState(title: 'Could not load students', message: studentsSnapshot.error.toString(), onRetry: _refresh);
              }

              final entries = entriesSnapshot.data ?? [];
              final students = studentsSnapshot.data ?? [];
              final rows = students.map((student) {
                final approved = entries.where((e) => e.studentId == student.id && e.entryStatus == EntryStatus.approved);
                final balance = approved.fold(0, (sum, e) => sum + e.outstanding);
                return (student, balance);
              }).where((row) {
                final query = search.text.toLowerCase().trim();
                return query.isEmpty || row.$1.name.toLowerCase().contains(query) || row.$1.rollNumber.toLowerCase().contains(query);
              }).toList();

              rows.sort((a, b) {
                return switch (sortBy) {
                  'name' => a.$1.name.compareTo(b.$1.name),
                  'room' => (a.$1.roomNumber ?? '').compareTo(b.$1.roomNumber ?? ''),
                  _ => b.$2.compareTo(a.$2),
                };
              });

              final scheme = Theme.of(context).colorScheme;
              final text = Theme.of(context).textTheme;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ContentList(children: [
                  TextField(
                    controller: search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or roll no…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(search.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      Text('Sort by', style: text.bodySmall),
                      const SizedBox(width: 10),
                      for (final s in _sorts.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(s.value),
                            selected: sortBy == s.key,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => sortBy = s.key),
                          ),
                        ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text('${rows.length} ${rows.length == 1 ? 'student' : 'students'}', style: text.bodySmall),
                  const SizedBox(height: 10),
                  if (rows.isEmpty)
                    const SizedBox(height: 320, child: EmptyState(title: 'No students', message: 'No students match the current search.', icon: Icons.person_search_outlined))
                  else
                    AdaptiveGrid(
                      minItemWidth: 420,
                      gap: 10,
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          FadeSlideIn(
                            index: i,
                            child: Card(
                              child: InkWell(
                                onTap: () => context.push('/manager/students/${rows[i].$1.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(children: [
                                    UserAvatar(name: rows[i].$1.name, radius: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(rows[i].$1.name, style: text.titleSmall?.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text('${rows[i].$1.rollNumber} • Room ${rows[i].$1.roomNumber ?? '-'}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ]),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      AmountText(rows[i].$2, bold: true, color: rows[i].$2 > 0 ? scheme.error : null),
                                      Text(rows[i].$2 > 0 ? 'owes' : 'settled', style: text.labelSmall),
                                    ]),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                                  ]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
