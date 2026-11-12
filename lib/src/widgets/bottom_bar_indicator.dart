import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

/// Builds a custom selection indicator at [rect].
///
/// [rect] is the animated indicator rect in the coordinates of the
/// [BottomBarItems] row. [settled] is `true` once the indicator has come to
/// rest on the selected item.
typedef BottomBarIndicatorBuilder =
    Widget Function(BuildContext context, Rect rect, bool settled);

/// The selection indicator drawn behind the selected item of a
/// [BottomBarItems] row.
///
/// Pass one to [BottomBarItems.indicator] together with
/// [BottomBarItems.selectedIndex]. The indicator slides between items on a
/// spring ([BottomBarItems.indicatorMotion]), carries its momentum into a new
/// target when the selection changes mid-flight, and jumps when the platform
/// asks for reduced motion. It paints behind the items and is excluded from
/// hit testing and semantics.
///
/// [pill], [tint] and [underline] reveal the selected look (colour and
/// `selectedIcon`) only where the indicator covers an item, so mid-flight a
/// label turns over exactly where the indicator passes. The reveal mounts an
/// item's icon and label twice, so an item whose `icon`, `selectedIcon` or
/// `label` has a [GlobalKey] skips it and is styled as selected outright.
/// Keep [GlobalKey]s out of deeper parts of item content with these styles.
///
/// Geometry is read after layout, so the indicator is placed correctly in the
/// same frame as a resize, a label change or an item insert or remove.
sealed class BottomBarIndicator {
  const BottomBarIndicator._();

  /// A solid capsule that fills the item's slot.
  ///
  /// [color] defaults to `colorScheme.primary` and [foregroundColor], the
  /// colour of the content it covers, to `colorScheme.onPrimary` (or black or
  /// white over a custom [color]). [inset] shrinks the capsule inside the
  /// slot. A null [borderRadius] gives fully rounded ends.
  ///
  /// With [stretch], the edge in the direction of travel moves first and the
  /// trailing edge follows on a slower spring, so fast moves look elastic.
  /// Neither edge overshoots its target.
  const factory BottomBarIndicator.pill({
    Color? color,
    Color? foregroundColor,
    EdgeInsetsGeometry inset,
    BorderRadiusGeometry? borderRadius,
    bool stretch,
  }) = _PillIndicator;

  /// A soft wash behind the item's slot, with the covered content in an
  /// accent colour.
  ///
  /// [color] defaults to `colorScheme.primary` at 12% opacity and
  /// [foregroundColor] to `colorScheme.primary`.
  const factory BottomBarIndicator.tint({
    Color? color,
    Color? foregroundColor,
    EdgeInsetsGeometry inset,
    BorderRadiusGeometry? borderRadius,
    bool stretch,
  }) = _TintIndicator;

  /// A bar under the item's content that stretches like a worm as it moves.
  ///
  /// Content above the bar takes [color], which defaults to
  /// `colorScheme.primary`. [thickness] defaults to 3. A null [width] matches
  /// the content width.
  const factory BottomBarIndicator.underline({
    Color? color,
    double thickness,
    double? width,
  }) = _UnderlineIndicator;

  /// A dot under the item's content that stretches into a capsule as it
  /// moves.
  ///
  /// [color] defaults to `colorScheme.primary` and [size] to 6.
  const factory BottomBarIndicator.dot({Color? color, double size}) =
      _DotIndicator;

  /// A custom indicator. [builder] runs for every animation frame and its
  /// widget is positioned at the animated rect, which follows the item's
  /// content (icon plus visible label). The widget may paint outside that
  /// rect.
  const factory BottomBarIndicator.builder(BottomBarIndicatorBuilder builder) =
      _BuilderIndicator;

  /// No indicator.
  ///
  /// Use it on [BottomBarItems.indicator] to opt a row out of the theme's
  /// [BottomBarItemThemeData.indicator].
  const factory BottomBarIndicator.none() = _NoIndicator;

  Rect _target(IndicatorGeometry geometry, TextDirection direction);

