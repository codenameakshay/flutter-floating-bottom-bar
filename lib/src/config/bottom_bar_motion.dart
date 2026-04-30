import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart' as motor;

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

/// Animation engine used by [BottomBarMotion].
enum BottomBarMotionMode {
  /// Apple-style spring presets backed by Motor's [motor.CupertinoMotion].
  cupertino,

  /// Traditional duration + curve motion.
  curved,

  /// A caller-supplied Motor motion.
  motor,
}

/// Built-in Cupertino spring presets for [BottomBarMotion.cupertino].
enum BottomBarCupertinoMotion {
  smooth,
  snappy,
  bouncy,
  interactive,
}

/// Animation configuration for [BottomBar] show/hide.
@immutable
class BottomBarMotion {
  static const Duration _defaultCupertinoDuration = Duration(milliseconds: 500);
  static const Duration _defaultCurvedDuration = Duration(milliseconds: 240);
  static const Curve _defaultCurve = Curves.easeOutCubic;

  const BottomBarMotion({
    Duration? duration,
    Curve? curve,
    this.transition = BottomBarTransition.slide,
    this.transitionBuilder,
    this.slideStart = const Offset(0, 2),
    this.slideEnd = Offset.zero,
  })  : mode = duration == null && curve == null
            ? BottomBarMotionMode.cupertino
            : BottomBarMotionMode.curved,
        duration = duration ??
            (curve == null
                ? _defaultCupertinoDuration
                : _defaultCurvedDuration),
        curve = curve ?? _defaultCurve,
        cupertinoPreset = BottomBarCupertinoMotion.snappy,
        extraBounce = 0,
        snapToEnd = true,
        motorMotion = null;

  const BottomBarMotion.cupertino({
    BottomBarCupertinoMotion preset = BottomBarCupertinoMotion.snappy,
    this.duration = _defaultCupertinoDuration,
    this.extraBounce = 0,
    this.snapToEnd = true,
    this.transition = BottomBarTransition.slide,
    this.transitionBuilder,
    this.slideStart = const Offset(0, 2),
    this.slideEnd = Offset.zero,
  })  : mode = BottomBarMotionMode.cupertino,
        curve = _defaultCurve,
        cupertinoPreset = preset,
        motorMotion = null;

  const BottomBarMotion.curved({
    this.duration = _defaultCurvedDuration,
    this.curve = _defaultCurve,
    this.transition = BottomBarTransition.slide,
    this.transitionBuilder,
    this.slideStart = const Offset(0, 2),
    this.slideEnd = Offset.zero,
  })  : mode = BottomBarMotionMode.curved,
        cupertinoPreset = BottomBarCupertinoMotion.snappy,
        extraBounce = 0,
        snapToEnd = true,
        motorMotion = null;

  const BottomBarMotion.motor(
    this.motorMotion, {
    this.duration = _defaultCurvedDuration,
    this.curve = _defaultCurve,
    this.transition = BottomBarTransition.slide,
    this.transitionBuilder,
    this.slideStart = const Offset(0, 2),
    this.slideEnd = Offset.zero,
  })  : mode = BottomBarMotionMode.motor,
        cupertinoPreset = BottomBarCupertinoMotion.snappy,
        extraBounce = 0,
        snapToEnd = true;

  /// Which motion engine drives the bar.
  final BottomBarMotionMode mode;

  /// Duration used by curve motion and as the estimated duration for springs.
  final Duration duration;

  /// Curve used by [BottomBarMotionMode.curved] and scroll-to-boundary actions.
  final Curve curve;

  /// Cupertino spring preset used by [BottomBarMotionMode.cupertino].
  final BottomBarCupertinoMotion cupertinoPreset;

  /// Additional bounce applied to Cupertino presets.
  final double extraBounce;

  /// Whether Motor should snap exactly to the target when the spring settles.
  final bool snapToEnd;

