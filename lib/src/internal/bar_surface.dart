import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../widgets/bottom_bar_surface.dart';
import 'bar_outline.dart';
import 'minimize.dart';

/// Paints the bar's decoration through its [BarOutline] and hosts a raised
/// centre action.
///
/// A raised action makes this box taller by its raise, so the part above the
/// bar's top edge counts in the bar's footprint: it hit-tests, it sits inside
/// semantics and focus exclusion, and [BottomBarScope.barHeight] includes it.
class BarSurface extends SingleChildRenderObjectWidget {
  const BarSurface({
    super.key,
    this.decoration,
    this.surface,
    this.edgeSurface,
    this.edge,
    this.visibility,
    this.fades = false,
    this.backdropKey,
    this.minimize,
    this.capsule,
    super.child,
  });

  /// Painted when [surface] is null. Its radius shapes the outline either way.
  final BoxDecoration? decoration;

  /// Paints the bar instead of [decoration]'s fill, border and shadows. Its
  /// colours are already resolved against the theme.
  final BottomBarSurface? surface;

  /// Blended over [surface] by [edge]. Ignored when [surface] is null.
  final BottomBarSurface? edgeSurface;

  /// How far the bar is from [surface] (0) to [edgeSurface] (1).
  final Animation<double>? edge;

  /// The bar's show progress. At 0 or below the bar is hidden and its glass
  /// reads no backdrop.
  final Animation<double>? visibility;

  /// Whether the bar fades itself by [visibility] instead of sitting inside a
  /// fade transition. A backdrop blur inside an opacity layer has no backdrop
  /// to read on Impeller, so the glass fades by scaling its blur instead.
  final bool fades;

  /// Shares one backdrop read with other glass that uses the same key and
  /// does not overlap the bar.
  final BackdropKey? backdropKey;

  /// How far the bar has shrunk onto the compact pill of the [MinimizeHost]
  /// inside it, from 0 (full) to 1 (pill). The outline, and with it the fill,
  /// glass, border and shadows, follows every frame. Without a pill the bar
  /// keeps its full outline.
  final Animation<double>? minimize;

  /// How far the outline's corners have rounded into a capsule, from 0 (the
  /// decoration's radius) to 1 (half the outline's shorter side).
  /// When set, the child is clipped and hit-tested through the outline.
  final Animation<double>? capsule;

  @override
  RenderBarSurface createRenderObject(BuildContext context) => RenderBarSurface(
    decoration: decoration,
    surface: surface,
    edgeSurface: edgeSurface,
    edge: edge,
    visibility: visibility,
    fades: fades,
    backdropKey: backdropKey,
    minimize: minimize,
    capsule: capsule,
    configuration: createLocalImageConfiguration(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderBarSurface renderObject) {
    renderObject
      ..decoration = decoration
      ..surface = surface
      ..edgeSurface = edgeSurface
      ..edge = edge
      ..visibility = visibility
      ..fades = fades
      ..backdropKey = backdropKey
      ..minimize = minimize
      ..capsule = capsule
      ..configuration = createLocalImageConfiguration(context);
  }
}

class RenderBarSurface extends RenderShiftedBox {
  RenderBarSurface({
    this._decoration,
    this._surface,
    this._edgeSurface,
    this._edge,
    this._visibility,
    this._fades = false,
    this._backdropKey,
    this._minimize,
    this._capsule,
    required this._configuration,
  }) : super(null);

  @override
  set child(RenderBox? value) {
    if (identical(value, child)) return;
    super.child = value;
    _surfaceChanged();
    if (value == null) _opacityLayer.layer = null;
  }

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

  BottomBarSurface? _surface;
  set surface(BottomBarSurface? value) {
    if (value == _surface) return;
    _surface = value;
    if (value == null) _opacityLayer.layer = null;
    _surfaceChanged();
    markNeedsPaint();
  }

  BottomBarSurface? _edgeSurface;
  set edgeSurface(BottomBarSurface? value) {
    if (value == _edgeSurface) return;
    _edgeSurface = value;
    _edgeChanged();
  }

  Animation<double>? _edge;
  set edge(Animation<double>? value) {
    if (identical(value, _edge)) return;
    if (attached) _edge?.removeListener(_edgeChanged);
    _edge = value;
    if (attached) value?.addListener(_edgeChanged);
    _edgeChanged();
  }

  void _edgeChanged() {
    _surfaceChanged();
    markNeedsPaint();
  }

