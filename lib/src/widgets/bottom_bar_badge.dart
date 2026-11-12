import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../internal/item_theme_scope.dart';
import '../internal/reduce_motion.dart';
import 'bottom_bar_item_theme.dart';

enum _Kind { dot, count, label }

/// An animated badge for [BottomBarItem.badge]: a dot, a count or a short
/// label on the icon's top-end corner.
///
/// ```dart
/// BottomBarItem(
///   icon: const Icon(Icons.inbox_outlined),
///   label: const Text('Inbox'),
///   badge: BottomBarBadge.count(unread, semanticLabel: '$unread new'),
/// )
/// ```
///
/// The badge scales in from its anchor with a slight overshoot and scales
/// out before it goes away. A count rolls its digits up when it grows and
/// down when it shrinks, and the badge width follows the text. Reduced
/// motion snaps every change.
///
/// Hide a badge with `show: false` or a count of 0, not by passing a null
/// `badge`, so the out animation can play.
///
/// The item adds the badge's [semanticLabel] to its accessible name, as in
/// "Inbox, 3 new". Without one, a count announces the text it shows ("3",
/// "99+"), a label announces its text and a dot announces nothing. To
/// localize, pass a translated [semanticLabel], such as
/// `AppLocalizations.of(context).unreadMessages(count)`.
///
/// Styled by [BottomBarBadgeThemeData], set as
/// [BottomBarItemThemeData.badge]. Arguments here win over the theme.
class BottomBarBadge extends StatefulWidget {
  /// A small dot, 6 by 6 by default.
  const BottomBarBadge.dot({
    super.key,
    bool show = true,
    Color? color,
    this.outline,
    this.offset,
    this.semanticLabel,
  }) : _kind = _Kind.dot,
       _text = null,
       _count = null,
       _visible = show,
       backgroundColor = color,
       textStyle = null;

  /// A count, shown as "[max]+" above [max] and hidden at 0 unless
  /// [showZero] is true.
  const BottomBarBadge.count(
    int count, {
    super.key,
    int max = 99,
    bool showZero = false,
    this.backgroundColor,
    this.textStyle,
    this.outline,
    this.offset,
    this.semanticLabel,
  }) : assert(count >= 0, 'count must not be negative'),
       assert(max > 0, 'max must be positive'),
       _kind = _Kind.count,
       _count = count,
       _text = count > max ? '$max+' : '$count',
       _visible = count > 0 || showZero;

  /// A short label such as "New". Hidden when [text] is empty.
  const BottomBarBadge.label(
    String text, {
    super.key,
    bool show = true,
    this.backgroundColor,
    this.textStyle,
    this.outline,
    this.offset,
    this.semanticLabel,
  }) : _kind = _Kind.label,
       _count = null,
       _text = text,
       _visible = show && text != '';

  final _Kind _kind;
  final String? _text;
  final int? _count;
  final bool _visible;

  /// Fill colour. Defaults to [BottomBarBadgeThemeData.backgroundColor], then
  /// `colorScheme.error`.
  final Color? backgroundColor;

  /// Text style, merged over the theme's. Defaults to `textTheme.labelSmall`
  /// in `colorScheme.onError`.
  final TextStyle? textStyle;

  /// A ring around the badge that separates it from the icon, drawn outside
  /// the badge. Defaults to the theme's outline, and none without one.
  final BorderSide? outline;

  /// Shift from the default spot. Positive x moves toward the item's end,
  /// positive y moves down. Defaults to [BottomBarBadgeThemeData.offset].
  final Offset? offset;

  /// What a screen reader reads for this badge, after the item's name.
  final String? semanticLabel;

  @override
  State<BottomBarBadge> createState() => _BottomBarBadgeState();
}

/// What [badge] adds to its item's accessible name, or null for nothing.
String? badgeSemanticsLabel(BottomBarBadge badge) {
  if (!badge._visible) return null;
  final label = badge.semanticLabel;
  if (label != null) return label.isEmpty ? null : label;
  return badge._text;
}

/// Defaults for every [BottomBarBadge] below a theme. Set it as
/// [BottomBarItemThemeData.badge].
///
/// Every field is optional. A null field keeps the Material 3 look.
@immutable
class BottomBarBadgeThemeData {
  /// Creates a [BottomBarBadgeThemeData].
  const BottomBarBadgeThemeData({
    this.backgroundColor,
    this.textColor,
    this.textStyle,
    this.dotSize,
    this.height,
    this.padding,
    this.offset,
    this.outlineColor,
    this.outlineWidth,
    this.motion,
  });

