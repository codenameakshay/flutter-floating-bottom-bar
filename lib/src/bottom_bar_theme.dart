import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import 'bottom_bar_presets.dart';
import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'config/bottom_bar_scroll_behavior.dart';
import 'widgets/bottom_bar_indicator.dart';
import 'widgets/bottom_bar_item_theme.dart';
import 'widgets/bottom_bar_surface.dart';

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
///
/// [items] follows the same order and continues it: [BottomBarItems]
/// arguments, then [BottomBarItem] arguments. See [BottomBarItemThemeData].
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
    this.items,
    this.surface,
    this.scrollEdgeSurface,
  });

  /// The iOS 26 tab bar: a floating glass capsule that clears at the scroll
  /// edge, a tinted capsule behind the selected item, springs and the
  /// selection haptic.
  ///
  /// [accent] colours the selected item and its tint, default
  /// `colorScheme.primary`. [indicator] replaces the tint.
  ///
  /// Colours left null fill from the [ColorScheme] when the bar builds, so
  /// the preset follows light, dark and dynamic colour. A preset is a plain
  /// [BottomBarThemeData]: pass it as `theme:` or add it to
  /// `ThemeData.extensions`, and change the rest with [copyWith] or [merge]:
  ///
  /// ```dart
  /// BottomBar(
  ///   theme: BottomBarThemeData.glass().merge(
  ///     const BottomBarThemeData(
  ///       items: BottomBarItemThemeData(haptics: BottomBarHaptics.none),
  ///     ),
  ///   ),
  ///   body: body,
  ///   child: items,
  /// )
  /// ```
  factory BottomBarThemeData.glass({
    Color? accent,
    BottomBarIndicator? indicator,
  }) => glassPreset(accent: accent, indicator: indicator);

  /// Flutter's Material 3 [NavigationBar]: docked full width on a solid
  /// `surfaceContainer`, an 80 tall row, the 64 x 32 stadium indicator in
  /// `secondaryContainer` behind the icon, and 12 sp medium labels.
  ///
  /// The selected icon and label take `colorScheme.primary`, where
  /// [NavigationBar] uses `onSecondaryContainer` and `onSurface`. Set
  /// [BottomBarItemThemeData.selectedColor] with [copyWith] to change it.
  /// Labels always show unless [BottomBarItems.labelBehavior] says otherwise.
  ///
  /// [backgroundColor] and [indicatorColor] replace the two fills. Null
  /// colours fill from the [ColorScheme] when the bar builds. Pass the preset
  /// as `theme:` or a `ThemeData` extension, and change the rest with
  /// [copyWith] or [merge]:
  ///
  /// ```dart
  /// BottomBarThemeData.material3().copyWith(
  ///   motion: const BottomBarMotion.curved(),
  /// )
  /// ```
  factory BottomBarThemeData.material3({
    Color? backgroundColor,
    Color? indicatorColor,
  }) => material3Preset(
    backgroundColor: backgroundColor,
    indicatorColor: indicatorColor,
  );

  /// A floating, fully rounded solid bar with a soft shadow, a sliding pill
  /// behind the selected item, a small press scale and the selection haptic.
  ///
  /// [accent] fills the pill, default `colorScheme.primary`, and the content
  /// it covers takes black or white for contrast. [indicator] replaces the
  /// pill.
  ///
  /// Null colours fill from the [ColorScheme] when the bar builds. Pass the
  /// preset as `theme:` or a `ThemeData` extension, and change the rest with
  /// [copyWith] or [merge]:
  ///
  /// ```dart
  /// BottomBarThemeData.pill(accent: Colors.teal).merge(
  ///   const BottomBarThemeData(
  ///     layout: BottomBarLayout.adaptive(maxWidth: 360),
  ///   ),
  /// )
  /// ```
  factory BottomBarThemeData.pill({
    Color? accent,
    BottomBarIndicator? indicator,
  }) => pillPreset(accent: accent, indicator: indicator);

  /// A flat floating bar with no shadow, a dot under the selected item,
  /// no ink and short, quiet motion. The bar fades instead of sliding.
  ///
  /// Pair it with `labelBehavior: BottomBarLabelBehavior.onlySelected` or
  /// `alwaysHide` on [BottomBarItems]. The label behaviour is a row argument,
  /// so a theme cannot set it.
  ///
  /// [accent] colours the selected item and the dot, default
  /// `colorScheme.primary`. [indicator] replaces the dot, for example with
  /// `BottomBarIndicator.underline()`.
  ///
  /// Null colours fill from the [ColorScheme] when the bar builds. Pass the
  /// preset as `theme:` or a `ThemeData` extension, and change the rest with
  /// [copyWith] or [merge]:
  ///
  /// ```dart
  /// BottomBarThemeData.minimal(
  ///   indicator: const BottomBarIndicator.underline(),
  /// )
  /// ```
  factory BottomBarThemeData.minimal({
    Color? accent,
    BottomBarIndicator? indicator,
  }) => minimalPreset(accent: accent, indicator: indicator);

  /// Decoration applied to the floating bar's outer container.
  ///
  /// Defaults to `BoxDecoration(color: colorScheme.surfaceContainer,
  /// borderRadius: BorderRadius.circular(28))` when unset.
  final BoxDecoration? barDecoration;

  /// Decoration applied to the back-to-top icon's container.
  ///
  /// Defaults to `BoxDecoration(color: colorScheme.primary,
  /// shape: BoxShape.circle)` when unset.
  final BoxDecoration? iconDecoration;

  /// Width of the back-to-top icon in logical pixels. Defaults to `30`.
  final double? iconWidth;

  /// Height of the back-to-top icon in logical pixels. Defaults to `30`.
  final double? iconHeight;

  /// Theme-level layout defaults. Overridden by the `layout:` argument on
  /// the individual [BottomBar] widget.
  final BottomBarLayout? layout;

  /// Theme-level motion defaults. Overridden by the `motion:` argument on
  /// the individual [BottomBar] widget.
  final BottomBarMotion? motion;

  /// Theme-level scroll behaviour defaults. Overridden by the
  /// `scrollBehavior:` argument on the individual [BottomBar] widget.
  final BottomBarScrollBehavior? scrollBehavior;

  /// Defaults for [BottomBarItem]s and [BottomBarItems] rows.
  ///
  /// [BottomBar] passes its resolved value to its `child` subtree. Items
  /// outside a [BottomBar] read the `ThemeData.extensions` value.
  final BottomBarItemThemeData? items;

  /// How the bar's surface paints, such as [BottomBarSurface.glass].
  ///
  /// When set, it paints the bar instead of the fill, gradient, image, border
  /// and shadows of [barDecoration]. The corner radius still comes from
  /// [BottomBarLayout.borderRadius] when a layout is given, else from
  /// [barDecoration]. Null paints [barDecoration] as before.
  final BottomBarSurface? surface;

  /// The surface while nothing scrolls under the bar, like UIKit's
  /// `scrollEdgeAppearance`. For example `BottomBarSurface(fillOpacity: 0)`
  /// for a clear bar.
  ///
  /// The bar follows the vertical list that scrolled last and is on screen.
  /// It is at the edge when that list's content does not reach under the bar:
  /// it is scrolled to its end, or to its start when it is reversed, or it is
  /// shorter than the viewport. A horizontal list never counts. With no list,
  /// the bar paints [surface].
  ///
  /// The bar blends between [surface] and this surface with
  /// [BottomBarSurface.lerp] and the bar's motion. Reduced motion snaps.
  /// When [surface] is null, the bar blends from the fill, gradient, border
  /// and shadows of [barDecoration] instead, and drops its image. Null always
  /// paints [surface].
  ///
  /// [copyWith] and [merge] keep this field when the new value is null. To
  /// change [surface] and keep the edge the same, set both.
  final BottomBarSurface? scrollEdgeSurface;

  /// Returns a new theme where non-null fields of [other] override fields of
  /// `this`. Null fields of [other] preserve `this`. [items] merges field by
  /// field.
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
      items: items?.merge(other.items) ?? other.items,
      surface: other.surface ?? surface,
      scrollEdgeSurface: other.scrollEdgeSurface ?? scrollEdgeSurface,
    );
  }

  /// Returns a copy of this theme with the given fields replaced by
  /// non-null values. Null arguments leave the corresponding field unchanged.
  @override
  BottomBarThemeData copyWith({
    BoxDecoration? barDecoration,
    BoxDecoration? iconDecoration,
    double? iconWidth,
    double? iconHeight,
    BottomBarLayout? layout,
    BottomBarMotion? motion,
    BottomBarScrollBehavior? scrollBehavior,
    BottomBarItemThemeData? items,
    BottomBarSurface? surface,
    BottomBarSurface? scrollEdgeSurface,
  }) {
    return BottomBarThemeData(
      barDecoration: barDecoration ?? this.barDecoration,
      iconDecoration: iconDecoration ?? this.iconDecoration,
      iconWidth: iconWidth ?? this.iconWidth,
      iconHeight: iconHeight ?? this.iconHeight,
      layout: layout ?? this.layout,
      motion: motion ?? this.motion,
      scrollBehavior: scrollBehavior ?? this.scrollBehavior,
      items: items ?? this.items,
      surface: surface ?? this.surface,
      scrollEdgeSurface: scrollEdgeSurface ?? this.scrollEdgeSurface,
    );
  }

  /// Linearly interpolates between this theme and [other] at fraction [t].
  ///
  /// Decoration fields use [BoxDecoration.lerp]. Numeric fields use standard
  /// linear interpolation. Config objects ([layout], [motion], [scrollBehavior])
  /// step at `t == 0.5` — `this` for `t < 0.5`, [other] for `t >= 0.5`.
  /// [items] uses [BottomBarItemThemeData.lerp], and [surface] and
  /// [scrollEdgeSurface] use [BottomBarSurface.lerp].
  @override
  BottomBarThemeData lerp(
    covariant ThemeExtension<BottomBarThemeData>? other,
    double t,
  ) {
    if (other is! BottomBarThemeData) return this;
    return BottomBarThemeData(
      barDecoration: BoxDecoration.lerp(barDecoration, other.barDecoration, t),
      iconDecoration: BoxDecoration.lerp(
        iconDecoration,
        other.iconDecoration,
        t,
      ),
      iconWidth: lerpDouble(iconWidth, other.iconWidth, t),
      iconHeight: lerpDouble(iconHeight, other.iconHeight, t),
      // Config objects are stepped at t < 0.5 → this, t >= 0.5 → other.
      layout: t < 0.5 ? layout : other.layout,
      motion: t < 0.5 ? motion : other.motion,
      scrollBehavior: t < 0.5 ? scrollBehavior : other.scrollBehavior,
      items: BottomBarItemThemeData.lerp(items, other.items, t),
      surface: BottomBarSurface.lerp(surface, other.surface, t),
      scrollEdgeSurface: BottomBarSurface.lerp(
        scrollEdgeSurface,
        other.scrollEdgeSurface,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BottomBarThemeData &&
      other.barDecoration == barDecoration &&
      other.iconDecoration == iconDecoration &&
      other.iconWidth == iconWidth &&
      other.iconHeight == iconHeight &&
      other.layout == layout &&
      other.motion == motion &&
      other.scrollBehavior == scrollBehavior &&
      other.items == items &&
      other.surface == surface &&
      other.scrollEdgeSurface == scrollEdgeSurface;

  @override
  int get hashCode => Object.hash(
    barDecoration,
    iconDecoration,
    iconWidth,
    iconHeight,
    layout,
    motion,
    scrollBehavior,
    items,
    surface,
    scrollEdgeSurface,
  );
}
