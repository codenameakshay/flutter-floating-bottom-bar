import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

/// Layout configuration for [BottomBar].
///
/// Group all sizing/positioning concerns into one immutable, const-friendly
/// value object so the [BottomBar] constructor stays readable.
///
/// [width] is always clamped by the host viewport, and optionally by
/// [maxWidth]. Use [BottomBarLayout.adaptive] when the bar should fill the
/// available host width up to a hard cap, and [BottomBarLayout.docked] for a
/// full-width bar on the screen's bottom edge.
///
/// [alignment], [borderRadius] and [iconOffset] are physical: they do not
/// mirror under [TextDirection.rtl]. Set [directionalAlignment],
/// [directionalBorderRadius] or [directionalIconOffset] for values that
/// follow the reading direction. A directional value, when set, is used
/// instead of its physical counterpart.
@immutable
class BottomBarLayout {
  const BottomBarLayout({
    this.width = 300,
    this.maxWidth,
    this.offset = 10,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.directionalBorderRadius,
    this.iconOffset = Offset.zero,
    this.directionalIconOffset,
    this.alignment = Alignment.bottomCenter,
    this.directionalAlignment,
    this.fit = StackFit.loose,
    this.clip = Clip.hardEdge,
    this.respectSafeArea = true,
    this.avoidKeyboard = true,
    this.groupSpacing = 8,
  }) : assert(
         maxWidth == null || (maxWidth >= 0 && maxWidth < double.infinity),
       ),
       assert(groupSpacing >= 0),
       docked = false;

  /// Creates a layout that fills the available host width up to [maxWidth].
  ///
  /// This is equivalent to setting [width] to `double.infinity` while keeping
  /// the regular constructor's other defaults intact. [maxWidth] must be
  /// finite and non-negative.
  const BottomBarLayout.adaptive({
    required double maxWidth,
    this.offset = 10,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.directionalBorderRadius,
    this.iconOffset = Offset.zero,
    this.directionalIconOffset,
    this.alignment = Alignment.bottomCenter,
    this.directionalAlignment,
    this.fit = StackFit.loose,
    this.clip = Clip.hardEdge,
    this.respectSafeArea = true,
    this.avoidKeyboard = true,
    this.groupSpacing = 8,
  }) : assert(maxWidth >= 0 && maxWidth < double.infinity),
       assert(groupSpacing >= 0),
       maxWidth = maxWidth,
       width = double.infinity,
       docked = false;

  /// Creates a full-width bar docked to the bottom edge, like the Material 3
  /// docked toolbar.
  ///
  /// The bar has no side margin and no [offset]. Its surface runs down to
  /// the screen's bottom edge, under the system navigation area, while its
  /// child stays above the bottom and side safe-area insets when
  /// [respectSafeArea] is true. Hiding slides the whole surface off screen,
  /// inset included. [BottomBarScope.barHeight] includes the inset.
  ///
  /// Corners are square by default. Pass a [borderRadius] such as
  /// `BorderRadius.vertical(top: Radius.circular(16))` to round the top.
  ///
  /// A docked bar is one surface, so it ignores `BottomBar.leading` and
  /// `BottomBar.trailing`. Put those widgets in the bar's child instead.
  const BottomBarLayout.docked({
    this.borderRadius = BorderRadius.zero,
    this.directionalBorderRadius,
    this.iconOffset = Offset.zero,
    this.directionalIconOffset,
    this.fit = StackFit.loose,
    this.clip = Clip.hardEdge,
    this.respectSafeArea = true,
    this.avoidKeyboard = true,
  }) : width = double.infinity,
       maxWidth = null,
       offset = 0,
       alignment = Alignment.bottomCenter,
       directionalAlignment = null,
       groupSpacing = 8,
       docked = true;

  /// Requested width of the bar before viewport and [maxWidth] clamping.
  final double width;

  /// Maximum width of the bar after host constraints are applied.
  ///
  /// When null, [width] is the only explicit width cap. Must be finite and
  /// non-negative when provided.
  final double? maxWidth;

  /// Padding/offset from all sides of the host stack.
  ///
  /// This contributes to the layout footprint reported through
  /// [BottomBarScope.barHeight] and reserved by [BottomBarBodyPadding].
  final double offset;

  /// Border radius applied to the bar's default decoration.
  ///
  /// Defaults to a 28px Material 3 radius, matching the built-in theme.
  /// Pass [BorderRadius.zero] for a square bar. [directionalBorderRadius]
  /// takes precedence when set.
  final BorderRadius borderRadius;

