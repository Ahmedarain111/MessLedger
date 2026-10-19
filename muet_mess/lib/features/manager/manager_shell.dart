import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/status_style.dart';
import '../../models/enums.dart';
import '../../models/food_item_model.dart';
import '../../models/meal_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/food_image.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/shift_badge.dart';
import '../../widgets/common/skeleton.dart';
import '../../widgets/common/user_avatar.dart';
import '../entries/records_screen.dart';
import '../profile/profile_screen.dart';

class ManagerShell extends StatefulWidget {
  final int initialIndex;
  const ManagerShell({super.key, this.initialIndex = 0});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  @override
  void didUpdateWidget(ManagerShell oldWidget) {
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
      return const Scaffold(body: DashboardSkeleton());
    }

    final pages = [
      _Dashboard(user: user),
      _Approvals(user: user),
      RecordsScreen(studentOnly: false, managerActions: true),
      const MenuManagementScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      floatingActionButton: index == 2
          ? FloatingActionButton.extended(
              heroTag: 'manager_shell_add_entry',
              onPressed: () => context.push('/manager/entry/new'),
              label: const Text('Add Entry'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class _Dashboard extends StatefulWidget {
  final AppUser user;
  const _Dashboard({required this.user});

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
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

  PreferredSizeWidget _appBar(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: 68,
      titleSpacing: 20,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(AppDateUtils.dayFull(DateTime.now()), style: text.bodySmall),
        Text('Manager Dashboard', style: text.titleLarge),
      ]),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.go(RouteNames.managerNotifications),
          icon: const Icon(Icons.notifications_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Meal>>(
      future: _entriesFuture,
      builder: (context, entriesSnapshot) {
        if (entriesSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: _appBar(context), body: const DashboardSkeleton());
        }
        if (entriesSnapshot.hasError) {
          return Scaffold(
            appBar: _appBar(context),
            body: ErrorState(title: 'Could not load dashboard', message: entriesSnapshot.error.toString(), onRetry: _refresh),
          );
        }

        return FutureBuilder<List<Student>>(
          future: _studentsFuture,
          builder: (context, studentsSnapshot) {
            final entries = entriesSnapshot.data ?? [];
            final students = studentsSnapshot.data ?? [];
            final studentNames = {for (final s in students) s.id: s.name};
            final approved = entries.where((e) => e.entryStatus == EntryStatus.approved).toList();
            final now = DateTime.now();
            bool isToday(Meal e) => e.dateTime.day == now.day && e.dateTime.month == now.month && e.dateTime.year == now.year;
            final todayEntries = entries.where(isToday).toList();
            final sales = todayEntries.fold(0, (s, e) => s + e.totalAmount);
            final outstanding = approved.fold(0, (s, e) => s + e.outstanding);
            final pending = entries.where((e) => e.entryStatus == EntryStatus.pending).length;
            final disputed = entries.where((e) => e.isDisputed).length;
            final overdue = approved.where((e) => e.outstanding > 0 && isOverdue(e.dateTime)).fold(0, (s, e) => s + e.outstanding);
            final todayByShift = <Shift, int>{for (final shift in Shift.values) shift: 0};
            for (final e in todayEntries) {
              todayByShift[e.shift] = (todayByShift[e.shift] ?? 0) + e.totalAmount;
            }
            final defaulters = students
                .map((s) => (s.name, approved.where((e) => e.studentId == s.id).fold(0, (sum, e) => sum + e.outstanding)))
                .where((row) => row.$2 > 0)
                .toList()
              ..sort((a, b) => b.$2.compareTo(a.$2));
            final tokens = context.tokens;

            return Scaffold(
              appBar: _appBar(context),
              body: RefreshIndicator(
                onRefresh: _refresh,
                child: ContentList(
                  children: [
                    FadeSlideIn(
                      child: BalanceCard(
                        amount: sales,
                        title: "Today's sales",
                        subtitle: '${todayEntries.length} ${todayEntries.length == 1 ? 'entry' : 'entries'} recorded today',
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      index: 1,
                      child: AdaptiveGrid(minItemWidth: 170, children: [
                        SummaryStatCard(title: 'Outstanding', value: money(outstanding), icon: Icons.account_balance_wallet_outlined, color: tokens.warning),
                        SummaryStatCard(title: 'Pending', value: '$pending', icon: Icons.pending_actions, color: tokens.pending),
                        SummaryStatCard(title: 'Disputed', value: '$disputed', icon: Icons.flag_outlined, color: tokens.disputed),
                        SummaryStatCard(title: 'Overdue', value: money(overdue), icon: Icons.warning_amber_rounded, color: tokens.overdue),
                      ]),
                    ),
                    if (pending > 0) ...[
                      const SizedBox(height: 14),
                      FadeSlideIn(
                        index: 2,
                        child: _ReviewBanner(count: pending, onReview: () => context.go(RouteNames.managerApprovals)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      index: 3,
                      child: TwoColumn(
                        left: _ShiftBreakdownCard(sales: sales, todayByShift: todayByShift),
                        right: _DefaultersCard(defaulters: defaulters),
                      ),
                    ),
                    const SectionHeader('Recent activity'),
                    if (entries.isEmpty)
                      const SizedBox(
                        height: 280,
                        child: EmptyState(title: 'No activity yet', message: 'New entries will appear here.', icon: Icons.receipt_long_outlined),
                      )
                    else
                      for (var i = 0; i < entries.take(8).length; i++)
                        FadeSlideIn(
                          index: i,
                          child: EntryCard(
                            entry: entries[i],
                            studentName: entries[i].studentName ?? studentNames[entries[i].studentId],
                            onTap: () => context.push('/entries/${entries[i].id}'),
                          ),
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

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onReview});

  final int count;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.pending;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(Icons.hourglass_top, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'entry is' : 'entries are'} waiting for approval',
            style: text.titleSmall,
          ),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: onReview,
          child: const Text('Review'),
        ),
      ]),
    );
  }
}

class _ShiftBreakdownCard extends StatelessWidget {
  const _ShiftBreakdownCard({required this.sales, required this.todayByShift});

  final int sales;
  final Map<Shift, int> todayByShift;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Today by shift', style: text.titleMedium),
          const SizedBox(height: 16),
          for (final shift in Shift.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                ShiftBadge(shift: shift, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(shiftLabel(shift.name), style: text.titleSmall)),
                      AmountText(todayByShift[shift] ?? 0, bold: true),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: sales == 0 ? 0 : (todayByShift[shift] ?? 0) / sales,
                        minHeight: 8,
                        color: shiftColor(context, shift),
                        backgroundColor: shiftColor(context, shift).withValues(alpha: 0.14),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _DefaultersCard extends StatelessWidget {
  const _DefaultersCard({required this.defaulters});

  final List<(String, int)> defaulters;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Top defaulters', style: text.titleMedium),
          const SizedBox(height: 12),
          if (defaulters.isEmpty)
            const EmptyState(title: 'No defaulters', message: 'Every student ledger is currently settled.', icon: Icons.verified_outlined)
          else
            for (final row in defaulters.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  UserAvatar(name: row.$1, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(row.$1, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  AmountText(row.$2, bold: true, color: scheme.error),
                ]),
              ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Approvals
// ---------------------------------------------------------------------------

class _Approvals extends StatefulWidget {
  final AppUser user;
  const _Approvals({required this.user});

  @override
  State<_Approvals> createState() => _ApprovalsState();
}

class _ApprovalsState extends State<_Approvals> {
  List<Meal> _entries = [];
  List<Student> _students = [];
  bool _loading = true;
  Object? _error;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meals = context.read<MealProvider>();
    final students = context.read<StudentProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entriesFuture = meals.getAllEntries();
      final studentsFuture = students.listStudents().catchError((Object _) => <Student>[]);
      final entries = await entriesFuture;
      final list = await studentsFuture;
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _students = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _removeLocally(String id) {
    setState(() => _entries = _entries.where((e) => e.id != id).toList());
  }

  Future<void> _approve(Meal e) async {
    final mealProvider = context.read<MealProvider>();
    setState(() => _busyIds.add(e.id));
    try {
      await mealProvider.approve(e.id);
      if (!mounted) return;
      _removeLocally(e.id);
      showSuccess(context, 'Entry approved.');
    } catch (err) {
      if (!mounted) return;
      showError(context, err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyIds.remove(e.id));
    }
  }

  Future<void> _reject(Meal e) async {
    final reason = await reasonDialog(
      context,
      title: 'Reject entry?',
      message: 'Give a short reason. The student will see it.',
      confirmLabel: 'Reject',
      destructive: true,
    );
    if (reason == null || !mounted) return;
    final mealProvider = context.read<MealProvider>();
    setState(() => _busyIds.add(e.id));
    try {
      await mealProvider.reject(e.id, reason: reason.isEmpty ? 'Rejected by manager' : reason);
      if (!mounted) return;
      _removeLocally(e.id);
      showInfo(context, 'Entry rejected.');
    } catch (err) {
      if (!mounted) return;
      showError(context, err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyIds.remove(e.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Approvals')), body: const ListSkeleton(itemHeight: 150));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Approvals')),
        body: ErrorState(title: 'Could not load approvals', message: _error.toString(), onRetry: _load),
      );
    }
    final studentNames = {for (final s in _students) s.id: s.name};
    final approvals = _entries.where((e) => e.entryStatus == EntryStatus.pending || e.isDisputed).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Approvals${approvals.isNotEmpty ? ' (${approvals.length})' : ''}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ContentList(
          children: [
            if (approvals.isEmpty)
              const SizedBox(
                height: 500,
                child: EmptyState(
                  title: 'All caught up',
                  message: 'There are no pending or disputed entries.',
                  icon: Icons.task_alt,
                ),
              )
            else
              AdaptiveGrid(
                minItemWidth: 420,
                gap: 12,
                children: [
                  for (final e in approvals)
                    _ApprovalCard(
                      entry: e,
                      name: e.studentName ?? studentNames[e.studentId] ?? e.studentId,
                      busy: _busyIds.contains(e.id),
                      onApprove: () => _approve(e),
                      onReject: () => _reject(e),
                      onOpen: () => context.push('/entries/${e.id}'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.entry,
    required this.name,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onOpen,
  });

  final Meal entry;
  final String name;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final pending = entry.entryStatus == EntryStatus.pending;
    return Card(
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              UserAvatar(name: name, radius: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: text.titleSmall?.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${shiftLabel(entry.shift.name)} • ${dateTimeText(entry.dateTime)}', style: text.bodySmall),
                ]),
              ),
              const SizedBox(width: 8),
              AmountText(entry.totalAmount, bold: true, size: 16),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final i in entry.items)
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    FoodImage(name: i.dishName, size: 24, radius: 12),
                    const SizedBox(width: 6),
                    Text('${i.dishName} ×${i.quantity}', style: text.labelMedium),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [
              StatusChip.style(entryStatusStyle(context, entry.entryStatus)),
              if (entry.isDisputed) StatusChip.style(disputedStyle(context)),
            ]),
            if (entry.isDisputed && entry.disputeReason != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.disputed.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('“${entry.disputeReason}”', style: text.bodyMedium),
              ),
            ],
            const SizedBox(height: 14),
            if (pending)
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withValues(alpha: 0.6)),
                    ),
                    onPressed: busy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      backgroundColor: tokens.success,
                      foregroundColor: tokens.onHero,
                    ),
                    onPressed: busy ? null : onApprove,
                    icon: busy
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.onHero))
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ])
            else
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Review dispute'),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Menu management
// ---------------------------------------------------------------------------

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<FoodItem> _dishes = [];
  bool _loading = true;
  Object? _error;
  String _query = '';
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final menu = context.read<MenuProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dishes = await menu.getDishes();
      if (!mounted) return;
      setState(() {
        _dishes = dishes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _replace(FoodItem updated) {
    final i = _dishes.indexWhere((d) => d.id == updated.id);
    if (i >= 0) {
      setState(() => _dishes = [..._dishes]..[i] = updated);
    }
  }

  Future<void> _toggle(FoodItem dish, bool value) async {
    final menu = context.read<MenuProvider>();
    setState(() => _busyIds.add(dish.id));
    try {
      final updated = await menu.update(id: dish.id, isAvailable: value);
      if (!mounted) return;
      _replace(updated);
      showInfo(context, '${dish.name} marked ${value ? 'available' : 'sold out'}.');
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyIds.remove(dish.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('Menu Management'));
    if (_loading) {
      return Scaffold(appBar: appBar, body: const ListSkeleton(itemHeight: 84));
    }
    if (_error != null) {
      return Scaffold(
        appBar: appBar,
        body: ErrorState(title: 'Could not load menu', message: _error.toString(), onRetry: _load),
      );
    }
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? _dishes
        : _dishes.where((d) => d.name.toLowerCase().contains(q) || d.category.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: appBar,
      floatingActionButton: FloatingActionButton(
        heroTag: 'manager_shell_add_dish',
        tooltip: 'Add dish',
        onPressed: () => _dishDialog(context, null),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ContentList(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search dishes…',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 14),
            if (_dishes.isEmpty)
              const SizedBox(
                height: 360,
                child: EmptyState(title: 'No dishes', message: 'Add dishes to start selling.', icon: Icons.restaurant_menu),
              )
            else if (visible.isEmpty)
              const SizedBox(
                height: 300,
                child: EmptyState(title: 'No matches', message: 'No dishes match your search.', icon: Icons.search_off),
              )
            else
              AdaptiveGrid(
                minItemWidth: 420,
                children: [
                  for (final d in visible)
                    _DishAdminTile(
                      dish: d,
                      busy: _busyIds.contains(d.id),
                      onToggle: (v) => _toggle(d, v),
                      onEdit: () => _dishDialog(context, d),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _dishDialog(BuildContext context, FoodItem? dish) async {
    final menu = context.read<MenuProvider>();
    final input = await showDialog<_DishInput>(
      context: context,
      builder: (_) => _DishDialog(dish: dish),
    );
    if (input == null) return;
    try {
      if (dish == null) {
        await menu.create(
          name: input.name,
          price: input.price,
          category: input.category,
          availableIn: [Shift.breakfast, Shift.lunch, Shift.dinner],
          isAvailable: true,
        );
      } else {
        await menu.update(id: dish.id, name: input.name, price: input.price, category: input.category);
      }
      if (!mounted) return;
      showSuccess(this.context, dish == null ? 'Dish added.' : 'Dish updated.');
      _load();
    } catch (e) {
      if (!mounted) return;
      showError(this.context, e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

class _DishAdminTile extends StatelessWidget {
  const _DishAdminTile({required this.dish, required this.busy, required this.onToggle, required this.onEdit});

  final FoodItem dish;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final available = dish.isAvailable;
    return Card(
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            FoodImage(path: dish.imagePath, name: dish.name, category: dish.category, size: 60, radius: 14, grayscale: !available),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  dish.name,
                  style: text.titleSmall?.copyWith(color: available ? null : scheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('${dish.category} • ${money(dish.price)}', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(spacing: 6, children: [
                  for (final s in Shift.values.where(dish.serves)) Icon(shiftIcon(s), size: 15, color: shiftColor(context, s)),
                ]),
              ]),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: available, onChanged: busy ? null : onToggle),
              Text(available ? 'Available' : 'Sold out', style: text.labelSmall),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _DishInput {
  const _DishInput(this.name, this.price, this.category);

  final String name;
  final int price;
  final String category;
}

class _DishDialog extends StatefulWidget {
  const _DishDialog({this.dish});

  final FoodItem? dish;

  @override
  State<_DishDialog> createState() => _DishDialogState();
}

class _DishDialogState extends State<_DishDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.dish?.name ?? '');
  late final TextEditingController _price = TextEditingController(text: widget.dish?.price.toString() ?? '');
  late final TextEditingController _category = TextEditingController(text: widget.dish?.category ?? 'Main');
  String? _nameError;
  String? _priceError;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Name is required' : null;
      _priceError = (price == null || price <= 0) ? 'Enter a price greater than 0' : null;
    });
    if (_nameError != null || _priceError != null) return;
    final category = _category.text.trim().isEmpty ? 'Main' : _category.text.trim();
    Navigator.pop(context, _DishInput(name, price!, category));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dish == null ? 'Add dish' : 'Edit dish'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price', prefixText: 'Rs. ', errorText: _priceError),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _category,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ]),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
