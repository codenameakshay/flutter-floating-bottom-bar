import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bar_surface.dart';

/// Lays the bar's pieces out in one row: an optional leading piece, the pill,
/// and an optional trailing piece, in reading order. With [hasAccessory] the
/// last child is the accessory, laid out above the row or beside the
/// minimized pill.
///
/// The row is as wide as its incoming max width. Each side piece is exactly
/// as tall as the pill's bar and at least as wide as it is tall, and the pill
/// takes the width left over after the pieces and [spacing]. The pieces never
/// shrink: when they leave no room, the pill gets zero width and the row
/// overflows at its end. Every piece sits on the pill's bottom edge, so a
/// raised centre action rises above all of them.
///
/// The accessory is as wide as the pill, less [accessoryInset], takes its
/// own height, and sits [spacing] above the row's top, a raised centre
/// action's top included. As [minimize] runs to 1 it moves onto the
/// minimized pill's row, between the pill and the trailing piece, as tall as
/// the pill, in the width left free. The row keeps its place and the group
/// keeps its height throughout, so the bar's footprint never changes.
///
/// The gaps paint nothing and hit-test nothing, so taps in them reach the
/// content under the bar.
class BarGroup extends MultiChildRenderObjectWidget {
  const BarGroup({
    super.key,
    required this.pillIndex,
    required this.spacing,
    this.hasAccessory = false,
    this.accessoryInset = EdgeInsets.zero,
    this.minimize,
    required super.children,
  });

  /// Index of the pill in [children]. Every other child is a side piece,
  /// except the last one with [hasAccessory].
  final int pillIndex;

  final double spacing;

  /// Whether the last child is the accessory.
  final bool hasAccessory;

  /// How far the accessory keeps from the pill's sides, and from the
  /// group's sides while inline.
  final EdgeInsets accessoryInset;

  /// How far the pill has minimized, from 0 (full) to 1 (pill).
  final Animation<double>? minimize;

  @override
  RenderBarGroup createRenderObject(BuildContext context) => RenderBarGroup(
    pillIndex: pillIndex,
    spacing: spacing,
    textDirection: Directionality.of(context),
    hasAccessory: hasAccessory,
    accessoryInset: accessoryInset,
    minimize: minimize,
  );

  @override
  void updateRenderObject(BuildContext context, RenderBarGroup renderObject) {
    renderObject
      ..pillIndex = pillIndex
      ..spacing = spacing
      ..textDirection = Directionality.of(context)
      ..hasAccessory = hasAccessory
      ..accessoryInset = accessoryInset
      ..minimize = minimize;
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
    this._hasAccessory = false,
    this._accessoryInset = EdgeInsets.zero,
    this._minimize,
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

  bool _hasAccessory;
  set hasAccessory(bool value) {
    if (value == _hasAccessory) return;
    _hasAccessory = value;
    _accessoryHeight = null;
    markNeedsLayout();
  }

  EdgeInsets _accessoryInset;
  set accessoryInset(EdgeInsets value) {
    if (value == _accessoryInset) return;
    _accessoryInset = value;
    markNeedsLayout();
  }

  Animation<double>? _minimize;
  set minimize(Animation<double>? value) {
    if (identical(value, _minimize)) return;
    if (attached) _minimize?.removeListener(_minimizeChanged);
    _minimize = value;
    if (attached) value?.addListener(_minimizeChanged);
    _minimizeChanged();
  }

  void _minimizeChanged() {
    if (_hasAccessory) markNeedsLayout();
  }

  double get _t => (_minimize?.value ?? 0).clamp(0.0, 1.0);

  /// The accessory's height above the bar, kept while it is inline so the
  /// group's height holds still.
  double? _accessoryHeight;

  /// The side pieces' total width at the last layout. The pill is laid out
  /// against it first, so a stable row lays the pill out once.
  double _piecesWidth = 0;

  RenderBox? get _accessory =>
      _hasAccessory && childCount > 1 ? lastChild : null;

  List<RenderBox> get _row {
    final children = getChildrenAsList();
    if (_accessory != null) children.removeLast();
    return children;
  }

  /// The top of the highest side piece, or null without one. The accessory
  /// does not count.
  double? get piecesTop {
    final row = _row;
    if (row.length < 2) return null;
    return [
      for (final (i, child) in row.indexed)
        if (i != _pillIndex) (child.parentData! as _GroupParentData).offset.dy,
    ].reduce(math.min);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _minimize?.addListener(_minimizeChanged);
  }

  @override
  void detach() {
    _minimize?.removeListener(_minimizeChanged);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupParentData) {
      child.parentData = _GroupParentData();
    }
  }

