import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/food_item_model.dart';
import '../../models/meal_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/common/food_image.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/skeleton.dart';
import '../entries/entry_form_screen.dart';
import '../entries/records_screen.dart';
import '../menu/student_menu_screen.dart';
import '../profile/profile_screen.dart';

class StudentShell extends StatefulWidget {
  final int initialIndex;
  const StudentShell({super.key, this.initialIndex = 0});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  @override
  void didUpdateWidget(StudentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() => index = widget.initialIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: ListSkeleton(showHero: true));
    }

    final pages = [
      _StudentHome(user: user, onViewAll: () => context.go(RouteNames.studentKhata)),
      RecordsScreen(studentOnly: true, studentId: user.id),
      EntryFormScreen(isManager: false, studentId: user.id),
      const StudentMenuScreen(),
      const ProfileScreen(),
    ];
    return IndexedStack(index: index, children: pages);
  }
}

class _StudentHome extends StatefulWidget {
  final AppUser user;
  final VoidCallback onViewAll;
  const _StudentHome({required this.user, required this.onViewAll});

  @override
  State<_StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<_StudentHome> {
  late Future<List<Meal>> _entriesFuture;
  late Future<List<FoodItem>> _menuFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _entriesFuture = context.read<MealProvider>().getAllEntries();
    // The menu strip is decorative; a failure here must never break the page.
    _menuFuture = context.read<MenuProvider>().getDishes().catchError((Object _) => <FoodItem>[]);
  }

  Future<void> _refresh() async {
    setState(_load);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user.name.split(' ').first;
    final desktop = MediaQuery.sizeOf(context).width > AppSizes.tabletMax;
    final text = Theme.of(context).textTheme;

    PreferredSizeWidget appBar({List<Widget> actions = const []}) => AppBar(
          toolbarHeight: 68,
          titleSpacing: 20,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_greeting, style: text.bodySmall),
            Text(firstName, style: text.titleLarge),
          ]),
          actions: actions,
        );

    return FutureBuilder<List<Meal>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: appBar(), body: const DashboardSkeleton());
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: appBar(),
            body: ErrorState(
              title: 'Could not load entries',
              message: snapshot.error.toString(),
              onRetry: _refresh,
            ),
          );
        }
        final entries = snapshot.data ?? [];
        final mine = entries.where((e) => e.studentId == widget.user.id).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final approved = mine.where((e) => e.entryStatus == EntryStatus.approved).toList();
        final pending = mine.where((e) => e.entryStatus == EntryStatus.pending).fold(0, (s, e) => s + e.totalAmount);
        final pendingCount = mine.where((e) => e.entryStatus == EntryStatus.pending).length;
        final balance = approved.fold(0, (s, e) => s + e.outstanding);
        final overdue = approved.where((e) => e.outstanding > 0 && isOverdue(e.dateTime)).length;
        final tokens = context.tokens;

        return Scaffold(
          appBar: appBar(actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.go(RouteNames.studentNotifications),
              icon: const Icon(Icons.notifications_outlined),
            ),
            if (desktop) ...[
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                onPressed: () => context.go(RouteNames.studentEnterMeal),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add entry'),
              ),
            ],
            const SizedBox(width: 12),
          ]),
          floatingActionButton: desktop
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'student_home_add_entry',
                  onPressed: () => context.go(RouteNames.studentEnterMeal),
                  icon: const Icon(Icons.add),
                  label: const Text('Add meal entry'),
                ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ContentList(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                FadeSlideIn(
                  child: BalanceCard(
                    amount: balance,
                    title: balance > 0 ? 'Outstanding balance' : "You're all settled up",
                    subtitle: 'Awaiting approval: ${money(pending)}',
                    warning: balance > 0,
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 1,
                  child: AdaptiveGrid(minItemWidth: 150, children: [
                    SummaryStatCard(title: 'Pending', value: '$pendingCount', icon: Icons.pending_actions, color: tokens.pending),
                    SummaryStatCard(title: 'Overdue', value: '$overdue', icon: Icons.warning_amber_rounded, color: tokens.overdue),
                    SummaryStatCard(title: 'Approved', value: '${approved.length}', icon: Icons.verified_outlined, color: tokens.success),
                  ]),
                ),
                if (overdue > 0) ...[
                  const SizedBox(height: 14),
                  FadeSlideIn(index: 2, child: _OverdueBanner(count: overdue)),
                ],
                _MenuStrip(future: _menuFuture),
                SectionHeader(
                  'Recent entries',
                  trailing: TextButton(onPressed: widget.onViewAll, child: const Text('View all')),
                ),
                if (mine.isEmpty)
                  EmptyState(
                    title: 'No entries yet',
                    message: 'Meals you log will show up here with their approval and payment status.',
                    icon: Icons.receipt_long_outlined,
                    action: FilledButton.icon(
                      onPressed: () => context.go(RouteNames.studentEnterMeal),
                      icon: const Icon(Icons.add),
                      label: const Text('Add your first entry'),
                    ),
                  )
                else
                  for (var i = 0; i < mine.take(5).length; i++)
                    FadeSlideIn(
                      index: i,
                      child: EntryCard(
                        entry: mine[i],
                        studentName: widget.user.name,
                        onTap: () => context.push('/entries/${mine[i].id}'),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.overdue;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$count ${count == 1 ? 'entry is' : 'entries are'} overdue', style: text.titleSmall),
            const SizedBox(height: 2),
            Text('Entries older than 7 days with an outstanding amount.', style: text.bodySmall),
          ]),
        ),
      ]),
    );
  }
}

/// Horizontal strip of dishes being served in the current shift.
class _MenuStrip extends StatelessWidget {
  const _MenuStrip({required this.future});

  final Future<List<FoodItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FoodItem>>(
      future: future,
      builder: (context, snapshot) {
        final shift = Shift.values.byName(autoShift(DateTime.now()));
        final dishes = (snapshot.data ?? []).where((d) => d.isAvailable && d.serves(shift)).toList();
        if (dishes.isEmpty) return const SizedBox.shrink();
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(
            'On the menu now',
            subtitle: '${shift.label} favourites',
            trailing: TextButton(onPressed: () => context.go(RouteNames.studentMenu), child: const Text('Full menu')),
          ),
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: dishes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final d = dishes[i];
                return SizedBox(
                  width: 136,
                  child: Card(
                    child: InkWell(
                      onTap: () => context.go(RouteNames.studentMenu),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(
                          height: 96,
                          width: double.infinity,
                          child: FoodImage(path: d.imagePath, name: d.name, category: d.category, fill: true, radius: 0),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.name, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(CurrencyUtils.format(d.price), style: text.labelLarge?.copyWith(color: scheme.primary)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}
