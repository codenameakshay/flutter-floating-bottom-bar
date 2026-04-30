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
    if (builder != null) {
      return AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => builder(context, animation, child!),
      );
    }
    final clamped = _ClampedAnimation(animation);

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
        return FadeTransition(opacity: clamped, child: child);
      case BottomBarTransition.scale:
        return ScaleTransition(
            scale: _NonNegativeAnimation(animation), child: child);
      case BottomBarTransition.slideAndFade:
        return FadeTransition(
          opacity: clamped,
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

class _ClampedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ClampedAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value.clamp(0.0, 1.0);
}

class _NonNegativeAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _NonNegativeAnimation(this.parent);

  @override
  final Animation<double> parent;

  @override
  double get value => parent.value < 0 ? 0 : parent.value;
}
