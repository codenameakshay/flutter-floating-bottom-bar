import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../bottom_bar_localizations.dart';
import '../widgets/bottom_bar_badge.dart';
import '../widgets/bottom_bar_item.dart';
import '../widgets/bottom_bar_items.dart';
import 'bar_surface.dart';
import 'focus_ring.dart';
import 'item_theme_scope.dart';

// The full bar holds on while it shrinks and the pill comes in early, so the
// glass always shows one of them while they cross.
const _fullFade = Interval(0, 0.6, curve: Curves.easeIn);
const _compactFade = Interval(0.3, 0.85, curve: Curves.easeOut);

/// The pill grows to its size from this scale as it fades in.
const _compactStartScale = 0.8;

/// The full bar's content opacity at morph progress [t].
double fullOpacity(double t) => 1 - _fullFade.transform(t.clamp(0.0, 1.0));

/// The compact pill's opacity at morph progress [t].
double compactOpacity(double t) => _compactFade.transform(t.clamp(0.0, 1.0));

/// The selected [BottomBarItem] of a [BottomBarItems] [child], or null when
/// there is none to show in the default pill. The pill mounts the item's icon
/// and badge a second time, which a [GlobalKey] forbids.
BottomBarItem? selectedItemOf(Widget child) {
  if (child is! BottomBarItems) return null;
  final index = child.selectedIndex;
  if (index == null || index < 0 || index >= child.children.length) {
    return null;
  }
  final item = child.children[index];
  if (item is! BottomBarItem) return null;
  final parts = [item.icon, item.selectedIcon, item.badge];
  return parts.any((part) => part?.key is GlobalKey) ? null : item;
}

/// What a screen reader says for [item], badge included.
String? itemSemanticsLabel(BottomBarItem item, BottomBarLocalizations strings) {
  final label = item.label;
  final base =
      item.semanticLabel ??
      item.tooltip ??
      (label is Text
          ? label.semanticsLabel ?? label.data ?? label.textSpan?.toPlainText()
          : null);
  final badge = item.badge;
  final badgeLabel = badge is BottomBarBadge
      ? badgeSemanticsLabel(badge, strings)
      : null;
  if (base == null || badgeLabel == null) return base ?? badgeLabel;
  return '$base, $badgeLabel';
}

/// The selected item's icon and badge, as the default compact pill shows it.
class DefaultCompactPill extends StatelessWidget {
  const DefaultCompactPill({super.key, required this.item});

  final BottomBarItem item;

  @override
  Widget build(BuildContext context) {
    final theme = itemThemeOf(context);
    final badge = item.badge;
    return SizedBox.square(
      dimension: 48,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconTheme.merge(
              data: IconThemeData(
                color:
                    item.selectedColor ??
                    theme.selectedColor ??
                    Theme.of(context).colorScheme.primary,
                size: theme.selectedIconSize ?? theme.iconSize,
              ),
              child: item.selectedIcon ?? item.icon,
            ),
            if (badge is BottomBarBadge)
              Positioned.fill(child: badge)
            else if (badge != null)
              PositionedDirectional(top: -4, end: -4, child: badge),
          ],
        ),
      ),
    );
  }
}

/// The compact pill as one collapsed button that expands the bar.
///
/// With [label] the pill's own semantics replace its child's, so a screen
/// reader hears the selected item once. Without one the child's labels merge
/// into the button and its own actions are dropped, so the pill reads as one
/// button, like "Midnight City, button, Expand".
class CompactPillButton extends StatelessWidget {
  const CompactPillButton({
    super.key,
    required this.onTap,
    required this.label,
    required this.child,
    this.focusNode,
  });