  /// The indicator's painted shape at [rect], or null if it does not paint.
  RRect? _shape(Rect rect, TextDirection direction) => null;

  Color _fill(ColorScheme colors) => colors.primary;

  /// Where covered content shows its selected look, or null when the
  /// selected item simply takes [_foreground].
  RRect? _ink(RRect shape) => null;

  void _paint(
    Canvas canvas,
    Rect rect,
    ColorScheme colors,
    TextDirection direction,
  ) {
    final shape = _shape(rect, direction);
    if (shape != null) canvas.drawRRect(shape, Paint()..color = _fill(colors));
  }

  bool get _stretch => false;

  Color? _foreground(ColorScheme colors) => null;
}

/// The colour selected content should use over [indicator], if it differs
/// from the item's default.
Color? indicatorForeground(BottomBarIndicator? indicator, ColorScheme colors) =>
    indicator?._foreground(colors);

/// The indicator a row draws: its own [row] argument, else the theme's
/// [theme] one, and null for [BottomBarIndicator.none].
BottomBarIndicator? effectiveIndicator(
  BottomBarIndicator? row,
  BottomBarIndicator? theme,
) => switch (row ?? theme) {
  _NoIndicator() => null,
  final indicator => indicator,
};

/// Whether [indicator] reveals the selected look only where it covers an
/// item.
bool indicatorInks(BottomBarIndicator? indicator) =>
    indicator?._ink(RRect.zero) != null;

Color _contrastOn(Color color) =>
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
    ? Colors.white
    : Colors.black;

final class _PillIndicator extends BottomBarIndicator {
  const _PillIndicator({
    this.color,
    this.foregroundColor,
    this.inset = const EdgeInsets.all(2),
    this.borderRadius,
    this.stretch = false,
  }) : super._();

  final Color? color;
  final Color? foregroundColor;
  final EdgeInsetsGeometry inset;
  final BorderRadiusGeometry? borderRadius;
  final bool stretch;

  @override
  bool get _stretch => stretch;

  @override
  Rect _target(IndicatorGeometry geometry, TextDirection direction) =>
      inset.resolve(direction).deflateRect(geometry.slot);

  @override
  RRect _shape(Rect rect, TextDirection direction) => switch (borderRadius) {
    null => RRect.fromRectAndRadius(
      rect,
      Radius.circular(math.max(0, rect.shortestSide / 2)),
    ),
    final radius => radius.resolve(direction).toRRect(rect),
  };

  @override
  Color _fill(ColorScheme colors) => color ?? colors.primary;

  @override
  RRect _ink(RRect shape) => shape;

  @override
  Color _foreground(ColorScheme colors) =>
      foregroundColor ??
      switch (color) {
        null => colors.onPrimary,
        final c => _contrastOn(c),
      };
}

final class _TintIndicator extends _PillIndicator {
  const _TintIndicator({
    super.color,
    super.foregroundColor,
    super.inset,
    super.borderRadius = const BorderRadius.all(Radius.circular(16)),
    super.stretch,
  });

  @override
  Color _fill(ColorScheme colors) =>
      color ?? colors.primary.withValues(alpha: 0.12);

  @override
  Color _foreground(ColorScheme colors) =>
      foregroundColor ?? color?.withValues(alpha: 1) ?? colors.primary;
}

final class _UnderlineIndicator extends BottomBarIndicator {
  const _UnderlineIndicator({this.color, this.thickness = 3, this.width})
    : super._();

  final Color? color;
  final double thickness;
  final double? width;

  @override
  bool get _stretch => true;

  @override
  Rect _target(IndicatorGeometry geometry, TextDirection direction) {
    final content = geometry.content;
    final w = width ?? content.width;
    return Rect.fromLTWH(
      content.center.dx - w / 2,
      content.bottom + 4,
      w,
      thickness,
    );
  }

  @override
  RRect _shape(Rect rect, TextDirection direction) =>
      RRect.fromRectAndRadius(rect, Radius.circular(thickness / 2));

  @override
  Color _fill(ColorScheme colors) => color ?? colors.primary;

