import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import 'bottom_bar_badge.dart';
import 'bottom_bar_indicator.dart';

/// Defaults for every [BottomBarItem] and [BottomBarItems] below a theme.
///
/// Set it as [BottomBarThemeData.items], either in the app's
/// `ThemeData.extensions` or on one [BottomBar]'s `theme:`:
///
/// ```dart
/// BottomBarThemeData(
///   items: BottomBarItemThemeData(
///     selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
///     pressedScale: 0.92,
///     indicator: BottomBarIndicator.pill(),
///   ),
/// )
/// ```
///
/// Every field is optional. A null field keeps the built-in look.
///
/// Resolution order, lowest to highest precedence:
/// 1. Built-in defaults.
/// 2. `ThemeData.extensions` [BottomBarThemeData.items].
/// 3. The enclosing [BottomBar]'s `theme:` [BottomBarThemeData.items].
/// 4. [BottomBarItems] arguments (`indicator`, `indicatorMotion`). An
///    indicator's foreground colour beats [selectedColor].
/// 5. [BottomBarItem] arguments (`color`, `selectedColor`).
///
/// Items outside a [BottomBar] read the `ThemeData.extensions` level only.
@immutable
class BottomBarItemThemeData {
  /// Creates a [BottomBarItemThemeData].
  const BottomBarItemThemeData({
    this.color,
    this.selectedColor,
    this.iconSize,
    this.selectedIconSize,
    this.labelStyle,
    this.selectedLabelStyle,
    this.padding,
    this.iconLabelGap,
    this.inkBorderRadius,
    this.overlayColor,
    this.splashFactory,
    this.pressedScale,
    this.motion,
    this.indicator,
    this.indicatorMotion,
    this.badge,
  });

  /// Icon and label colour of an unselected item.
  ///
  /// Defaults to `colorScheme.onSurfaceVariant`.
  final Color? color;

  /// Icon and label colour of a selected item.
  ///
  /// Defaults to `colorScheme.primary`. A row indicator with its own
  /// foreground colour (pill, tint, underline) wins over this.
  final Color? selectedColor;

  /// Icon size of an unselected item. Defaults to the ambient [IconTheme].
  final double? iconSize;

  /// Icon size of a selected item. Defaults to [iconSize].
  final double? selectedIconSize;

  /// Label style of an unselected item, merged over `textTheme.labelSmall`.
  ///
  /// Its colour is replaced by [color] or [selectedColor].
  final TextStyle? labelStyle;

  /// Label style of a selected item, merged over [labelStyle].
  ///
  /// The change animates, so a heavier `fontWeight` grows in.
  final TextStyle? selectedLabelStyle;

  /// Padding around the icon and label.
  ///
  /// Defaults to 8 horizontal and 4 vertical.
  final EdgeInsetsGeometry? padding;

  /// Space between the icon and the label. Defaults to 2.
  final double? iconLabelGap;

  /// Corner radius of the ink highlight and splash. Defaults to 8.
  final BorderRadius? inkBorderRadius;

  /// Ink overlay colour per state, as in [InkWell.overlayColor].
  final WidgetStateProperty<Color?>? overlayColor;

  /// Ink splash, as in [InkWell.splashFactory].
  ///
  /// Use [NoSplash.splashFactory] to remove the ripple.
  final InteractiveInkFeatureFactory? splashFactory;

  /// Scale of the icon and label while the item is pressed.
  ///
  /// Defaults to 1, which turns it off. A value like 0.92 shrinks the content
  /// on press and springs it back on release. The hit target and the
  /// indicator do not scale.
  final double? pressedScale;

  /// The spring for item transitions: colour, icon, label and press.
  ///
  /// Defaults to a short smooth Cupertino spring. Reduced motion skips it.
  final Motion? motion;

  /// The indicator for a [BottomBarItems] row with no `indicator` argument.
  ///
  /// A row opts out with [BottomBarIndicator.none].
  final BottomBarIndicator? indicator;

  /// The indicator spring for a [BottomBarItems] row with no
  /// `indicatorMotion` argument.
  final Motion? indicatorMotion;

  /// Defaults for every [BottomBarBadge] on these items.
  final BottomBarBadgeThemeData? badge;

  /// Returns a theme where the non-null fields of [other] override this one.
  BottomBarItemThemeData merge(BottomBarItemThemeData? other) {
    if (other == null) return this;
    return copyWith(
      color: other.color,
      selectedColor: other.selectedColor,
      iconSize: other.iconSize,
      selectedIconSize: other.selectedIconSize,
      labelStyle: other.labelStyle,
      selectedLabelStyle: other.selectedLabelStyle,
      padding: other.padding,
      iconLabelGap: other.iconLabelGap,
      inkBorderRadius: other.inkBorderRadius,
      overlayColor: other.overlayColor,
      splashFactory: other.splashFactory,
      pressedScale: other.pressedScale,
      motion: other.motion,
      indicator: other.indicator,
      indicatorMotion: other.indicatorMotion,
      badge: badge?.merge(other.badge) ?? other.badge,
    );
  }