  /// Fill colour. Defaults to `colorScheme.error`.
  final Color? backgroundColor;

  /// Text colour. Defaults to `colorScheme.onError`.
  final Color? textColor;

  /// Text style, merged over `textTheme.labelSmall`.
  final TextStyle? textStyle;

  /// Diameter of a dot badge. Defaults to 6.
  final double? dotSize;

  /// Height of a count or label badge, and its minimum width. Defaults to
  /// 16. Large text grows it.
  final double? height;

  /// Space around the text of a count or label badge. Only the horizontal
  /// part applies. Defaults to 4 on each side.
  final EdgeInsetsGeometry? padding;

  /// Shift from the default spot. Positive x moves toward the item's end,
  /// positive y moves down. Defaults to none.
  final Offset? offset;

  /// Ring colour. Defaults to `colorScheme.surface`.
  final Color? outlineColor;

  /// Ring width. Defaults to 0, which draws no ring.
  final double? outlineWidth;

  /// The spring for appearing, disappearing, rolling digits and resizing.
  ///
  /// Defaults to a snappy Cupertino spring with a slight overshoot.
  final Motion? motion;

  /// Returns a theme where the non-null fields of [other] override this one.
  BottomBarBadgeThemeData merge(BottomBarBadgeThemeData? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      textColor: other.textColor,
      textStyle: other.textStyle,
      dotSize: other.dotSize,
      height: other.height,
      padding: other.padding,
      offset: other.offset,
      outlineColor: other.outlineColor,
      outlineWidth: other.outlineWidth,
      motion: other.motion,
    );
  }

  /// Returns a copy with the given non-null fields replaced.
  BottomBarBadgeThemeData copyWith({
    Color? backgroundColor,
    Color? textColor,
    TextStyle? textStyle,
    double? dotSize,
    double? height,
    EdgeInsetsGeometry? padding,
    Offset? offset,
    Color? outlineColor,
    double? outlineWidth,
    Motion? motion,
  }) {
    return BottomBarBadgeThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      textStyle: textStyle ?? this.textStyle,
      dotSize: dotSize ?? this.dotSize,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      offset: offset ?? this.offset,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      motion: motion ?? this.motion,
    );
  }

  /// Linearly interpolates between [a] and [b]. [motion] switches at
  /// `t == 0.5`.
  static BottomBarBadgeThemeData? lerp(
    BottomBarBadgeThemeData? a,
    BottomBarBadgeThemeData? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    a ??= const BottomBarBadgeThemeData();
    b ??= const BottomBarBadgeThemeData();
    return BottomBarBadgeThemeData(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      textColor: Color.lerp(a.textColor, b.textColor, t),
      textStyle: lerpLabelStyle(a.textStyle, b.textStyle, t),
      dotSize: lerpDouble(a.dotSize, b.dotSize, t),
      height: lerpDouble(a.height, b.height, t),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      offset: Offset.lerp(a.offset, b.offset, t),
      outlineColor: Color.lerp(a.outlineColor, b.outlineColor, t),
      outlineWidth: lerpDouble(a.outlineWidth, b.outlineWidth, t),
      motion: t < 0.5 ? a.motion : b.motion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarBadgeThemeData &&
        other.backgroundColor == backgroundColor &&
        other.textColor == textColor &&
        other.textStyle == textStyle &&
        other.dotSize == dotSize &&
        other.height == height &&
        other.padding == padding &&
        other.offset == offset &&
        other.outlineColor == outlineColor &&
        other.outlineWidth == outlineWidth &&
        other.motion == motion;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    textColor,
    textStyle,
    dotSize,
    height,
    padding,
    offset,
    outlineColor,
    outlineWidth,
    motion,
  );
}

