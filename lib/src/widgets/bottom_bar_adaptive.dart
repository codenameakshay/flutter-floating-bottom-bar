import 'package:material_ui/material_ui.dart';

import '../bottom_bar.dart';
import '../bottom_bar_controller.dart';
import '../bottom_bar_scope.dart';
import '../bottom_bar_theme.dart';
import '../config/bottom_bar_layout.dart';
import '../config/bottom_bar_motion.dart';
import '../config/bottom_bar_scroll_behavior.dart';
import '../internal/bar_surface.dart';
import '../internal/item_theme_scope.dart';
import '../internal/scroll_notification_dispatcher.dart';
import '../internal/size_observer.dart';
import 'bottom_bar_accessory.dart';
import 'bottom_bar_items.dart';
import 'bottom_bar_surface.dart';

/// How a [BottomBarAdaptive] rail sits beside the body.
enum BottomBarRailStyle {
  /// A vertical capsule inset from the start edge, with the bar's surface and
  /// corner radius, centred on the screen's height.
  floating,

  /// A full-height rail on the start edge, like Material 3's
  /// [NavigationRail]. Its surface paints under the system insets.
  attached,
}

/// A [BottomBar] on narrow screens and a navigation rail on wide ones, from
/// the same [items].
///
/// Below [breakpoint] (600 by default, the Material 3 compact width) it is a
/// [BottomBar] with [items] as its child. At or above it, [items] run down a
/// rail on the start side (the right in RTL) and [body] sits beside it. The
/// rail uses the bar's theme: its surface, glass included, its item theme,
/// its indicator and its badges. [BottomBarItems.centerAction] moves to the
/// top of the rail.
///
/// ```dart
/// BottomBarAdaptive(
///   theme: BottomBarThemeData.glass(),
///   items: BottomBarItems(
///     selectedIndex: index,
///     onSelected: (i) => setState(() => index = i),
///     children: [...],
///   ),
///   body: pages[index],
/// )
/// ```
///
/// Crossing the breakpoint, by a window resize, a rotation or a foldable
/// opening, keeps [body]'s state: its scroll positions and text fields
/// survive, and so does the selected index, which [items] own. The bar comes
/// back shown.
///
/// The rail never hides on scroll. The bar's hidden back-to-top action and
/// minimize do not apply to it, and [controller] is attached only while the
/// bar shows. [BottomBarItems.scrollToStartOnReselect] works in both.
/// Inside [body], [BottomBarBodyPadding] reserves only the bottom safe-area
/// inset while the rail shows, plus the [accessory] when there is one.
class BottomBarAdaptive extends StatefulWidget {
  /// Creates a [BottomBarAdaptive].
  const BottomBarAdaptive({
    super.key,
    required this.items,
    required this.body,
    this.breakpoint = 600,
    this.railStyle,
    this.railLabelBehavior,
    this.railLeading,
    this.railTrailing,
    this.accessory,
    this.controller,
    this.layout,
    this.motion,
    this.scrollBehavior,
    this.theme,
  }) : assert(breakpoint >= 0);

  /// The items, shown in a row in the bar and in a column in the rail.
  final BottomBarItems items;

  /// The content beside the rail, or under the bar. See [BottomBar.body].
  final Widget body;

  /// The width at and above which the rail shows instead of the bar.
  ///
  /// Measured against the width this widget gets. Defaults to 600, where
  /// Material 3's compact window class ends.
  final double breakpoint;

  /// Whether the rail floats or is attached to the start edge.
  ///
  /// Defaults to [BottomBarRailStyle.attached] for a docked layout, such as
  /// [BottomBarThemeData.material3]'s, and to [BottomBarRailStyle.floating]
  /// for any other.
  final BottomBarRailStyle? railStyle;

  /// When item labels show in the rail. Defaults to the
  /// [BottomBarItems.labelBehavior] of [items], then the theme's.
  final BottomBarLabelBehavior? railLabelBehavior;

  /// A widget above the items in the rail, such as a logo or a menu button.
  final Widget? railLeading;

  /// A widget below the items in the rail, such as a settings button.
  final Widget? railTrailing;

  /// See [BottomBar.accessory].
  ///
  /// While the rail shows, the accessory floats at the bottom of the body,
  /// inset [BottomBarLayout.offset] from the body's sides and bottom and
  /// clear of the bottom safe area, no wider than [BottomBarLayout.maxWidth].
  /// It keeps the bar's surface and radius, is always
  /// [BottomBarAccessoryPlacement.expanded], and never hides.
  /// [BottomBarBodyPadding] reserves its height. It keeps its state across
  /// the breakpoint.
  final Widget? accessory;

