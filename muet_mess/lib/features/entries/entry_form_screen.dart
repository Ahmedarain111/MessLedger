import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../models/enums.dart';
import '../../models/food_item_model.dart';
import '../../models/hostel_model.dart';
import '../../models/meal_item_model.dart';
import '../../models/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/api_hostel_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../../widgets/common/dialogs.dart';
import '../../widgets/common/food_image.dart';
import '../../widgets/common/layout_widgets.dart';
import '../../widgets/common/shift_badge.dart';
import '../../widgets/common/skeleton.dart';

class EntryFormScreen extends StatefulWidget {
  final bool isManager;
  final String? editId;
  final String? studentId;
  const EntryFormScreen({super.key, required this.isManager, this.editId, this.studentId});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  static const _maxQuantity = 20;

  DateTime _dateTime = DateTime.now();
  Shift _shift = Shift.lunch;
  String? _studentId;
  String? _hostelId;
  final Map<String, int> _quantities = {};
  final _note = TextEditingController();
  Future<List<Student>>? _studentsFuture;
  Future<List<Hostel>>? _hostelsFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _shift = _autoShift(_dateTime);
    _studentId = widget.studentId;
    _hostelsFuture = ApiHostelService().getHostels();
    if (widget.isManager) {
      _studentsFuture = context.read<StudentProvider>().listStudents();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().load();
    });
    if (widget.editId != null) {
      _loadEntry();
    }
  }

  Future<void> _loadEntry() async {
    final entry = await context.read<MealProvider>().getEntry(widget.editId!);
    if (!mounted) return;
    setState(() {
      _dateTime = entry.dateTime;
      _shift = entry.shift;
      _studentId = entry.studentId;
      _hostelId = entry.hostelId;
      for (final item in entry.items) {
        _quantities[item.dishId] = item.quantity;
      }
      _note.text = entry.note ?? '';
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Shift _autoShift(DateTime dt) {
    final hour = dt.hour;
    if (hour >= 6 && hour <= 10) return Shift.breakfast;
    if (hour >= 11 && hour <= 16) return Shift.lunch;
    return Shift.dinner;
  }

  void _setQuantity(String dishId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _quantities.remove(dishId);
      } else {
        _quantities[dishId] = quantity > _maxQuantity ? _maxQuantity : quantity;
      }
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final menu = context.read<MenuProvider>().dishes;
    final selected = _quantities.entries.where((e) => e.value > 0).toList();
    if (selected.isEmpty) {
      showError(context, 'Select at least one dish.');
      return;
    }
    final sid = widget.isManager ? _studentId : auth.user!.id;
    if (sid == null) {
      showError(context, 'Select a student.');
      return;
    }
    final items = selected.map((q) {
      final d = menu.firstWhere((x) => x.id == q.key);
      return MealItem(dishId: d.id, dishName: d.name, unitPrice: d.price, quantity: q.value);
    }).toList();

    setState(() => _submitting = true);
    try {
      if (widget.editId != null) {
        await context.read<MealProvider>().edit(
          mealId: widget.editId!,
          newItems: items,
          reason: _note.text.trim().isEmpty ? 'Updated' : _note.text.trim(),
        );
      } else {
        final authUser = auth.user;
        final selectedHostelId = _hostelId ?? authUser?.hostelId;
        await context.read<MealProvider>().submit(
          items: items,
          dateTime: _dateTime,
          shift: _shift,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          studentId: widget.isManager ? sid : null,
          hostelId: selectedHostelId,
        );
      }
      if (!mounted) return;
      showSuccess(context, 'Entry submitted successfully.');
      if (widget.isManager || widget.editId != null) {
        context.pop();
      } else {
        setState(() => _quantities.clear());
      }
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: widget.isManager
          ? DateTime.now().subtract(const Duration(days: 365))
          : DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now(),
      initialDate: _dateTime.isAfter(DateTime.now()) ? DateTime.now() : _dateTime,
    );
    if (d != null) {
      setState(() {
        _dateTime = DateTime(d.year, d.month, d.day, _dateTime.hour, _dateTime.minute);
        _shift = _autoShift(_dateTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final menu = menuProvider.dishes;
    final availableDishes = menu.where((d) => d.isAvailable && d.serves(_shift)).toList();
    final selectedDishes = menu.where((d) => (_quantities[d.id] ?? 0) > 0).toList();
    // Dishes picked under another shift stay visible so they can be removed.
    final gridDishes = [
      ...availableDishes,
      ...selectedDishes.where((d) => !availableDishes.contains(d)),
    ];
    final total = selectedDishes.fold(0, (s, d) => s + d.price * (_quantities[d.id] ?? 0));
    final itemCount = selectedDishes.fold(0, (s, d) => s + (_quantities[d.id] ?? 0));
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.isManager ? 'Add Entry' : 'Add Meal Entry')),
      body: ContentList(
        maxWidth: 900,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          if (widget.isManager) ...[
            FutureBuilder<List<Student>>(
              future: _studentsFuture,
              builder: (_, snap) => DropdownButtonFormField<String>(
                initialValue: _studentId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Student', prefixIcon: Icon(Icons.person_outline)),
                items: (snap.data ?? []).map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} • ${s.rollNumber}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _studentId = v),
              ),
            ),
            const SizedBox(height: 14),
          ],
          FutureBuilder<List<Hostel>>(
            future: _hostelsFuture,
            builder: (context, snap) {
              final hostels = snap.data ?? [];
              if (hostels.isEmpty) return const SizedBox.shrink();
              final authUser = context.read<AuthProvider>().user;
              final defaultHostelId = _hostelId ?? (hostels.any((h) => h.id == authUser?.hostelId) ? authUser?.hostelId : hostels.first.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DropdownButtonFormField<String>(
                  value: _hostelId ?? defaultHostelId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Hostel Mess',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  items: hostels.map((h) => DropdownMenuItem(
                    value: h.id,
                    child: Text('${h.name} Mess', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (v) => setState(() => _hostelId = v),
                ),
              );
            },
          ),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(AppDateUtils.dateText(_dateTime)),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final showIcons = constraints.maxWidth >= 380;
            return SegmentedButton<Shift>(
              showSelectedIcon: false,
              segments: [
                for (final s in Shift.values)
                  ButtonSegment<Shift>(
                    value: s,
                    icon: showIcons ? Icon(shiftIcon(s), size: 18) : null,
                    label: Text(s.label),
                  ),
              ],
              selected: {_shift},
              onSelectionChanged: (set) => setState(() => _shift = set.first),
            );
          }),
          SectionHeader(
            'Pick your dishes',
            subtitle: menuProvider.loading ? 'Loading menu…' : '${availableDishes.length} available for ${_shift.label.toLowerCase()}',
          ),
          if (menuProvider.loading && menu.isEmpty)
            const SkeletonPulse(
              child: Column(children: [
                SkeletonCard(height: 88),
                SizedBox(height: 12),
                SkeletonCard(height: 88),
                SizedBox(height: 12),
                SkeletonCard(height: 88),
              ]),
            )
          else if (gridDishes.isEmpty)
            const SizedBox(
              height: 260,
              child: EmptyState(
                title: 'No dishes for this shift',
                message: 'Try another shift, or check back when the menu is updated.',
                icon: Icons.no_meals,
              ),
            )
          else
            AdaptiveGrid(
              minItemWidth: 320,
              children: [
                for (final dish in gridDishes)
                  _DishPickTile(
                    dish: dish,
                    quantity: _quantities[dish.id] ?? 0,
                    maxQuantity: _maxQuantity,
                    onChanged: (q) => _setQuantity(dish.id, q),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _note,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes)),
          ),
          if (selectedDishes.isEmpty) ...[
            const SizedBox(height: 14),
            Text('Tap a dish above to add it to this entry.', style: text.bodySmall, textAlign: TextAlign.center),
          ],
        ],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : _TotalBar(
              total: total,
              itemCount: itemCount,
              submitting: _submitting,
              onSubmit: selectedDishes.isEmpty ? null : _submit,
            ),
    );
  }
}