  /// A column through the bar, so content above it takes the bar's colour.
  @override
  RRect _ink(RRect shape) =>
      RRect.fromLTRBR(shape.left, -1e5, shape.right, 1e5, Radius.zero);

  @override
  Color _foreground(ColorScheme colors) => color ?? colors.primary;
}

final class _DotIndicator extends BottomBarIndicator {
  const _DotIndicator({this.color, this.size = 6}) : super._();

  final Color? color;
  final double size;

  @override
  bool get _stretch => true;

  @override
  Rect _target(IndicatorGeometry geometry, TextDirection direction) =>
      Rect.fromCenter(
        center: Offset(
          geometry.icon.center.dx,
          geometry.content.bottom + 4 + size / 2,
        ),
        width: size,
        height: size,
      );

  @override
  RRect _shape(Rect rect, TextDirection direction) =>
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2));

  @override
  Color _fill(ColorScheme colors) => color ?? colors.primary;
}

final class _NoIndicator extends BottomBarIndicator {
  const _NoIndicator() : super._();

  @override
  Rect _target(IndicatorGeometry geometry, TextDirection direction) =>
      geometry.slot;
}

final class _BuilderIndicator extends BottomBarIndicator {
  const _BuilderIndicator(this.builder) : super._();

  final BottomBarIndicatorBuilder builder;

  @override
  Rect _target(IndicatorGeometry geometry, TextDirection direction) =>
      geometry.content;
}

/// Where one item sits in the row, in the row's coordinates.
typedef IndicatorGeometry = ({Rect slot, Rect content, Rect icon});

/// What an [IndicatorAnchor] marks inside a [BottomBarItems] row.
enum IndicatorAnchorRole { slot, icon, label }

/// Marks a box whose geometry the selection indicator follows.
class IndicatorAnchor extends SingleChildRenderObjectWidget {
  const IndicatorAnchor({super.key, required this.role, super.child});

  final IndicatorAnchorRole role;

  @override
  RenderIndicatorAnchor createRenderObject(BuildContext context) =>
      RenderIndicatorAnchor(role);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderIndicatorAnchor renderObject,
  ) {
    renderObject.role = role;
  }
}

class RenderIndicatorAnchor extends RenderProxyBox {
  RenderIndicatorAnchor(this.role);

  IndicatorAnchorRole role;

  // Recorded here because an ancestor may not read a grandchild's size
  // during its own layout.
  Size _laidOutSize = Size.zero;

  @override
  void markNeedsLayout() {
    final ancestors = <RenderObject>[];
    RenderObject? track = parent;
    while (track != null && track is! RenderIndicatorTrack) {
      ancestors.add(track);
      track = track.parent;
    }
    super.markNeedsLayout();
    if (track is RenderIndicatorTrack && !track._layingOutRow) {
      for (final ancestor in ancestors) {
        ancestor.markNeedsLayout();
      }
      track.markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    super.performLayout();
    _laidOutSize = size;
  }
}

double _edge(Rect rect, int edge) => switch (edge) {
  0 => rect.left,
  1 => rect.top,
  2 => rect.right,
  _ => rect.bottom,
};

/// The indicator's spring state.
///
/// Each edge of the indicator (left, top, right, bottom) moves from a
/// weighted blend of item rects toward the selected item's rect. The weights
/// refer to items by index and resolve against the latest geometry, so a
/// resize or a label change mid-flight never leaves the indicator behind.
/// Retargeting folds the current position into a new blend and carries the
/// edges' velocity over.
class IndicatorMotion extends ChangeNotifier {
  IndicatorMotion({
    required TickerProvider vsync,
    required int index,
    required Motion motion,
  }) : _to = index,
       _lead = SingleMotionController(
         motion: motion,
         vsync: vsync,
         initialValue: 1,
       ),
       _trail = SingleMotionController(
         motion: _trailFor(motion),
         vsync: vsync,
         initialValue: 1,
       ) {
    _from = List.generate(4, (_) => {index: 1.0});
    _reveal = (index: index, animated: false);
    _lead.addListener(notifyListeners);
    _trail.addListener(notifyListeners);
  }

