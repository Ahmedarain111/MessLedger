import 'package:flutter/material.dart';

/// True when the platform asks apps to reduce / disable animations.
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Fades and slides its child up slightly on first build. Use [index] to
/// stagger items in a list (capped so long lists do not feel slow).
///
/// Implemented with a single [AnimationController] (no timers), so it is
/// safe in widget tests.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 14});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  static const _baseMs = 360;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    final step = widget.index > 8 ? 8 : widget.index;
    final delayMs = step * 50;
    final totalMs = _baseMs + delayMs;
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: totalMs));
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayMs / totalMs, 1, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return FadeTransition(
      opacity: _animation,
      child: AnimatedBuilder(
        animation: _animation,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _animation.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}
