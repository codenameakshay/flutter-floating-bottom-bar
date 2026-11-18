import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart' show Theme;
import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../bottom_bar.dart';
import '../bottom_bar_theme.dart';
import '../config/bottom_bar_motion.dart';
import '../internal/item_theme_scope.dart';
import '../internal/minimize.dart' show RenderMinimizeHost;
import '../internal/reduce_motion.dart';

/// Swaps a [BottomBar]'s content with a morph of the bar itself.
///
/// Use it as [BottomBar.child]. It shows one [child] at a time. When the
/// child changes to one with a different key or type, as with
/// [AnimatedSwitcher], the bar springs from the old child's size to the new
/// one's, and the two children cross-fade inside it:
///
/// ```dart
/// BottomBar(
///   child: BottomBarSwitcher(
///     child: switch (mode) {
///       Mode.nav => BottomBarItems(key: const ValueKey('nav'), ...),
///       Mode.selection => SelectionActions(key: const ValueKey('actions')),
///       Mode.compose => Composer(key: const ValueKey('composer')),
///     },
///   ),
///   body: ...,
/// )
/// ```
///
/// The bar draws its fill, glass, shadows and notch from its child's size
/// on every frame, so they all follow the morph. The corners keep the bar's
/// radius rule as the height changes: a 28 pixel radius stays 28 pixels, and
/// a capsule (a radius of at least half the height) stays a capsule.
///
/// ## Size
///
/// The height always morphs. Inside a [BottomBar] the width does not: the bar
/// gives its child its resolved width ([BottomBarLayout.width], clamped by
/// [BottomBarLayout.maxWidth] and the host). Outside a bar, or anywhere the
/// incoming constraints leave the width loose, the width morphs as well.
///
/// The size springs on [motion]. A switch mid-flight retargets from the
/// current size and velocity, so it never jumps. A child that changes size
/// on its own, like a composer whose text field grows a line, morphs the same
/// way. With reduced motion the size snaps and the children swap at once.
///
/// [BottomBarScope.barHeight] reports the bar's footprint after every frame
/// of the morph, so [BottomBarBodyPadding] pads the body by the live height,
/// one frame behind. A list scrolled away from its end does not move. A list
/// scrolled to its end, or content pinned to the bottom of the body, moves
/// with the bar's top edge.
///
/// ## Children
///
/// The old child fades out and scales toward the new size while the new one
/// fades in and grows into place. They overlap in the middle of the morph, so
/// the bar is never empty. From the first frame of a switch only the new
/// child takes pointers, focus and semantics.
///
/// When focus was inside the old child, it moves into the new child once the
/// switch is built: to wherever the app puts it (a text field with
/// `autofocus`, or a node the app focuses), or else to the new child's first
/// focusable widget.
///
/// ## State
///
/// A child that leaves is disposed when its fade ends, like in
/// [AnimatedSwitcher]. A child that comes back before then keeps its state.
/// To keep a child's state while it is away, give it a [GlobalKey]: the
/// switcher then keeps it mounted, out of sight and with its tickers off,
/// until the same key comes back. A [BottomBarItems] row keeps its selection
/// in the app, so it needs no [GlobalKey] to come back on the right item.
///
/// ## Minimize
///
/// While the bar is minimized its full content is out of sight, so a switch
/// lands at once, with no morph. The bar shows the new child when it expands.
/// The default pill shows the selected item of a [BottomBarItems] child only,
/// so give [BottomBar.compactChild] when the bar's child is a switcher.
class BottomBarSwitcher extends StatefulWidget {
  /// Creates a [BottomBarSwitcher].
  const BottomBarSwitcher({
    super.key,
    required this.child,
    this.motion,
    this.alignment = Alignment.center,
  });

  /// The content the bar shows. A child with a new key or type starts a
  /// morph. A child that [Widget.canUpdate] the current one updates in
  /// place.
  final Widget child;

  /// The spring that drives the size and the cross-fade.
  ///
  /// Defaults to the enclosing [BottomBar]'s motion ([BottomBar.motion], then
  /// [BottomBarThemeData.motion], then [BottomBarMotion]'s default). Outside
  /// a bar it falls back to [BottomBarItemThemeData.indicatorMotion], then to
  /// a snappy Cupertino spring.
  final Motion? motion;