  /// [_surface] blended toward [_edgeSurface] by [_edge].
  BottomBarSurface? get _painted {
    final surface = _surface;
    final edgeSurface = _edgeSurface;
    if (surface == null || edgeSurface == null) return surface;
    final t = (_edge?.value ?? 0).clamp(0.0, 1.0);
    return BottomBarSurface.lerp(surface, edgeSurface, t);
  }

  Animation<double>? _visibility;
  set visibility(Animation<double>? value) {
    if (identical(value, _visibility)) return;
    if (attached) _visibility?.removeListener(_visibilityChanged);
    _visibility = value;
    if (attached) value?.addListener(_visibilityChanged);
    _surfaceChanged();
    if (_fades) markNeedsPaint();
  }

  bool _fades;
  set fades(bool value) {
    if (value == _fades) return;
    _fades = value;
    if (!value) _opacityLayer.layer = null;
    _surfaceChanged();
    markNeedsPaint();
  }

  double get _opacity =>
      _fades ? (_visibility?.value ?? 1).clamp(0.0, 1.0) : 1.0;

  void _visibilityChanged() {
    if (_fades) markNeedsPaint();
    _surfaceChanged();
  }

  BackdropKey? _backdropKey;
  set backdropKey(BackdropKey? value) {
    if (value == _backdropKey) return;
    _backdropKey = value;
    markNeedsPaint();
  }

