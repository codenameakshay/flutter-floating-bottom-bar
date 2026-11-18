import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show PredictiveBackEvent;
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../bottom_bar.dart';
import '../bottom_bar_controller.dart';
import '../bottom_bar_theme.dart';
import '../config/bottom_bar_layout.dart';
import '../internal/bar_group.dart';
import '../internal/bar_outline.dart';
import '../internal/bar_surface.dart';
import '../internal/minimize.dart';
import '../internal/reduce_motion.dart';
import 'bottom_bar_adaptive.dart';
import 'bottom_bar_surface.dart';

/// Grows the nearest [BottomBar] into a panel above a scrim, and shrinks it
/// back into the bar when the panel closes.
///
/// Use it for a menu, a create sheet or a full panel that belongs to the bar.
/// The returned future completes with the value passed to
/// [Navigator.pop], or null when the panel closes another way.
///
/// ```dart
/// BottomBar(
///   trailing: Builder(
///     builder: (context) => IconButton(
///       icon: const Icon(Icons.more_horiz),
///       onPressed: () => showBottomBarPanel<String>(
///         context,
///         semanticLabel: 'More',
///         builder: (context) => const MorePanel(),
///       ),
///     ),
///   ),
///   ...
/// )
/// ```
///
/// The panel opens from the [BottomBar] that encloses [context]. When none
/// does, as with the context of the widget whose `build` method makes the
/// bar, it opens from the first [BottomBar] below [context].
///
/// ## The morph
///
/// The panel starts as the bar's outline and springs on the bar's
/// [BottomBar.motion] to its own rect. When [context] is inside a piece of
/// the bar, such as [BottomBar.trailing], the panel grows from that piece;
/// otherwise from the bar. It grows from the compact pill when the bar is
/// minimized, and slides up from the bottom edge when the bar is hidden.
/// The corners grow from the bar's radius to the panel's. Closing runs the
/// same morph back into the bar, and either direction can turn around
/// mid-flight.
///
/// The panel paints the bar's surface: its glass, tint, edge highlight,
/// border and shadows, or its high contrast fill. While the panel is open,
/// the bar itself does not paint; its content fades out inside the panel as
/// the panel's content fades in. With reduced motion the panel does not
/// morph. It fades in and out where it rests, over the bar.
///
/// ## Size
///
/// The panel is as wide as the bar with its pieces, and full width in a
/// [BottomBarLayout.docked] bar. It sits on the bar's bottom edge and is as
/// tall as its content, up to [maxHeight] of the height between the top safe
/// area and that edge. Make the content scrollable when it can be taller.
/// When the keyboard opens, the panel rises to stay above it.
///
/// In a [BottomBarAdaptive] that shows its rail, the panel grows from the
/// rail into a centred panel, as wide as [BottomBarLayout.maxWidth] or 560,
/// whichever is less.
///
/// ## Closing
///
/// The panel closes on [Navigator.pop], the system back gesture (with
/// Android's predictive back, the panel follows the gesture), the Escape
/// key, and, when [dismissible], a tap on the scrim or a drag down on the
/// panel. Wrap the content in a [PopScope] to stop it closing.
///
/// ## Accessibility
///
/// The panel is a modal route. Focus moves into it and cannot leave it, and
/// goes back to where it was when the panel closes. Screen readers announce
/// [semanticLabel] and ignore what is behind the scrim. [barrierLabel]
/// names the scrim, "Dismiss" by default.
Future<T?> showBottomBarPanel<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxHeight = 0.9,
  Color? barrierColor,
  String? barrierLabel,
  bool dismissible = true,
  String? semanticLabel,
}) {
  assert(maxHeight > 0 && maxHeight <= 1);
  final anchor = PanelAnchor.of(context);
  final localizations = MaterialLocalizations.of(context);
  final route = BarPanelRoute<T>(
    anchor: anchor,
    builder: builder,
    maxHeight: maxHeight,
    barrierColor:
        barrierColor ??
        Theme.of(context).colorScheme.scrim.withValues(alpha: 0.32),
    barrierLabel: barrierLabel ?? localizations.modalBarrierDismissLabel,
    dismissible: dismissible,
    semanticLabel: semanticLabel ?? localizations.dialogLabel,
    reduceMotion: reduceMotion(context),
    opener: FocusManager.instance.primaryFocus,
  );
  return Navigator.of(anchor.context).push(route);
}

