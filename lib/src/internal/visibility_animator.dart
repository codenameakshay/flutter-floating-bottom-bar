import 'package:flutter/widgets.dart';

import '../config/bottom_bar_motion.dart';

/// Wraps [child] in the transition selected by [motion].
///
/// Drives off [animation] (0 = hidden, 1 = shown). When
/// [BottomBarMotion.transitionBuilder] is non-null it is used directly;
/// otherwise [BottomBarMotion.transition] dispatches to a built-in.
class VisibilityAnimator extends StatelessWidget {
  const VisibilityAnimator({
    super.key,
    required this.animation,
    required this.motion,
    required this.child,
  });

  final Animation<double> animation;
  final BottomBarMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final builder = motion.transitionBuilder;
    if (builder != null) return builder(context, animation, child);

    switch (motion.transition) {
      case BottomBarTransition.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: motion.slideStart,
            end: motion.slideEnd,
          ).animate(animation),
          child: child,
        );
      case BottomBarTransition.fade:
        return FadeTransition(opacity: animation, child: child);
      case BottomBarTransition.scale:
        return ScaleTransition(scale: animation, child: child);
      case BottomBarTransition.slideAndFade:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: motion.slideStart,
              end: motion.slideEnd,
            ).animate(animation),
            child: child,
          ),
        );
    }
  }
}