  Animation<double>? _minimize;
  set minimize(Animation<double>? value) {
    if (identical(value, _minimize)) return;
    if (attached) _minimize?.removeListener(markNeedsPaint);
    _minimize = value;
    if (attached) value?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Animation<double>? _capsule;
  set capsule(Animation<double>? value) {
    if (identical(value, _capsule)) return;
    if (attached) _capsule?.removeListener(markNeedsPaint);
    _capsule = value;
    if (attached) value?.addListener(markNeedsPaint);
    if (value == null) _childClipLayer.layer = null;
    markNeedsPaint();
  }

  /// Set by the [RenderMinimizeHost] inside this bar when it attaches.
  RenderMinimizeHost? _minimizeHost;
  RenderMinimizeHost? get minimizeHost => _minimizeHost;
  set minimizeHost(RenderMinimizeHost? value) {
    if (identical(value, _minimizeHost)) return;
    _minimizeHost = value;
    markNeedsPaint();
  }

  /// The pill the bar shrinks onto, in this box's coordinates.
  Rect? get _compactRect => _minimizeHost?.compactRectIn(this);

  /// How far the outline has moved onto the pill, or 0 without a pill.
  @visibleForTesting
  double get morph => _morph;
  double get _morph {
    final t = (_minimize?.value ?? 0).clamp(0.0, 1.0);
    return t == 0 || _compactRect == null ? 0 : t;
  }

  /// The rect the outline is drawn in: the bar, shrinking onto the pill.
  @visibleForTesting
  Rect get outlineRect => _outlineRect;
  Rect get _outlineRect {
    final t = _morph;
    return t == 0 ? _barRect : Rect.lerp(_barRect, _compactRect, t)!;
  }

  bool get _blurs =>
      child != null &&
      (_painted?.blur ?? 0) > 0 &&
      (_visibility?.value ?? 1) > 0;

  // Non-fading glass repaints only when its backdrop turns on or off.
  bool _composited = false;
  void _surfaceChanged() {
    if (!_blurs) {
      _clipLayer.layer = null;
      _backdropLayer.layer = null;
    }
    if (_opacity == 0 || _opacity == 1) _opacityLayer.layer = null;
    if (alwaysNeedsCompositing == _composited) return;
    _composited = alwaysNeedsCompositing;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing =>
      _blurs ||
      (_surface != null && child != null && _opacity > 0 && _opacity < 1);

  final _clipLayer = LayerHandle<ClipPathLayer>();
  final _childClipLayer = LayerHandle<ClipPathLayer>();
  final _backdropLayer = LayerHandle<BackdropFilterLayer>();
  final _opacityLayer = LayerHandle<OpacityLayer>();

  final List<RenderCenterActionSlot> _actions = [];
  RenderCenterActionSlot? _action;

  void _updateAction() {
    final previous = _action;
    _action =
        _actions.where((action) => action._lift).firstOrNull ??
        _actions.firstOrNull;
    if (identical(previous, _action)) return;
    _actionsNeedLayout = true;
    markNeedsLayout();
  }

  bool _actionsNeedLayout = false;
  Decoration? _paintedDecoration;
  BoxPainter? _painter;

  double get _raise {
    final action = _action;
    return action == null || !action._lifted ? 0 : action._raise;
  }

  double get layoutRaise => _raise;

  /// The bar's own height, without the raise of a raised centre action.
  /// Read by the parent after layout.
  double get barHeight {
    final child = this.child;
    if (child == null) return size.height;
    return math.max(
      0,
      size.height - (child.parentData! as BoxParentData).offset.dy,
    );
  }

  Rect get _barRect {
    final child = this.child!;
    return (child.parentData! as BoxParentData).offset & child.size;
  }

  /// The bar's current outline, to draw in the bar's rect, or while it
  /// minimizes in the rect shrinking onto the pill. The notch follows the
  /// action as laid out, and closes as the action fades out.
  BarOutline get outline {
    final decoration = _decoration;
    final morph = _morph;
    final outlineRect = _outlineRect;
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
          (math.max(rect.width, rect.height) + 2 * action._notchMargin) *
          fullOpacity(morph);
      notch = diameter <= 0
          ? null
          : Rect.fromCircle(
              center: rect.center - outlineRect.center,
              radius: diameter / 2,
            );
    }
    final surface = _painted;
    var radius = decoration?.borderRadius ?? BorderRadius.zero;
    if (morph != 0) {
      radius = BorderRadiusGeometry.lerp(
        radius,
        BorderRadius.circular(_compactRect!.shortestSide / 2),
        morph,
      )!;
    }
    final capsule = (_capsule?.value ?? 0).clamp(0.0, 1.0);
    if (capsule != 0) {
      radius = BorderRadiusGeometry.lerp(
        radius,
        BorderRadius.circular(outlineRect.shortestSide / 2),
        capsule,
      )!;
    }
    return BarOutline(
      borderRadius: radius,
      notch: notch,
      border: surface != null ? surface.border : decoration?.border,
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
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _visibility?.addListener(_visibilityChanged);
    _edge?.addListener(_edgeChanged);
    _minimize?.addListener(markNeedsPaint);
    _capsule?.addListener(markNeedsPaint);
    _edgeChanged();
  }

  @override
  void detach() {
    _visibility?.removeListener(_visibilityChanged);
    _edge?.removeListener(_edgeChanged);
    _minimize?.removeListener(markNeedsPaint);
    _capsule?.removeListener(markNeedsPaint);
    _clipLayer.layer = null;
    _childClipLayer.layer = null;
    _backdropLayer.layer = null;
    _opacityLayer.layer = null;
    _painter?.dispose();
    _painter = null;
    _paintedDecoration = null;
    super.detach();
  }

  @override
  void dispose() {
    _painter?.dispose();
    _clipLayer.layer = null;
    _childClipLayer.layer = null;
    _backdropLayer.layer = null;
    _opacityLayer.layer = null;
    super.dispose();
  }

  @override
  void performLayout() {
    if (_actionsNeedLayout) {
      _actionsNeedLayout = false;
      invokeLayoutCallback((constraints) {
        for (final action in _actions) {
          action.markNeedsLayout();
        }
      });
    }
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
    final surface = _painted;
    if (surface == null || child == null || !_blurs) {
      _clipLayer.layer = null;
      _backdropLayer.layer = null;
    }
    if (surface != null && child != null) {
      final opacity = _opacity;
      if (opacity == 0) {
        _opacityLayer.layer = null;
        return;
      }
      _paintSurface(context, offset, surface, opacity);
      if (opacity < 1) {
        _opacityLayer.layer = context.pushOpacity(
          offset,
          (opacity * 255).round(),
          _paintChild,
          oldLayer: _opacityLayer.layer,
        );
      } else {
        _opacityLayer.layer = null;
        _paintChild(context, offset);
      }
      return;
    }
    _opacityLayer.layer = null;
    final decoration = _decoration;
    if (decoration != null && child != null) {
      final paintable = _paintable(decoration);
      if (paintable != _paintedDecoration) {
        _painter?.dispose();
        _painter = paintable.createBoxPainter(markNeedsPaint);
        _paintedDecoration = paintable;
      }
      final bar = _outlineRect;
      _painter!.paint(
        context.canvas,
        offset + bar.topLeft,
        _configuration.copyWith(size: bar.size),
      );
      if (decoration.isComplex) context.setIsComplexHint();
    }
    _paintChild(context, offset);
  }

  void _paintChild(PaintingContext context, Offset offset) {
    if (_capsule == null || child == null) {
      _childClipLayer.layer = null;
      super.paint(context, offset);
      return;
    }
    final rect = _outlineRect;
    _childClipLayer.layer = context.pushClipPath(
      needsCompositing,
      offset,
      rect,
      outline.getOuterPath(rect, textDirection: _configuration.textDirection),
      super.paint,
      clipBehavior: Clip.antiAlias,
      oldLayer: _childClipLayer.layer,
    );
  }

  // The blurred backdrop clipped to the outline, then the fill,
  // edge highlight and border. The child paints on top, outside the clip, so
  // a raised action is never cut.
  void _paintSurface(
    PaintingContext context,
    Offset offset,
    BottomBarSurface surface,
    double opacity,
  ) {
    final outline = this.outline;
    final rect = _outlineRect;
    final textDirection = _configuration.textDirection;
    final path = outline.getOuterPath(rect, textDirection: textDirection);
    void faded(Canvas canvas, Rect bounds, VoidCallback paint) {
      if (opacity == 1) return paint();
      canvas.saveLayer(
        bounds,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
      );
      paint();
      canvas.restore();
    }

    void paintFill(PaintingContext context, Offset offset) =>
        faded(context.canvas, rect.shift(offset).inflate(1), () {
          final canvas = context.canvas;
          final shifted = rect.shift(offset);
          final shape = path.shift(offset);
          final tint = surface.tint;
          if (tint != null) {
            canvas.drawPath(
              shape,
              Paint()
                ..color = tint.withValues(alpha: tint.a * surface.fillOpacity),
            );
          }
          final gradient = surface.gradient;
          if (gradient != null) {
            canvas.drawPath(
              shape,
              Paint()
                ..shader = gradient.createShader(
                  shifted,
                  textDirection: textDirection,
                )
                ..color = Color.fromRGBO(0, 0, 0, surface.fillOpacity),
            );
          }
          final highlight = surface.edgeHighlight;
          if (highlight != null && highlight.a > 0) {
            // A 2px stroke clipped to the inside leaves 1px along the edge.
            canvas
              ..save()
              ..clipPath(shape)
              ..drawPath(
                shape,
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..shader = LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [highlight, highlight.withValues(alpha: 0)],
                    stops: const [0, 0.6],
                  ).createShader(shifted),
              )
              ..restore();
          }
          outline.paint(canvas, shifted, textDirection: textDirection);
        });

    if (!_blurs) {
      paintFill(context, offset);
    } else {
      final backdrop = _backdropLayer.layer ??= BackdropFilterLayer();
      backdrop
        ..filter = _filter(surface, opacity)
        ..backdropKey = _backdropKey;
      _clipLayer.layer = context.pushClipPath(
        needsCompositing,
        offset,
        rect,
        path,
        (context, offset) => context.pushLayer(backdrop, paintFill, offset),
        oldLayer: _clipLayer.layer,
      );
    }
    // Exterior shadows must not become part of the backdrop being blurred.
    faded(
      context.canvas,
      Rect.largest,
      () => _paintShadows(context.canvas, offset, rect, outline, path, surface),
    );
  }

  // A fading bar scales its blur and saturation toward none.
  static ui.ImageFilter _filter(BottomBarSurface surface, double opacity) {
    final sigma = surface.blur * opacity;
    final blur = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    final s = 1 + (surface.saturation - 1) * opacity;
    if (s == 1) return blur;
    final r = 0.2126 * (1 - s), g = 0.7152 * (1 - s), b = 0.0722 * (1 - s);
    return ui.ImageFilter.compose(
      outer: ColorFilter.matrix([
        r + s, g, b, 0, 0, //
        r, g + s, b, 0, 0, //
        r, g, b + s, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      inner: blur,
    );
  }

  // Clipped to the outside of the outline, so a translucent fill never shows
  // the shadow through it.
  void _paintShadows(
    Canvas canvas,
    Offset offset,
    Rect rect,
    BarOutline outline,
    Path path,
    BottomBarSurface surface,
  ) {
    final shadows = surface.shadows;
    if (shadows == null || shadows.isEmpty) return;
    final reach = shadows.fold<double>(
      0,
      (reach, shadow) => math.max(
        reach,
        shadow.blurRadius * 2 +
            shadow.spreadRadius.abs() +
            shadow.offset.distance,
      ),
    );
    final shifted = rect.shift(offset);
    canvas
      ..save()
      ..clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(shifted.inflate(reach + 1))
          ..addPath(path, offset),
      );
    for (final shadow in shadows) {
      canvas.drawPath(
        outline.getOuterPath(
          shifted.shift(shadow.offset).inflate(shadow.spreadRadius),
          textDirection: _configuration.textDirection,
        ),
        shadow.toPaint(),
      );
    }
    canvas.restore();
  }

  bool _actionAllowsHit(Offset position) {
    RenderObject? child = _action;
    var ancestor = child?.parent;
    while (ancestor != null && !identical(ancestor, this)) {
      if (ancestor is RenderIgnorePointer && ancestor.ignoring ||
          ancestor is RenderAbsorbPointer && ancestor.absorbing ||
          ancestor is RenderOffstage && ancestor.offstage ||
          ancestor is RenderMinimizeHost && ancestor.minimized) {
        return false;
      }
      if (ancestor is RenderBox && child != null) {
        final clip = ancestor.describeApproximatePaintClip(child);
        final local = ancestor.globalToLocal(localToGlobal(position));
        if (clip != null && !clip.contains(local)) return false;
      }
      child = ancestor;
      ancestor = ancestor.parent;
    }
    return true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (_capsule != null &&
        child != null &&
        !outline
            .getOuterPath(
              _outlineRect,
              textDirection: _configuration.textDirection,
            )
            .contains(position)) {
      return false;
    }
    // The raised action paints above the bar's own box, where its ancestors
    // up to here would reject the pointer, so test it directly.
    final button = _action?._lifted ?? false ? _action!.child : null;
    if (button != null && button.hasSize && _actionAllowsHit(position)) {
      final hit = result.addWithPaintTransform(
        transform: button.getTransformTo(this),
        position: position,
        hitTest: (result, local) =>
            (Offset.zero & button.size).contains(local) &&
            button.hitTest(result, position: local),
      );
      if (hit) {
        var ancestor = button.parent;
        while (ancestor != null && !identical(ancestor, this)) {
          if (ancestor is RenderBox) {
            final target = ancestor;
            result.addWithPaintTransform(
              transform: target.getTransformTo(this),
              position: position,
              hitTest: (result, local) {
                result.add(BoxHitTestEntry(target, local));
                return true;
              },
            );
          }
          ancestor = ancestor.parent;
        }
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    // A minimizing bar takes pointers only inside its shrinking outline.
    if (_morph > 0 && !_outlineRect.contains(position)) return false;
    return super.hitTest(result, position: position);
  }
}

/// The centre action's slot in a row. Reserves [width] in the row; when
/// [lifted] inside a [BarSurface], it reserves the part below the bar's top
/// edge and paints its child with its top [raise] above that edge.
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
    _host?._updateAction();
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
  bool get _lifted => _lift && identical(_host?._action, this);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    var ancestor = parent;
    while (ancestor != null && ancestor is! RenderBarSurface) {
      ancestor = ancestor.parent;
    }
    final host = ancestor as RenderBarSurface?;
    if (host != null) {
      _host = host;
      host._actions.add(this);
      host._updateAction();
    }
  }

  @override
  void detach() {
    final host = _host;
    if (host != null) {
      host._actions.remove(this);
      host._updateAction();
    }
    _host = null;
    super.detach();
  }

  Offset _inlineOffset = Offset.zero;

  Offset get _childOffset {
    final host = _host;
    if (!_lifted || host == null) return _inlineOffset;
    var top = Offset.zero;
    RenderObject descendant = this;
    while (!identical(descendant, host)) {
      final ancestor = descendant.parent!;
      final transform = Matrix4.identity();
      if (ancestor is RenderMinimizeHost) {
        // The raise is a layout offset; the morph scales it with the content.
        final offset = (descendant.parentData! as BoxParentData).offset;
        transform.translateByDouble(offset.dx, offset.dy, 0, 1);
      } else {
        ancestor.applyPaintTransform(descendant, transform);
      }
      top = MatrixUtils.transformPoint(transform, top);
      descendant = ancestor;
    }
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
      Size(
        math.max(_width, child.size.width),
        _lifted ? math.max(0, child.size.height - _raise) : child.size.height,
      ),
    );
    _inlineOffset = Alignment.center.alongOffset(size - child.size as Offset);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final childSize =
        child?.getDryLayout(constraints.loosen()) ?? Size(_width, 0);
    return constraints.constrain(
      Size(
        math.max(_width, childSize.width),
        _lifted ? math.max(0, childSize.height - _raise) : childSize.height,
      ),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(_width, super.computeMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(_width, super.computeMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    0,
    super.computeMinIntrinsicHeight(width) - (_lifted ? _raise : 0),
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    0,
    super.computeMaxIntrinsicHeight(width) - (_lifted ? _raise : 0),
  );

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