  /// A border radius that follows the reading direction, such as a
  /// [BorderRadiusDirectional] with only `topStart` rounded.
  ///
  /// When non-null, it is used instead of [borderRadius].
  final BorderRadiusGeometry? directionalBorderRadius;

  /// Additional translation applied only to the built-in hidden action.
  ///
  /// For example, `Offset(0, 10)` moves the icon 10 logical pixels lower
  /// without changing the bar position. [directionalIconOffset] takes
  /// precedence when set.
  final Offset iconOffset;

  /// Like [iconOffset], but `dx` points toward the end side: right in
  /// [TextDirection.ltr] and left in [TextDirection.rtl].
  ///
  /// When non-null, it is used instead of [iconOffset].
  final Offset? directionalIconOffset;

  /// Alignment of the bar (and the built-in hidden action) within the host
  /// stack. [directionalAlignment] takes precedence when set.
  final Alignment alignment;

  /// An alignment that follows the reading direction, such as
  /// [AlignmentDirectional.bottomStart].
  ///
  /// When non-null, it is used instead of [alignment].
  final AlignmentGeometry? directionalAlignment;

  /// `Stack.fit` applied to the host stack.
  final StackFit fit;

  /// `Stack.clipBehavior` applied to the host stack.
  final Clip clip;

  /// When true, the bar stays inside the safe area: the bottom inset (home
  /// indicator, gesture or button navigation) and the side insets (notch,
  /// landscape navigation buttons). A bottom-aligned bar ignores the top
  /// inset, and a top-aligned bar ignores the bottom one.
  ///
  /// When false, the bar may extend into system UI areas.
  final bool respectSafeArea;

  /// When true, the bar and the built-in hidden action are padded by
  /// `MediaQuery.viewInsets.bottom` so they sit above the on-screen keyboard.
  ///
  /// Has no effect when `viewInsets.bottom` is already zero, which is the
  /// typical case for a `Scaffold` body since the `Scaffold` already shrinks
  /// its body to avoid the keyboard. Does not change [BottomBarScope.barHeight].
  final bool avoidKeyboard;

  /// The clear gap between the pill and each of `BottomBar.leading` and
  /// `BottomBar.trailing`. Defaults to 8. Unused when the bar has neither.
  final double groupSpacing;

  /// Whether the bar is docked: its surface reaches the bottom edge under the
  /// safe-area inset. Set by [BottomBarLayout.docked].
  final bool docked;

  /// [directionalAlignment], or [alignment] when it is null.
  AlignmentGeometry get effectiveAlignment => directionalAlignment ?? alignment;

  /// [directionalBorderRadius], or [borderRadius] when it is null.
  BorderRadiusGeometry get effectiveBorderRadius =>
      directionalBorderRadius ?? borderRadius;

  /// The hidden action's translation for [textDirection], from
  /// [directionalIconOffset] or else [iconOffset].
  Offset resolveIconOffset(TextDirection textDirection) {
    final directional = directionalIconOffset;
    if (directional == null) return iconOffset;
    return textDirection == TextDirection.rtl
        ? Offset(-directional.dx, directional.dy)
        : directional;
  }

  /// Returns a copy of this layout with the given fields replaced by non-null
  /// values.
  ///
  /// Null arguments leave the corresponding field unchanged. Set
  /// [clearMaxWidth] to true to remove an existing [maxWidth] cap. A
  /// directional field keeps its precedence: passing [alignment] does not
  /// clear [directionalAlignment].
  BottomBarLayout copyWith({
    double? width,
    double? maxWidth,
    bool clearMaxWidth = false,
    double? offset,
    BorderRadius? borderRadius,
    BorderRadiusGeometry? directionalBorderRadius,
    Offset? iconOffset,
    Offset? directionalIconOffset,
    Alignment? alignment,
    AlignmentGeometry? directionalAlignment,
    StackFit? fit,
    Clip? clip,
    bool? respectSafeArea,
    bool? avoidKeyboard,
    double? groupSpacing,
    bool? docked,
  }) {
    assert(
      !clearMaxWidth || maxWidth == null,
      'maxWidth and clearMaxWidth cannot both be provided.',
    );
    return BottomBarLayout._(
      width: width ?? this.width,
      maxWidth: clearMaxWidth ? null : (maxWidth ?? this.maxWidth),
      offset: offset ?? this.offset,
      borderRadius: borderRadius ?? this.borderRadius,
      directionalBorderRadius:
          directionalBorderRadius ?? this.directionalBorderRadius,
      iconOffset: iconOffset ?? this.iconOffset,
      directionalIconOffset:
          directionalIconOffset ?? this.directionalIconOffset,
      alignment: alignment ?? this.alignment,
      directionalAlignment: directionalAlignment ?? this.directionalAlignment,
      fit: fit ?? this.fit,
      clip: clip ?? this.clip,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
      avoidKeyboard: avoidKeyboard ?? this.avoidKeyboard,
      groupSpacing: groupSpacing ?? this.groupSpacing,
      docked: docked ?? this.docked,
    );
  }

