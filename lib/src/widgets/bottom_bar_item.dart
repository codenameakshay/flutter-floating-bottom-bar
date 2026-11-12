import 'dart:ui' show lerpDouble;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../internal/bottom_bar_item_height.dart';
import '../internal/item_theme_scope.dart';
import '../internal/reduce_motion.dart';
import 'bottom_bar_badge.dart';
import 'bottom_bar_indicator.dart';
import 'bottom_bar_item_theme.dart';
import 'bottom_bar_items.dart';

/// A simple, opinionated nav-item widget for use inside [BottomBar.child].
///
/// Renders an [icon] (or [selectedIcon] when [selected]), an optional [label]
/// underneath, and an optional [badge] floating on the icon's top-end.
/// Wraps the whole thing in an [InkWell] with an explicit 48 by 48 minimum
/// interactive target, button semantics, and an optional [Tooltip].
///
/// Use [semanticLabel] to provide a deterministic accessible name when the
/// visible [label] is decorative, custom, or otherwise unsuitable for
/// accessibility. When [semanticLabel] is null, [tooltip] becomes the explicit
/// accessible name fallback. If neither is provided, the child's own semantics
/// remain visible.
///
/// No internal selection state. Pass [selected] from your own state and
/// handle [onTap], or let a [BottomBarItems] with a
/// [BottomBarItems.selectedIndex] select it.
///
/// Style it through [BottomBarItemThemeData]. Selection changes animate on
/// [BottomBarItemThemeData.motion]: the colour, the icon, the label style
/// and, with [BottomBarLabelBehavior.onlySelected], the label itself. A row
/// indicator that reveals the selected look (pill, tint, underline) drives
/// the colour and icon instead.
class BottomBarItem extends StatelessWidget {
  const BottomBarItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
    this.selected = false,
    this.onTap,
    this.semanticLabel,
    this.tooltip,
    this.color,
    this.selectedColor,
  });

  /// The icon displayed when [selected] is `false`.
  final Widget icon;

  /// The icon displayed when [selected] is `true`.
  ///
  /// Falls back to [icon] when null.
  final Widget? selectedIcon;

  /// Optional label rendered below the icon.
  ///
  /// Styled with `textTheme.labelSmall` (or [BottomBarItemThemeData.labelStyle])
  /// tinted to [color] or [selectedColor].
  /// A `Text` label with non-null `data` is truncated to a single line with
  /// an ellipsis. Other widgets (including `Text.rich`) are left untouched.
  /// Label visibility is controlled by the enclosing
  /// [BottomBarItems.labelBehavior].
  final Widget? label;

  /// Optional badge on the icon's top-end corner.
  ///
  /// Use a [BottomBarBadge] for a dot, a count or a short label that
  /// animates, follows the theme and joins the item's accessible name. Any
  /// other widget sits 4 pixels past the corner and is not announced.
  final Widget? badge;

  /// Whether this item is currently the active/selected tab.
  ///
  /// Does not maintain state internally — pass from your own state and update
  /// in [onTap].
  ///
  /// Ignored inside a [BottomBarItems] with a non-null
  /// [BottomBarItems.selectedIndex], which decides selection instead.
  final bool selected;

  /// Called when the item is tapped.
  ///
  /// Inside a [BottomBarItems] with a [BottomBarItems.selectedIndex], this
  /// runs first and [BottomBarItems.onSelected] runs after it.
  final VoidCallback? onTap;

  /// Explicit accessible name for this item.
  ///
  /// When non-null, this name is exposed as the only semantics label for the
  /// item and descendant semantics are excluded to prevent duplicate
  /// announcements. When null, [tooltip] becomes the explicit accessible name
  /// fallback. If both are null, descendant semantics remain visible.
  final String? semanticLabel;

  /// Tooltip shown on long-press.
  ///
  /// When [semanticLabel] is null, this also becomes the explicit accessible
  /// name fallback. When null no tooltip is rendered.
  final String? tooltip;

  /// Icon and label colour when [selected] is `false`.
  ///
  /// Defaults to [BottomBarItemThemeData.color], then
  /// `colorScheme.onSurfaceVariant`.
  final Color? color;

  /// Icon and label colour when [selected] is `true`.
  ///
  /// Defaults to a colour that contrasts with the row's
  /// [BottomBarItems.indicator] (`colorScheme.onPrimary` over the default
  /// pill), then [BottomBarItemThemeData.selectedColor], then
  /// `colorScheme.primary`.
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) => _ItemView(item: this);
}

