import 'package:flutter/rendering.dart';
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
          AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) => EdgeSlide(
              start: motion.slideStart,
              end: motion.slideEnd,
              progress: animation.value,
              child: child,
            ),
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
    return ExcludeFocus(
      excluding: !isVisible,
      child: IgnorePointer(
        ignoring: !isVisible,
        child: ExcludeSemantics(excluding: !isVisible, child: child),
      ),
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

/// Slides [child] from [start] (hidden, at [progress] 0) to [end] (shown, at
/// [progress] 1), in multiples of the child's size.
///
/// [start] is measured from where the child sits flush against the edge of
/// the enclosing [BottomBar] stack that it moves toward, so `Offset(0, 1)`
/// hides it fully whatever layout offset, safe-area padding or keyboard lift
/// sits between the bar and that edge.
class EdgeSlide extends SingleChildRenderObjectWidget {
  const EdgeSlide({
    super.key,
    required this.start,
    required this.end,
    required this.progress,
    super.child,
  });

  final Offset start;
  final Offset end;
  final double progress;

  @override
  RenderEdgeSlide createRenderObject(BuildContext context) {
    return RenderEdgeSlide(start: start, end: end, progress: progress);
  }

  @override
  void updateRenderObject(BuildContext context, RenderEdgeSlide renderObject) {
    renderObject
      ..start = start
      ..end = end
      ..progress = progress;
  }
}

/// Render object for [EdgeSlide].
class RenderEdgeSlide extends RenderProxyBox {
  RenderEdgeSlide({
    required this._start,
    required this._end,
    required this._progress,
  });

  Offset _start;
  set start(Offset value) {
    if (value == _start) return;
    _start = value;
    markNeedsPaint();
  }

  Offset _end;
  set end(Offset value) {
    if (value == _end) return;
    _end = value;
    markNeedsPaint();
  }

  double _progress;
  set progress(double value) {
    if (value == _progress) return;
    _progress = value;
    markNeedsPaint();
  }

  Offset get translation {
    final hidden =
        Offset(_start.dx * size.width, _start.dy * size.height) +
        _gapToHostEdge(_start);
    final shown = Offset(_end.dx * size.width, _end.dy * size.height);
    return hidden + (shown - hidden) * _progress;
  }

  // Distance from this box to the edge of the BottomBar's Stack (the nearest
  // RenderStack ancestor) along each axis [direction] moves on.
  Offset _gapToHostEdge(Offset direction) {
    if (direction == Offset.zero) return Offset.zero;
    var host = parent;
    while (host != null && host is! RenderStack) {
      host = host.parent;
    }
    if (host is! RenderStack || !host.hasSize) return Offset.zero;
    final rect = MatrixUtils.transformRect(
      getTransformTo(host),
      Offset.zero & size,
    );
    return Offset(
      direction.dx > 0
          ? host.size.width - rect.right
          : (direction.dx < 0 ? -rect.left : 0),
      direction.dy > 0
          ? host.size.height - rect.bottom
          : (direction.dy < 0 ? -rect.top : 0),
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // The child paints outside this box while sliding; test it there.
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintOffset(
      offset: translation,
      position: position,
      hitTest: (result, position) =>
          super.hitTestChildren(result, position: position),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset + translation);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final t = translation;
    transform.translateByDouble(t.dx, t.dy, 0, 1);
  }
}
