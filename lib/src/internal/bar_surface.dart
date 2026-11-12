import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bar_outline.dart';

/// Paints the bar's decoration through its [BarOutline] and hosts a raised
/// centre action.
///
/// A raised action makes this box taller by its raise, so the part above the
/// bar's top edge counts in the bar's footprint: it hit-tests, it sits inside
/// semantics and focus exclusion, and [BottomBarScope.barHeight] includes it.
class BarSurface extends SingleChildRenderObjectWidget {
  const BarSurface({super.key, this.decoration, super.child});

  final BoxDecoration? decoration;

  @override
  RenderBarSurface createRenderObject(BuildContext context) => RenderBarSurface(
    decoration: decoration,
    configuration: createLocalImageConfiguration(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderBarSurface renderObject) {
    renderObject
      ..decoration = decoration
      ..configuration = createLocalImageConfiguration(context);
  }
}

class RenderBarSurface extends RenderShiftedBox {
  RenderBarSurface({this._decoration, required this._configuration})
    : super(null);

  BoxDecoration? _decoration;
  set decoration(BoxDecoration? value) {
    if (value == _decoration) return;
    _decoration = value;
    markNeedsPaint();
  }

  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  RenderCenterActionSlot? _action;
  Decoration? _paintedDecoration;
  BoxPainter? _painter;

  double get _raise {
    final action = _action;
    return action == null || !action._lifted ? 0 : action._raise;
  }

  Rect get _barRect {
    final child = this.child!;
    return (child.parentData! as BoxParentData).offset & child.size;
  }

  /// The bar's current outline, in this box's coordinates once shifted by
  /// the bar's top-left. The notch follows the action as laid out.
  BarOutline get outline {
    final decoration = _decoration;
    final action = _action;
    final button = action?.child;
    Rect? notch;
    if (child != null &&
        action != null &&
        action._lifted &&
        action._notched &&
        button != null &&
        button.hasSize) {
      final rect = MatrixUtils.transformRect(
        button.getTransformTo(this),
        Offset.zero & button.size,
      );
      final diameter =
          math.max(rect.width, rect.height) + 2 * action._notchMargin;
      notch = Rect.fromCircle(
        center: rect.center - _barRect.center,
        radius: diameter / 2,
      );
    }
    return BarOutline(
      borderRadius: decoration?.borderRadius ?? BorderRadius.zero,
      notch: notch,
      border: decoration?.border,
    );
  }

  /// [decoration] drawn through [outline], or as is when the outline cannot
  /// express it.
  Decoration _paintable(BoxDecoration decoration) {
    if (decoration.shape != BoxShape.rectangle ||
        decoration.backgroundBlendMode != null) {
      return decoration;
    }
    return ShapeDecoration(
      color: decoration.gradient == null ? decoration.color : null,
      gradient: decoration.gradient,
      image: decoration.image,
      shadows: decoration.boxShadow,
      shape: outline,
    );
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    _paintedDecoration = null;
    super.detach();
  }

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }

  @override
  void performLayout() {
    final child = this.child;
    var raise = _raise;
    if (child == null) {
      size = constraints.constrain(Size(0, raise));
      return;
    }
    void layoutChild() => child.layout(
      constraints.deflate(EdgeInsets.only(top: raise)),
      parentUsesSize: true,
    );
    layoutChild();
    // A row builds its children during layout, so the action can attach or
    // change style inside the layoutChild call above. Its request to lay
    // this box out again is lost while this box is laying out.
    if (_raise != raise) {
      raise = _raise;
      layoutChild();
    }
    (child.parentData! as BoxParentData).offset = Offset(0, raise);
    size = constraints.constrain(
      Size(child.size.width, child.size.height + raise),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final raise = _raise;
    final childSize =
        child?.getDryLayout(constraints.deflate(EdgeInsets.only(top: raise))) ??
        Size.zero;
    return constraints.constrain(
      Size(childSize.width, childSize.height + raise),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) + _raise;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) + _raise;

  @override
  void paint(PaintingContext context, Offset offset) {
    final decoration = _decoration;
    if (decoration != null && child != null) {
      final paintable = _paintable(decoration);
      if (paintable != _paintedDecoration) {
        _painter?.dispose();
        _painter = paintable.createBoxPainter(markNeedsPaint);
        _paintedDecoration = paintable;
      }
      final bar = _barRect;
      _painter!.paint(
        context.canvas,
        offset + bar.topLeft,
        _configuration.copyWith(size: bar.size),
      );
      if (decoration.isComplex) context.setIsComplexHint();
    }
    super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    // The raised action paints above the bar's own box, where its ancestors
    // up to here would reject the pointer, so test it directly.
    final button = _action?._lifted ?? false ? _action!.child : null;
    if (button != null && button.hasSize) {
      final hit = result.addWithPaintTransform(
        transform: button.getTransformTo(this),
        position: position,
        hitTest: (result, local) =>
            (Offset.zero & button.size).contains(local) &&
            button.hitTest(result, position: local),
      );
      if (hit) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return super.hitTest(result, position: position);
  }
}

/// The centre action's slot in a row. Reserves [width] in the row; when
/// [lifted] inside a [BarSurface], it has no height and paints its child with
/// its top [raise] above the bar's top edge.
class CenterActionSlot extends SingleChildRenderObjectWidget {
  const CenterActionSlot({
    super.key,
    required this.width,
    required this.lifted,
    required this.notched,
    required this.raise,
    required this.notchMargin,
    super.child,
  });

  final double width;
  final bool lifted;
  final bool notched;
  final double raise;
  final double notchMargin;

  @override
  RenderCenterActionSlot createRenderObject(BuildContext context) =>
      RenderCenterActionSlot(
        width: width,
        lifted: lifted,
        notched: notched,
        raise: raise,
        notchMargin: notchMargin,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderCenterActionSlot renderObject,
  ) {
    renderObject
      ..width = width
      ..lifted = lifted
      ..notched = notched
      ..raise = raise
      ..notchMargin = notchMargin;
  }
}

class RenderCenterActionSlot extends RenderShiftedBox {
  RenderCenterActionSlot({
    required this._width,
    required bool lifted,
    required this._notched,
    required this._raise,
    required this._notchMargin,
  }) : _lift = lifted,
       super(null);

  RenderBarSurface? _host;

  double _width;
  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  bool _lift;
  set lifted(bool value) {
    if (value == _lift) return;
    _lift = value;
    markNeedsLayout();
    _host?.markNeedsLayout();
  }

  bool _notched;
  set notched(bool value) {
    if (value == _notched) return;
    _notched = value;
    _host?.markNeedsPaint();
  }

  double _raise;
  set raise(double value) {
    if (value == _raise) return;
    _raise = value;
    _host?.markNeedsLayout();
  }

  double _notchMargin;
  set notchMargin(double value) {
    if (value == _notchMargin) return;
    _notchMargin = value;
    _host?.markNeedsPaint();
  }

  /// Raised or notched only inside a bar; anywhere else it sits inline.
  bool get _lifted => _lift && _host != null;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var ancestor = parent;
    while (ancestor != null && ancestor is! RenderBarSurface) {
      ancestor = ancestor.parent;
    }
    final host = ancestor as RenderBarSurface?;
    if (host != null && host._action == null) {
      _host = host.._action = this;
      host.markNeedsLayout();
    }
  }

  @override
  void detach() {
    final host = _host;
    if (host != null && identical(host._action, this)) {
      host._action = null;
      host.markNeedsLayout();
    }
    _host = null;
    super.detach();
  }

  Offset _inlineOffset = Offset.zero;

  Offset get _childOffset {
    final host = _host;
    if (!_lifted || host == null) return _inlineOffset;
    final top = MatrixUtils.transformPoint(getTransformTo(host), Offset.zero);
    return Offset(_inlineOffset.dx, -top.dy);
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size(_width, 0));
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(math.max(_width, child.size.width), _lifted ? 0 : child.size.height),
    );
    _inlineOffset = Alignment.center.alongOffset(size - child.size as Offset);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childSize =
        child?.getDryLayout(constraints.loosen()) ?? Size(_width, 0);
    return constraints.constrain(
      Size(math.max(_width, childSize.width), _lifted ? 0 : childSize.height),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_width, super.computeMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_width, super.computeMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _lifted ? 0 : super.computeMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _lifted ? 0 : super.computeMaxIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset + _childOffset);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = _childOffset;
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }
}
