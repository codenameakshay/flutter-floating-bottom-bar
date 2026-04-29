import 'package:flutter/widgets.dart';

/// Built-in transition presets for [BottomBar].
///
/// Pair with [BottomBarMotion.transition]. To customize beyond the presets,
/// supply [BottomBarMotion.transitionBuilder] (which overrides this enum).
enum BottomBarTransition {
  /// Slide the bar from offscreen toward its rest position.
  slide,

  /// Fade the bar in and out without translation.
  fade,

  /// Scale the bar from 0.0 to 1.0 (and back) while showing/hiding.
  scale,

  /// Slide and fade simultaneously.
  slideAndFade,
}

/// Animation configuration for [BottomBar] show/hide.
@immutable
class BottomBarMotion {
  const BottomBarMotion({
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeOutCubic,
    this.transition = BottomBarTransition.slide,
    this.transitionBuilder,
    this.slideStart = const Offset(0, 2),
    this.slideEnd = Offset.zero,
  });

  /// Duration of the show/hide animation.
  final Duration duration;

  /// Curve of the show/hide animation.
  final Curve curve;

  /// Built-in preset to use when [transitionBuilder] is null.
  final BottomBarTransition transition;

  /// When non-null, takes precedence over [transition]; receives the bar's
  /// `Animation<double>` (from 0 hidden → 1 shown) and the bar child.
  final Widget Function(BuildContext, Animation<double>, Widget)?
      transitionBuilder;

  /// Slide source offset (used by `BottomBarTransition.slide` and
  /// `BottomBarTransition.slideAndFade`). Expressed in the same units as
  /// `SlideTransition.position` — multiples of the child size.
  final Offset slideStart;

  /// Slide rest offset (the visible position).
  final Offset slideEnd;

  BottomBarMotion copyWith({
    Duration? duration,
    Curve? curve,
    BottomBarTransition? transition,
    Widget Function(BuildContext, Animation<double>, Widget)? transitionBuilder,
    Offset? slideStart,
    Offset? slideEnd,
  }) {
    return BottomBarMotion(
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      transition: transition ?? this.transition,
      transitionBuilder: transitionBuilder ?? this.transitionBuilder,
      slideStart: slideStart ?? this.slideStart,
      slideEnd: slideEnd ?? this.slideEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarMotion &&
        other.duration == duration &&
        other.curve == curve &&
        other.transition == transition &&
        other.transitionBuilder == transitionBuilder &&
        other.slideStart == slideStart &&
        other.slideEnd == slideEnd;
  }

  @override
  int get hashCode => Object.hash(
        duration,
        curve,
        transition,
        transitionBuilder,
        slideStart,
        slideEnd,
      );
}