  final SingleMotionController _lead;
  final SingleMotionController _trail;
  late final List<Map<int, double>> _from;
  final List<bool> _trails = List.filled(4, false);
  int _to;
  double? _dragX;
  List<Rect> _rects = const [];
  ({int index, bool animated})? _reveal;
  int _revealRevision = 0;

  /// Whether a stretching indicator is in use: one edge leads, the other
  /// trails, and neither overshoots.
  bool _stretch = false;
  bool get stretch => _stretch;
  set stretch(bool value) {
    if (value == _stretch) return;
    if (settled || !_covers(_rects)) {
      _stretch = value;
      _trails.fillRange(0, _trails.length, false);
      return;
    }
    _retarget(_to, stretch: value, reveal: false, dragX: _dragX);
  }

  set indicator(BottomBarIndicator? value) =>
      stretch = value?._stretch ?? false;

  set motion(Motion value) {
    if (_lead.motion == value) return;
    _lead.motion = value;
    _trail.motion = _trailFor(value);
  }

  static Motion _trailFor(Motion lead) => lead is CupertinoMotion
      ? CupertinoMotion(duration: lead.duration * 1.6)
      : const CupertinoMotion.smooth(duration: Duration(milliseconds: 700));

  bool get settled =>
      _dragX == null && !_lead.isAnimating && !_trail.isAnimating;

  /// The selected index the indicator rests on or springs to.
  int get target => _to;

  /// Whether the indicator follows a drag.
  bool get dragging => _dragX != null;

  SingleMotionController _controller(int edge) =>
      _trails[edge] ? _trail : _lead;

  double _progress(int edge) {
    final controller = _controller(edge);
    if (!controller.isAnimating) return 1;
    final value = controller.value;
    return stretch ? math.min(value, 1) : value;
  }

  double _velocity(int edge) {
    final controller = _controller(edge);
    if (!controller.isAnimating) return 0;
    return stretch && controller.value >= 1 ? 0 : controller.velocity;
  }

  bool _covers(List<Rect> rects) =>
      _to >= 0 &&
      _to < rects.length &&
      _from.every(
        (blend) => blend.keys.every((i) => i >= 0 && i < rects.length),
      );

  static double _blend(Map<int, double> blend, int edge, List<Rect> rects) {
    var sum = 0.0;
    blend.forEach((i, weight) => sum += weight * _edge(rects[i], edge));
    return sum;
  }

  /// Where a drag at [x] sits, as a fractional item index clamped to the
  /// row. Works in either text direction because it follows item centres.
  static double? _position(double x, List<Rect> rects) {
    if (rects.isEmpty) return null;
    for (var i = 0; i < rects.length - 1; i++) {
      final a = rects[i].center.dx;
      final b = rects[i + 1].center.dx;
      if (a != b && (x - a) * (x - b) <= 0) return i + (x - a) / (b - a);
    }
    final first = (x - rects.first.center.dx).abs();
    final last = (x - rects.last.center.dx).abs();
    return first <= last ? 0 : rects.length - 1.0;
  }

  /// The blend the indicator heads for: the selected item, or the drag
  /// position between the two items around it.
  Map<int, double> _target(List<Rect> rects, [double? x]) {
    x ??= _dragX;
    final position = x == null ? null : _position(x, rects);
    if (position == null) return {_to: 1};
    final lo = position.floor();
    final f = position - lo;
    return {lo: 1 - f, if (f > 0) lo + 1: f};
  }

  double _value(int edge, List<Rect> rects, Map<int, double> target) {
    final from = _blend(_from[edge], edge, rects);
    return from + (_blend(target, edge, rects) - from) * _progress(edge);
  }

  /// The item nearest [x] in the latest geometry, or null before layout.
  int? indexAt(double x) => _position(x, _rects)?.round();

