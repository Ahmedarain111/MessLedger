import 'package:flutter/material.dart';

/// Initials avatar with a stable, name-derived tint (no hard-coded colors).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    var hash = 7;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) % 360;
    }
    final hue = hash.toDouble();
    final background = HSLColor.fromAHSL(1, hue, 0.5, dark ? 0.28 : 0.9).toColor();
    final foreground = HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.86 : 0.3).toColor();
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        _initials,
        style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: radius * 0.78, height: 1),
      ),
    );
  }
}
