import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bar_surface.dart';

/// Lays the bar's pieces out in one row: an optional leading piece, the pill,
/// and an optional trailing piece, in reading order.
///
/// The row is as wide as its incoming max width. Each side piece is exactly
/// as tall as the pill's bar and at least as wide as it is tall, and the pill
/// takes the width left over after the pieces and [spacing]. The pieces never
/// shrink: when they leave no room, the pill gets zero width and the row
/// overflows at its end. Every piece sits on the pill's bottom edge, so a
/// raised centre action rises above all of them.
///
/// The gaps paint nothing and hit-test nothing, so taps in them reach the
/// content under the bar.
class BarGroup extends MultiChildRenderObjectWidget {
  const BarGroup({
    super.key,
    required this.pillIndex,
    required this.spacing,
    required super.children,
  });

  /// Index of the pill in [children]. Every other child is a side piece.
  final int pillIndex;

  final double spacing;

  @override
  RenderBarGroup createRenderObject(BuildContext context) => RenderBarGroup(
    pillIndex: pillIndex,
    spacing: spacing,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderBarGroup renderObject) {
    renderObject
      ..pillIndex = pillIndex
      ..spacing = spacing
      ..textDirection = Directionality.of(context);
  }
}

class RenderBarGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupParentData> {
  RenderBarGroup({
    required this._pillIndex,
    required this._spacing,
    required this._textDirection,
  });

  int _pillIndex;
  set pillIndex(int value) {
    if (value == _pillIndex) return;
    _pillIndex = value;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The side pieces' total width at the last layout. The pill is laid out
  /// against it first, so a stable row lays the pill out once.
  double _piecesWidth = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupParentData) {
      child.parentData = _GroupParentData();
    }
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    if (children.isEmpty) {
      size = constraints.smallest;
      return;
    }
    final pill = children[_pillIndex];
    if (children.length == 1) {
      pill.layout(constraints, parentUsesSize: true);
      size = pill.size;
      (pill.parentData! as _GroupParentData).offset = Offset.zero;
      return;
    }
    final pieces = [...children]..removeAt(_pillIndex);
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : getMaxIntrinsicWidth(constraints.maxHeight);
    final gaps = _spacing * pieces.length;

    void layoutPill() {
      final pillWidth = math.max(0.0, width - gaps - _piecesWidth);
      pill.layout(
        BoxConstraints(
          minWidth: pillWidth,
          maxWidth: pillWidth,
          maxHeight: constraints.maxHeight,
        ),
        parentUsesSize: true,
      );
    }

    layoutPill();
    // ponytail: assumes the pill's height does not depend on its width, true
    // for item rows and tab bars; lay the pieces out again if one ever does.
    final barHeight = pill is RenderBarSurface
        ? pill.barHeight
        : pill.size.height;
    var piecesWidth = 0.0;
    for (final piece in pieces) {
      piece.layout(
        BoxConstraints(
          minWidth: barHeight,
          maxWidth: math.max(barHeight, width),
          minHeight: barHeight,
          maxHeight: barHeight,
        ),
        parentUsesSize: true,
      );
      piecesWidth += piece.size.width;
    }
    if (piecesWidth != _piecesWidth) {
      _piecesWidth = piecesWidth;
      layoutPill();
    }

    final height = math.max(pill.size.height, barHeight);
    final rowWidth = piecesWidth + gaps + pill.size.width;
    size = constraints.constrain(Size(rowWidth, height));
    var x = 0.0;
    for (final child in children) {
      final w = child.size.width;
      (child.parentData! as _GroupParentData).offset = Offset(
        _textDirection == TextDirection.ltr ? x : size.width - x - w,
        height - child.size.height,
      );
      x += w + _spacing;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final children = getChildrenAsList();
    if (children.isEmpty) return constraints.smallest;
    final pill = children[_pillIndex];
    if (children.length == 1) return pill.getDryLayout(constraints);
    final pieces = [...children]..removeAt(_pillIndex);
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : getMaxIntrinsicWidth(constraints.maxHeight);
    final gaps = _spacing * pieces.length;
    BoxConstraints pillConstraints(double piecesWidth) => BoxConstraints(
      minWidth: math.max(0, width - gaps - piecesWidth),
      maxWidth: math.max(0, width - gaps - piecesWidth),
      maxHeight: constraints.maxHeight,
    );
    var pillSize = pill.getDryLayout(pillConstraints(0));
    final barHeight = math.max(
      0.0,
      pillSize.height - (pill is RenderBarSurface ? pill.layoutRaise : 0),
    );
    var piecesWidth = 0.0;
    for (final piece in pieces) {
      piecesWidth += piece
          .getDryLayout(
            BoxConstraints(
              minWidth: barHeight,
              maxWidth: math.max(barHeight, width),
              minHeight: barHeight,
              maxHeight: barHeight,
            ),
          )
          .width;
    }
    pillSize = pill.getDryLayout(pillConstraints(piecesWidth));
    return constraints.constrain(
      Size(
        piecesWidth + gaps + pillSize.width,
        math.max(pillSize.height, barHeight),
      ),
    );
  }

  double _intrinsicWidth(double height, {required bool minimum}) {
    final children = getChildrenAsList();
    if (children.isEmpty) return 0;
    final pill = children[_pillIndex];
    double widthOf(RenderBox child, double height) => minimum
        ? child.getMinIntrinsicWidth(height)
        : child.getMaxIntrinsicWidth(height);
    final pillWidth = widthOf(pill, height);
    if (children.length == 1) return pillWidth;
    final barHeight =
        (minimum
            ? pill.getMinIntrinsicHeight(pillWidth)
            : pill.getMaxIntrinsicHeight(pillWidth)) -
        (pill is RenderBarSurface ? pill.layoutRaise : 0);
    return pillWidth +
        _spacing * (children.length - 1) +
        children
            .where((child) => child != pill)
            .fold<double>(
              0,
              (width, child) =>
                  width + math.max(barHeight, widthOf(child, barHeight)),
            );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _intrinsicWidth(height, minimum: true);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _intrinsicWidth(height, minimum: false);

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

class _GroupParentData extends ContainerBoxParentData<RenderBox> {}