  /// Returns a copy with the given non-null fields replaced.
  BottomBarItemThemeData copyWith({
    Color? color,
    Color? selectedColor,
    double? iconSize,
    double? selectedIconSize,
    TextStyle? labelStyle,
    TextStyle? selectedLabelStyle,
    EdgeInsetsGeometry? padding,
    double? iconLabelGap,
    BorderRadius? inkBorderRadius,
    WidgetStateProperty<Color?>? overlayColor,
    InteractiveInkFeatureFactory? splashFactory,
    double? pressedScale,
    Motion? motion,
    BottomBarIndicator? indicator,
    Motion? indicatorMotion,
    BottomBarBadgeThemeData? badge,
  }) {
    return BottomBarItemThemeData(
      color: color ?? this.color,
      selectedColor: selectedColor ?? this.selectedColor,
      iconSize: iconSize ?? this.iconSize,
      selectedIconSize: selectedIconSize ?? this.selectedIconSize,
      labelStyle: labelStyle ?? this.labelStyle,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      padding: padding ?? this.padding,
      iconLabelGap: iconLabelGap ?? this.iconLabelGap,
      inkBorderRadius: inkBorderRadius ?? this.inkBorderRadius,
      overlayColor: overlayColor ?? this.overlayColor,
      splashFactory: splashFactory ?? this.splashFactory,
      pressedScale: pressedScale ?? this.pressedScale,
      motion: motion ?? this.motion,
      indicator: indicator ?? this.indicator,
      indicatorMotion: indicatorMotion ?? this.indicatorMotion,
      badge: badge ?? this.badge,
    );
  }

  /// Linearly interpolates between [a] and [b].
  ///
  /// Colours, sizes, styles, padding and radii interpolate, and [badge] uses
  /// [BottomBarBadgeThemeData.lerp]. [splashFactory],
  /// [motion], [indicator] and [indicatorMotion] switch at `t == 0.5`.
  static BottomBarItemThemeData? lerp(
    BottomBarItemThemeData? a,
    BottomBarItemThemeData? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    a ??= const BottomBarItemThemeData();
    b ??= const BottomBarItemThemeData();
    final first = t < 0.5;
    return BottomBarItemThemeData(
      color: Color.lerp(a.color, b.color, t),
      selectedColor: Color.lerp(a.selectedColor, b.selectedColor, t),
      iconSize: lerpDouble(a.iconSize, b.iconSize, t),
      selectedIconSize: lerpDouble(a.selectedIconSize, b.selectedIconSize, t),
      labelStyle: lerpLabelStyle(a.labelStyle, b.labelStyle, t),
      selectedLabelStyle: lerpLabelStyle(
        a.selectedLabelStyle,
        b.selectedLabelStyle,
        t,
      ),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      iconLabelGap: lerpDouble(a.iconLabelGap, b.iconLabelGap, t),
      inkBorderRadius: BorderRadius.lerp(
        a.inkBorderRadius,
        b.inkBorderRadius,
        t,
      ),
      overlayColor: WidgetStateProperty.lerp<Color?>(
        a.overlayColor,
        b.overlayColor,
        t,
        Color.lerp,
      ),
      splashFactory: first ? a.splashFactory : b.splashFactory,
      pressedScale: lerpDouble(a.pressedScale, b.pressedScale, t),
      motion: first ? a.motion : b.motion,
      indicator: first ? a.indicator : b.indicator,
      indicatorMotion: first ? a.indicatorMotion : b.indicatorMotion,
      badge: BottomBarBadgeThemeData.lerp(a.badge, b.badge, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarItemThemeData &&
        other.color == color &&
        other.selectedColor == selectedColor &&
        other.iconSize == iconSize &&
        other.selectedIconSize == selectedIconSize &&
        other.labelStyle == labelStyle &&
        other.selectedLabelStyle == selectedLabelStyle &&
        other.padding == padding &&
        other.iconLabelGap == iconLabelGap &&
        other.inkBorderRadius == inkBorderRadius &&
        other.overlayColor == overlayColor &&
        other.splashFactory == splashFactory &&
        other.pressedScale == pressedScale &&
        other.motion == motion &&
        other.indicator == indicator &&
        other.indicatorMotion == indicatorMotion &&
        other.badge == badge;
  }

  @override
  int get hashCode => Object.hash(
    color,
    selectedColor,
    iconSize,
    selectedIconSize,
    labelStyle,
    selectedLabelStyle,
    padding,
    iconLabelGap,
    inkBorderRadius,
    overlayColor,
    splashFactory,
    pressedScale,
    motion,
    indicator,
    indicatorMotion,
    badge,
  );
}

/// [TextStyle.lerp] that switches at `t == 0.5` instead of asserting when
/// only one style inherits.
TextStyle? lerpLabelStyle(TextStyle? a, TextStyle? b, double t) {
  if (a != null && b != null && a.inherit != b.inherit) return t < 0.5 ? a : b;
  return TextStyle.lerp(a, b, t);
}
