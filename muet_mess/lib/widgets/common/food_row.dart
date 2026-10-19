import 'package:flutter/material.dart';

import '../../core/utils/currency_utils.dart';
import '../../models/food_item_model.dart';
import 'food_image.dart';

/// [Image] [Name] ... [Price] all on a single row. Price is right-aligned.
class FoodRow extends StatelessWidget {
  const FoodRow({
    super.key,
    required this.item,
    this.trailing,
    this.leading,
    this.onTap,
  });

  final FoodItem item;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          FoodImage(path: item.imagePath, name: item.name, category: item.category, size: 48),
          const SizedBox(width: 12),
          Expanded(child: Text(item.name, style: Theme.of(context).textTheme.titleSmall)),
          Text(CurrencyUtils.format(item.price), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary)),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ]),
      ),
    );
  }
}