  /// The indicator rect for the item [rects], or null when the selected
  /// index has no item.
  Rect? resolve(List<Rect> rects) {
    _rects = rects;
    if (_to < 0 || _to >= rects.length) return null;
    if (settled || !_covers(rects)) return rects[_to];
    final target = _target(rects);
    final rect = Rect.fromLTRB(
      _value(0, rects, target),
      _value(1, rects, target),
      _value(2, rects, target),
      _value(3, rects, target),
    );
    if (rect.width >= 0 && rect.height >= 0) return rect;
    return Rect.fromCenter(
      center: rect.center,
      width: math.max(0, rect.width),
      height: math.max(0, rect.height),
    );
  }

  /// Places the indicator on [index] without animating.
  void jumpTo(int index) {
    _to = index;
    _dragX = null;
    for (var edge = 0; edge < 4; edge++) {
      _from[edge] = {index: 1.0};
    }
    _reveal = (index: index, animated: false);
    _revealRevision++;
    _trail.value = 1;
    _lead.value = 1;
    notifyListeners();
  }

  /// Springs the indicator to [index], carrying its current velocity
  /// projected onto the new direction of travel.
  void animateTo(int index) {
    if (index == _to && !dragging) return;
    _retarget(index);
  }

  /// Moves the indicator toward a drag at [x], in the row's coordinates.
  ///
  /// The first call springs it from where it is to the finger, later calls
  /// track the finger exactly. Between items it blends their rects, and it
  /// stays within the row.
  void follow(double x) {
    if (_dragX == null) {
      _retarget(_to, reveal: false, dragX: x);
    } else if (x != _dragX) {
      _dragX = x;
      notifyListeners();
    }
  }

  /// Ends a drag and springs the indicator to [index], carrying the finger's
  /// horizontal [velocity] in logical pixels per second.
  void release(int index, {double velocity = 0}) {
    if (_dragX == null) {
      animateTo(index);
    } else {
      _retarget(index, fingerVelocity: velocity);
    }
  }

  void _retarget(
    int index, {
    bool? stretch,
    bool reveal = true,
    double? dragX,
    double fingerVelocity = 0,
  }) {
    final rects = _rects;
    if (index < 0 || index >= rects.length || !_covers(rects)) {
      jumpTo(index);
      _dragX = dragX;
      return;
    }

    final current = List<double>.filled(4, 0);
    final velocity = List<double>.filled(4, 0);
    final heading = _target(rects);
    final step = fingerVelocity.sign;
    final ahead = _dragX == null || step == 0
        ? heading
        : _target(rects, _dragX! + step);
    for (var edge = 0; edge < 4; edge++) {
      final p = _progress(edge);
      final from = _blend(_from[edge], edge, rects);
      final to = _blend(heading, edge, rects);
      final fingerEdge =
          (_blend(ahead, edge, rects) - to) * fingerVelocity.abs();
      current[edge] = from + (to - from) * p;
      velocity[edge] = _velocity(edge) * (to - from) + fingerEdge * p;
      _from[edge] =
          {
              for (final MapEntry(:key, :value) in _from[edge].entries)
                key: value * (1 - p),
            }
            ..addAll({
              for (final MapEntry(:key, :value) in heading.entries)
                key: (_from[edge][key] ?? 0) * (1 - p) + value * p,
            })
            ..removeWhere((_, w) => w.abs() < 1e-9);
    }

    _to = index;
    _dragX = dragX;
    if (stretch != null) _stretch = stretch;
    final goal = _target(rects);
    final target = Rect.fromLTRB(
      _blend(goal, 0, rects),
      _blend(goal, 1, rects),
      _blend(goal, 2, rects),
      _blend(goal, 3, rects),
    );
    final travel = target.center.dx - (current[0] + current[2]) / 2;
    _trails
      ..[0] = _stretch && travel > 0
      ..[2] = _stretch && travel < 0;

    if (reveal) {
      _reveal = (index: index, animated: true);
      _revealRevision++;
    }

    for (final (controller, trailing) in [(_lead, false), (_trail, true)]) {
      var dot = 0.0;
      var span = 0.0;
      for (var edge = 0; edge < 4; edge++) {
        if (_trails[edge] != trailing) continue;
        final distance = _edge(target, edge) - current[edge];
        dot += velocity[edge] * distance;
        span += distance * distance;
      }
      var start = 0.0;
      if (!_stretch && fingerVelocity != 0 && span <= 1e-6) {
        // A nonzero blend basis carries momentum even at the exact target.
        dot = 0;
        span = 0;
        for (var edge = 0; edge < 4; edge++) {
          if (_trails[edge] != trailing) continue;
          _from[edge] = {
            for (final key in {...goal.keys, ...heading.keys, ...ahead.keys})
              key: (goal[key] ?? 0) + (heading[key] ?? 0) - (ahead[key] ?? 0),
          }..removeWhere((_, weight) => weight.abs() < 1e-9);
          final distance =
              _edge(target, edge) - _blend(_from[edge], edge, rects);
          dot += velocity[edge] * distance;
          span += distance * distance;
        }
        start = 1;
      }
      if (trailing && !_trails.contains(true)) {
        controller.value = 1;
      } else {
        controller.animateTo(
          1,
          from: start,
          withVelocity: span > 1e-6 ? dot / span : 0,
        );
      }
    }
  }