  @override
  void performLayout() {
    final row = _row;
    if (row.isEmpty) {
      size = constraints.smallest;
      return;
    }
    final pill = row[_pillIndex];
    final rowSize = _layoutRow(row, pill);
    final accessory = _accessory;
    if (accessory == null) {
      size = constraints.constrain(rowSize);
      _placeRow(row, 0, rowSize.height);
      return;
    }

    final rowWidth = rowSize.width;
    final inset = _accessoryInset;
    final expandedWidth = math.max(0.0, pill.size.width - inset.horizontal);
    BoxConstraints expanded() => BoxConstraints(
      minWidth: expandedWidth,
      maxWidth: expandedWidth,
      maxHeight: math.max(
        0.0,
        constraints.maxHeight - rowSize.height - _spacing,
      ),
    );
    final t = _t;
    if (t == 0 || _accessoryHeight == null) {
      accessory.layout(expanded(), parentUsesSize: true);
      _accessoryHeight = accessory.size.height;
    }
    final band = _accessoryHeight! + _spacing;
    size = constraints.constrain(Size(rowWidth, band + rowSize.height));
    _placeRow(row, band, rowSize.height);

    final pillOffset = (pill.parentData! as _GroupParentData).offset;
    final expandedRect = Rect.fromLTWH(
      pillOffset.dx + inset.left,
      0,
      expandedWidth,
      _accessoryHeight!,
    );
    final inline = t == 0 ? null : _inlineRect(row, pill);
    final rect = inline == null
        ? expandedRect
        : Rect.lerp(expandedRect, inline, t)!;
    if (inline != null) {
      accessory.layout(BoxConstraints.tight(rect.size), parentUsesSize: true);
    }
    (accessory.parentData! as _GroupParentData).offset = rect.topLeft;
  }

  /// Where the accessory sits beside the minimized pill, or null without a
  /// pill to sit beside.
  Rect? _inlineRect(List<RenderBox> row, RenderBox pill) {
    final host = pill is RenderBarSurface ? pill.minimizeHost : null;
    final compact = host?.compactRectIn(this);
    if (compact == null) return null;
    final trailing = _pillIndex + 1 < row.length ? row[_pillIndex + 1] : null;
    final trailingRect = trailing == null
        ? null
        : (trailing.parentData! as _GroupParentData).offset & trailing.size;
    final double start;
    final double end;
    if (_textDirection == TextDirection.ltr) {
      start = compact.right + _spacing;
      end = trailingRect == null
          ? size.width - _accessoryInset.right
          : trailingRect.left - _spacing;
    } else {
      start = trailingRect == null
          ? _accessoryInset.left
          : trailingRect.right + _spacing;
      end = compact.left - _spacing;
    }
    return Rect.fromLTWH(
      start,
      compact.top,
      math.max(0.0, end - start),
      compact.height,
    );
  }

  /// Lays out the pill and the side pieces and returns the row's size.
  Size _layoutRow(List<RenderBox> row, RenderBox pill) {
    if (row.length == 1) {
      pill.layout(constraints, parentUsesSize: true);
      return pill.size;
    }
    final pieces = [...row]..removeAt(_pillIndex);
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

    double barHeightOf(RenderBox pill) =>
        pill is RenderBarSurface ? pill.barHeight : pill.size.height;
    double layoutPieces(double barHeight) {
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
      return piecesWidth;
    }

    layoutPill();
    var barHeight = barHeightOf(pill);
    var piecesWidth = layoutPieces(barHeight);
    if (piecesWidth != _piecesWidth) {
      _piecesWidth = piecesWidth;
      layoutPill();
      // ponytail: a pill whose height follows its width resizes the pieces
      // once more; pieces that then change width overflow or leave a gap.
      if (barHeightOf(pill) != barHeight) {
        barHeight = barHeightOf(pill);
        piecesWidth = layoutPieces(barHeight);
      }
    }

    return Size(
      piecesWidth + gaps + pill.size.width,
      math.max(pill.size.height, barHeight),
    );
  }

  /// Puts the row's children on its bottom edge, [top] below the group's
  /// top, in reading order.
  void _placeRow(List<RenderBox> row, double top, double height) {
    var x = 0.0;
    for (final child in row) {
      final w = child.size.width;
      (child.parentData! as _GroupParentData).offset = Offset(
        _textDirection == TextDirection.ltr ? x : size.width - x - w,
        top + height - child.size.height,
      );
      x += w + _spacing;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final row = _row;
    if (row.isEmpty) return constraints.smallest;
    final (rowSize, pillWidth) = _dryRow(row, constraints);
    final accessory = _accessory;
    if (accessory == null) return rowSize;
    final width = math.max(0.0, pillWidth - _accessoryInset.horizontal);
    final height = _t > 0 && _accessoryHeight != null
        ? _accessoryHeight!
        : accessory
              .getDryLayout(
                BoxConstraints(
                  minWidth: width,
                  maxWidth: width,
                  maxHeight: math.max(
                    0.0,
                    constraints.maxHeight - rowSize.height - _spacing,
                  ),
                ),
              )
              .height;
    return constraints.constrain(
      Size(rowSize.width, rowSize.height + height + _spacing),
    );
  }

  /// The row's dry size and the pill's width in it.
  (Size, double) _dryRow(List<RenderBox> children, BoxConstraints constraints) {
    final pill = children[_pillIndex];
    if (children.length == 1) {
      final size = pill.getDryLayout(constraints);
      return (size, size.width);
    }
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
    final size = constraints.constrain(
      Size(
        piecesWidth + gaps + pillSize.width,
        math.max(pillSize.height, barHeight),
      ),
    );
    return (size, pillSize.width);
  }

  double _intrinsicWidth(double height, {required bool minimum}) {
    final children = _row;
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
