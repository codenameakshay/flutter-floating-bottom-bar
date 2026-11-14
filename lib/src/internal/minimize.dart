import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../widgets/bottom_bar_badge.dart';
import '../widgets/bottom_bar_item.dart';
import '../widgets/bottom_bar_items.dart';
import 'bar_surface.dart';
import 'item_theme_scope.dart';

// The full bar fades out over the first part of the morph and the pill fades
// in over the last part, so the two overlap briefly in the middle.
const _fullFade = Interval(0, 0.55, curve: Curves.easeOut);
const _compactFade = Interval(0.45, 1, curve: Curves.easeIn);

/// The full bar's content opacity at morph progress [t].
double fullOpacity(double t) => 1 - _fullFade.transform(t.clamp(0.0, 1.0));

/// The compact pill's opacity at morph progress [t].
double compactOpacity(double t) => _compactFade.transform(t.clamp(0.0, 1.0));

/// The selected [BottomBarItem] of a [BottomBarItems] [child], or null when
/// there is none to show in the default pill.
BottomBarItem? selectedItemOf(Widget child) {
  if (child is! BottomBarItems) return null;
  final index = child.selectedIndex;
  if (index == null || index < 0 || index >= child.children.length) {
    return null;
  }
  final item = child.children[index];
  return item is BottomBarItem ? item : null;
}

/// What a screen reader says for [item], badge included.
String? itemSemanticsLabel(BottomBarItem item) {
  final label = item.label;
  final base =
      item.semanticLabel ??
      item.tooltip ??
      (label is Text ? label.semanticsLabel ?? label.data : null);
  final badge = item.badge;
  final badgeLabel = badge is BottomBarBadge
      ? badgeSemanticsLabel(badge)
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

/// The compact pill as one button that expands the bar.
///
/// With [label] the pill's own semantics replace its child's, so a screen
/// reader hears the selected item once. Without one the child's semantics
/// stay inside the button.
class CompactPillButton extends StatelessWidget {
  const CompactPillButton({
    super.key,
    required this.onTap,
    required this.label,
    required this.child,
  });

  final VoidCallback onTap;
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hint =
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        )?.collapsedIconTapHint ??
        'Expand';
    return Semantics(
      container: true,
      button: true,
      label: label,
      hint: hint,
      onTap: onTap,
      excludeSemantics: label != null,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: child,
      ),
    );
  }
}

/// Holds the full bar content and, while the bar minimizes, the compact pill.
///
/// [progress] runs from 0 (full bar) to 1 (pill). The full content fades out
/// and the pill fades in on it. Only the side [minimized] points to takes
/// pointers, focus and semantics. The pill sits at the leading edge,
/// vertically centred, inset from the leading edge as far as from the top,
/// so it is concentric with a capsule bar's leading end.
///
/// The enclosing [RenderBarSurface] reads [RenderMinimizeHost.compactRect]
/// to shrink its outline onto the pill.
class MinimizeHost extends MultiChildRenderObjectWidget {
  MinimizeHost({
    super.key,
    required this.progress,
    required this.minimized,
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

  @override
  RenderMinimizeHost createRenderObject(BuildContext context) =>
      RenderMinimizeHost(
        progress: progress,
        minimized: minimized,
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
  set minimized(bool value) {
    if (value == _minimized) return;
    _minimized = value;
    markNeedsSemanticsUpdate();
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

  static bool _partial(double opacity) => opacity > 0 && opacity < 1;

  bool _composited = false;
  void _progressChanged() {
    markNeedsPaint();
    _host?.markNeedsPaint();
    if (alwaysNeedsCompositing == _composited) return;
    _composited = alwaysNeedsCompositing;
    markNeedsCompositingBitsUpdate();
  }

  @override
  bool get alwaysNeedsCompositing =>
      _partial(_fullOpacity) || _partial(_compactOpacity);

  final _fullLayer = LayerHandle<OpacityLayer>();
  final _compactLayer = LayerHandle<OpacityLayer>();

  /// The pill's rect in [ancestor]'s coordinates, or null without a pill.
  Rect? compactRectIn(RenderObject ancestor) {
    final compact = _compact;
    if (compact == null || !compact.hasSize || !attached) return null;
    return MatrixUtils.transformRect(
      compact.getTransformTo(ancestor),
      Offset.zero & compact.size,
    );
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
    _fullLayer.layer = null;
    _compactLayer.layer = null;
    super.detach();
  }

  @override
  void dispose() {
    _fullLayer.layer = null;
    _compactLayer.layer = null;
    super.dispose();
  }

  @override
  void performLayout() {
    final full = _full;
    if (full == null) {
      size = constraints.smallest;
      return;
    }
    full.layout(constraints, parentUsesSize: true);
    size = full.size;
    final compact = _compact;
    if (compact == null) return;
    compact.layout(BoxConstraints.loose(size), parentUsesSize: true);
    final inset = math.max(0.0, (size.height - compact.size.height) / 2);
    (compact.parentData! as _MinimizeParentData).offset = Offset(
      _textDirection == TextDirection.ltr
          ? inset
          : size.width - inset - compact.size.width,
      inset,
    );
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
      LayerHandle<OpacityLayer> handle,
    ) {
      if (child == null || opacity == 0) {
        handle.layer = null;
        return;
      }
      final at = (child.parentData! as _MinimizeParentData).offset;
      if (opacity == 1) {
        handle.layer = null;
        context.paintChild(child, offset + at);
        return;
      }
      handle.layer = context.pushOpacity(
        offset,
        (opacity * 255).round(),
        (context, offset) => context.paintChild(child, offset + at),
        oldLayer: handle.layer,
      );
    }

    paintFaded(_full, _fullOpacity, _fullLayer);
    paintFaded(_compact, _compactOpacity, _compactLayer);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = _minimized ? _compact : _full;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: (child.parentData! as _MinimizeParentData).offset,
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