  /// See [BottomBar.controller]. Attached only while the bar shows.
  final BottomBarController? controller;

  /// See [BottomBar.layout]. The rail uses its corner radius, side margin
  /// ([BottomBarLayout.offset]), safe-area choice and whether it is docked.
  final BottomBarLayout? layout;

  /// See [BottomBar.motion]. The rail uses its duration and curve to scroll
  /// the body to its start on reselect.
  final BottomBarMotion? motion;

  /// See [BottomBar.scrollBehavior]. Not used by the rail.
  final BottomBarScrollBehavior? scrollBehavior;

  /// See [BottomBar.theme].
  final BottomBarThemeData? theme;

  @override
  State<BottomBarAdaptive> createState() => _BottomBarAdaptiveState();
}

class _BottomBarAdaptiveState extends State<BottomBarAdaptive> {
  /// Width of the rail's content, as in Material 3's [NavigationRail].
  static const _railWidth = 80.0;

  /// Moves the body between the bar and the rail without rebuilding it.
  final _bodyKey = GlobalKey(debugLabel: 'BottomBarAdaptive body');

  final _railScrolls = ScrollNotificationDispatcher(onShouldHide: (_) {});
  final _railBarHeight = ValueNotifier<double>(0);
  final _railVisible = ValueNotifier<bool>(true);

  /// Moves the accessory between the bar and the rail without rebuilding it.
  final _accessoryKey = GlobalKey(debugLabel: 'BottomBarAdaptive accessory');