/// The badge's look after per-badge arguments, the theme and the defaults.
class _Look {
  _Look(BuildContext context, BottomBarBadge badge) {
    final cs = Theme.of(context).colorScheme;
    final theme = itemThemeOf(context).badge ?? const BottomBarBadgeThemeData();
    final textColor = theme.textColor;
    dot = badge._kind == _Kind.dot;
    background = badge.backgroundColor ?? theme.backgroundColor ?? cs.error;
    style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
        .copyWith(color: cs.onError)
        .merge(theme.textStyle)
        .merge(textColor == null ? null : TextStyle(color: textColor))
        .merge(badge.textStyle);
    final outlineWidth = theme.outlineWidth ?? 0;
    outline =
        badge.outline ??
        (outlineWidth > 0
            ? BorderSide(
                color: theme.outlineColor ?? cs.surface,
                width: outlineWidth,
              )
            : BorderSide.none);
    offset = badge.offset ?? theme.offset ?? Offset.zero;
    dotSize = theme.dotSize ?? 6;
    minHeight = theme.height ?? 16;
    padding = (theme.padding ?? const EdgeInsets.symmetric(horizontal: 4))
        .resolve(Directionality.of(context))
        .horizontal;
    motion = theme.motion ?? _defaultMotion;
    textScaler = MediaQuery.textScalerOf(context);
    direction = Directionality.of(context);
  }

  static const _defaultMotion = CupertinoMotion.snappy(
    duration: Duration(milliseconds: 400),
  );

  late final bool dot;
  late final Color background;
  late final TextStyle style;
  late final BorderSide outline;
  late final Offset offset;
  late final double dotSize;
  late final double minHeight;
  late final double padding;
  late final Motion motion;
  late final TextScaler textScaler;
  late final TextDirection direction;

  Size size(String? text) {
    if (dot || text == null) return Size.square(dotSize);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final height = math.max(minHeight, painter.height);
    final size = Size(math.max(height, painter.width + padding), height);
    painter.dispose();
    return size;
  }
}