  /// Where the children sit inside the bar while its size morphs, and the
  /// point they scale around. Defaults to the centre.
  final AlignmentGeometry alignment;

  @override
  State<BottomBarSwitcher> createState() => _BottomBarSwitcherState();
}

class _Entry {
  _Entry(this.widget, this.presence);

  Widget widget;

  /// 0 when out of the bar, 1 when in. Springs may overshoot.
  final MotionController<double> presence;

  final FocusNode focusNode = FocusNode(
    debugLabel: 'BottomBarSwitcher child',
    canRequestFocus: false,
    skipTraversal: true,
  );

  /// Kept mounted out of sight after leaving, for its [GlobalKey].
  bool parked = false;

  bool get keepsState => widget.key is GlobalKey;

  void dispose() {
    presence.dispose();
    focusNode.dispose();
  }
}

class _SwitcherFocusScope extends FocusScopeNode {
  _SwitcherFocusScope()
    : super(
        debugLabel: 'BottomBarSwitcher',
        traversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
        directionalTraversalEdgeBehavior: TraversalEdgeBehavior.parentScope,
      );

  @override
  void autofocus(FocusNode node) {
    if (hasFocus || enclosingScope?.focusedChild == null) super.autofocus(node);
  }
}

class _BottomBarSwitcherState extends State<BottomBarSwitcher>
    with TickerProviderStateMixin {
  static const _fallbackMotion = CupertinoMotion.snappy();

  final List<_Entry> _entries = [];
  final _focusScope = _SwitcherFocusScope();
  late Motion _motion;
  Listenable _presences = const _NoListenable();
  bool _switching = false;

  _Entry get _current => _entries.last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    if (_entries.isEmpty) {
      _entries.add(_createEntry(widget.child, present: true));
      _presences = Listenable.merge([for (final e in _entries) e.presence]);
    }
  }

  @override
  void didUpdateWidget(BottomBarSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    final current = _current;
    if (Widget.canUpdate(current.widget, widget.child)) {
      current.widget = widget.child;
      return;
    }
    _switchTo(widget.child, from: current);
  }

  void _syncMotion() {
    final motion = widget.motion ?? _inheritedMotion();
    if (_entries.isNotEmpty && motion == _motion) return;
    _motion = motion;
    for (final entry in _entries) {
      entry.presence.motion = motion;
    }
  }

  Motion _inheritedMotion() {
    final bar = context.findAncestorWidgetOfExactType<BottomBar>();
    if (bar != null) {
      final barMotion =
          bar.motion ??
          bar.theme?.motion ??
          Theme.of(context).extension<BottomBarThemeData>()?.motion ??
          const BottomBarMotion();
      return barMotion.resolveMotion();
    }
    return itemThemeOf(context).indicatorMotion ?? _fallbackMotion;
  }

  bool get _prefersReducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) == true ||
      reduceMotion(context);

  /// Whether a switch should land without a morph: reduced motion, or a
  /// minimized bar whose full content is out of sight.
  bool get _snaps {
    final box = context.findRenderObject();
    return _prefersReducedMotion ||
        (box is RenderBottomBarSwitcher && box.hiddenByMinimize);
  }

  _Entry _createEntry(Widget child, {required bool present}) {
    final entry = _Entry(
      child,
      MotionController<double>(
        motion: _motion,
        vsync: this,
        converter: MotionConverter.single,
        initialValue: present ? 1 : 0,
      ),
    );
    entry.presence.addStatusListener((_) => _settle(entry));
    return entry;
  }

  void _switchTo(Widget child, {required _Entry from}) {
    _switching = true;
    final hadFocus = from.focusNode.hasFocus;
    final index = _entries.indexWhere(
      (e) =>
          Widget.canUpdate(e.widget, child) ||
          (child.key is GlobalKey && e.widget.key == child.key),
    );
    final _Entry next;
    if (index == -1) {
      next = _createEntry(child, present: false);
    } else {
      next = _entries.removeAt(index)
        ..widget = child
        ..parked = false;
    }
    _entries.add(next);

    if (_snaps) {
      _snapEntries();
    } else {
      if (!identical(from, next)) _retarget(from, 0);
      _retarget(next, 1);
    }
    _presences = Listenable.merge([for (final e in _entries) e.presence]);
    _switching = false;
    if (hadFocus) _focusAfterSwitch(next);
  }

  void _retarget(_Entry entry, double target) {
    if (entry.presence.isAnimating || entry.presence.value != target) {
      entry.presence.animateTo(target);
    } else if (target == 0 && _drop(entry)) {
      _entries.remove(entry);
    }
  }

  void _snapEntries() {
    final current = _current;
    _entries.removeWhere((entry) {
      if (entry.parked) return false;
      final active = identical(entry, current);
      entry.presence.stop(canceled: true);
      entry.presence.value = active ? 1 : 0;
      return !active && _drop(entry);
    });
  }

  /// Ends [entry]'s exit: parks it when it keeps its state, or disposes it.
  /// Returns whether it left the list.
  bool _drop(_Entry entry) {
    if (entry.keepsState) {
      entry.parked = true;
      return false;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) => entry.dispose());
    return true;
  }

  void _settle(_Entry entry) {
    if (!mounted ||
        _switching ||
        identical(entry, _current) ||
        entry.parked ||
        entry.presence.isAnimating ||
        !_entries.contains(entry)) {
      return;
    }
    setState(() {
      if (_drop(entry)) _entries.remove(entry);
      _presences = Listenable.merge([for (final e in _entries) e.presence]);
    });
  }

  /// Moves focus into [entry] after the frame that built it, unless the app
  /// or an `autofocus` already put it there.
  void _focusAfterSwitch(_Entry entry) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (!mounted || !identical(entry, _current)) return;
        context.owner!.focusManager.applyFocusChangesIfNeeded();
        if (!_focusScope.hasPrimaryFocus) return;
        final node = entry.focusNode;
        final policy = FocusTraversalGroup.maybeOfNode(node);
        final first = policy == null
            ? node.traversalDescendants.firstOrNull
            : policy.findFirstFocus(node, ignoreCurrentFocus: true);
        first?.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.dispose();
    }
    _focusScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = _prefersReducedMotion;
    if (snap && _entries.any((entry) => entry.presence.isAnimating)) {
      _switching = true;
      _snapEntries();
      _presences = Listenable.merge([for (final e in _entries) e.presence]);
      _switching = false;
    }
    final current = _current;
    return FocusScope.withExternalFocusNode(
      focusScopeNode: _focusScope,
      includeSemantics: false,
      child: _SwitcherBox(
        vsync: this,
        motion: _motion,
        snap: snap,
        alignment: widget.alignment,
        textDirection: Directionality.maybeOf(context),
        repaint: _presences,
        children: [
          for (final entry in _entries)
            _SwitcherSlot(
              key: ObjectKey(entry),
              presence: entry.presence,
              current: identical(entry, current),
              child: TickerMode(
                enabled: !entry.parked,
                child: Offstage(
                  offstage: entry.parked,
                  child: ExcludeFocus(
                    excluding: !identical(entry, current),
                    child: Focus(
                      focusNode: entry.focusNode,
                      includeSemantics: false,
                      child: entry.widget,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoListenable implements Listenable {
  const _NoListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class _SwitcherParentData extends ContainerBoxParentData<RenderBox> {
  Animation<double>? presence;
  bool current = false;
  final LayerHandle<OpacityLayer> opacityLayer = LayerHandle();
  final LayerHandle<TransformLayer> transformLayer = LayerHandle();

  void dropLayers() {
    opacityLayer.layer = null;
    transformLayer.layer = null;
  }

  @override
  void detach() {
    dropLayers();
    super.detach();
  }
}

class _SwitcherSlot extends ParentDataWidget<_SwitcherParentData> {
  const _SwitcherSlot({
    super.key,
    required this.presence,
    required this.current,
    required super.child,
  });

  final Animation<double> presence;
  final bool current;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as _SwitcherParentData;
    if (identical(data.presence, presence) && data.current == current) return;
    final outgoing = data.current && !current;
    data
      ..presence = presence
      ..current = current;
    final parent = renderObject.parent;
    if (parent is RenderBottomBarSwitcher) {
      if (outgoing) parent._cancelPointers();
      parent
        ..markNeedsLayout()
        ..markNeedsSemanticsUpdate();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _SwitcherBox;
}

class _SwitcherBox extends MultiChildRenderObjectWidget {
  const _SwitcherBox({
    required this.vsync,
    required this.motion,
    required this.snap,
    required this.alignment,
    required this.textDirection,
    required this.repaint,
    super.children,
  });

  final TickerProvider vsync;
  final Motion motion;
  final bool snap;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final Listenable repaint;

  @override
  RenderBottomBarSwitcher createRenderObject(BuildContext context) =>
      RenderBottomBarSwitcher(
        vsync: vsync,
        motion: motion,
        snap: snap,
        alignment: alignment,
        textDirection: textDirection,
        repaint: repaint,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBottomBarSwitcher renderObject,
  ) {
    renderObject
      ..motion = motion
      ..snap = snap
      ..alignment = alignment
      ..textDirection = textDirection
      ..repaint = repaint;
  }
}

/// Lays out every child of a [BottomBarSwitcher] and springs its own size to
/// the current child's.
class RenderBottomBarSwitcher extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SwitcherParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SwitcherParentData> {
  RenderBottomBarSwitcher({
    required TickerProvider vsync,
    required Motion motion,
    required this._snap,
    required this._alignment,
    required this._textDirection,
    required this._repaint,
  }) {
    _size = MotionController<Size>(
      motion: motion,
      vsync: vsync,
      converter: MotionConverter.size,
      initialValue: Size.zero,
    )..addListener(_onSizeTick);
  }

  /// The children start fading this far into their presence and finish this
  /// far, so the old and the new one overlap in the middle.
  static const _fade = Interval(0.35, 0.65);

  /// How far a child scales toward the bar's size while it fades.
  static const double _maxScale = 1.1;

  late final MotionController<Size> _size;
  bool _inLayout = false;

  void _onSizeTick() {
    if (!_inLayout) markNeedsLayout();
  }

  Size? _target;
  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle();
  final Set<int> _pointers = {};

  set motion(Motion value) {
    if (_size.motion == value) return;
    _size.motion = value;
  }

  bool _snap;
  set snap(bool value) {
    if (value == _snap) return;
    _snap = value;
    if (value && _size.isAnimating) markNeedsLayout();
  }

  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (value == _alignment) return;
    _alignment = value;
    markNeedsLayout();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Listenable _repaint;
  set repaint(Listenable value) {
    if (identical(value, _repaint)) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  /// The size the bar is springing toward: the current child's.
  @visibleForTesting
  Size? get targetSize => _target;

  /// Whether the size is still springing.
  @visibleForTesting
  bool get isMorphing => _size.isAnimating;

  Alignment get _resolvedAlignment => _alignment.resolve(_textDirection);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SwitcherParentData) {
      child.parentData = _SwitcherParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dropChild(RenderObject child) {
    final data = child.parentData! as _SwitcherParentData;
    if (data.current) _cancelPointers();
    super.dropChild(child);
  }

  @override
  void dispose() {
    _size.dispose();
    _clipLayer.layer = null;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _SwitcherParentData;
      data.dropLayers();
      child = data.nextSibling;
    }
    super.dispose();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  RenderBox? get _currentChild {
    var child = lastChild;
    while (child != null) {
      final data = child.parentData! as _SwitcherParentData;
      if (data.current) return child;
      child = data.previousSibling;
    }
    return null;
  }

  /// Whether a minimized bar hides the side of it this switcher sits in.
  bool get hiddenByMinimize {
    RenderObject child = this;
    var node = parent;
    while (node != null) {
      if (node is RenderMinimizeHost) {
        final inFull = identical(child, node.firstChild);
        return inFull == node.minimized;
      }
      child = node;
      node = node.parent;
    }
    return false;
  }

  @override
  void performLayout() {
    var child = firstChild;
    while (child != null) {
      child.layout(constraints, parentUsesSize: true);
      child = childAfter(child);
    }
    final current = _currentChild;
    final target = current == null ? constraints.smallest : current.size;
    if (_target == null || _snap || hiddenByMinimize) {
      if (_size.isAnimating) _size.stop(canceled: true);
      _inLayout = true;
      if (_size.value != target) _size.value = target;
      _inLayout = false;
    } else if (target != _target) {
      _size.animateTo(target);
    }
    _target = target;
    size = constraints.constrain(_size.value);

    final alignment = _resolvedAlignment;
    child = firstChild;
    while (child != null) {
      final data = child.parentData! as _SwitcherParentData;
      data.offset = alignment.alongOffset((size - child.size) as Offset);
      child = data.nextSibling;
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final current = _currentChild;
    return current?.getDryLayout(constraints) ?? constraints.smallest;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _currentChild?.getMinIntrinsicWidth(height) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _currentChild?.getMaxIntrinsicWidth(height) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _currentChild?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _currentChild?.getMaxIntrinsicHeight(width) ?? 0;

  double _presenceOf(RenderBox child) =>
      ((child.parentData! as _SwitcherParentData).presence?.value ?? 1).clamp(
        0.0,
        1.0,
      );

  /// [child]'s opacity from its presence.
  @visibleForTesting
  double opacityOf(RenderBox child) =>
      _opacityOf(_presenceOf(child), _opacityGap);

  double get _opacityGap {
    var gap = 1.0;
    var child = firstChild;
    while (child != null && gap > 0) {
      gap -= _fade.transform(_presenceOf(child));
      child = childAfter(child);
    }
    return math.max(0, gap);
  }

  double _opacityOf(double presence, double gap) =>
      _fade.transform(presence) + presence * gap;

  /// The child's scale: the bar's size over the child's, on the axis that
  /// differs most, so a child scales toward the size the bar is heading for
  /// and sits at 1 once the bar matches it.
  double _scaleOf(RenderBox child) {
    double ratio(double bar, double own) => own <= 0 ? 1 : bar / own;
    final w = ratio(size.width, child.size.width);
    final h = ratio(size.height, child.size.height);
    final scale = (math.log(w).abs() > math.log(h).abs()) ? w : h;
    return scale.clamp(1 / _maxScale, _maxScale);
  }

  Matrix4 _transformOf(RenderBox child, [double? childScale]) {
    final offset = (child.parentData! as BoxParentData).offset;
    final scale = childScale ?? _scaleOf(child);
    final transform = Matrix4.translationValues(offset.dx, offset.dy, 0);
    if (scale == 1) return transform;
    final anchor = _resolvedAlignment.alongSize(child.size);
    return transform
      ..translateByDouble(anchor.dx, anchor.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-anchor.dx, -anchor.dy, 0, 1);
  }

  bool _overflows(double gap) {
    var child = firstChild;
    while (child != null) {
      if (_opacityOf(_presenceOf(child), gap) > 0) {
        final rect = MatrixUtils.transformRect(
          _transformOf(child),
          Offset.zero & child.size,
        );
        if (rect.left < 0 ||
            rect.top < 0 ||
            rect.right > size.width ||
            rect.bottom > size.height) {
          return true;
        }
      }
      child = childAfter(child);
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final gap = _opacityGap;
    if (_overflows(gap)) {
      _clipLayer.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (context, offset) => _paintChildren(context, offset, gap),
        oldLayer: _clipLayer.layer,
      );
    } else {
      _clipLayer.layer = null;
      _paintChildren(context, offset, gap);
    }
  }

  void _paintChildren(PaintingContext context, Offset offset, double gap) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _SwitcherParentData;
      _paintChild(
        context,
        offset,
        child,
        data,
        _opacityOf(_presenceOf(child), gap),
      );
      child = data.nextSibling;
    }
  }

  void _paintChild(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    _SwitcherParentData data,
    double opacity,
  ) {
    if (opacity == 0) {
      data.dropLayers();
      return;
    }
    void paintChild(PaintingContext context, Offset offset) {
      final scale = _scaleOf(child);
      if (scale == 1) {
        data.transformLayer.layer = null;
        context.paintChild(child, offset + data.offset);
        return;
      }
      data.transformLayer.layer = context.pushTransform(
        needsCompositing,
        offset,
        _transformOf(child, scale),
        (context, offset) => context.paintChild(child, offset),
        oldLayer: data.transformLayer.layer,
      );
    }

    if (opacity == 1) {
      data.opacityLayer.layer = null;
      paintChild(context, offset);
      return;
    }
    data.opacityLayer.layer = context.pushOpacity(
      offset,
      (opacity * 255).round(),
      paintChild,
      oldLayer: data.opacityLayer.layer,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_transformOf(child));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = _currentChild;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _transformOf(child),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _pointers.add(event.pointer);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointers.remove(event.pointer);
    }
  }

  void _cancelPointers() {
    for (final pointer in _pointers) {
      GestureBinding.instance.cancelPointer(pointer);
    }
    _pointers.clear();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    final child = _currentChild;
    if (child != null) visitor(child);
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _overflows(_opacityGap) ? Offset.zero & size : null;
}
