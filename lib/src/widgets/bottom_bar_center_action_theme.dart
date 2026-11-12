import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

/// Defaults for the centre action button below a theme. Set it as
/// [BottomBarItemThemeData.centerAction].
///
/// Every field is optional. A null field keeps the Material 3 look for the
/// button's style.
@immutable
class BottomBarCenterActionThemeData {
  /// Creates a [BottomBarCenterActionThemeData].
  const BottomBarCenterActionThemeData({
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.shape,
    this.elevation,
    this.shadowColor,
    this.raise,
    this.notchMargin,
  });

  /// Fill of the button. Defaults to `colorScheme.primary`.
  final Color? backgroundColor;

  /// Icon colour. Defaults to `colorScheme.onPrimary`.
  final Color? foregroundColor;

  /// Width and height of the button. Defaults to 48 for
  /// `BottomBarCenterActionStyle.inline` and 56 for raised and notched.
  final double? size;

  /// Button shape. Defaults to a Material 3 FAB rounded rectangle (radius 16
  /// at size 56, scaled with size) for inline and raised, and a circle for
  /// notched. The notch is always circular.
  final ShapeBorder? shape;

  /// Elevation of the button. Defaults to 0 for inline and 3 for raised or
  /// notched.
  final double? elevation;

  /// Colour of the button's shadow. Defaults to `colorScheme.shadow`.
  final Color? shadowColor;

  /// How far the button's top sits above the bar's top edge. Raised and
  /// notched only. Defaults to half the size, so the button's centre sits on
  /// the edge.
  final double? raise;

  /// Gap between the button and the notch. Notched only. Defaults to 6.
  final double? notchMargin;

  /// Returns a theme where the non-null fields of [other] override this one.
  BottomBarCenterActionThemeData merge(BottomBarCenterActionThemeData? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      foregroundColor: other.foregroundColor,
      size: other.size,
      shape: other.shape,
      elevation: other.elevation,
      shadowColor: other.shadowColor,
      raise: other.raise,
      notchMargin: other.notchMargin,
    );
  }

  /// Returns a copy with the given non-null fields replaced.
  BottomBarCenterActionThemeData copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    double? size,
    ShapeBorder? shape,
    double? elevation,
    Color? shadowColor,
    double? raise,
    double? notchMargin,
  }) {
    return BottomBarCenterActionThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      size: size ?? this.size,
      shape: shape ?? this.shape,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      raise: raise ?? this.raise,
      notchMargin: notchMargin ?? this.notchMargin,
    );
  }

  /// Linearly interpolates between [a] and [b]. A null theme counts as empty.
  /// [shape] interpolates with [ShapeBorder.lerp].
  static BottomBarCenterActionThemeData? lerp(
    BottomBarCenterActionThemeData? a,
    BottomBarCenterActionThemeData? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    a ??= const BottomBarCenterActionThemeData();
    b ??= const BottomBarCenterActionThemeData();
    return BottomBarCenterActionThemeData(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      foregroundColor: Color.lerp(a.foregroundColor, b.foregroundColor, t),
      size: lerpDouble(a.size, b.size, t),
      shape: ShapeBorder.lerp(a.shape, b.shape, t),
      elevation: lerpDouble(a.elevation, b.elevation, t),
      shadowColor: Color.lerp(a.shadowColor, b.shadowColor, t),
      raise: lerpDouble(a.raise, b.raise, t),
      notchMargin: lerpDouble(a.notchMargin, b.notchMargin, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarCenterActionThemeData &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.size == size &&
        other.shape == shape &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.raise == raise &&
        other.notchMargin == notchMargin;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    size,
    shape,
    elevation,
    shadowColor,
    raise,
    notchMargin,
  );
}
