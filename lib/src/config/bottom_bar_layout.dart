import 'package:flutter/widgets.dart';

/// Layout configuration for [BottomBar].
///
/// Group all sizing/positioning concerns into one immutable, const-friendly
/// value object so the [BottomBar] constructor stays readable.
@immutable
class BottomBarLayout {
  const BottomBarLayout({
    this.width = 300,
    this.offset = 10,
    this.borderRadius = BorderRadius.zero,
    this.iconOffset = Offset.zero,
    this.alignment = Alignment.bottomCenter,
    this.fit = StackFit.loose,
    this.clip = Clip.hardEdge,
    this.respectSafeArea = true,
  });

  /// Width of the bar.
  final double width;

  /// Padding/offset from all sides of the host stack.
  final double offset;

  /// Border radius applied to the bar's default decoration.
  final BorderRadius borderRadius;

  /// Additional translation applied only to the back-to-top icon.
  ///
  /// For example, `Offset(0, 10)` moves the icon 10 logical pixels lower
  /// without changing the bar position.
  final Offset iconOffset;

  /// Alignment of the bar (and the back-to-top icon) within the host stack.
  final Alignment alignment;

  /// `Stack.fit` applied to the host stack.
  final StackFit fit;

  /// `Stack.clipBehavior` applied to the host stack.
  final Clip clip;

  /// When true, the bar is wrapped in a `SafeArea`; when false, the bar may
  /// extend into system UI areas.
  final bool respectSafeArea;

  /// Returns a copy of this layout with the given fields replaced by
  /// non-null values. Null arguments leave the corresponding field unchanged.
  BottomBarLayout copyWith({
    double? width,
    double? offset,
    BorderRadius? borderRadius,
    Offset? iconOffset,
    Alignment? alignment,
    StackFit? fit,
    Clip? clip,
    bool? respectSafeArea,
  }) {
    return BottomBarLayout(
      width: width ?? this.width,
      offset: offset ?? this.offset,
      borderRadius: borderRadius ?? this.borderRadius,
      iconOffset: iconOffset ?? this.iconOffset,
      alignment: alignment ?? this.alignment,
      fit: fit ?? this.fit,
      clip: clip ?? this.clip,
      respectSafeArea: respectSafeArea ?? this.respectSafeArea,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarLayout &&
        other.width == width &&
        other.offset == offset &&
        other.borderRadius == borderRadius &&
        other.iconOffset == iconOffset &&
        other.alignment == alignment &&
        other.fit == fit &&
        other.clip == clip &&
        other.respectSafeArea == respectSafeArea;
  }

  @override
  int get hashCode => Object.hash(
        width,
        offset,
        borderRadius,
        iconOffset,
        alignment,
        fit,
        clip,
        respectSafeArea,
      );
}
