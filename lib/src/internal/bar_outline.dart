import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// The bar's outline: a rounded rectangle, optionally with a smooth circular
/// notch cut into its top edge.
///
/// [notch] is the circle the notch makes room for, already inflated by the
/// notch margin. It is relative to the centre of the rect the shape is drawn
/// in, so an offset shadow carries the notch with it.
///
/// The bar paints its fill and its shadows through this shape, and any clip
/// of the bar should use [getOuterPath], so all of them agree.
@immutable
class BarOutline extends ShapeBorder {
  const BarOutline({
    this.borderRadius = BorderRadius.zero,
    this.notch,
    this.border,
  });

  final BorderRadiusGeometry borderRadius;
  final Rect? notch;

  /// The decoration's border. Painted exactly as [BoxDecoration] paints it
  /// when there is no notch.
  final BoxBorder? border;

  /// [notch] placed for [rect], or null when it misses the top edge.
  Rect? _notchIn(Rect rect) {
    final notch = this.notch;
    if (notch == null) return null;
    final guest = notch.shift(rect.center);
    if (!rect.overlaps(guest) || guest.top >= rect.top) return null;
    return guest;
  }

  RRect _rrect(Rect rect, TextDirection? textDirection) =>
      borderRadius.resolve(textDirection).toRRect(rect);

  @override
  EdgeInsetsGeometry get dimensions => border?.dimensions ?? EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final rounded = Path()..addRRect(_rrect(rect, textDirection));
    final guest = _notchIn(rect);
    if (guest == null) return rounded;
    return Path.combine(
      PathOperation.intersect,
      rounded,
      const CircularNotchedRectangle().getOuterPath(rect, guest),
    );
  }

  // ShapeDecoration clips only its image to this. BoxDecoration clips the
  // image to the outer edge, so this does too.
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  bool get preferPaintInterior => true;

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) {
    // Matches BoxDecoration's own fill so a bar without a notch paints the
    // same pixels it always did.
    if (_notchIn(rect) != null) {
      canvas.drawPath(getOuterPath(rect, textDirection: textDirection), paint);
    } else if (borderRadius == BorderRadius.zero) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRRect(_rrect(rect, textDirection), paint);
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final border = this.border;
    if (border == null) return;
    if (_notchIn(rect) == null) {
      border.paint(
        canvas,
        rect,
        borderRadius: borderRadius.resolve(textDirection),
        textDirection: textDirection,
      );
      return;
    }
    // ponytail: a notched outline strokes one side all round; per-side
    // borders would need the path split into edges.
    final side = border.top;
    if (side.style == BorderStyle.none || side.width == 0) return;
    final inset = side.width / 2 - side.strokeInset;
    canvas.drawPath(
      getOuterPath(rect.deflate(-inset), textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  ShapeBorder scale(double t) => BarOutline(
    borderRadius: borderRadius * t,
    notch: notch == null
        ? null
        : Rect.fromCenter(
            center: notch!.center * t,
            width: notch!.width * t,
            height: notch!.height * t,
          ),
    border: border?.scale(t) as BoxBorder?,
  );

  @override
  bool operator ==(Object other) =>
      other is BarOutline &&
      other.borderRadius == borderRadius &&
      other.notch == notch &&
      other.border == border;

  @override
  int get hashCode => Object.hash(borderRadius, notch, border);
}