class _BottomBarBadgeState extends State<BottomBarBadge>
    with TickerProviderStateMixin {
  /// 0 hidden, 1 shown. Overshoots on the way in.
  SingleMotionController? _presence;

  /// Roll progress from [_from] to [_to]. Values below 0 or above 1 keep a
  /// retargeted roll continuous.
  SingleMotionController? _roll;

  /// Badge width in logical pixels.
  SingleMotionController? _width;

  bool? _shown;
  Size? _size;
  double? _widthTarget;
  String? _from;
  String? _to;
  int? _toCount;

  /// 1 rolls the new text up from below, -1 rolls it down from above.
  int _direction = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BottomBarBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _presence?.dispose();
    _roll?.dispose();
    _width?.dispose();
    super.dispose();
  }

  void _sync() {
    final look = _Look(context, widget);
    final reduced = reduceMotion(context);
    final visible = widget._visible;
    final presence = _presence ??= SingleMotionController(
      motion: look.motion,
      vsync: this,
      initialValue: visible ? 1 : 0,
    );
    final roll = _roll ??= SingleMotionController(
      motion: look.motion,
      vsync: this,
      initialValue: 1,
    );
    final firstSync = _shown == null;
    final wasHidden = !(_shown ?? false) && !presence.isAnimating;
    presence.motion = look.motion;
    roll.motion = look.motion;

    final text = widget._text;
    if (visible || firstSync) {
      if (text == null) {
        if (_to != null) _setText(null, null);
      } else if (text != _to) {
        if (reduced || wasHidden || _to == null) {
          _setText(text, widget._count);
        } else {
          _rollTo(text, widget._count);
        }
      }
    }

    if (_shown != visible) {
      _shown = visible;
      if (reduced) {
        presence.value = visible ? 1 : 0;
      } else {
        presence.animateTo(visible ? 1 : 0);
      }
    } else if (reduced && presence.isAnimating) {
      presence.value = visible ? 1 : 0;
    }
    if (reduced && roll.isAnimating) _setText(_to, _toCount);

    final size = _size = look.size(_to);
    final width = size.width;
    final widthController = _width ??= SingleMotionController(
      motion: look.motion,
      vsync: this,
      initialValue: width,
    );
    widthController.motion = look.motion;
    if (reduced || wasHidden) {
      if (widthController.value != width) widthController.value = width;
    } else if (_widthTarget != width) {
      widthController.animateTo(width);
    }
    _widthTarget = width;
  }

  void _setText(String? text, int? count) {
    _from = null;
    _to = text;
    _toCount = count;
    _roll!.value = 1;
  }

  /// Starts or retargets the roll so every visible layer keeps its place.
  void _rollTo(String text, int? count) {
    final roll = _roll!;
    final previous = _toCount;
    final direction = count != null && previous != null && count < previous
        ? -1
        : 1;
    if (!roll.isAnimating) {
      _from = _to;
      _to = text;
      _toCount = count;
      _direction = direction;
      roll.animateTo(1, from: 0);
      return;
    }
    final v = roll.value;
    final velocity = roll.velocity;
    if (direction != _direction) {
      // The incoming text turns back into the outgoing one, and the new text
      // takes the place of the old outgoing text.
      _from = _to;
      _to = text;
      _toCount = count;
      _direction = direction;
      roll.animateTo(1, from: 1 - v, withVelocity: -velocity);
    } else if (v < 0.5) {
      // The incoming text is still mostly out of view: swap it.
      _to = text;
      _toCount = count;
    } else {
      // The outgoing text is mostly gone: drop it, and the incoming text
      // starts to leave from where it is.
      _from = _to;
      _to = text;
      _toCount = count;
      roll.animateTo(1, from: v - 1);
    }
  }

  static double _settled(SingleMotionController controller, double target) =>
      controller.isAnimating ? controller.value : target;

  @override
  Widget build(BuildContext context) {
    final look = _Look(context, widget);
    return Semantics(
      label: badgeSemanticsLabel(widget),
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: ListenableBuilder(
            listenable: Listenable.merge([_presence, _roll, _width]),
            builder: (context, _) => _build(look),
          ),
        ),
      ),
    );
  }

  Widget _build(_Look look) {
    final presence = _settled(_presence!, _shown! ? 1 : 0);
    if (presence <= 0 && !_shown!) return const SizedBox.shrink();
    final dot = look.dot || _to == null;
    final size = _size!;
    final width = dot ? size.width : _settled(_width!, _widthTarget!);
    final height = size.height;
    final roll = _settled(_roll!, 1);
    final rtl = look.direction == TextDirection.rtl;

    Widget layer(String text, double position) => Transform.translate(
      offset: Offset(0, position * height),
      child: Opacity(
        opacity: (1 - position.abs()).clamp(0, 1),
        child: OverflowBox(
          maxWidth: double.infinity,
          child: Text(text, style: look.style, maxLines: 1, softWrap: false),
        ),
      ),
    );

    final from = _from;
    final to = _to;
    final pill = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: look.background,
        shape: StadiumBorder(
          side: look.outline.copyWith(
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
      child: dot
          ? null
          : Stack(
              alignment: Alignment.center,
              children: [
                if (from != null && roll < 1) layer(from, -_direction * roll),
                if (to != null) layer(to, _direction * (1 - roll)),
              ],
            ),
    );

    // Scales about the icon's top-end corner.
    final scale = math.max(presence, 0.0);
    final anchor = dot
        ? Offset(rtl ? 0 : size.width, 0)
        : Offset(
            rtl ? width - (look.minHeight - 4) : look.minHeight - 4,
            height / 2 - 4,
          );
    return CustomSingleChildLayout(
      delegate: _BadgePlacement(
        dot: dot,
        minHeight: look.minHeight,
        offset: look.offset,
        direction: look.direction,
      ),
      child: Opacity(
        opacity: presence.clamp(0, 1),
        child: Transform(
          transform: Matrix4.diagonal3Values(scale, scale, 1),
          origin: anchor,
          child: pill,
        ),
      ),
    );
  }
}

/// Puts the badge on the icon's top-end corner, as Material 3 does: a dot
/// inside the corner, a large badge 4 past it on both axes and growing
/// toward the end.
class _BadgePlacement extends SingleChildLayoutDelegate {
  const _BadgePlacement({
    required this.dot,
    required this.minHeight,
    required this.offset,
    required this.direction,
  });

  final bool dot;
  final double minHeight;
  final Offset offset;
  final TextDirection direction;

  @override
  Size getSize(BoxConstraints constraints) => constraints.constrain(Size.zero);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      const BoxConstraints();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final start = dot
        ? size.width - childSize.width
        : size.width - minHeight + 4;
    final top = dot ? 0.0 : 4 - childSize.height / 2;
    final x = start + offset.dx;
    return Offset(
      direction == TextDirection.rtl ? size.width - x - childSize.width : x,
      top + offset.dy,
    );
  }

  @override
  bool shouldRelayout(_BadgePlacement oldDelegate) =>
      dot != oldDelegate.dot ||
      minHeight != oldDelegate.minHeight ||
      offset != oldDelegate.offset ||
      direction != oldDelegate.direction;
}
