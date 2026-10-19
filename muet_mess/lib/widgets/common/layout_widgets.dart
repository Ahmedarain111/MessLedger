import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

/// A scrolling column that stays centered with a max readable width on wide
/// screens, while keeping the scrollbar at the screen edge.
class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
    required this.children,
    this.maxWidth = AppSizes.maxContentWidth,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 28),
    this.physics = const AlwaysScrollableScrollPhysics(),
    this.controller,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;
  final ScrollPhysics physics;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final side = constraints.maxWidth > maxWidth ? (constraints.maxWidth - maxWidth) / 2 : 0.0;
      return ListView(
        controller: controller,
        physics: physics,
        padding: padding.copyWith(left: padding.left + side, right: padding.right + side),
        children: children,
      );
    });
  }
}

/// Lays children out in as many equal-width columns as fit [minItemWidth].
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 180,
    this.gap = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      var columns = ((width + gap) / (minItemWidth + gap)).floor();
      if (columns < 1) columns = 1;
      if (columns > children.length && children.isNotEmpty) columns = children.length;
      final itemWidth = (width - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final c in children) SizedBox(width: itemWidth, child: c)],
      );
    });
  }
}

/// Two columns on wide layouts, stacked on narrow ones.
class TwoColumn extends StatelessWidget {
  const TwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 760,
    this.gap = 16,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final Widget left;
  final Widget right;
  final double breakpoint;
  final double gap;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= breakpoint) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: gap),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      }
      return Column(children: [left, SizedBox(height: gap), right]);
    });
  }
}

/// Section title with optional subtitle and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.trailing, this.padding = const EdgeInsets.only(top: 22, bottom: 10)});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: text.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: text.bodySmall),
            ],
          ]),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