class _DishPickTile extends StatelessWidget {
  const _DishPickTile({
    required this.dish,
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  final FoodItem dish;
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final selected = quantity > 0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? scheme.primary : Colors.transparent, width: 1.6),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
        child: InkWell(
          onTap: selected ? null : () => onChanged(1),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              FoodImage(path: dish.imagePath, name: dish.name, category: dish.category, size: 68, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dish.name, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(dish.category, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(CurrencyUtils.format(dish.price), style: text.labelLarge?.copyWith(color: scheme.primary)),
                ]),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: selected
                    ? _Stepper(
                        key: const ValueKey('stepper'),
                        quantity: quantity,
                        canIncrease: quantity < maxQuantity,
                        onChanged: onChanged,
                      )
                    : FilledButton.tonalIcon(
                        key: const ValueKey('add'),
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                        onPressed: () => onChanged(1),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({super.key, required this.quantity, required this.canIncrease, required this.onChanged});

  final int quantity;
  final bool canIncrease;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: quantity == 1 ? 'Remove' : 'Decrease',
          color: scheme.onPrimary,
          icon: Icon(quantity == 1 ? Icons.delete_outline : Icons.remove, size: 20),
          onPressed: () => onChanged(quantity - 1),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onPrimary),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Increase',
          color: scheme.onPrimary,
          disabledColor: scheme.onPrimary.withValues(alpha: 0.4),
          icon: const Icon(Icons.add, size: 20),
          onPressed: canIncrease ? () => onChanged(quantity + 1) : null,
        ),
      ]),
    );
  }
}

class _TotalBar extends StatelessWidget {
  const _TotalBar({required this.total, required this.itemCount, required this.submitting, required this.onSubmit});

  final int total;
  final int itemCount;
  final bool submitting;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant))),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        itemCount == 0 ? 'No dishes yet' : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        style: text.bodySmall,
                      ),
                      Text(
                        CurrencyUtils.format(total),
                        style: text.headlineSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
                      ),
                    ]),
                  ),
                  FilledButton.icon(
                    onPressed: submitting ? null : onSubmit,
                    icon: submitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.onPrimary),
                          )
                        : const Icon(Icons.check),
                    label: Text(submitting ? 'Submitting…' : 'Submit entry'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
