import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Gradient background used on auth / landing screens.
class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child, this.borderRadius = BorderRadius.zero});

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: tokens.heroGradient),
        ),
        child: Stack(fit: StackFit.expand, children: [
          Positioned(right: -70, top: -70, child: _Orb(260, tokens.onHero.withValues(alpha: 0.07))),
          Positioned(left: -50, bottom: -90, child: _Orb(240, tokens.onHero.withValues(alpha: 0.06))),
          Positioned(right: 40, bottom: 80, child: _Orb(90, tokens.onHero.withValues(alpha: 0.05))),
          child,
        ]),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

/// Translucent logo tile shown on gradient backgrounds.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final onHero = context.tokens.onHero;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onHero.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: onHero.withValues(alpha: 0.28)),
      ),
      child: Icon(Icons.restaurant_menu, color: onHero, size: size * 0.52),
    );
  }
}
