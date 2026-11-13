import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How the bar's surface paints: a solid fill, or frosted glass that blurs
/// what scrolls under it.
///
/// Set it as `BottomBarThemeData.surface`. It then paints the bar instead of
/// the fill, gradient, image, border and shadows of
/// `BottomBarThemeData.barDecoration`. The bar's corner radius still comes from
/// `BottomBarLayout.borderRadius` or `barDecoration.borderRadius`, and a
/// notched centre action still cuts its notch out of the surface.
///
/// [BottomBarSurface.solid] and [BottomBarSurface.glass] are presets of this
/// one class, so [lerp] blends between them: blur grows from 0 and the fill
/// opacity moves smoothly.
///
/// When the platform asks for high contrast, the bar paints no blur. It fills
/// with [fallbackColor] and keeps the outline, [border] and [shadows].
@immutable
class BottomBarSurface {
  /// Creates a surface. Every field defaults to a plain, opaque bar.
  const BottomBarSurface({
    this.blur = 0,
    this.saturation = 1,
    this.tint,
    this.fillOpacity = 1,
    this.gradient,
    this.border,
    this.edgeHighlight,
    this.shadows,
    this.fallbackColor,
  }) : assert(blur >= 0),
       assert(saturation >= 0),
       assert(fillOpacity >= 0 && fillOpacity <= 1);

  /// An opaque bar. [color] defaults to the `ColorScheme.surfaceContainer`.
  const BottomBarSurface.solid({
    Color? color,
    Gradient? gradient,
    BoxBorder? border,
    List<BoxShadow>? shadows,
    Color? fallbackColor,
  }) : this(
         tint: color,
         gradient: gradient,
         border: border,
         shadows: shadows,
         fallbackColor: fallbackColor,
       );

  /// A frosted glass bar.
  ///
  /// It blurs the content under the bar by [blur], boosts its [saturation],
  /// and lays [tint] over it at [fillOpacity]. [tint] defaults to the
  /// `ColorScheme.surfaceContainer`. The default opacity keeps the default
  /// item colours readable over both white and black content.
  /// [edgeHighlight] draws a light line along the inner top edge. Pass
  /// `edgeHighlight: null` or `shadows: null` to turn either off.
  const BottomBarSurface.glass({
    double blur = 16,
    double saturation = 1.6,
    Color? tint,
    double fillOpacity = 0.8,
    Gradient? gradient,
    BoxBorder? border,
    Color? edgeHighlight = const Color(0x59FFFFFF),
    List<BoxShadow>? shadows = const [
      BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
    Color? fallbackColor,
  }) : this(
         blur: blur,
         saturation: saturation,
         tint: tint,
         fillOpacity: fillOpacity,
         gradient: gradient,
         border: border,
         edgeHighlight: edgeHighlight,
         shadows: shadows,
         fallbackColor: fallbackColor,
       );

  /// Gaussian blur sigma for the content behind the bar. `0` reads no
  /// backdrop at all.
  final double blur;

  /// Saturation of the blurred backdrop. `1` leaves it unchanged, above `1`
  /// makes colours richer. Ignored when [blur] is `0`.
  final double saturation;

  /// Fill colour, drawn at [fillOpacity]. Defaults to the
  /// `ColorScheme.surfaceContainer`.
  final Color? tint;

  /// Opacity of the fill: [tint] and [gradient]. `1` is opaque.
  final double fillOpacity;

  /// Gradient drawn over [tint], at [fillOpacity].
  final Gradient? gradient;

  /// Border drawn along the outline, notch included.
  final BoxBorder? border;

  /// Colour of a 1px line along the inside of the top edge. It fades out
  /// down the sides. Null draws none.
  final Color? edgeHighlight;

  /// Shadows cast outside the outline. They never show through a translucent
  /// fill.
  final List<BoxShadow>? shadows;

  /// Fill used instead of the glass when the platform asks for high contrast.
  /// Defaults to the opaque `ColorScheme.surfaceContainer`.
  final Color? fallbackColor;

  /// Returns a copy with the given fields replaced.
  BottomBarSurface copyWith({
    double? blur,
    double? saturation,
    Color? tint,
    double? fillOpacity,
    Gradient? gradient,
    BoxBorder? border,
    Color? edgeHighlight,
    List<BoxShadow>? shadows,
    Color? fallbackColor,
  }) {
    return BottomBarSurface(
      blur: blur ?? this.blur,
      saturation: saturation ?? this.saturation,
      tint: tint ?? this.tint,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      gradient: gradient ?? this.gradient,
      border: border ?? this.border,
      edgeHighlight: edgeHighlight ?? this.edgeHighlight,
      shadows: shadows ?? this.shadows,
      fallbackColor: fallbackColor ?? this.fallbackColor,
    );
  }

  /// Interpolates field by field. A null surface on one side steps at
  /// `t == 0.5`, because no surface means the bar paints `barDecoration`.
  static BottomBarSurface? lerp(
    BottomBarSurface? a,
    BottomBarSurface? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null || b == null) return t < 0.5 ? a : b;
    if (t == 0) return a;
    if (t == 1) return b;
    return BottomBarSurface(
      blur: lerpDouble(a.blur, b.blur, t)!.clamp(0, double.infinity),
      saturation: lerpDouble(
        a.saturation,
        b.saturation,
        t,
      )!.clamp(0, double.infinity),
      tint: Color.lerp(a.tint, b.tint, t),
      fillOpacity: lerpDouble(a.fillOpacity, b.fillOpacity, t)!.clamp(0, 1),
      gradient: Gradient.lerp(a.gradient, b.gradient, t),
      border: BoxBorder.lerp(a.border, b.border, t),
      edgeHighlight: Color.lerp(a.edgeHighlight, b.edgeHighlight, t),
      shadows: BoxShadow.lerpList(a.shadows, b.shadows, t),
      fallbackColor: Color.lerp(a.fallbackColor, b.fallbackColor, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BottomBarSurface &&
      other.blur == blur &&
      other.saturation == saturation &&
      other.tint == tint &&
      other.fillOpacity == fillOpacity &&
      other.gradient == gradient &&
      other.border == border &&
      other.edgeHighlight == edgeHighlight &&
      listEquals(other.shadows, shadows) &&
      other.fallbackColor == fallbackColor;

  @override
  int get hashCode => Object.hash(
    blur,
    saturation,
    tint,
    fillOpacity,
    gradient,
    border,
    edgeHighlight,
    shadows == null ? null : Object.hashAll(shadows!),
    fallbackColor,
  );
}