  const BottomBarLayout._({
    required this.width,
    required this.maxWidth,
    required this.offset,
    required this.borderRadius,
    required this.directionalBorderRadius,
    required this.iconOffset,
    required this.directionalIconOffset,
    required this.alignment,
    required this.directionalAlignment,
    required this.fit,
    required this.clip,
    required this.respectSafeArea,
    required this.avoidKeyboard,
    required this.groupSpacing,
    required this.docked,
  }) : assert(
         maxWidth == null || (maxWidth >= 0 && maxWidth < double.infinity),
       ),
       assert(groupSpacing >= 0);

  /// Linearly interpolates between [a] and [b] at fraction [t].
  ///
  /// [offset], [borderRadius], [iconOffset], [alignment] and [groupSpacing]
  /// interpolate. [width] and [maxWidth] interpolate when both are finite and
  /// step otherwise, so an adaptive layout never turns into a NaN width.
  /// When either side sets a directional alignment or border radius, the
  /// result interpolates the two effective values into the directional
  /// field. [directionalIconOffset] interpolates when both sides set it and
  /// steps when only one does. The other fields step at `t == 0.5`.
  static BottomBarLayout? lerp(
    BottomBarLayout? a,
    BottomBarLayout? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null || b == null) return t < 0.5 ? a : b;
    final near = t < 0.5 ? a : b;
    double? size(double? x, double? y) =>
        x != null && y != null && x.isFinite && y.isFinite
        ? lerpDouble(x, y, t)
        : (t < 0.5 ? x : y);
    final anyDirectionalAlignment =
        a.directionalAlignment != null || b.directionalAlignment != null;
    final anyDirectionalRadius =
        a.directionalBorderRadius != null || b.directionalBorderRadius != null;
    final bothDirectionalIcon =
        a.directionalIconOffset != null && b.directionalIconOffset != null;
    final anyDirectionalIcon =
        a.directionalIconOffset != null || b.directionalIconOffset != null;
    return BottomBarLayout._(
      width: size(a.width, b.width)!,
      maxWidth: size(a.maxWidth, b.maxWidth),
      offset: lerpDouble(a.offset, b.offset, t)!,
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t)!,
      directionalBorderRadius: anyDirectionalRadius
          ? BorderRadiusGeometry.lerp(
              a.effectiveBorderRadius,
              b.effectiveBorderRadius,
              t,
            )
          : null,
      iconOffset: Offset.lerp(a.iconOffset, b.iconOffset, t)!,
      directionalIconOffset: bothDirectionalIcon
          ? Offset.lerp(a.directionalIconOffset, b.directionalIconOffset, t)
          : anyDirectionalIcon
          ? near.directionalIconOffset
          : null,
      alignment: Alignment.lerp(a.alignment, b.alignment, t)!,
      directionalAlignment: anyDirectionalAlignment
          ? AlignmentGeometry.lerp(
              a.effectiveAlignment,
              b.effectiveAlignment,
              t,
            )
          : null,
      fit: near.fit,
      clip: near.clip,
      respectSafeArea: near.respectSafeArea,
      avoidKeyboard: near.avoidKeyboard,
      groupSpacing: lerpDouble(a.groupSpacing, b.groupSpacing, t)!,
      docked: near.docked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarLayout &&
        other.width == width &&
        other.maxWidth == maxWidth &&
        other.offset == offset &&
        other.borderRadius == borderRadius &&
        other.directionalBorderRadius == directionalBorderRadius &&
        other.iconOffset == iconOffset &&
        other.directionalIconOffset == directionalIconOffset &&
        other.alignment == alignment &&
        other.directionalAlignment == directionalAlignment &&
        other.fit == fit &&
        other.clip == clip &&
        other.respectSafeArea == respectSafeArea &&
        other.avoidKeyboard == avoidKeyboard &&
        other.groupSpacing == groupSpacing &&
        other.docked == docked;
  }

  @override
  int get hashCode => Object.hash(
    width,
    maxWidth,
    offset,
    borderRadius,
    directionalBorderRadius,
    iconOffset,
    directionalIconOffset,
    alignment,
    directionalAlignment,
    fit,
    clip,
    respectSafeArea,
    avoidKeyboard,
    groupSpacing,
    docked,
  );
}
