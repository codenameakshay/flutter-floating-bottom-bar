import 'package:flutter/material.dart';

import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'config/bottom_bar_scroll_behavior.dart';

/// App-wide defaults for [BottomBar].
///
/// Add to your `ThemeData.extensions` to change the defaults across the app:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [
///       BottomBarThemeData(iconWidth: 36, iconHeight: 36),
///     ],
///   ),
/// );
/// ```
///
/// Resolution order at build time, lowest → highest precedence:
/// 1. Built-in defaults (Material 3 colors).
/// 2. `Theme.of(context).extension<BottomBarThemeData>()`.
/// 3. The `theme:` argument on [BottomBar].
/// 4. Per-widget config arguments (`layout`, `motion`, `scrollBehavior`).
@immutable
class BottomBarThemeData extends ThemeExtension<BottomBarThemeData> {
  const BottomBarThemeData({
    this.barDecoration,
    this.iconDecoration,
    this.iconWidth,
    this.iconHeight,
    this.layout,
    this.motion,
    this.scrollBehavior,
  });

  final BoxDecoration? barDecoration;
  final BoxDecoration? iconDecoration;
  final double? iconWidth;
  final double? iconHeight;
  final BottomBarLayout? layout;
  final BottomBarMotion? motion;
  final BottomBarScrollBehavior? scrollBehavior;

  /// Returns a new theme where non-null fields of [other] override fields of
  /// `this`. Null fields of [other] preserve `this`.
  BottomBarThemeData merge(BottomBarThemeData? other) {
    if (other == null) return this;
    return BottomBarThemeData(
      barDecoration: other.barDecoration ?? barDecoration,
      iconDecoration: other.iconDecoration ?? iconDecoration,
      iconWidth: other.iconWidth ?? iconWidth,
      iconHeight: other.iconHeight ?? iconHeight,
      layout: other.layout ?? layout,
      motion: other.motion ?? motion,
      scrollBehavior: other.scrollBehavior ?? scrollBehavior,
    );
  }

  @override
  BottomBarThemeData copyWith({
    BoxDecoration? barDecoration,
    BoxDecoration? iconDecoration,
    double? iconWidth,
    double? iconHeight,
    BottomBarLayout? layout,
    BottomBarMotion? motion,
    BottomBarScrollBehavior? scrollBehavior,
  }) {
    return BottomBarThemeData(
      barDecoration: barDecoration ?? this.barDecoration,
      iconDecoration: iconDecoration ?? this.iconDecoration,
      iconWidth: iconWidth ?? this.iconWidth,
      iconHeight: iconHeight ?? this.iconHeight,
      layout: layout ?? this.layout,
      motion: motion ?? this.motion,
      scrollBehavior: scrollBehavior ?? this.scrollBehavior,
    );
  }

  @override
  BottomBarThemeData lerp(
    covariant ThemeExtension<BottomBarThemeData>? other,
    double t,
  ) {
    if (other is! BottomBarThemeData) return this;
    return BottomBarThemeData(
      barDecoration:
          BoxDecoration.lerp(barDecoration, other.barDecoration, t),
      iconDecoration:
          BoxDecoration.lerp(iconDecoration, other.iconDecoration, t),
      iconWidth: _lerpDouble(iconWidth, other.iconWidth, t),
      iconHeight: _lerpDouble(iconHeight, other.iconHeight, t),
      // Config objects are stepped at t < 0.5 → this, t >= 0.5 → other.
      layout: t < 0.5 ? layout : other.layout,
      motion: t < 0.5 ? motion : other.motion,
      scrollBehavior: t < 0.5 ? scrollBehavior : other.scrollBehavior,
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) + ((b ?? 0) - (a ?? 0)) * t;
  }
}