/// The bar a panel grows out of and back into.
class PanelAnchor {
  PanelAnchor._({
    required this.context,
    required this.root,
    required this.source,
    required this.group,
    required this.hidden,
    required this.docked,
    required this.offset,
    required this.maxWidth,
    required this.motion,
  });

  /// Resolves the [BottomBar], or the rail of a [BottomBarAdaptive], nearest
  /// to [context].
  factory PanelAnchor.of(BuildContext context) {
    bool isHost(Element element) =>
        element is StatefulElement &&
        (element.state is State<BottomBar> ||
            element.state is State<BottomBarAdaptive>);
    Element? host;
    context.visitAncestorElements((element) {
      if (!isHost(element)) return true;
      host = element;
      return false;
    });
    if (host == null) {
      void visit(Element element) {
        if (host != null) return;
        if (isHost(element)) {
          host = element;
          return;
        }
        element.visitChildren(visit);
      }

      context.visitChildElements(visit);
    }
    final found = (host as StatefulElement?)?.state;
    if (found == null) {
      throw FlutterError.fromParts([
        ErrorSummary(
          'showBottomBarPanel() called with a context that has no BottomBar '
          'above or below it.',
        ),
        ErrorDescription(
          'The panel grows out of a BottomBar or a BottomBarAdaptive rail, so '
          'the context must be inside one, or above one.',
        ),
        context.describeElement('The context used was'),
      ]);
    }
    final theme = Theme.of(context).extension<BottomBarThemeData>();
    final root = found.context.findRenderObject()! as RenderBox;
    final opener = context.findRenderObject();
    RenderBarSurface? enclosing;
    for (RenderObject? o = opener; o != null; o = o.parent) {
      if (o is RenderBarSurface) {
        enclosing = o;
        break;
      }
    }
    if (found is State<BottomBar>) {
      final bar = found.widget;
      final layout =
          bar.layout ??
          bar.theme?.layout ??
          theme?.layout ??
          const BottomBarLayout();
      final group = _descendant<RenderBarGroup>(root);
      final pieces = <RenderBarSurface>[];
      group?.visitChildren((child) {
        if (child is RenderBarSurface) pieces.add(child);
      });
      final source = pieces.contains(enclosing)
          ? enclosing!
          : pieces.firstWhere(
              (piece) => piece.minimizeHost != null,
              orElse: () => pieces.first,
            );
      return PanelAnchor._(
        context: found.context,
        root: root,
        source: source,
        group: group,
        hidden:
            (found as BottomBarVisibilityBinding).visibility ==
            BottomBarVisibility.hidden,
        docked: layout.docked,
        offset: layout.offset,
        maxWidth: null,
        motion: (bar.motion ?? bar.theme?.motion ?? theme?.motion)
            ?.resolveMotion(),
      );
    }
    final adaptive = (found as State<BottomBarAdaptive>).widget;
    final layout =
        adaptive.layout ??
        adaptive.theme?.layout ??
        theme?.layout ??
        const BottomBarLayout();
    return PanelAnchor._(
      context: found.context,
      root: root,
      source: enclosing ?? _descendant<RenderBarSurface>(root)!,
      group: null,
      hidden: false,
      docked: false,
      offset: layout.offset,
      maxWidth: math.min(layout.maxWidth ?? _railPanelWidth, _railPanelWidth),
      motion: (adaptive.motion ?? adaptive.theme?.motion ?? theme?.motion)
          ?.resolveMotion(),
    );
  }

  static const _railPanelWidth = 560.0;

  static T? _descendant<T extends RenderObject>(RenderObject from) {
    T? found;
    void visit(RenderObject child) {
      if (found != null) return;
      if (child is T) {
        found = child;
        return;
      }
      child.visitChildren(visit);
    }

    from.visitChildren(visit);
    return found;
  }

  /// The bar's or the adaptive's element, under the navigator the panel
  /// opens in.
  final BuildContext context;