  final VoidCallback onTap;
  final String? label;
  final Widget child;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final hint =
        (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ??
                const DefaultMaterialLocalizations())
            .collapsedIconTapHint;
    return MergeSemantics(
      child: Semantics(
        button: true,
        expanded: false,
        label: label,
        hint: hint,
        onTap: onTap,
        excludeSemantics: label != null,
        child: Semantics(
          blockUserActions: true,
          child: FocusRing(
            shape: const StadiumBorder(),
            child: InkWell(
              focusNode: focusNode,
              onTap: onTap,
              customBorder: const StadiumBorder(),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Holds the full bar content and, while the bar minimizes, the compact pill.
///
/// [progress] runs from 0 (full bar) to 1 (pill). The full content shrinks
/// with the outline toward the pill and fades out, and the pill grows in. Only
/// the side [minimized] points to takes pointers, focus and semantics. The
/// pill sits at the leading edge, vertically centred, inset from the leading
/// edge as far as from the top, so it is concentric with a capsule bar's
/// leading end. With [flushStart] it sits on the leading edge instead, so a
/// leading piece before the bar keeps the group's spacing to it.
///
/// The enclosing [RenderBarSurface] reads [RenderMinimizeHost.compactRect]
/// to shrink its outline onto the pill.
class MinimizeHost extends MultiChildRenderObjectWidget {
  MinimizeHost({
    super.key,
    required this.progress,
    required this.minimized,
    this.flushStart = false,
    required Widget full,
    Widget? compact,
  }) : super(
         children: [
           ExcludeFocus(excluding: minimized, child: full),
           if (compact != null)
             ExcludeFocus(excluding: !minimized, child: compact),
         ],
       );

  final Animation<double> progress;
  final bool minimized;
  final bool flushStart;

  @override
  RenderMinimizeHost createRenderObject(BuildContext context) =>
      RenderMinimizeHost(
        progress: progress,
        minimized: minimized,
        flushStart: flushStart,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMinimizeHost renderObject,
  ) {
    renderObject
      ..progress = progress
      ..minimized = minimized
      ..flushStart = flushStart
      ..textDirection = Directionality.of(context);
  }
}

class _MinimizeParentData extends ContainerBoxParentData<RenderBox> {}

class RenderMinimizeHost extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MinimizeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MinimizeParentData> {
  RenderMinimizeHost({
    required this._progress,
    required this._minimized,
    this._flushStart = false,
    required this._textDirection,
  });

  Animation<double> _progress;
  set progress(Animation<double> value) {
    if (identical(value, _progress)) return;
    if (attached) _progress.removeListener(_progressChanged);
    _progress = value;
    if (attached) value.addListener(_progressChanged);
    _progressChanged();
  }

  bool _minimized;
  bool get minimized => _minimized;

  set minimized(bool value) {
    if (value == _minimized) return;
    _minimized = value;
    markNeedsSemanticsUpdate();
  }

  bool _flushStart;
  set flushStart(bool value) {
    if (value == _flushStart) return;
    _flushStart = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBarSurface? _host;

  RenderBox? get _full => firstChild;
  RenderBox? get _compact => _full == null ? null : childAfter(_full!);

  double get _t => _progress.value.clamp(0.0, 1.0);
  double get _fullOpacity => fullOpacity(_t);
  double get _compactOpacity => _compact == null ? 0 : compactOpacity(_t);

  static Offset _offsetOf(RenderBox child) =>
      (child.parentData! as _MinimizeParentData).offset;

  /// Where [child] paints: the full content scaled into the outline as it
  /// shrinks onto the pill, the pill growing in about its centre.
  Matrix4 _transformOf(RenderBox child) {
    final at = _offsetOf(child);
    final t = _t;
    final compact = _compact;
    if (t == 0 || compact == null) {
      return Matrix4.translationValues(at.dx, at.dy, 0);
    }
    final Rect from;
    final Rect to;
    final double scale;
    final pill = _offsetOf(compact) & compact.size;
    if (identical(child, compact)) {
      from = to = pill;
      scale = _compactStartScale + (1 - _compactStartScale) * t;
    } else {
      from = at & child.size;
      to = Rect.lerp(Offset.zero & size, pill, t)!;
      scale = math.min(
        1.0,
        math.min(
          from.width == 0 ? 1.0 : to.width / from.width,
          from.height == 0 ? 1.0 : to.height / from.height,
        ),
      );
    }
    return Matrix4.translationValues(to.center.dx, to.center.dy, 0)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(
        from.left - from.center.dx,
        from.top - from.center.dy,
        0,
        1,
      );
  }

  static bool _partial(double opacity) => opacity > 0 && opacity < 1;

  bool _composited = false;
  void _progressChanged() {
    markNeedsPaint();
    _host?.markNeedsPaint();
    markNeedsSemanticsUpdate();
    if (alwaysNeedsCompositing == _composited) return;
    _composited = alwaysNeedsCompositing;
    markNeedsCompositingBitsUpdate();
  }

  @override
  bool get alwaysNeedsCompositing =>
      _partial(_fullOpacity) || _partial(_compactOpacity);

  final _fullLayer = LayerHandle<OpacityLayer>();
  final _compactLayer = LayerHandle<OpacityLayer>();
  final _fullTransformLayer = LayerHandle<TransformLayer>();
  final _compactTransformLayer = LayerHandle<TransformLayer>();

  /// The pill's resting rect in [ancestor]'s coordinates, or null without a
  /// pill. Its grow-in scale does not count.
  Rect? compactRectIn(RenderObject ancestor) {
    final rest = _compactRest;
    if (rest == null || _compact == null || !attached) return null;
    return MatrixUtils.transformRect(getTransformTo(ancestor), rest);
  }

  /// The pill's resting rect at the last layout, so an ancestor can read it
  /// during its own layout.
  Rect? _compactRest;

  void _dropLayers() {
    _fullLayer.layer = null;
    _compactLayer.layer = null;
    _fullTransformLayer.layer = null;
    _compactTransformLayer.layer = null;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MinimizeParentData) {
      child.parentData = _MinimizeParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(_progressChanged);
    var ancestor = parent;
    while (ancestor != null && ancestor is! RenderBarSurface) {
      ancestor = ancestor.parent;
    }
    _host = ancestor as RenderBarSurface?;
    _host?.minimizeHost = this;
  }

  @override
  void detach() {
    _progress.removeListener(_progressChanged);
    if (identical(_host?.minimizeHost, this)) _host?.minimizeHost = null;
    _host = null;
    _dropLayers();
    super.detach();
  }

  @override
  void dispose() {
    _dropLayers();
    super.dispose();
  }

  @override
  void performLayout() {
    final full = _full;
    if (full == null) {
      _compactRest = null;
      size = constraints.smallest;
      return;
    }
    full.layout(constraints, parentUsesSize: true);
    size = full.size;
    final compact = _compact;
    _compactRest = null;
    if (compact == null) return;
    compact.layout(BoxConstraints.loose(size), parentUsesSize: true);
    final inset = math.max(0.0, (size.height - compact.size.height) / 2);
    final start = _flushStart ? 0.0 : inset;
    final offset = Offset(
      _textDirection == TextDirection.ltr
          ? start
          : size.width - start - compact.size.width,
      inset,
    );
    (compact.parentData! as _MinimizeParentData).offset = offset;
    _compactRest = offset & compact.size;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _full?.getDryLayout(constraints) ?? constraints.smallest;

  @override
  double computeMinIntrinsicWidth(double height) =>
      _full?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _full?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _full?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _full?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      _full?.getDistanceToActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) {
    void paintFaded(
      RenderBox? child,
      double opacity,
      LayerHandle<OpacityLayer> opacityHandle,
      LayerHandle<TransformLayer> transformHandle,
    ) {
      if (child == null || opacity == 0) {
        opacityHandle.layer = null;
        transformHandle.layer = null;
        return;
      }
      void paintChild(PaintingContext context, Offset offset) {
        transformHandle.layer = context.pushTransform(
          needsCompositing,
          offset,
          _transformOf(child),
          (context, offset) => context.paintChild(child, offset),
          oldLayer: transformHandle.layer,
        );
      }

      if (opacity == 1) {
        opacityHandle.layer = null;
        paintChild(context, offset);
        return;
      }
      opacityHandle.layer = context.pushOpacity(
        offset,
        (opacity * 255).round(),
        paintChild,
        oldLayer: opacityHandle.layer,
      );
    }

    paintFaded(_full, _fullOpacity, _fullLayer, _fullTransformLayer);
    paintFaded(
      _compact,
      _compactOpacity,
      _compactLayer,
      _compactTransformLayer,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transformOf(child));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = _minimized ? _compact : _full;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transformOf(child),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final child = _minimized ? _compact : _full;
    if (child != null) visitor(child);
  }
}