  @override
  void didUpdateWidget(BottomBarAdaptive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.accessory == null && oldWidget.accessory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.accessory == null) _railBarHeight.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _railBarHeight.dispose();
    _railVisible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = KeyedSubtree(key: _bodyKey, child: widget.body);
    final accessory = widget.accessory == null
        ? null
        : KeyedSubtree(key: _accessoryKey, child: widget.accessory!);
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < widget.breakpoint
          ? BottomBar(
              controller: widget.controller,
              layout: widget.layout,
              motion: widget.motion,
              scrollBehavior: widget.scrollBehavior,
              theme: widget.theme,
              accessory: accessory,
              body: body,
              child: widget.items,
            )
          : _buildRail(context, body, accessory),
    );
  }

  /// The theme a [BottomBar] here would resolve.
  BottomBarThemeData _resolvedTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
          ),
        )
        .merge(Theme.of(context).extension<BottomBarThemeData>())
        .merge(widget.theme);
  }

  /// [surface] with its colours filled in, as a [BottomBar] paints it. High
  /// contrast swaps the glass for an opaque fill.
  BottomBarSurface? _effectiveSurface(BottomBarSurface? surface) {
    if (surface == null) return null;
    final fill = Theme.of(context).colorScheme.surfaceContainer;
    if (MediaQuery.maybeHighContrastOf(context) == true) {
      final fallback = surface.fallbackColor ?? fill;
      return BottomBarSurface(
        tint: fallback.withValues(alpha: 1),
        border: surface.border,
        shadows: surface.shadows,
      );
    }
    return surface.copyWith(tint: surface.tint ?? fill);
  }

  void _scrollBodyToStart() {
    final position = _railScrolls.activeScrollable()?.position;
    if (position == null) return;
    final motion =
        widget.motion ??
        _resolvedTheme(context).motion ??
        const BottomBarMotion();
    position.animateTo(
      position.minScrollExtent,
      duration: motion.duration,
      curve: motion.curve,
    );
  }

  Widget _buildRail(BuildContext context, Widget body, Widget? accessory) {
    final theme = _resolvedTheme(context);
    final layout = widget.layout ?? theme.layout ?? const BottomBarLayout();
    final floating =
        (widget.railStyle ??
            (layout.docked
                ? BottomBarRailStyle.attached
                : BottomBarRailStyle.floating)) ==
        BottomBarRailStyle.floating;
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final safe = layout.respectSafeArea;
    final radius = !floating
        ? BorderRadius.zero
        : widget.layout != null || theme.layout != null
        ? layout.effectiveBorderRadius
        : theme.barDecoration?.borderRadius ?? BorderRadius.zero;
    final surface = _effectiveSurface(theme.surface);
    final decoration = theme.barDecoration;
    final itemTheme = theme.items;
    final pieceColor =
        itemTheme?.color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    Widget piece(Widget child) => IconTheme.merge(
      data: IconThemeData(color: pieceColor, size: itemTheme?.iconSize),
      child: child,
    );

    final items = widget.items;
    final railItems = BottomBarItems(
      key: items.key,
      spacing: items.spacing,
      labelBehavior: widget.railLabelBehavior ?? items.labelBehavior,
      selectedIndex: items.selectedIndex,
      onSelected: items.onSelected,
      indicator: items.indicator,
      indicatorMotion: items.indicatorMotion,
      onReselected: items.onReselected,
      scrollToStartOnReselect: items.scrollToStartOnReselect,
      onLongPressed: items.onLongPressed,
      dragToSelect: items.dragToSelect,
      centerAction: items.centerAction,
      direction: Axis.vertical,
      children: items.children,
    );

    final leading = widget.railLeading;
    final trailing = widget.railTrailing;
    Widget rail = SizedBox(
      width: _railWidth,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: floating ? 8 : 12),
        child: Column(
          mainAxisSize: floating ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (leading != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: piece(leading),
              ),
            Flexible(child: railItems),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: piece(trailing),
              ),
          ],
        ),
      ),
    );
    if (!floating) {
      rail = SafeArea(
        left: safe && ltr,
        right: safe && !ltr,
        top: safe,
        bottom: safe,
        child: rail,
      );
    }
    rail = BarSurface(
      decoration: surface == null
          ? decoration?.shape == BoxShape.rectangle
                ? decoration!.copyWith(borderRadius: radius)
                : decoration
          : BoxDecoration(borderRadius: radius),
      surface: surface,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: rail,
      ),
    );
    if (floating) {
      rail = SafeArea(
        left: safe && ltr,
        right: safe && !ltr,
        top: safe,
        bottom: safe,
        child: Padding(
          padding: EdgeInsets.all(layout.offset),
          child: Center(child: rail),
        ),
      );
    }
    rail = Semantics(
      container: true,
      explicitChildNodes: true,
      child: ItemThemeScope(
        items: itemTheme,
        scrollToStart: _scrollBodyToStart,
        child: rail,
      ),
    );

    Widget? floatingAccessory;
    if (accessory != null) {
      final accessoryRadius = widget.layout != null || theme.layout != null
          ? layout.effectiveBorderRadius
          : decoration?.borderRadius ?? BorderRadius.zero;
      floatingAccessory = Align(
        alignment: Alignment.bottomCenter,
        child: SizeObserver(
          onSizeChanged: (size) => _railBarHeight.value = size.height,
          child: SafeArea(
            top: false,
            left: safe,
            right: safe,
            bottom: safe,
            child: Padding(
              padding: EdgeInsets.all(layout.offset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: layout.maxWidth ?? double.infinity,
                ),
                child: BarSurface(
                  decoration: surface == null
                      ? decoration?.shape == BoxShape.rectangle
                            ? decoration!.copyWith(
                                borderRadius: accessoryRadius,
                              )
                            : decoration
                      : BoxDecoration(borderRadius: accessoryRadius),
                  surface: surface,
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: accessoryRadius,
                    clipBehavior: Clip.antiAlias,
                    child: AccessoryPlacementScope(
                      placement: BottomBarAccessoryPlacement.expanded,
                      child: Semantics(
                        container: true,
                        child: piece(accessory),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget pane = NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        _railScrolls.track(notification);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _railScrolls.handle(notification);
          return false;
        },
        child: BottomBarScope(
          barHeight: _railBarHeight,
          isVisible: _railVisible,
          bottomInset: safe
              ? MediaQuery.maybePaddingOf(context)?.bottom ?? 0
              : 0,
          child: body,
        ),
      ),
    );
    if (floatingAccessory != null) {
      pane = Stack(fit: StackFit.expand, children: [pane, floatingAccessory]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rail,
        Expanded(
          child: _withoutStartInset(context, ltr: ltr, child: pane),
        ),
      ],
    );
  }

  /// [child] without the start-side inset, which the rail already keeps
  /// clear of.
  static Widget _withoutStartInset(
    BuildContext context, {
    required bool ltr,
    required Widget child,
  }) => MediaQuery.maybeOf(context) == null
      ? child
      : MediaQuery.removePadding(
          context: context,
          removeLeft: ltr,
          removeRight: !ltr,
          child: child,
        );
}
