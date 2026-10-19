import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/enums.dart';
import '../../models/food_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../widgets/common/food_image.dart';
import '../../widgets/common/motion.dart';
import '../../widgets/common/shift_badge.dart';
import '../../widgets/common/skeleton.dart';

class StudentMenuScreen extends StatefulWidget {
  const StudentMenuScreen({super.key});

  @override
  State<StudentMenuScreen> createState() => _StudentMenuScreenState();
}

class _StudentMenuScreenState extends State<StudentMenuScreen> {
  late Future<List<FoodItem>> _dishesFuture;
  Shift? _selectedShift;

  @override
  void initState() {
    super.initState();
    _dishesFuture = context.read<MenuProvider>().getDishes();
  }

  Future<void> _refresh() async {
    setState(() {
      _dishesFuture = context.read<MenuProvider>().getDishes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mess Menu')),
      body: FutureBuilder<List<FoodItem>>(
        future: _dishesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const GridSkeleton();
          }
          if (snapshot.hasError) {
            return ErrorState(
              title: 'Could not load menu',
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final allDishes = snapshot.data ?? [];
          final dishes = _selectedShift == null
              ? allDishes
              : allDishes.where((d) => d.serves(_selectedShift!)).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    ChoiceChip(
                      avatar: const Icon(Icons.restaurant_menu, size: 18),
                      label: const Text('All shifts'),
                      selected: _selectedShift == null,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedShift = null),
                    ),
                    const SizedBox(width: 8),
                    ...Shift.values.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(shiftIcon(s), size: 18, color: shiftColor(context, s)),
                          label: Text(s.label),
                          selected: _selectedShift == s,
                          showCheckmark: false,
                          onSelected: (sel) => setState(() => _selectedShift = sel ? s : null),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${dishes.length} ${dishes.length == 1 ? 'dish' : 'dishes'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: dishes.isEmpty
                      ? ListView(children: const [
                          SizedBox(
                            height: 360,
                            child: EmptyState(
                              title: 'No dishes found',
                              message: 'No menu items match the selected filter.',
                              icon: Icons.no_meals,
                            ),
                          ),
                        ])
                      : LayoutBuilder(builder: (context, constraints) {
                          final side = constraints.maxWidth > AppSizes.maxContentWidth
                              ? (constraints.maxWidth - AppSizes.maxContentWidth) / 2
                              : 0.0;
                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(16 + side, 8, 16 + side, 28),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 230,
                              mainAxisExtent: 246,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: dishes.length,
                            itemBuilder: (context, index) => FadeSlideIn(
                              index: index,
                              child: _DishCard(dish: dishes[index]),
                            ),
                          );
                        }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({required this.dish});

  final FoodItem dish;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final available = dish.isAvailable;
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 138,
          width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            FoodImage(
              path: dish.imagePath,
              name: dish.name,
              category: dish.category,
              fill: true,
              radius: 0,
              grayscale: !available,
            ),
            if (!available)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    'Sold out',
                    style: text.labelSmall?.copyWith(color: scheme.onErrorContainer, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              dish.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                color: available ? null : scheme.onSurfaceVariant,
                decoration: available ? null : TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(height: 2),
            Text(dish.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text(
                  CurrencyUtils.format(dish.price),
                  style: text.titleMedium?.copyWith(color: available ? scheme.primary : scheme.onSurfaceVariant),
                ),
              ),
              for (final s in Shift.values.where(dish.serves))
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Tooltip(
                    message: s.label,
                    child: Icon(shiftIcon(s), size: 16, color: shiftColor(context, s)),
                  ),
                ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