  /// The [BottomBar] or [BottomBarAdaptive] box.
  final RenderBox root;

  /// The piece the panel grows from.
  final RenderBarSurface source;

  /// The bar and its pieces, whose width and bottom edge the panel takes.
  /// Null for a rail, where the panel is centred instead.
  final RenderBox? group;

  final bool hidden;
  final bool docked;
  final double offset;

  /// The width of a centred panel. Null when the panel takes the bar's.
  final double? maxWidth;

  /// The bar's motion, or null for the default.
  final Motion? motion;

  bool get centred => group == null;
}

/// The route [showBottomBarPanel] pushes. Its animation is the morph: 0 is
/// the bar, 1 the open panel. It runs on the bar's spring, from wherever it
/// is, so open and close can interrupt each other.
class BarPanelRoute<T> extends PopupRoute<T> {
  BarPanelRoute({
    required this.anchor,
    required this.builder,
    required this.maxHeight,
    required this.barrierColor,
    required this.barrierLabel,
    required this.dismissible,
    required this.semanticLabel,
    required this.reduceMotion,
    this.opener,
  });

  final PanelAnchor anchor;
  final WidgetBuilder builder;
  final double maxHeight;
  final bool dismissible;
  final String semanticLabel;
  final bool reduceMotion;

  /// Where focus was when the panel opened. It goes back there on close.
  final FocusNode? opener;

  @override
  final Color barrierColor;

  @override
  final String barrierLabel;

  /// Always true, so Escape closes the panel. [buildModalBarrier] takes a
  /// tap on the scrim only when [dismissible].
  @override
  bool get barrierDismissible => true;

  @override
  Widget buildModalBarrier() => AnimatedModalBarrier(
    color: animation!.drive(
      ColorTween(
        begin: barrierColor.withValues(alpha: 0),
        end: barrierColor,
      ).chain(CurveTween(curve: barrierCurve)),
    ),
    dismissible: dismissible,
    semanticsLabel: barrierLabel,
    barrierSemanticsDismissible: dismissible,
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  TraversalEdgeBehavior get traversalEdgeBehavior =>
      TraversalEdgeBehavior.closedLoop;

  static const _fade = CurvedMotion(
    Duration(milliseconds: 150),
    Curves.easeOut,
  );
  static const _fallbackMotion = CupertinoMotion.snappy();

  Motion get _motion => reduceMotion ? _fade : anchor.motion ?? _fallbackMotion;

  AnimationController get _controller => controller!;

  /// Springs the morph to [target] from where it is, carrying [velocity] in
  /// morph units per second, or the current velocity.
  TickerFuture _springTo(double target, {double? velocity}) {
    final c = _controller;
    final simulation = _motion.createSimulation(
      start: c.value,
      end: target,
      velocity: velocity ?? c.velocity,
    );
    return target == 1
        ? c.animateWith(simulation)
        : c.animateBackWith(simulation);
  }

  double? _releaseVelocity;

  @override
  TickerFuture didPush() {
    super.didPush();
    return _springTo(1);
  }

  @override
  bool didPop(T? result) {
    final popped = super.didPop(result);
    _springTo(0, velocity: _releaseVelocity);
    _releaseVelocity = null;
    final opener = this.opener;
    if (opener != null && opener.context != null && opener.canRequestFocus) {
      opener.requestFocus();
    }
    return popped;
  }

  @override
  void handleCancelBackGesture() {
    navigator?.didStopUserGesture();
    _springTo(1);
  }

  @override
  void handleCommitBackGesture() {
    navigator?.didStopUserGesture();
    navigator?.pop();
  }

  /// Stops the morph where it is, for a drag to take over.
  void holdMorph() => _controller.stop();

  /// Moves the morph by a drag of [delta] morph units.
  void dragBy(double delta) {
    _controller.value = (_controller.value - delta).clamp(0.0, 1.0);
  }

  /// Ends a drag at [velocity] morph units per second, positive toward
  /// closed. A fast fling or a drag past halfway closes the panel.
  void endDrag(double velocity) {
    if (!isCurrent) return;
    final closes =
        velocity > _flingVelocity ||
        (velocity > -_flingVelocity && _controller.value < 0.5);
    if (!closes) {
      _springTo(1, velocity: -velocity);
      return;
    }
    _releaseVelocity = -velocity;
    navigator?.maybePop().then((_) {
      if (!isCurrent) return;
      _releaseVelocity = null;
      _springTo(1);
    });
  }

  /// A fling faster than this, in morph units per second, settles the panel
  /// in its direction.
  static const _flingVelocity = 2.0;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _BarPanel(route: this);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _BarPanel extends StatefulWidget {
  const _BarPanel({required this.route});

  final BarPanelRoute route;

  @override
  State<_BarPanel> createState() => _BarPanelState();
}

class _BarPanelState extends State<_BarPanel> with WidgetsBindingObserver {
  final _panelKey = GlobalKey();

  BarPanelRoute get _route => widget.route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = FocusScope.of(context);
      if (FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional &&
          scope.focusedChild == null) {
        scope.nextFocus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (!_route.isCurrent || !_route.popGestureEnabled) return false;
    _gestureFocus = FocusManager.instance.primaryFocus;
    _route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  /// Where focus was when a back gesture started. The route drops focus
  /// while the gesture runs, so a cancelled gesture puts it back.
  FocusNode? _gestureFocus;

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) =>
      _route.handleUpdateBackGestureProgress(progress: 1 - backEvent.progress);

  @override
  void handleCancelBackGesture() {
    _route.handleCancelBackGesture();
    final focus = _gestureFocus;
    _gestureFocus = null;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (!mounted) return;
        if (focus != null && focus.context != null && focus.canRequestFocus) {
          focus.requestFocus();
        } else {
          FocusScope.of(context).requestFocus();
        }
      })
      ..ensureVisualUpdate();
  }

