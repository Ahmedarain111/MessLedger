import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';

/// Compact metric card (icon + value + label). Thin wrapper kept for
/// backwards compatibility; prefer [SummaryStatCard].
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.icon = Icons.analytics_outlined, this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => SummaryStatCard(title: label, value: value, icon: icon, color: color);
}
