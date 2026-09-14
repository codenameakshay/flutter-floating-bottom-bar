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
    required this.isVisible,
    required this.motion,
    required this.child,
  });

  final Animation<double> animation;
  final bool isVisible;
  final BottomBarMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final builder = motion.transitionBuilder;
    if (builder != null) {
      return _wrapInteraction(
        AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) => builder(context, animation, child!),
        ),
      );
    }
    final clamped = _ClampedAnimation(animation, max: 1);

    switch (motion.transition) {
      case BottomBarTransition.slide:
        return _wrapInteraction(
          SlideTransition(
            position: Tween<Offset>(
              begin: motion.slideStart,
              end: motion.slideEnd,
            ).animate(animation),
            child: child,
          ),
        );
      case BottomBarTransition.fade:
        return _wrapInteraction(FadeTransition(opacity: clamped, child: child));
      case BottomBarTransition.scale:
        return _wrapInteraction(
          ScaleTransition(scale: _ClampedAnimation(animation), child: child),
        );
      case BottomBarTransition.slideAndFade:
        return _wrapInteraction(
          FadeTransition(
            opacity: clamped,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: motion.slideStart,
                end: motion.slideEnd,
              ).animate(animation),
              child: child,
            ),
          ),
        );
    }
  }

  Widget _wrapInteraction(Widget child) {
    return IgnorePointer(
      ignoring: !isVisible,
      child: ExcludeSemantics(excluding: !isVisible, child: child),
    );
  }
}

/// Clamps [parent] to `[0, max]` so spring overshoot never feeds a negative
/// scale or an out-of-range opacity.
class _ClampedAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _ClampedAnimation(this.parent, {this.max = double.infinity});

  @override
  final Animation<double> parent;
  final double max;

  @override
  double get value => parent.value.clamp(0, max);
}
