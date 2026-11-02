import 'package:flutter/material.dart';

/// Wraps a list item or card in a hardware-accelerated, lightweight entry animation
/// that glides into view smoothly with zero jank or frame drops.
class AppAnimatedItem extends StatelessWidget {
  final int index;
  final Widget child;

  const AppAnimatedItem({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 180 + (index * 25).clamp(0, 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, animChild) {
        return Transform.translate(
          offset: Offset(0, 8 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: animChild,
          ),
        );
      },
      child: child,
    );
  }
}
