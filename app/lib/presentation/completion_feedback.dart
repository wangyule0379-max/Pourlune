import 'package:flutter/material.dart';

import 'motion.dart';

class CompletionFeedback extends StatelessWidget {
  const CompletionFeedback({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduced
          ? const Duration(milliseconds: 150)
          : KnitMotion.success,
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: reduced
            ? child
            : Transform.scale(
                scale: .94 + .06 * value,
                alignment: Alignment.centerLeft,
                child: child,
              ),
      ),
    );
  }
}