  ({int index, bool animated})? _takeReveal() {
    final reveal = _reveal;
    _reveal = null;
    return reveal;
  }

  @override
  void dispose() {
    _lead.dispose();
    _trail.dispose();
    super.dispose();
  }
}

/// Box constraints that also carry the builder indicator's frame, so the
/// layout-time builder reruns whenever the animated rect changes.
class _FrameConstraints extends BoxConstraints {
  _FrameConstraints(super.size, this.rect, this.settled) : super.tight();

  final Rect? rect;
  final bool settled;

  @override
  bool operator ==(Object other) =>
      other is _FrameConstraints &&
      super == other &&
      other.rect == rect &&
      other.settled == settled;

  @override
  int get hashCode => Object.hash(super.hashCode, rect, settled);
}

/// Paints [indicator] behind [row] at the item geometry read after layout.
class IndicatorTrack extends MultiChildRenderObjectWidget {
  IndicatorTrack({
    super.key,
    required this.motion,
    required this.indicator,
    required this.reveal,
    required Widget row,
  }) : super(children: [_layer(indicator), row]);

  final IndicatorMotion motion;
  final BottomBarIndicator indicator;

  /// Whether selecting an item scrolls it into view.
  final bool reveal;

  static Widget _layer(BottomBarIndicator indicator) => IgnorePointer(
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (indicator is! _BuilderIndicator ||
              constraints is! _FrameConstraints) {
            return const SizedBox.shrink();
          }
          final rect = constraints.rect;
          if (rect == null) return const SizedBox.shrink();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: rect,
                child: indicator.builder(context, rect, constraints.settled),
              ),
            ],
          );
        },
      ),
    ),
  );

  @override
  RenderIndicatorTrack createRenderObject(BuildContext context) =>
      RenderIndicatorTrack(
        motion: motion,
        indicator: indicator,
        reveal: reveal,
        colors: Theme.of(context).colorScheme,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderIndicatorTrack renderObject,
  ) {
    renderObject
      ..motion = motion
      ..indicator = indicator
      ..reveal = reveal
      ..colors = Theme.of(context).colorScheme
      ..textDirection = Directionality.of(context);
  }
}