  /// Custom Motor motion used when [mode] is [BottomBarMotionMode.motor].
  final motor.Motion? motorMotion;

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
    BottomBarMotionMode? mode,
    Duration? duration,
    Curve? curve,
    BottomBarCupertinoMotion? cupertinoPreset,
    double? extraBounce,
    bool? snapToEnd,
    motor.Motion? motorMotion,
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
    )._copyMotionFields(
      mode: mode ?? this.mode,
      cupertinoPreset: cupertinoPreset ?? this.cupertinoPreset,
      extraBounce: extraBounce ?? this.extraBounce,
      snapToEnd: snapToEnd ?? this.snapToEnd,
      motorMotion: motorMotion ?? this.motorMotion,
    );
  }

  BottomBarMotion _copyMotionFields({
    required BottomBarMotionMode mode,
    required BottomBarCupertinoMotion cupertinoPreset,
    required double extraBounce,
    required bool snapToEnd,
    required motor.Motion? motorMotion,
  }) {
    switch (mode) {
      case BottomBarMotionMode.cupertino:
        return BottomBarMotion.cupertino(
          preset: cupertinoPreset,
          duration: duration,
          extraBounce: extraBounce,
          snapToEnd: snapToEnd,
          transition: transition,
          transitionBuilder: transitionBuilder,
          slideStart: slideStart,
          slideEnd: slideEnd,
        );
      case BottomBarMotionMode.curved:
        return BottomBarMotion.curved(
          duration: duration,
          curve: curve,
          transition: transition,
          transitionBuilder: transitionBuilder,
          slideStart: slideStart,
          slideEnd: slideEnd,
        );
      case BottomBarMotionMode.motor:
        return BottomBarMotion.motor(
          motorMotion ??
              this.motorMotion ??
              motor.Motion.curved(duration, curve),
          duration: duration,
          curve: curve,
          transition: transition,
          transitionBuilder: transitionBuilder,
          slideStart: slideStart,
          slideEnd: slideEnd,
        );
    }
  }

  /// Resolves this package-level configuration to the Motor motion that drives
  /// the controller.
  motor.Motion resolveMotion() {
    switch (mode) {
      case BottomBarMotionMode.cupertino:
        return switch (cupertinoPreset) {
          BottomBarCupertinoMotion.smooth => motor.CupertinoMotion.smooth(
              duration: duration,
              extraBounce: extraBounce,
              snapToEnd: snapToEnd,
            ),
          BottomBarCupertinoMotion.snappy => motor.CupertinoMotion.snappy(
              duration: duration,
              extraBounce: extraBounce,
              snapToEnd: snapToEnd,
            ),
          BottomBarCupertinoMotion.bouncy => motor.CupertinoMotion.bouncy(
              duration: duration,
              extraBounce: extraBounce,
              snapToEnd: snapToEnd,
            ),
          BottomBarCupertinoMotion.interactive =>
            motor.CupertinoMotion.interactive(
              duration: duration,
              extraBounce: extraBounce,
              snapToEnd: snapToEnd,
            ),
        };
      case BottomBarMotionMode.curved:
        return motor.Motion.curved(duration, curve);
      case BottomBarMotionMode.motor:
        return motorMotion ?? motor.Motion.curved(duration, curve);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarMotion &&
        other.mode == mode &&
        other.duration == duration &&
        other.curve == curve &&
        other.cupertinoPreset == cupertinoPreset &&
        other.extraBounce == extraBounce &&
        other.snapToEnd == snapToEnd &&
        other.motorMotion == motorMotion &&
        other.transition == transition &&
        other.transitionBuilder == transitionBuilder &&
        other.slideStart == slideStart &&
        other.slideEnd == slideEnd;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        duration,
        curve,
        cupertinoPreset,
        extraBounce,
        snapToEnd,
        motorMotion,
        transition,
        transitionBuilder,
        slideStart,
        slideEnd,
      );
}