  @override
  void handleCommitBackGesture() => _route.handleCommitBackGesture();

  /// How far a drag of one pixel moves the morph.
  double get _dragScale {
    final box = _panelKey.currentContext?.findRenderObject();
    final span = box is RenderBarPanel ? box.dragSpan : 0.0;
    return span > 0 ? 1 / span : 0;
  }

  void _dragStart(DragStartDetails details) => _route.holdMorph();

  void _dragUpdate(DragUpdateDetails details) =>
      _route.dragBy(details.primaryDelta! * _dragScale);

  void _dragEnd(DragEndDetails details) =>
      _route.endDrag(details.primaryVelocity! * _dragScale);

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    Widget content = Builder(builder: route.builder);
    if (route.anchor.docked && keyboard == 0) {
      content = Padding(
        padding: EdgeInsets.only(bottom: media.padding.bottom),
        child: content,
      );
    }
    content = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      removeLeft: !route.anchor.docked,
      removeRight: !route.anchor.docked,
      child: content,
    );
    if (route.dismissible) {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: _dragStart,
        onVerticalDragUpdate: _dragUpdate,
        onVerticalDragEnd: _dragEnd,
        child: content,
      );
    }
    return PanelBox(
      key: _panelKey,
      anchor: route.anchor,
      progress: route.animation!,
      reduceMotion: route.reduceMotion,
      maxHeight: route.maxHeight,
      padding: media.padding,
      keyboard: keyboard,
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: route.semanticLabel,
        child: Material(type: MaterialType.transparency, child: content),
      ),
    );
  }
}

/// Lays the panel's content out at the panel's size and paints the morph.
class PanelBox extends SingleChildRenderObjectWidget {
  const PanelBox({
    super.key,
    required this.anchor,
    required this.progress,
    required this.reduceMotion,
    required this.maxHeight,
    required this.padding,
    required this.keyboard,
    super.child,
  });

  final PanelAnchor anchor;
  final Animation<double> progress;
  final bool reduceMotion;
  final double maxHeight;
  final EdgeInsets padding;
  final double keyboard;

  @override
  RenderBarPanel createRenderObject(BuildContext context) => RenderBarPanel(
    anchor: anchor,
    progress: progress,
    reduceMotion: reduceMotion,
    maxHeight: maxHeight,
    padding: padding,
    keyboard: keyboard,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderBarPanel renderObject) {
    renderObject
      ..maxHeight = maxHeight
      ..padding = padding
      ..keyboard = keyboard
      ..textDirection = Directionality.of(context);
  }
}

