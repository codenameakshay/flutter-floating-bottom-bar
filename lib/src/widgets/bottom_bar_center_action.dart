import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../internal/bar_surface.dart';
import '../internal/haptics.dart';
import '../internal/item_theme_scope.dart';
import '../internal/reduce_motion.dart';
import 'bottom_bar_center_action_theme.dart';
import 'bottom_bar_item_theme.dart';

/// Where a [BottomBarCenterAction] sits relative to the bar.
enum BottomBarCenterActionStyle {
  /// A filled button in the row's middle slot, inside the bar.
  inline,

  /// The button sits partly above the bar's top edge, centred on its slot.
  raised,

  /// Raised, with a smooth circular notch cut into the bar around it. The
  /// bar's fill, border and shadow follow the cut.
  notched,
}

/// A primary action, such as "create", in the middle of a [BottomBarItems]
/// row.
///
/// Set it as [BottomBarItems.centerAction]. It is never a tab: the row's
/// indicator, `selectedIndex`, `onSelected`, `onReselected`, `dragToSelect`
/// and selection semantics all skip it, and a drag across it passes on to the
/// next item. It takes the slot at `children.length ~/ 2`, so with an even
/// number of children it sits in the exact centre.
///
/// [BottomBarCenterActionStyle.raised] and
/// [BottomBarCenterActionStyle.notched] need an enclosing [BottomBar]. There
/// the part above the bar is tappable, counts in [BottomBarScope.barHeight]
/// and [BottomBarBodyPadding], and hides and shows with the bar. Outside a
/// [BottomBar], or in a row too narrow for its items that scrolls instead,
/// the action is inline.
///
/// It follows [BottomBarItemThemeData.pressedScale],
/// [BottomBarItemThemeData.haptics] and [BottomBarItemThemeData.motion], and
/// takes its defaults from [BottomBarItemThemeData.centerAction]. Arguments
/// here win over the theme.
class BottomBarCenterAction extends StatefulWidget {
  /// Creates a [BottomBarCenterAction].
  ///
  /// Give it a [semanticLabel] or a [tooltip] so it has an accessible name.
  const BottomBarCenterAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.style = BottomBarCenterActionStyle.inline,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.shape,
  }) : assert(
         semanticLabel != null || tooltip != null,
         'BottomBarCenterAction needs a semanticLabel or a tooltip.',
       );

  /// The icon in the button, tinted with [foregroundColor].
  final Widget icon;

  /// Called when the button is tapped. Null disables it.
  final VoidCallback? onPressed;

  /// The accessible name. Defaults to [tooltip].
  final String? semanticLabel;

  /// Tooltip shown on long-press or hover.
  final String? tooltip;

  /// Where the button sits. Defaults to [BottomBarCenterActionStyle.inline].
  final BottomBarCenterActionStyle style;

  /// Fill of the button. Defaults to
  /// [BottomBarCenterActionThemeData.backgroundColor], then
  /// `colorScheme.primary`.
  final Color? backgroundColor;

  /// Icon colour. Defaults to
  /// [BottomBarCenterActionThemeData.foregroundColor], then
  /// `colorScheme.onPrimary`.
  final Color? foregroundColor;

  /// Width and height of the button. Defaults to
  /// [BottomBarCenterActionThemeData.size], then 48 inline and 56 raised or
  /// notched.
  final double? size;

  /// Shape of the button. Defaults to [BottomBarCenterActionThemeData.shape],
  /// then a Material 3 FAB shape, or a circle when notched. The notch is
  /// always circular.
  final ShapeBorder? shape;

  @override
  State<BottomBarCenterAction> createState() => _BottomBarCenterActionState();
}

/// Tells a [BottomBarCenterAction] below it whether its row scrolls, which
/// forces it inline.
class CenterActionInline extends InheritedWidget {
  const CenterActionInline({
    super.key,
    required this.inline,
    required super.child,
  });

  final bool inline;

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CenterActionInline>()
          ?.inline ??
      false;

  @override
  bool updateShouldNotify(CenterActionInline oldWidget) =>
      inline != oldWidget.inline;
}