/// Paints [child] only where the row's indicator covers it.
///
/// [BottomBarItem] stacks its selected look under this over its plain look,
/// so the selected colour follows the indicator mid-flight.
class IndicatorInk extends SingleChildRenderObjectWidget {
  const IndicatorInk({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderInk();
}

class _RenderInk extends RenderProxyBox {
  RenderIndicatorTrack? _track;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    RenderObject? ancestor = parent;
    while (ancestor != null && ancestor is! RenderIndicatorTrack) {
      ancestor = ancestor.parent;
    }
    _track = ancestor as RenderIndicatorTrack?;
    _track?._inks.add(this);
  }

  @override
  void detach() {
    _track?._inks.remove(this);
    _track = null;
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final track = _track;
    final ink = track?._resolveInk();
    final inverse = track == null
        ? null
        : Matrix4.tryInvert(getTransformTo(track));
    final clip = ink == null || inverse == null
        ? null
        : (Path()..addRRect(ink)).transform(inverse.storage);
    if (child == null ||
        clip == null ||
        !clip.getBounds().overlaps(Offset.zero & size)) {
      layer = null;
      return;
    }
    final translation = MatrixUtils.getAsTranslation(getTransformTo(track));
    if (translation != null) {
      layer = context.pushClipRRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        ink!.shift(-translation),
        super.paint,
        oldLayer: layer is ClipRRectLayer ? layer as ClipRRectLayer : null,
      );
      return;
    }
    layer = context.pushClipPath(
      needsCompositing,
      offset,
      Offset.zero & size,
      clip,
      super.paint,
      oldLayer: layer is ClipPathLayer ? layer as ClipPathLayer : null,
    );
  }
}

class _TrackParentData extends ContainerBoxParentData<RenderBox> {}

class RenderIndicatorTrack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TrackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TrackParentData> {
  RenderIndicatorTrack({
    required this._motion,
    required this._indicator,
    required this._reveal,
    required this._colors,
    required this._textDirection,
  });

  IndicatorMotion _motion;
  set motion(IndicatorMotion value) {
    if (identical(value, _motion)) return;
    if (attached) _motion.removeListener(_onTick);
    _motion = value;
    _needsInitialReveal = true;
    _revealGeneration++;
    if (attached) _motion.addListener(_onTick);
    markNeedsLayout();
  }

  BottomBarIndicator _indicator;
  set indicator(BottomBarIndicator value) {
    if (identical(value, _indicator)) return;
    _indicator = value;
    if (_observesGeometry) {
      _observeGeometry();
    } else {
      _cancelGeometryObservation();
    }
    markNeedsLayout();
  }

  bool _reveal;
  set reveal(bool value) {
    if (value == _reveal) return;
    _reveal = value;
    _needsInitialReveal = true;
    _revealGeneration++;
    markNeedsLayout();
  }