/// Where the bar sits, in global coordinates.
@immutable
class _BarPlace {
  const _BarPlace({required this.root, required this.group});

  /// The [BottomBar] or [BottomBarAdaptive] box.
  final Rect root;

  /// The bar and its pieces at rest, without the hide, minimize or keyboard
  /// transforms. Null for a rail.
  final Rect? group;

  static _BarPlace? of(PanelAnchor anchor) {
    final root = anchor.root;
    if (!root.attached || !root.hasSize) return null;
    final rootRect = MatrixUtils.transformRect(
      root.getTransformTo(null),
      Offset.zero & root.size,
    );
    final group = anchor.group;
    if (group == null) return _BarPlace(root: rootRect, group: null);
    if (!group.attached || !group.hasSize) return null;
    var offset = Offset.zero;
    for (RenderObject node = group; node != root; node = node.parent!) {
      final data = node.parentData;
      if (data is BoxParentData) offset += data.offset;
    }
    return _BarPlace(
      root: rootRect,
      group: (offset & group.size).shift(rootRect.topLeft),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _BarPlace && other.root == root && other.group == group;

  @override
  int get hashCode => Object.hash(root, group);
}

class RenderBarPanel extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderBarPanel({
    required this._anchor,
    required this._progress,
    required this._reduceMotion,
    required this._maxHeight,
    required this._padding,
    required this._keyboard,
    required this._textDirection,
  }) : _place = _BarPlace.of(_anchor);

  final PanelAnchor _anchor;
  final Animation<double> _progress;
  final bool _reduceMotion;

  /// The panel's radius when the bar's is smaller.
  static const _panelRadius = 32.0;

  double _maxHeight;
  set maxHeight(double value) {
    if (value == _maxHeight) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (value == _padding) return;
    _padding = value;
    markNeedsLayout();
  }

  double _keyboard;
  set keyboard(double value) {
    if (value == _keyboard) return;
    _keyboard = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  _BarPlace? _place;
  Offset _origin = Offset.zero;
  bool _relayoutScheduled = false;

  /// The open panel's rect, from the last layout.
  Rect _end = Rect.zero;

  /// The open panel's rect, in this box's coordinates.
  @visibleForTesting
  Rect get panelRect => _end;

  /// How far the panel's top edge moves between the bar and the open panel,
  /// so a drag can follow the finger.
  double get dragSpan => math.max(0, _start.top - _end.top);

  final _lift = LayerHandle<OffsetLayer>();
  final _surfacePainter = SurfacePainter();
  final _ghostOpacity = LayerHandle<OpacityLayer>();
  final _ghostTransform = LayerHandle<TransformLayer>();
  final _contentClip = LayerHandle<ClipPathLayer>();
  final _contentOpacity = LayerHandle<OpacityLayer>();

  RenderBarSurface get _source => _anchor.source;
  bool get _sourceLive => _source.attached && _source.hasSize;

  /// Whether the bar's content fades out inside the panel. A hidden bar
  /// shows nothing to fade, and reduced motion leaves the bar where it is.
  bool get _lifts => !_reduceMotion && !_anchor.hidden && _sourceLive;

  double get _t => math.max(0, _progress.value);

  /// The morph as painted: the panel's rect, its outline and how far it is
  /// from the bar.
  @visibleForTesting
  Rect get currentRect => _rectAt(_t);

  @visibleForTesting
  BorderRadius get currentRadius => _radiusAt(_t);

  Rect _rectAt(double t) {
    if (_reduceMotion) return _end;
    final rect = Rect.lerp(_start, _end, t)!;
    return Rect.fromLTWH(
      rect.left,
      rect.top,
      math.max(0, rect.width),
      math.max(0, rect.height),
    );
  }

  BorderRadius _radiusAt(double t) {
    if (_reduceMotion) return _endRadius;
    return BorderRadius.lerp(_startRadius, _endRadius, t)!;
  }

  /// The bar's outline rect, or for a hidden bar the panel's footprint just
  /// below the bar's bottom edge, as if it slides up.
  Rect get _start {
    final place = _place;
    if (!_anchor.hidden && _sourceLive) {
      return MatrixUtils.transformRect(
        _source.getTransformTo(this),
        _source.outlineRect,
      );
    }
    final bottom = (place?.group ?? place?.root ?? _end).bottom - _origin.dy;
    final height = _sourceLive ? _source.outlineRect.height : 0.0;
    return Rect.fromLTWH(_end.left, bottom, _end.width, height);
  }

  BorderRadius get _startRadius {
    if (!_sourceLive) return BorderRadius.zero;
    final radius = _source.outline.borderRadius.resolve(
      _source.textDirection ?? _textDirection,
    );
    final cap = _start.shortestSide / 2;
    Radius clamp(Radius r) =>
        Radius.elliptical(math.min(r.x, cap), math.min(r.y, cap));
    return BorderRadius.only(
      topLeft: clamp(radius.topLeft),
      topRight: clamp(radius.topRight),
      bottomLeft: clamp(radius.bottomLeft),
      bottomRight: clamp(radius.bottomRight),
    );
  }

  BorderRadius get _endRadius {
    final radius = Radius.circular(
      math.max(_panelRadius, _sourceLive ? _startRadius.topLeft.x : 0),
    );
    return _anchor.docked
        ? BorderRadius.vertical(top: radius)
        : BorderRadius.all(radius);
  }

  /// The bar's notch, in this box's coordinates, or null.
  Rect? get _notch {
    if (_reduceMotion || _anchor.hidden || !_sourceLive) return null;
    final notch = _source.outline.notch;
    if (notch == null) return null;
    return MatrixUtils.transformRect(
      _source.getTransformTo(this),
      notch.shift(_source.outlineRect.center),
    );
  }

  BarOutline _outlineAt(Rect rect, double t) {
    final notch = _notch;
    return BarOutline(
      borderRadius: _radiusAt(t),
      notch: notch?.shift(-rect.center),
      border: _surface.border,
    );
  }

  BottomBarSurface? _lastSurface;
  BottomBarSurface get _surface {
    if (_sourceLive) _lastSurface = _source.paintedSurface;
    return _lastSurface ?? const BottomBarSurface();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(_progressChanged);
  }

  @override
  void detach() {
    _progress.removeListener(_progressChanged);
    _release();
    super.detach();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  void _release() {
    if (identical(_source.lift, _lift.layer)) _source.lift = null;
    _lift.layer = null;
    _surfacePainter.release();
    _ghostOpacity.layer = null;
    _ghostTransform.layer = null;
    _contentClip.layer = null;
    _contentOpacity.layer = null;
  }

  void _progressChanged() {
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  bool get _offstage {
    for (var node = parent; node != null; node = node.parent) {
      if (node is RenderOffstage && node.offstage) return true;
    }
    return false;
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    final place = _place;
    final bounds = Offset.zero & size;
    final root = place?.root.shift(-_origin) ?? bounds;
    final keyboardTop = size.height - _keyboard;
    double width, left, bottom, top;
    if (_anchor.centred) {
      width = math.min(
        _anchor.maxWidth ?? double.infinity,
        root.width - 2 * _anchor.offset,
      );
      left = root.center.dx - width / 2;
      top = math.max(root.top, _padding.top) + _anchor.offset;
      bottom =
          math.min(root.bottom - _padding.bottom, keyboardTop) - _anchor.offset;
    } else if (_anchor.docked) {
      width = root.width;
      left = root.left;
      top = _padding.top + _anchor.offset;
      bottom = math.min(root.bottom, keyboardTop);
    } else {
      final group = place?.group?.shift(-_origin) ?? root;
      width = group.width;
      left = group.left;
      top = _padding.top + _anchor.offset;
      bottom = math.min(group.bottom, keyboardTop - _anchor.offset);
    }
    width = math.max(0, width);
    final maxHeight = math.max(0.0, (bottom - top) * _maxHeight);
    final child = this.child;
    var height = 0.0;
    if (child != null) {
      child.layout(
        BoxConstraints(minWidth: width, maxWidth: width, maxHeight: maxHeight),
        parentUsesSize: true,
      );
      height = child.size.height;
    }
    if (_anchor.centred) {
      final centre = (top + bottom) / 2;
      _end = Rect.fromLTWH(left, centre - height / 2, width, height);
    } else {
      _end = Rect.fromLTWH(left, bottom - height, width, height);
    }
    if (_lifts && _lift.layer == null && !_offstage) {
      _lift.layer = OffsetLayer();
      _source.lift = _lift.layer;
    }
  }

  /// Where the panel's content paints: its top on the morphing rect's top,
  /// centred across it.
  Offset _contentOffset(Rect rect) =>
      Offset(rect.center.dx - _end.width / 2, rect.top);

  /// Re-reads where the bar is, and lays out again next frame if it moved.
  void _refreshPlace() {
    final place = _BarPlace.of(_anchor);
    final origin = localToGlobal(Offset.zero);
    if ((place == null || place == _place) && origin == _origin) return;
    if (place != null) _place = place;
    _origin = origin;
    if (_relayoutScheduled) return;
    _relayoutScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _relayoutScheduled = false;
      if (attached) markNeedsLayout();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _refreshPlace();
    final t = _t;
    final rect = _rectAt(t);
    final outline = _outlineAt(rect, t);
    final surface = _surface;
    final opacity = _reduceMotion ? t.clamp(0.0, 1.0) : 1.0;
    if (opacity == 0) {
      _surfacePainter.release();
      _ghostOpacity.layer = null;
      _contentClip.layer = null;
      _contentOpacity.layer = null;
      return;
    }
    _surfacePainter.paint(
      context,
      offset,
      rect: rect,
      outline: outline,
      surface: surface,
      opacity: opacity,
      blurs: surface.blur > 0,
      needsCompositing: true,
      textDirection: _textDirection,
    );
    _paintGhost(context, offset, t);
    _paintContent(context, offset, rect, outline, t);
  }

  /// The bar's content, where the bar is, fading out as the panel grows.
  void _paintGhost(PaintingContext context, Offset offset, double t) {
    final lift = _lift.layer;
    final alpha = (fullOpacity(t) * 255).round();
    if (lift == null || alpha == 0 || !_sourceLive) {
      _ghostOpacity.layer = null;
      _ghostTransform.layer = null;
      return;
    }
    final transform = _ghostTransform.layer ??= TransformLayer();
    transform.transform =
        Matrix4.translationValues(offset.dx, offset.dy, 0) *
        _source.getTransformTo(this);
    _ghostOpacity.layer = context.pushOpacity(
      Offset.zero,
      alpha,
      (context, _) => context.pushLayer(
        transform,
        (context, _) => context.addLayer(lift),
        Offset.zero,
      ),
      oldLayer: _ghostOpacity.layer,
    );
  }

  void _paintContent(
    PaintingContext context,
    Offset offset,
    Rect rect,
    BarOutline outline,
    double t,
  ) {
    final child = this.child;
    final opacity = _reduceMotion ? t.clamp(0.0, 1.0) : compactOpacity(t);
    final alpha = (opacity * 255).round();
    if (child == null || alpha == 0) {
      _contentClip.layer = null;
      _contentOpacity.layer = null;
      return;
    }
    final at = _contentOffset(rect);
    _contentClip.layer = context.pushClipPath(
      true,
      offset,
      rect,
      outline.getOuterPath(rect, textDirection: _textDirection),
      (context, offset) {
        if (alpha == 255) {
          _contentOpacity.layer = null;
          context.paintChild(child, offset + at);
          return;
        }
        _contentOpacity.layer = context.pushOpacity(
          offset,
          alpha,
          (context, offset) => context.paintChild(child, offset + at),
          oldLayer: _contentOpacity.layer,
        );
      },
      clipBehavior: Clip.antiAlias,
      oldLayer: _contentClip.layer,
    );
  }

  Path get _hitPath {
    final t = _t;
    final rect = _rectAt(t);
    return _outlineAt(
      rect,
      t,
    ).getOuterPath(rect, textDirection: _textDirection);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_hitPath.contains(position)) return false;
    return super.hitTest(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _contentOffset(_rectAt(_t)),
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final at = _contentOffset(_rectAt(_t));
    transform.translateByDouble(at.dx, at.dy, 0, 1);
  }
}