/// The resolved look of a centre action.
typedef CenterActionGeometry = ({
  BottomBarCenterActionStyle style,
  double size,
  double raise,
  double notchMargin,
  double slotWidth,
});

/// Resolves [action]'s style and size at [context], as a row lays it out.
CenterActionGeometry centerActionGeometry(
  BuildContext context,
  BottomBarCenterAction action, {
  bool inline = false,
}) {
  final theme =
      itemThemeOf(context).centerAction ??
      const BottomBarCenterActionThemeData();
  final style =
      inline ||
          CenterActionInline.of(context) ||
          context.findAncestorWidgetOfExactType<BarSurface>() == null
      ? BottomBarCenterActionStyle.inline
      : action.style;
  final size =
      action.size ??
      theme.size ??
      (style == BottomBarCenterActionStyle.inline ? 48.0 : 56.0);
  final notchMargin = theme.notchMargin ?? 6;
  return (
    style: style,
    size: size,
    raise: theme.raise ?? size / 2,
    notchMargin: notchMargin,
    slotWidth:
        size +
        16 +
        (style == BottomBarCenterActionStyle.notched ? 2 * notchMargin : 0),
  );
}

class _BottomBarCenterActionState extends State<BottomBarCenterAction>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _defaultMotion = CupertinoMotion.smooth(
    duration: Duration(milliseconds: 300),
  );

  SingleMotionController? _press;
  double _pressTarget = 1;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(BottomBarCenterAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAccessibilityFeatures() => _sync();

  @override
  void deactivate() {
    _pressed = false;
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _press?.dispose();
    super.dispose();
  }

  void _sync() {
    final theme = itemThemeOf(context);
    final motion = theme.motion ?? _defaultMotion;
    final target = _pressed ? theme.pressedScale ?? 1 : 1.0;
    final press = _press ??= SingleMotionController(
      motion: motion,
      vsync: this,
      initialValue: target,
    );
    press.motion = motion;
    if (reduceMotion(context)) {
      if (press.isAnimating || press.value != target) press.value = target;
    } else if (target != _pressTarget) {
      press.animateTo(target);
    }
    _pressTarget = target;
  }

  void _onHighlightChanged(bool value) {
    _pressed = value;
    _sync();
  }

  void _onTap() {
    playHaptics(itemThemeOf(context).haptics ?? BottomBarHaptics.none);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final action = widget;
    final cs = Theme.of(context).colorScheme;
    final theme =
        itemThemeOf(context).centerAction ??
        const BottomBarCenterActionThemeData();
    final geometry = centerActionGeometry(context, action);
    final style = geometry.style;
    final lifted = style != BottomBarCenterActionStyle.inline;
    final size = geometry.size;
    final shape =
        action.shape ??
        theme.shape ??
        (style == BottomBarCenterActionStyle.notched
            ? const CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size * 2 / 7),
              ));
    final onTap = action.onPressed == null ? null : _onTap;
    final label = action.semanticLabel ?? action.tooltip;

    Widget button = Material(
      color: action.backgroundColor ?? theme.backgroundColor ?? cs.primary,
      shape: shape,
      elevation: theme.elevation ?? (lifted ? 3 : 0),
      shadowColor: theme.shadowColor ?? cs.shadow,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        onHighlightChanged: _onHighlightChanged,
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(
                color:
                    action.foregroundColor ??
                    theme.foregroundColor ??
                    cs.onPrimary,
              ),
              child: action.icon,
            ),
          ),
        ),
      ),
    );
    if ((itemThemeOf(context).pressedScale ?? 1) != 1) {
      final press = _press!;
      button = ListenableBuilder(
        listenable: press,
        builder: (context, child) => Transform.scale(
          scale: press.isAnimating ? press.value : _pressTarget,
          child: child,
        ),
        child: button,
      );
    }
    if (action.tooltip != null) {
      button = Tooltip(
        message: action.tooltip!,
        excludeFromSemantics: true,
        child: button,
      );
    }
    button = Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(child: button),
    );

    return CenterActionSlot(
      width: geometry.slotWidth,
      lifted: lifted,
      notched: style == BottomBarCenterActionStyle.notched,
      raise: geometry.raise,
      notchMargin: geometry.notchMargin,
      child: button,
    );
  }
}