class _ItemView extends StatefulWidget {
  const _ItemView({required this.item});

  final BottomBarItem item;

  @override
  State<_ItemView> createState() => _ItemViewState();
}

class _ItemViewState extends State<_ItemView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _defaultMotion = CupertinoMotion.smooth(
    duration: Duration(milliseconds: 300),
  );

  /// Selection progress: 0 unselected, 1 selected.
  SingleMotionController? _selection;

  /// Content scale: 1 at rest, the theme's pressed scale while pressed.
  SingleMotionController? _press;
  double? _selectionTarget;
  double? _pressTarget;
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
  void didUpdateWidget(_ItemView oldWidget) {
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
    _selection?.dispose();
    _press?.dispose();
    super.dispose();
  }

  bool get _selected =>
      BottomBarItemSelectionScope.maybeOf(context)?.selected ??
      widget.item.selected;

  /// Moves both springs toward their targets, or jumps under reduced motion
  /// so no ticker outlives the change.
  void _sync() {
    final theme = itemThemeOf(context);
    final motion = theme.motion ?? _defaultMotion;
    final reduced = reduceMotion(context);
    final selectionTarget = _selected ? 1.0 : 0.0;
    final pressTarget = _pressed ? theme.pressedScale ?? 1 : 1.0;
    final selection = _selection ??= SingleMotionController(
      motion: motion,
      vsync: this,
      initialValue: _selectionTarget = selectionTarget,
    );
    final press = _press ??= SingleMotionController(
      motion: motion,
      vsync: this,
      initialValue: _pressTarget = pressTarget,
    );
    selection.motion = motion;
    press.motion = motion;
    _selectionTarget = _drive(
      selection,
      _selectionTarget,
      selectionTarget,
      reduced,
    );
    _pressTarget = _drive(press, _pressTarget, pressTarget, reduced);
  }

  static double _drive(
    SingleMotionController controller,
    double? previous,
    double target,
    bool reduced,
  ) {
    if (reduced) {
      if (controller.isAnimating || controller.value != target) {
        controller.value = target;
      }
    } else if (previous != target) {
      controller.animateTo(target);
    }
    return target;
  }

  /// A spring stops within tolerance of its target, so a settled item uses
  /// the exact target and renders exactly as it did before animating.
  static double _settledValue(
    SingleMotionController controller,
    double target,
  ) => controller.isAnimating ? controller.value : target;

  void _onHighlightChanged(bool value) {
    _pressed = value;
    _sync();
  }

  @override
  Widget build(BuildContext context) {
    final theme = itemThemeOf(context);
    final selection = BottomBarItemSelectionScope.maybeOf(context);
    final pressedScale = theme.pressedScale ?? 1;
    return ListenableBuilder(
      listenable: Listenable.merge([_selection, _press]),
      builder: (context, _) => _build(
        context,
        theme: theme,
        selection: selection,
        selected: _selected,
        t: _settledValue(_selection!, _selectionTarget!).clamp(0, 1),
        scale: pressedScale == 1 ? null : _settledValue(_press!, _pressTarget!),
      ),
    );
  }

  /// [t] runs from 0 (unselected) to 1 (selected). [scale] is null when the
  /// theme has no press scale, so the default tree carries no transform.
  Widget _build(
    BuildContext context, {
    required BottomBarItemThemeData theme,
    required BottomBarItemSelectionScope? selection,
    required bool selected,
    required double t,
    required double? scale,
  }) {
    final item = widget.item;
    final icon = item.icon;
    final selectedIcon = item.selectedIcon;
    final badge = item.badge;
    final cs = Theme.of(context).colorScheme;
    final onSelect = selection?.onSelect;
    final onTap = onSelect == null
        ? item.onTap
        : () {
            item.onTap?.call();
            onSelect();
          };
    final labelBehavior =
        BottomBarItemsScope.maybeOf(context) ??
        BottomBarLabelBehavior.alwaysShow;
    final showLabel = switch (labelBehavior) {
      BottomBarLabelBehavior.alwaysShow => true,
      BottomBarLabelBehavior.onlySelected => selected,
      BottomBarLabelBehavior.alwaysHide => false,
    };
    final growLabel = labelBehavior == BottomBarLabelBehavior.onlySelected;
    final labelShown = growLabel ? t : (showLabel ? 1.0 : 0.0);
    final plainColor = item.color ?? theme.color ?? cs.onSurfaceVariant;
    final selectedLookColor =
        item.selectedColor ??
        selection?.selectedForegroundColor ??
        theme.selectedColor ??
        cs.primary;
    final explicitSemanticLabel = item.semanticLabel ?? item.tooltip;
    final minHeight = BottomBarItemHeightScope.maybeOf(context) ?? 48;

    final currentLabel = item.label;
    Widget labelChild = currentLabel ?? const SizedBox.shrink();
    if (currentLabel is Text && currentLabel.data != null) {
      labelChild = Text(
        currentLabel.data!,
        key: currentLabel.key,
        style: currentLabel.style,
        strutStyle: currentLabel.strutStyle,
        textAlign: currentLabel.textAlign ?? TextAlign.center,
        textDirection: currentLabel.textDirection,
        locale: currentLabel.locale,
        softWrap: currentLabel.softWrap,
        textScaler: currentLabel.textScaler,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        semanticsLabel: currentLabel.semanticsLabel,
        semanticsIdentifier: currentLabel.semanticsIdentifier,
        textWidthBasis: currentLabel.textWidthBasis,
        textHeightBehavior: currentLabel.textHeightBehavior,
        selectionColor: currentLabel.selectionColor,
      );
    }

    final badgeLabel = badge is BottomBarBadge
        ? badgeSemanticsLabel(badge)
        : null;
    final baseLabel =
        explicitSemanticLabel ??
        ((!showLabel || badgeLabel != null) &&
                currentLabel is Text &&
                currentLabel.data != null
            ? currentLabel.semanticsLabel ?? currentLabel.data
            : null);
    final accessibleLabel = baseLabel == null || badgeLabel == null
        ? baseLabel
        : '$baseLabel, $badgeLabel';

    // The reveal mounts the icon and label twice, which a GlobalKey forbids.
    final ink =
        (selection?.ink ?? false) &&
        ![
          icon,
          selectedIcon,
          currentLabel,
        ].any((part) => part?.key is GlobalKey);

    // The indicator drives colour and icon on the reveal path; the item
    // animates them itself everywhere else.
    final color = ink
        ? plainColor
        : Color.lerp(plainColor, selectedLookColor, t)!;

    final ambientIconSize = IconTheme.of(context).size;
    final iconSize = theme.iconSize == null && theme.selectedIconSize == null
        ? null
        : lerpDouble(
            theme.iconSize ?? ambientIconSize,
            theme.selectedIconSize ?? theme.iconSize ?? ambientIconSize,
            t,
          );

    Widget pressed(Widget child) =>
        scale == null ? child : Transform.scale(scale: scale, child: child);

    Widget grown(Widget child) => !growLabel
        ? child
        : Align(
            widthFactor: labelShown,
            heightFactor: labelShown,
            child: Opacity(
              opacity: labelShown,
              child: Transform.scale(scale: labelShown, child: child),
            ),
          );

    Widget reveal(Widget plain, Widget selected) => Stack(
      children: [
        plain,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeFocus(
              child: ExcludeSemantics(child: IndicatorInk(child: selected)),
            ),
          ),
        ),
      ],
    );

    Widget tinted(Color color, Widget child) => IconTheme.merge(
      data: IconThemeData(color: color, size: iconSize),
      child: child,
    );

    Widget plainIcon() {
      if (ink ||
          t == 0 ||
          selectedIcon == null ||
          identical(icon, selectedIcon)) {
        return icon;
      }
      if (icon.key is GlobalKey && icon.key == selectedIcon.key) {
        return selected ? selectedIcon : icon;
      }
      if (t == 1) return selectedIcon;
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 1 - t, child: icon),
          Opacity(opacity: t, child: selectedIcon),
        ],
      );
    }

    Widget iconStack(double? maxIconWidth) => Stack(
      clipBehavior: Clip.none,
      children: [
        if (ink)
          reveal(
            tinted(color, icon),
            tinted(
              selectedLookColor,
              OverflowBox(
                minWidth: 0,
                maxWidth: maxIconWidth,
                child: selectedIcon ?? icon,
              ),
            ),
          )
        else
          tinted(color, plainIcon()),
        if (badge is BottomBarBadge)
          Positioned.fill(child: badge)
        else if (badge != null)
          PositionedDirectional(top: -4, end: -4, child: badge),
      ],
    );

    final anchors = selection != null;
    Widget stack = pressed(
      ink
          ? LayoutBuilder(
              builder: (context, constraints) =>
                  iconStack(constraints.maxWidth),
            )
          : iconStack(null),
    );
    if (anchors) {
      stack = IndicatorAnchor(role: IndicatorAnchorRole.icon, child: stack);
    }

    final labelBase =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).merge(
          theme.labelStyle,
        );
    final label = pressed(
      ink
          ? reveal(
              labelChild,
              DefaultTextStyle.merge(
                style: TextStyle(color: selectedLookColor),
                child: labelChild,
              ),
            )
          : labelChild,
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        stack,
        if (currentLabel != null && labelShown > 0) ...[
          SizedBox(height: (theme.iconLabelGap ?? 2) * labelShown),
          _FillBoundedWidth(
            child: DefaultTextStyle(
              style: lerpLabelStyle(
                labelBase,
                labelBase.merge(theme.selectedLabelStyle),
                t,
              )!.copyWith(color: color),
              child: selection == null
                  ? grown(label)
                  : Center(
                      heightFactor: 1,
                      child: anchors
                          ? IndicatorAnchor(
                              role: IndicatorAnchorRole.label,
                              child: grown(label),
                            )
                          : grown(label),
                    ),
            ),
          ),
        ],
      ],
    );

    Widget child = InkWell(
      onTap: onTap,
      onHighlightChanged: _onHighlightChanged,
      borderRadius: theme.inkBorderRadius ?? BorderRadius.circular(8),
      overlayColor: theme.overlayColor,
      splashFactory: theme.splashFactory,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 48, minHeight: minHeight),
        child: Padding(
          padding:
              theme.padding ??
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          // heightFactor keeps the item content-tall when the bar hands it
          // loose height up to the full screen.
          child: Center(heightFactor: 1, child: column),
        ),
      ),
    );

    if (item.tooltip != null) {
      child = Tooltip(
        message: item.tooltip!,
        excludeFromSemantics: true,
        child: child,
      );
    }

    // Always present so a badge or label toggling the name keeps the subtree.
    child = ExcludeSemantics(excluding: accessibleLabel != null, child: child);

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: accessibleLabel,
      onTap: accessibleLabel != null ? onTap : null,
      child: child,
    );
  }
}

/// Fills a bounded width and keeps its child's width when unbounded.
///
/// Not a [LayoutBuilder]: one rebuilds its child during layout, and an
/// [IndicatorAnchor] changed then would dirty ancestors outside that layout.
class _FillBoundedWidth extends SingleChildRenderObjectWidget {
  const _FillBoundedWidth({super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFillBoundedWidth();
}

class _RenderFillBoundedWidth extends RenderProxyBox {
  BoxConstraints _fill(BoxConstraints constraints) =>
      constraints.hasBoundedWidth
      ? constraints.tighten(width: constraints.maxWidth)
      : constraints;

  @override
  void performLayout() {
    child!.layout(_fill(constraints), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(child!.getDryLayout(_fill(constraints)));
}