  ColorScheme _colors;
  set colors(ColorScheme value) {
    if (value == _colors) return;
    _colors = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Rect? _builderRect;
  bool _layingOutRow = false;
  bool _needsInitialReveal = true;
  ({int index, Rect rect})? _revealedSlot;
  int _revealGeneration = 0;
  int? _geometryFrameCallback;

  bool get _usesBuilder => _indicator is _BuilderIndicator;

  RenderBox get _layer => firstChild!;
  RenderBox get _row => lastChild!;

  final Set<_RenderInk> _inks = {};

  bool get _observesGeometry => _usesBuilder || indicatorInks(_indicator);

  void _invalidateInk() {
    for (final ink in _inks) {
      ink.markNeedsPaint();
    }
  }

  void _onTick() {
    _invalidateInk();
    if (_usesBuilder || _motion._reveal != null) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  void _observeGeometry() {
    if (!attached || !_observesGeometry || _geometryFrameCallback != null) {
      return;
    }
    // Descendant paint-only transforms need not dirty any ancestor outside
    // their repaint boundary. Observe frames without requesting idle frames.
    _geometryFrameCallback = SchedulerBinding.instance.scheduleFrameCallback((
      _,
    ) {
      _geometryFrameCallback = null;
      if (!attached || !_observesGeometry) return;
      markNeedsLayout();
      _observeGeometry();
    }, scheduleNewFrame: false);
  }

  void _cancelGeometryObservation() {
    final callback = _geometryFrameCallback;
    if (callback == null) return;
    SchedulerBinding.instance.cancelFrameCallbackWithId(callback);
    _geometryFrameCallback = null;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TrackParentData) {
      child.parentData = _TrackParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _motion.addListener(_onTick);
    _observeGeometry();
  }

  @override
  void detach() {
    _revealGeneration++;
    _needsInitialReveal = true;
    _cancelGeometryObservation();
    _motion.removeListener(_onTick);
    super.detach();
  }

  Rect _rectOf(RenderIndicatorAnchor anchor) => MatrixUtils.transformRect(
    anchor.getTransformTo(this),
    Offset.zero & anchor._laidOutSize,
  );

  List<RenderIndicatorAnchor> get _slots {
    final slots = <RenderIndicatorAnchor>[];
    void visit(RenderObject child) {
      if (child is RenderIndicatorAnchor &&
          child.role == IndicatorAnchorRole.slot) {
        slots.add(child);
        return;
      }
      child.visitChildren(visit);
    }

    visit(_row);
    return slots;
  }

  IndicatorGeometry _geometry(RenderIndicatorAnchor slot) {
    RenderIndicatorAnchor? icon;
    RenderIndicatorAnchor? label;
    void visit(RenderObject node) {
      if (node is RenderIndicatorAnchor) {
        switch (node.role) {
          case IndicatorAnchorRole.icon:
            icon ??= node;
          case IndicatorAnchorRole.label:
            label ??= node;
          case IndicatorAnchorRole.slot:
            break;
        }
      }
      node.visitChildren(visit);
    }

    slot.visitChildren(visit);
    final slotRect = _rectOf(slot);
    final iconRect = icon == null ? slotRect : _rectOf(icon!);
    return (
      slot: slotRect,
      icon: iconRect,
      content: label == null
          ? iconRect
          : iconRect.expandToInclude(_rectOf(label!)),
    );
  }

  Rect? _resolve() => _motion.resolve([
    for (final slot in _slots)
      _indicator._target(_geometry(slot), _textDirection),
  ]);

  @override
  void performLayout() {
    final row = _row;
    _layingOutRow = true;
    try {
      row.layout(constraints.loosen(), parentUsesSize: true);
    } finally {
      _layingOutRow = false;
    }
    size = constraints.constrain(row.size);
    (row.parentData! as _TrackParentData).offset = Alignment.center.alongOffset(
      size - row.size as Offset,
    );

    _builderRect = null;
    if (_usesBuilder) {
      invokeLayoutCallback<BoxConstraints>((_) {
        _builderRect = _resolve();
      });
    }
    _layer.layout(
      _usesBuilder
          ? _FrameConstraints(size, _builderRect, _motion.settled)
          : BoxConstraints.tight(size),
    );

    _invalidateInk();
    final motion = _motion;
    final slots = _reveal ? _slots : const <RenderIndicatorAnchor>[];
    final slot = motion._to >= 0 && motion._to < slots.length
        ? (index: motion._to, rect: _rectOf(slots[motion._to]))
        : null;
    final resized =
        slot != null &&
        _revealedSlot?.index == slot.index &&
        _revealedSlot?.rect != slot.rect;
    _revealedSlot = slot;
    final reveal =
        motion._takeReveal() ??
        (_reveal && (_needsInitialReveal || resized)
            ? (index: motion._to, animated: false)
            : null);
    final revision = motion._revealRevision;
    final generation = _revealGeneration;
    if (_reveal && reveal != null) {
      _needsInitialReveal = false;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!attached ||
            !_reveal ||
            _revealGeneration != generation ||
            !identical(motion, _motion) ||
            motion._revealRevision != revision ||
            reveal.index != motion._to) {
          return;
        }
        final slots = _slots;
        if (reveal.index < 0 || reveal.index >= slots.length) return;
        slots[reveal.index].showOnScreen(
          duration: reveal.animated
              ? const Duration(milliseconds: 350)
              : Duration.zero,
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  RRect? _resolveInk() {
    final rect = _resolve();
    final shape = rect == null ? null : _indicator._shape(rect, _textDirection);
    return shape == null ? null : _indicator._ink(shape);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = _resolve();
    if (rect != null) {
      _indicator._paint(
        context.canvas,
        rect.shift(offset),
        _colors,
        _textDirection,
      );
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_row.getDryLayout(constraints.loosen()));

  @override
  double computeMinIntrinsicWidth(double height) =>
      _row.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _row.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _row.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _row.getMaxIntrinsicHeight(width);
}
