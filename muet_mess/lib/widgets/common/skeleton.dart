import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';
import 'layout_widgets.dart';
import 'motion.dart';

/// Gently pulses its child; used to wrap skeleton placeholders. Respects the
/// platform "reduce motion" setting.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late final Animation<double> _opacity = Tween<double>(begin: 0.45, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}

/// A rounded placeholder block.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder shaped like an entry / list card.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.height = 96});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: height,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(children: [
            SkeletonBox(width: 44, height: 44, radius: 14),
            SizedBox(width: 12),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                SkeletonBox(width: 150, height: 14),
                SizedBox(height: 10),
                SkeletonBox(height: 12),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 12),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Full-screen list skeleton (replaces a centered spinner).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 5, this.itemHeight = 96, this.showHero = false});

  final int itemCount;
  final double itemHeight;
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ContentList(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (showHero) ...[
            const SkeletonBox(height: 140, radius: AppSizes.radiusXl),
            const SizedBox(height: 14),
          ],
          for (var i = 0; i < itemCount; i++) ...[
            SkeletonCard(height: itemHeight),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// Skeleton for the dashboards: hero + stat tiles + a few cards.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ContentList(
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SkeletonBox(height: 150, radius: AppSizes.radiusXl),
          SizedBox(height: 14),
          AdaptiveGrid(minItemWidth: 160, children: [
            SkeletonBox(height: 76, radius: AppSizes.radiusLg),
            SkeletonBox(height: 76, radius: AppSizes.radiusLg),
            SkeletonBox(height: 76, radius: AppSizes.radiusLg),
            SkeletonBox(height: 76, radius: AppSizes.radiusLg),
          ]),
          SizedBox(height: 20),
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
          SizedBox(height: 12),
          SkeletonCard(),
        ],
      ),
    );
  }
}

/// Skeleton for image grids (menu).
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.count = 8, this.maxCrossAxisExtent = 220, this.mainAxisExtent = 232});

  final int count;
  final double maxCrossAxisExtent;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisExtent: mainAxisExtent,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const SkeletonBox(radius: AppSizes.radiusLg),
      ),
    );
  }
}
