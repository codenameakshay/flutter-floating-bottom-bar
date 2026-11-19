import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kMinFlingVelocity;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import 'bottom_bar_controller.dart';
import 'bottom_bar_localizations.dart';
import 'bottom_bar_scope.dart';
import 'bottom_bar_theme.dart';
import 'internal/bar_group.dart';
import 'internal/bar_surface.dart';
import 'internal/item_theme_scope.dart';
import 'internal/minimize.dart';
import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'internal/reduce_motion.dart';
import 'config/bottom_bar_scroll_behavior.dart';
import 'internal/scroll_notification_dispatcher.dart';
import 'internal/size_observer.dart';
import 'internal/bottom_bar_action.dart';
import 'internal/visibility_animator.dart';
import 'widgets/bottom_bar_accessory.dart';
import 'widgets/bottom_bar_item.dart';
import 'widgets/bottom_bar_items.dart';
import 'widgets/bottom_bar_surface.dart';

/// Builds the back-to-top icon child.
///
/// [width] and [height] reflect the animated visual container size at the
/// moment of build (they shrink to zero as the bar becomes fully visible).
/// Ignore them to keep a constant icon size, or use them to scale the icon
/// along with the container.
typedef BackToTopIconBuilder = Widget Function(double width, double height);

/// A floating bar widget that hosts any child widget above scrollable content
/// and automatically hides/shows in response to scroll events.
///
/// The bar listens to [ScrollNotification]s bubbled up from any descendant
/// scrollable in [body] — no [ScrollController] wiring is required. It can
/// host a [TabBar], search bar, custom [Row], [BottomBarItems], or any widget.
/// Because the bar is stacked above [body], use [BottomBarBodyPadding] (or
/// [BottomBarScope.barHeight]) when the body should reserve matching bottom
/// clearance.
///
/// Basic usage:
///
/// ```dart
/// BottomBar(
///   body: ListView.builder(
///     itemCount: 200,
///     itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
///   ),
///   child: const Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Floating content'),
///   ),
/// )
/// ```
///
/// See also:
/// * [BottomBarLayout] — size, shape, and position configuration.
/// * [BottomBarMotion] — show/hide animation configuration.
/// * [BottomBarScrollBehavior] — scroll detection configuration.
/// * [BottomBarThemeData] — app-wide defaults via [ThemeExtension].
/// * [BottomBarController] — imperative show/hide/scroll API.
/// * [BottomBarScope] — read bar height and visibility from descendants.
/// * [BottomBarBodyPadding] — reserve body space equal to the bar footprint,
///   including [BottomBarLayout.offset] and bottom safe-area when enabled.
class BottomBar extends StatefulWidget {
  /// Creates a [BottomBar].
  ///
  /// Both [child] and [body] are required. All other parameters are optional
  /// and fall back to [BottomBarThemeData] or built-in Material 3 defaults.
  const BottomBar({
    required this.child,
    required this.body,
    this.leading,
    this.trailing,
    this.compactChild,
    this.accessory,
    this.controller,
    this.layout,
    this.motion,
    this.scrollBehavior,
    this.theme,
    this.icon,
    this.showIcon = true,
    this.iconSemanticLabel,
    this.iconTooltip,
    this.onVisibilityChanged,
    this.onBottomBarShown,
    this.onBottomBarHidden,
    super.key,
  });

  /// The widget shown as the floating bar — typically a [TabBar],
  /// [BottomBarItems], or a custom [Row].
  final Widget child;

  /// The content placed beneath (and behind) the bar.
  ///
  /// Any [ScrollNotification] bubbled from a descendant scrollable here drives
  /// the bar's hide/show behaviour without requiring a [ScrollController].
  /// This subtree also receives [BottomBarScope], so descendants can read the
  /// live bar footprint and visibility.
  final Widget body;

  /// A detached piece before the bar, in reading order, like the profile
  /// button beside an iOS 26 tab bar.
  ///
  /// It paints with the bar's surface and outline radius, is exactly as tall
  /// as the bar and at least as wide, and hides and shows with it. The bar
  /// itself takes the width left after [leading], [trailing] and
  /// [BottomBarLayout.groupSpacing]. A piece never shrinks: in a row too
  /// narrow for it, the bar narrows first, and [BottomBarItems] scroll.
  ///
  /// [child] fills the piece's height and is at least as wide, so an
  /// [IconButton] becomes a round button the size of the piece. Icons take
  /// [BottomBarItemThemeData.color] and [BottomBarItemThemeData.iconSize].
  /// Wrap [child] in a [Center] to keep its own size.
  final Widget? leading;

  /// A detached piece after the bar, in reading order, like the search
  /// button beside an iOS 26 tab bar. Laid out and painted like [leading].
  final Widget? trailing;

  /// What the bar shows when it minimizes into a compact pill, like a
  /// now-playing pill.
  ///
  /// When null, the pill shows the selected [BottomBarItem]'s icon and badge,
  /// if [child] itself is a [BottomBarItems] with a
  /// [BottomBarItems.selectedIndex]. A [BottomBarItems] wrapped in another
  /// widget, such as a [Padding], does not count, and neither does an item
  /// whose icon or badge has a [GlobalKey], since the pill would mount it a
  /// second time. With neither, the bar has no pill, and minimizing hides it
  /// instead.
  ///
  /// The pill sits at the bar's leading edge (the right edge in RTL),
  /// vertically centred and inset from that edge as far as from the bar's
  /// top, whatever [BottomBarLayout.alignment] says. [compactChild] takes its
  /// own size, up to the bar's. A [leading] piece keeps its place, and the
  /// pill sits [BottomBarLayout.groupSpacing] after it. Tapping the pill
  /// anywhere [compactChild] does not handle itself expands the bar. To a
  /// screen reader the pill is one collapsed button with an "Expand" hint,
  /// labelled with [compactChild]'s text. Controls inside [compactChild]
  /// merge into that button.
  ///
  /// See [BottomBarScrollBehavior.minimizeBehavior] and
  /// [BottomBarController.minimize].
  final Widget? compactChild;

  /// A piece stacked above the bar, like a mini player or a dock, as with
  /// SwiftUI's `tabViewBottomAccessory`.
  ///
  /// It is as wide as the bar between [leading] and [trailing], takes its
  /// own height, and sits [BottomBarLayout.groupSpacing] above the bar's top,
  /// above a raised centre action's top when there is one. It paints with
  /// the bar's surface, glass, scroll edge blend and corner radius, and hides
  /// and shows with the bar. [BottomBarScope.barHeight] and
  /// [BottomBarBodyPadding] count it and the spacing.
  ///
  /// When the bar minimizes, the accessory moves down beside the pill, on
  /// the same spring, and takes the width between the pill and [trailing].
  /// There it is as tall as the pill, and its corners round into the
  /// pill's capsule. [BottomBarScope.barHeight] keeps the
  /// full height. The footprint changes only when the accessory comes or
  /// goes, or when its height changes while it is expanded: while minimized,
  /// the bar holds its expanded height until it expands again.
  /// Read [BottomBarAccessoryPlacement.of] inside the accessory
  /// to choose what to show: it turns [BottomBarAccessoryPlacement.inline]
  /// when the move passes its midpoint, and back to
  /// [BottomBarAccessoryPlacement.expanded] when it passes it again. While it
  /// moves, the accessory lays out at every size in between and clips to its
  /// outline.
  ///
  /// Tapping the accessory runs its own controls. It never expands the bar.
  ///
  /// In a [BottomBarLayout.docked] bar the accessory floats above it, inset
  /// [BottomBarLayout.groupSpacing] from each side, plus the side safe-area
  /// insets.
  final Widget? accessory;

  /// Optional imperative controller for the bar.
  ///
  /// Attach a [BottomBarController] to programmatically [BottomBarController.show],
  /// [BottomBarController.hide], [BottomBarController.toggle], or scroll the
  /// body to its start/end. A controller can be attached to only one bar at a
  /// time; double-attach fails in both debug and release.
  final BottomBarController? controller;

  /// Size, shape, and positioning configuration.
  ///
  /// Falls back to [BottomBarThemeData.layout], then to [BottomBarLayout]
  /// defaults when null.
  final BottomBarLayout? layout;

  /// Show/hide animation configuration.
  ///
  /// Falls back to [BottomBarThemeData.motion], then to [BottomBarMotion]
  /// defaults (Cupertino spring) when null.
  final BottomBarMotion? motion;

  /// Scroll-detection configuration.
  ///
  /// Falls back to [BottomBarThemeData.scrollBehavior], then to
  /// [BottomBarScrollBehavior] defaults when null.
  final BottomBarScrollBehavior? scrollBehavior;

  /// Per-instance decoration overrides.
  ///
  /// Applied after [ThemeExtension] defaults but before per-widget config
  /// arguments ([layout], [motion], [scrollBehavior]).
  final BottomBarThemeData? theme;

  /// Builder for a custom hidden action shown while the bar is hidden.
  ///
  /// When null a default up-arrow icon is used. The builder receives the
  /// current animated width and height of the icon container. The action is
  /// non-interactive and removed from semantics while the bar itself is
  /// visible.
  final BackToTopIconBuilder? icon;

  /// Whether the built-in hidden action is rendered at all.
  ///
  /// Defaults to `true`. Set to `false` to suppress the icon entirely.
  final bool showIcon;

  /// Accessibility label for the hidden action.
  ///
  /// Passed to [Semantics.label]. Defaults to the direction-aware tooltip text:
  /// [BottomBarLocalizations.scrollToTop] or
  /// [BottomBarLocalizations.scrollToBottom].
  final String? iconSemanticLabel;

  /// Tooltip text shown on long-press of the hidden action.
  ///
  /// Defaults to [BottomBarLocalizations.scrollToTop] or
  /// [BottomBarLocalizations.scrollToBottom], depending on
  /// [BottomBarScrollBehavior.scrollOpposite].
  final String? iconTooltip;

  /// Called every time bar visibility changes.
  ///
  /// The argument is `true` when the bar becomes visible, `false` when hidden.
  final ValueChanged<bool>? onVisibilityChanged;

  /// Called when the bar transitions from hidden to visible.
  final VoidCallback? onBottomBarShown;

  /// Called when the bar transitions from visible to hidden.
  final VoidCallback? onBottomBarHidden;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with TickerProviderStateMixin
    implements BottomBarBindingForController, BottomBarVisibilityBinding {
  late BoundedSingleMotionController _motionController;

  /// 0 paints [BottomBarThemeData.surface], 1 paints
  /// [BottomBarThemeData.scrollEdgeSurface].
  late BoundedSingleMotionController _edgeController;
  late ScrollNotificationDispatcher _dispatcher;
  late BottomBarMotion _motion;
  late BottomBarScrollBehavior _scrollBehavior;
  final FocusNode _barFocusNode = FocusNode(
    debugLabel: 'BottomBar child',
    canRequestFocus: false,
  );
  final GlobalKey _barRenderKey = GlobalKey();
  final GlobalKey _leadingPieceKey = GlobalKey();
  final GlobalKey _trailingPieceKey = GlobalKey();

  /// Every piece of the bar reads the backdrop under it once, together.
  final BackdropKey _backdropKey = BackdropKey();

  /// The one source of truth for where the bar is. Every transition goes
  /// through [_go].
  BottomBarVisibility _visibility = BottomBarVisibility.shown;
  bool get _targetVisible => _visibility != BottomBarVisibility.hidden;

  /// The bar sits where a followed scroll put it, not where [_visibility]
  /// says, until [_go] settles it.
  bool _tracking = false;

  /// Whether the bar's shape is the pill: true while minimized, and kept
  /// while hidden so a minimized bar hides and comes back as a pill.
  bool _pill = false;
  int _visibilityTransition = 0;

  /// 0 is the full bar, 1 the compact pill.
  late BoundedSingleMotionController _minimizeController;
  final GlobalKey _minimizeHostKey = GlobalKey();

  /// Holds no focus itself; tells whether focus is inside the full bar.
  final FocusNode _fullFocusNode = FocusNode(
    debugLabel: 'BottomBar full',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _pillFocusNode = FocusNode(debugLabel: 'BottomBar pill');

  /// Turns inline as the minimize spring passes its midpoint.
  final ValueNotifier<BottomBarAccessoryPlacement> _accessoryPlacement =
      ValueNotifier(BottomBarAccessoryPlacement.expanded);

  void _syncAccessoryPlacement() {
    _accessoryPlacement.value = _minimizeController.value >= 0.5
        ? BottomBarAccessoryPlacement.inline
        : BottomBarAccessoryPlacement.expanded;
  }

  BottomBarLayout _effectiveLayout(BottomBarThemeData theme) {
    return widget.layout ?? theme.layout ?? const BottomBarLayout();
  }

  BottomBarMotion _effectiveMotion(BottomBarThemeData theme) {
    return widget.motion ?? theme.motion ?? const BottomBarMotion();
  }

  BottomBarScrollBehavior _effectiveScrollBehavior(BottomBarThemeData theme) {
    return widget.scrollBehavior ??
        theme.scrollBehavior ??
        const BottomBarScrollBehavior();
  }

  final ValueNotifier<double> _barHeight = ValueNotifier<double>(0);
  final ValueNotifier<bool> _isVisibleNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<BottomBarVisibility> _visibilityNotifier = ValueNotifier(
    BottomBarVisibility.shown,
  );
  final ValueNotifier<double> _visibleHeight = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();

    // Theme.of is unavailable here; didChangeDependencies re-syncs against
    // the fully resolved theme before the first build.
    final theme = widget.theme ?? const BottomBarThemeData();
    _motion = _effectiveMotion(theme);
    _scrollBehavior = _effectiveScrollBehavior(theme);

    _motionController = BoundedSingleMotionController(
      motion: _motion.resolveMotion(),
      vsync: this,
      initialValue: 1,
    );
    _edgeController = BoundedSingleMotionController(
      motion: _motion.resolveMotion(),
      vsync: this,
    );
    _minimizeController =
        BoundedSingleMotionController(
            motion: _motion.resolveMotion(),
            vsync: this,
          )
          ..addStatusListener(_handleMinimizeStatus)
          ..addListener(_syncAccessoryPlacement);

    _dispatcher = ScrollNotificationDispatcher(
      deltaThreshold: _scrollBehavior.deltaThreshold,
      reverse: _scrollReverse(_scrollBehavior),
      showAtStart: _scrollBehavior.showAtStart,
      showOnScrollEnd: _scrollBehavior.showOnScrollEnd,
      predicate: _scrollBehavior.predicate,
      restoreTabVisibility: _restoresTabs(_scrollBehavior),
      followScroll: _follows(_scrollBehavior),
      onShouldHide: (away) =>
          away ? _scrollAway() : _go(BottomBarVisibility.shown),
      onFollow: _follow,
      onFollowEnd: _settleFollow,
    );

    widget.controller?.attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionAndScroll(_resolvedTheme(context));
    if (_disableAnimations) {
      if (!_tracking) _animate(_motionController, _targetVisible ? 1 : 0);
      _animate(_minimizeController, _pill ? 1 : 0);
      _animate(_edgeController, _atEdge ? 1 : 0);
    }
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      widget.controller?.attach(this);
      oldWidget.controller?.detach(this);
    }

    if (_visibility == BottomBarVisibility.minimized && !_hasPill) {
      // The pill is gone, so the bar hides. Not during build: _go notifies
      // listeners outside this widget.
      final transition = _visibilityTransition;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && transition == _visibilityTransition) {
          _go(BottomBarVisibility.minimized);
        }
      });
    }

    _syncMotionAndScroll(_resolvedTheme(context));
  }

  void _syncMotionAndScroll(BottomBarThemeData theme) {
    final newMotion = _effectiveMotion(theme);
    final newScroll = _effectiveScrollBehavior(theme);

    if (_motion != newMotion) {
      _motionController.motion = newMotion.resolveMotion();
      _edgeController.motion = newMotion.resolveMotion();
      _minimizeController.motion = newMotion.resolveMotion();
    }

    if (_scrollBehavior != newScroll) {
      _dispatcher.deltaThreshold = newScroll.deltaThreshold;
      _dispatcher.reverse = _scrollReverse(newScroll);
      _dispatcher.showAtStart = newScroll.showAtStart;
      _dispatcher.showOnScrollEnd = newScroll.showOnScrollEnd;
      _dispatcher.predicate = newScroll.predicate;
      _dispatcher.restoreTabVisibility = _restoresTabs(newScroll);
      _dispatcher.followScroll = _follows(newScroll);
      if (_tracking && !_follows(newScroll)) {
        // Not during build: _go notifies listeners outside this widget.
        SchedulerBinding.instance.addPostFrameCallback((_) => _settleFollow(0));
      }
    }

    _motion = newMotion;
    _scrollBehavior = newScroll;
  }

  static bool _follows(BottomBarScrollBehavior behavior) =>
      behavior.followScroll &&
      behavior.hideOnScroll &&
      behavior.minimizeBehavior == BottomBarMinimizeBehavior.never;

  static bool _restoresTabs(BottomBarScrollBehavior behavior) =>
      behavior.visibilityOnTabChange == BottomBarTabVisibility.restore;

  /// The dispatcher's "away" direction: the minimize mode's when minimizing,
  /// [BottomBarScrollBehavior.reverse] otherwise.
  static bool _scrollReverse(BottomBarScrollBehavior behavior) =>
      switch (behavior.minimizeBehavior) {
        BottomBarMinimizeBehavior.never => behavior.reverse,
        BottomBarMinimizeBehavior.onScrollDown => false,
        BottomBarMinimizeBehavior.onScrollUp => true,
      };

  // -- visibility state machine ----------------------------------------------

  /// Whether the bar has a compact pill to minimize into.
  bool get _hasPill =>
      widget.compactChild != null || selectedItemOf(widget.child) != null;

  /// A scroll moved in the direction that gets the bar out of the way. With a
  /// minimize mode it minimizes a shown bar; otherwise it hides a visible
  /// bar, if [BottomBarScrollBehavior.hideOnScroll] allows.
  void _scrollAway() {
    final minimizes =
        _scrollBehavior.minimizeBehavior != BottomBarMinimizeBehavior.never;
    if (minimizes
        ? _visibility != BottomBarVisibility.shown
        : !_scrollBehavior.hideOnScroll) {
      return;
    }
    if (_scrollBehavior.keepVisibleOnFocus && _barFocusNode.hasFocus) return;
    _go(minimizes ? BottomBarVisibility.minimized : BottomBarVisibility.hidden);
  }

  /// Moves the bar [delta] logical pixels toward hidden, out of its full
  /// footprint. Visibility changes only when the scroll settles.
  void _follow(double delta) {
    final travel = _barHeight.value;
    if (!mounted || travel <= 0) return;
    if (delta > 0 &&
        _scrollBehavior.keepVisibleOnFocus &&
        _barFocusNode.hasFocus) {
      return;
    }
    final from = _motionController.value;
    final to = (from.clamp(0.0, 1.0) - delta / travel).clamp(0.0, 1.0);
    if (to == from && !_motionController.isAnimating) return;
    _tracking = true;
    _motionController
      ..stop(canceled: true)
      ..value = to;
  }

  /// Settles a followed bar on the spring: toward [velocity], in logical
  /// pixels per second toward hidden, when it is a fling, else to the nearer
  /// state.
  void _settleFollow(double velocity) {
    if (!_tracking) return;
    final hide = velocity.abs() >= kMinFlingVelocity
        ? velocity > 0
        : _motionController.value < 0.5;
    final travel = _barHeight.value;
    _go(
      hide ? BottomBarVisibility.hidden : BottomBarVisibility.shown,
      velocity: travel > 0 ? -velocity / travel : null,
    );
  }

  /// [_go] for a call from outside the scroll, such as the controller. It
  /// wins over a scroll in progress, which leaves the bar alone until it
  /// ends.
  void _goHolding(BottomBarVisibility next, {bool focusSelected = false}) {
    _dispatcher.holdFollow();
    _go(next, focusSelected: focusSelected);
  }

  /// Moves the bar to [next]. A bar with no pill hides instead of
  /// minimizing. Hiding keeps the bar's shape, so a minimized bar slides out
  /// as a pill. Focus follows: into the pill when the full bar minimizes
  /// around it, and to the selected item when the pill expands while
  /// focused or with [focusSelected].
  ///
  /// Settles the bar on the spring, starting at [velocity].
  void _go(
    BottomBarVisibility next, {
    bool focusSelected = false,
    double? velocity,
  }) {
    if (!mounted) return;
    if (next == BottomBarVisibility.minimized && !_hasPill) {
      next = BottomBarVisibility.hidden;
    }
    final settles = _tracking;
    _tracking = false;
    if (next == _visibility) {
      if (settles) {
        _animate(_motionController, _targetVisible ? 1 : 0, velocity: velocity);
      }
      return;
    }
    final transition = ++_visibilityTransition;
    final wasVisible = _targetVisible;
    final focusTarget = switch ((_visibility, next)) {
      (BottomBarVisibility.shown, BottomBarVisibility.minimized)
          when _fullFocusNode.hasFocus =>
        () => _pillFocusNode,
      (BottomBarVisibility.minimized, BottomBarVisibility.shown)
          when focusSelected || _pillFocusNode.hasFocus =>
        _selectedItemFocusNode,
      _ => null,
    };
    if (focusTarget != null) {
      // The side gaining focus can take it only after this rebuild.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && transition == _visibilityTransition) {
          focusTarget()?.requestFocus();
        }
      });
    }
    setState(() {
      _visibility = next;
      if (next != BottomBarVisibility.hidden) {
        _pill = next == BottomBarVisibility.minimized;
      }
    });
    _visibilityNotifier.value = next;
    if (transition != _visibilityTransition) return;
    _isVisibleNotifier.value = _targetVisible;
    if (transition != _visibilityTransition) return;
    _animate(_motionController, _targetVisible ? 1 : 0, velocity: velocity);
    _animate(_minimizeController, _pill ? 1 : 0);
    _syncVisibleHeight();
    if (transition != _visibilityTransition) return;
    widget.controller?.updateVisibilityState(this, next);
    if (transition != _visibilityTransition) return;

    final visible = _targetVisible;
    if (visible == wasVisible) return;
    widget.onVisibilityChanged?.call(visible);
    if (transition != _visibilityTransition) return;
    if (visible) {
      widget.onBottomBarShown?.call();
    } else {
      widget.onBottomBarHidden?.call();
    }
  }

  /// The selected item's focus node in the full bar, or its first one when
  /// no [BottomBarItem] is selected.
  FocusNode? _selectedItemFocusNode() {
    final child = widget.child;
    final index = child is BottomBarItems ? child.selectedIndex : null;
    final selected = child is BottomBarItems && index != null && index >= 0
        ? child.children.elementAtOrNull(index)
        : null;
    final nodes = _fullFocusNode.traversalDescendants;
    return nodes
            .where(
              (node) =>
                  selected != null &&
                  identical(
                    node.context
                        ?.findAncestorWidgetOfExactType<BottomBarItem>(),
                    selected,
                  ),
            )
            .firstOrNull ??
        nodes.firstOrNull;
  }

  /// The pill: [BottomBar.compactChild], or the selected item's icon.
  Widget _buildCompact() {
    final item = selectedItemOf(widget.child);
    final custom = widget.compactChild;
    return CompactPillButton(
      focusNode: _pillFocusNode,
      // A touch takes no focus, or keepVisibleOnFocus would stop the next
      // scroll from minimizing the bar.
      onTap: () => _goHolding(
        BottomBarVisibility.shown,
        focusSelected:
            FocusManager.instance.highlightMode ==
            FocusHighlightMode.traditional,
      ),
      label: custom == null && item != null
          ? itemSemanticsLabel(item, BottomBarLocalizations.of(context))
          : null,
      child:
          custom ??
          (item == null
              ? const SizedBox.shrink()
              : DefaultCompactPill(item: item)),
    );
  }

  /// Drops the pill from the tree once the bar has fully expanded.
  void _handleMinimizeStatus(AnimationStatus status) {
    if (status.isDismissed && !_pill && mounted) setState(() {});
  }

  void _syncVisibleHeight() {
    _visibleHeight.value = switch (_visibility) {
      BottomBarVisibility.shown => _barHeight.value,
      BottomBarVisibility.hidden => 0,
      BottomBarVisibility.minimized => _minimizedHeight(),
    };
  }

  /// The footprint from the top of the pill or the side pieces down, with
  /// the same margin above it as the full bar has.
  double _minimizedHeight() {
    final group = _resolveBarRenderBox();
    final host = _minimizeHostKey.currentContext?.findRenderObject();
    final pill = host is RenderMinimizeHost && group != null
        ? host.compactRectIn(group)
        : null;
    if (pill == null) return _barHeight.value;
    final pieces = group is RenderBarGroup ? group.piecesTop : null;
    return math.max(
      0,
      _barHeight.value - math.min(pill.top, pieces ?? double.infinity),
    );
  }

  // -- BottomBarBindingForController -----------------------------------------

  @override
  bool get isVisible => _targetVisible;

  @override
  void requestVisible(bool visible) => _goHolding(
    visible ? BottomBarVisibility.shown : BottomBarVisibility.hidden,
  );

  @override
  BottomBarVisibility get visibility => _visibility;

  @override
  void requestVisibility(BottomBarVisibility visibility) =>
      _goHolding(visibility);

  @override
  Future<void> scrollToBoundary({required bool toEnd}) async {
    // The scroll ends shown, so a bar the finger left midway goes there now.
    _dispatcher.holdFollow();
    if (_tracking) _go(BottomBarVisibility.shown);
    if (await _scrollActiveToBoundary(toEnd: toEnd)) {
      _go(BottomBarVisibility.shown);
    }
  }

  void _scrollToStartOnReselect() {
    _goHolding(BottomBarVisibility.shown);
    _scrollActiveToBoundary(toEnd: false);
  }

  Future<void> _handleActionTap() async {
    _dispatcher.holdFollow();
    await _scrollActiveToBoundary(toEnd: _scrollBehavior.scrollOpposite);
    _go(BottomBarVisibility.shown);
  }

  /// Animates the active scrollable to a boundary. Returns `false` without
  /// doing anything when no scrollable is active.
  Future<bool> _scrollActiveToBoundary({required bool toEnd}) async {
    // A NestedScrollView splits scrolling across two coordinated positions —
    // an outer one driving the header slivers (e.g. SliverAppBar/
    // FlexibleSpaceBar) and an inner one driving the body. Animating the single
    // last-active position only resets one of them, leaving the header
    // collapsed.
    //
    // The two positions are not independent: NestedScrollView routes every
    // `animateTo` through a shared coordinator, so a single call already drives
    // both. Driving the *outer* controller to its top expands the header and
    // pulls the inner body to the top with it; driving the *inner* controller
    // to its bottom collapses the header and scrolls the body to the end. We
    // therefore issue exactly one call — animating both controllers at once
    // would have them fight over the coordinator and land at the wrong offset.
    final active = _dispatcher.activeScrollable();
    if (active == null) return false;
    final position = active.position;

    final nested = _nestedScrollViewOf(active.context);
    final controller = nested == null
        ? null
        : _nestedBoundaryControllerForPosition(
            nested,
            position: position,
            toEnd: toEnd,
          );
    final targets = controller?.positions ?? [position];
    await Future.wait([
      for (final target in targets)
        target.animateTo(
          toEnd ? target.maxScrollExtent : target.minScrollExtent,
          duration: _motion.duration,
          curve: _motion.curve,
        ),
    ]);
    return true;
  }

  @override
  void reportScroll({required double delta}) {
    if (!mounted) return;
    _dispatcher.handleDelta(delta);
  }

  /// Returns the [NestedScrollViewState] enclosing [context], or `null` if the
  /// active scrollable is not inside a [NestedScrollView] (or the context is no
  /// longer mounted).
  NestedScrollViewState? _nestedScrollViewOf(BuildContext? context) {
    if (context == null || !context.mounted) return null;
    return context.findAncestorStateOfType<NestedScrollViewState>();
  }

  /// Picks the controller that must be driven when [position] belongs to a
  /// [NestedScrollView]: the outer one to reach the top, the inner one to
  /// reach the bottom. Returns `null` when [position] is not one of its own.
  ScrollController? _nestedBoundaryControllerForPosition(
    NestedScrollViewState nested, {
    required ScrollPosition position,
    required bool toEnd,
  }) {
    bool owns(ScrollController c) =>
        c.positions.any((p) => identical(p, position));
    if (owns(nested.outerController) || owns(nested.innerController)) {
      return toEnd ? nested.innerController : nested.outerController;
    }
    return null;
  }

  // -- theme resolution ------------------------------------------------------

  BottomBarThemeData _resolvedTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final builtIn = BottomBarThemeData(
      barDecoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      iconDecoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
      iconWidth: 30,
      iconHeight: 30,
    );
    final ext = Theme.of(context).extension<BottomBarThemeData>();
    return builtIn.merge(ext).merge(widget.theme);
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    _motionController.dispose();
    _edgeController.dispose();
    _minimizeController.dispose();
    _accessoryPlacement.dispose();
    _barHeight.dispose();
    _isVisibleNotifier.dispose();
    _visibilityNotifier.dispose();
    _visibleHeight.dispose();
    _barFocusNode.dispose();
    _fullFocusNode.dispose();
    _pillFocusNode.dispose();
    super.dispose();
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = _resolvedTheme(context);
    final l = _effectiveLayout(theme);
    _tracksEdge = theme.scrollEdgeSurface != null;
    _scheduleTargetCheck();
    final slideOutsideLayout =
        _motion.transition == BottomBarTransition.slide &&
        _motion.transitionBuilder == null;

    Widget bar = _wrapWithSafeArea(
      l,
      insetInside: l.docked,
      onSizeChanged: _handleBarFootprintChanged,
      child: _buildBottomBar(theme, l, animate: !slideOutsideLayout),
    );
    if (slideOutsideLayout) {
      final follows = _follows(_scrollBehavior);
      bar = ValueListenableBuilder(
        valueListenable: _barHeight,
        child: bar,
        builder: (context, footprint, bar) => AnimatedBuilder(
          animation: follows ? _motionController : kAlwaysCompleteAnimation,
          child: bar,
          builder: (context, bar) => VisibilityAnimator(
            animation: _motionController,
            isVisible: _tracking ? _motionController.value > 0 : _targetVisible,
            motion: _motion,
            slideTargetResolver: _resolveBarRenderBox,
            slideTravel: follows && footprint > 0 ? footprint : null,
            child: bar!,
          ),
        ),
      );
    }

    final bottomInset = _avoidsBottomInset(l)
        ? (MediaQuery.maybePaddingOf(context)?.bottom ?? 0)
        : 0.0;

    return Stack(
      fit: l.fit,
      alignment: l.effectiveAlignment,
      clipBehavior: l.clip,
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleScrollMetrics,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleBodyScrollNotification,
            child: BottomBarScope(
              barHeight: _barHeight,
              isVisible: _isVisibleNotifier,
              visibility: _visibilityNotifier,
              visibleHeight: _visibleHeight,
              bottomInset: bottomInset,
              child: widget.body,
            ),
          ),
        ),
        if (widget.showIcon)
          _wrapWithSafeArea(
            l,
            translate: l.resolveIconOffset(Directionality.of(context)),
            child: AnimatedBuilder(
              animation: _follows(_scrollBehavior)
                  ? _motionController
                  : kAlwaysCompleteAnimation,
              builder: (context, _) => _buildIcon(theme),
            ),
          ),
        bar,
      ],
    );
  }

  bool _handleBodyScrollNotification(ScrollNotification notification) {
    _dispatcher.handle(notification);
    return false;
  }

  /// The bar's vertical side of the stack, from -1 (top) to 1 (bottom).
  double _alignmentY(BottomBarLayout l) =>
      l.effectiveAlignment.resolve(Directionality.of(context)).y;

  /// Whether the bar keeps clear of the bottom inset, and so counts it in
  /// its footprint. A top-aligned bar ignores the bottom inset.
  bool _avoidsBottomInset(BottomBarLayout l) =>
      l.respectSafeArea && _alignmentY(l) >= 0;

  /// Places [child] in the stack. With [insetInside] the safe-area padding is
  /// left to [child], which paints under the inset instead.
  Widget _wrapWithSafeArea(
    BottomBarLayout l, {
    required Widget child,
    Offset translate = Offset.zero,
    ValueChanged<Size>? onSizeChanged,
    bool insetInside = false,
  }) {
    Widget content = Padding(padding: EdgeInsets.all(l.offset), child: child);
    if (MediaQuery.maybeOf(context) != null) {
      final y = _alignmentY(l);
      final outside = l.respectSafeArea && !insetInside;
      content = SafeArea(
        top: outside && y <= 0,
        bottom: outside && y >= 0,
        left: outside,
        right: outside,
        child: content,
      );
    }
    if (onSizeChanged != null) {
      content = SizeObserver(onSizeChanged: onSizeChanged, child: content);
    }
    // Translate outside the SafeArea/Padding so the offset wraps everything
    // below it. Transform keeps hit-testing aligned with the painted position
    // for its own subtree, so any size-checking ancestor (the SafeArea's
    // RenderPadding) must sit beneath the Transform — otherwise large offsets
    // move the icon outside its untranslated hit rect and taps stop landing.
    if (translate != Offset.zero) {
      content = Transform.translate(offset: translate, child: content);
    }
    content = Align(alignment: l.effectiveAlignment, child: content);
    if (l.avoidKeyboard) {
      // Always wrap, even at zero inset: inserting the Transform only when the
      // keyboard opens would remount the bar and drop a focused text field.
      content = Transform.translate(
        offset: Offset(
          0,
          -(MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0),
        ),
        child: content,
      );
    }
    return content;
  }

  void _handleBarFootprintChanged(Size size) {
    if (!mounted || _barHeight.value == size.height) return;
    _barHeight.value = size.height;
    _syncVisibleHeight();
  }

  Widget _buildIcon(BottomBarThemeData theme) {
    // _resolvedTheme always seeds iconWidth/iconHeight.
    final iconWidth = theme.iconWidth!;
    final iconHeight = theme.iconHeight!;
    return BottomBarAction(
      animation: ReverseAnimation(_motionController),
      enabled: _tracking ? _motionController.value <= 0 : !_targetVisible,
      visualWidth: iconWidth,
      visualHeight: iconHeight,
      decoration: theme.iconDecoration ?? const BoxDecoration(),
      tooltip: _defaultIconTooltip,
      semanticLabel: _defaultIconSemanticLabel,
      onTap: _handleActionTap,
      visualBuilder: (width, height) => _buildIconChild(width, height),
    );
  }

  String get _defaultIconTooltip {
    final strings = BottomBarLocalizations.of(context);
    return widget.iconTooltip ??
        (_scrollBehavior.scrollOpposite
            ? strings.scrollToBottom
            : strings.scrollToTop);
  }

  String get _defaultIconSemanticLabel {
    return widget.iconSemanticLabel ?? _defaultIconTooltip;
  }

  /// Springs [controller] to [target] from wherever it is, so a change
  /// mid-flight turns around smoothly. Reduced motion snaps.
  void _animate(
    BoundedSingleMotionController controller,
    double target, {
    double? velocity,
  }) {
    if (controller.value == target && !controller.isAnimating) return;
    if (_disableAnimations) {
      controller.stop(canceled: true);
      controller.value = target;
      return;
    }
    controller.animateTo(target, forward: target == 1, withVelocity: velocity);
  }

  // -- scroll edge -----------------------------------------------------------

  /// Content closer than this to the bar's side of the viewport does not
  /// count as under the bar, so a fling that settles a fraction short of the
  /// end stays at the edge.
  static const double _edgeTolerance = 1;

  bool _tracksEdge = false;
  bool _atEdge = false;
  bool _edgeSeen = false;
  bool _targetCheckScheduled = false;

  /// Re-reads the list the bar follows after every frame. One check covers
  /// scrolls, flings, content changes and tab switches, none of which
  /// reliably notify the bar.
  void _scheduleTargetCheck() {
    if (_targetCheckScheduled) return;
    _targetCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _targetCheckScheduled = false;
      if (!mounted) return;
      _followTarget();
      _syncVisibleHeight();
      _scheduleTargetCheck();
    });
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    _dispatcher.track(notification);
    _followTarget();
    return false;
  }

  /// Applies a tab change and the scroll edge of the list the bar follows.
  /// Keeps both as they are while a page swipe settles.
  void _followTarget() {
    final (:active, :paging) = _dispatcher.resolve();
    if (paging) return;
    if (_tracking && !_dispatcher.isFollowing) _settleFollow(0);
    final tabVisibility = active == null
        ? null
        : _dispatcher.enterTab(active.tab, current: _visibility);
    if (tabVisibility != null) _go(tabVisibility);
    // A new tab shows its own edge at once, not a fade from the old tab's.
    if (_tracksEdge) _syncEdge(active, snap: tabVisibility != null);
  }

  void _syncEdge(ActiveScrollable? active, {required bool snap}) {
    final atEdge =
        active != null && _isAtScrollEdge(active.position, active.context);
    // The first list the bar sees sets the surface without a transition, so
    // a short list never animates in from the standard surface.
    snap |= !_edgeSeen;
    _edgeSeen |= active != null;
    final target = atEdge ? 1.0 : 0.0;
    final changed = atEdge != _atEdge;
    _atEdge = atEdge;
    if (snap || _disableAnimations) {
      if (_edgeController.value != target) {
        _edgeController.stop(canceled: true);
        _edgeController.value = target;
      }
      return;
    }
    if (changed) _edgeController.animateTo(target, forward: atEdge);
  }

  /// Whether no content of [position]'s list reaches under the bar. Inside a
  /// [NestedScrollView] the outer header must be collapsed too, since a
  /// floating header pushes the inner list's end back under the bar.
  bool _isAtScrollEdge(ScrollPosition position, BuildContext context) {
    final nested = _nestedScrollViewOf(context);
    if (nested != null) {
      bool owns(ScrollController c) =>
          c.positions.any((p) => identical(p, position));
      final inner = owns(nested.innerController)
          ? [position]
          : owns(nested.outerController)
          ? nested.innerController.positions.where(
              ScrollNotificationDispatcher.isPositionVisible,
            )
          : null;
      if (inner != null) {
        return [
          ...nested.outerController.positions,
          ...inner,
        ].where((p) => p.hasPixels && p.hasContentDimensions).every(_isAtEnd);
      }
    }
    return _isAtEnd(position);
  }

  static bool _isAtEnd(ScrollPosition position) {
    final under = switch (position.axisDirection) {
      AxisDirection.down => position.extentAfter,
      AxisDirection.up => position.extentBefore,
      AxisDirection.left || AxisDirection.right => double.infinity,
    };
    return under <= _edgeTolerance;
  }

  bool get _disableAnimations => reduceMotion(context);

  Widget _buildIconChild(double iconWidth, double iconHeight) {
    if (widget.icon != null) {
      return widget.icon!(iconWidth, iconHeight);
    }
    return Center(
      child: Icon(
        _scrollBehavior.scrollOpposite
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded,
        color: Theme.of(context).colorScheme.onPrimary,
        size: math.min(iconWidth, iconHeight) / 2,
      ),
    );
  }

  RenderBox? _resolveBarRenderBox() {
    final renderObject = _barRenderKey.currentContext?.findRenderObject();
    return renderObject is RenderBox ? renderObject : null;
  }

  Widget _buildBottomBar(
    BottomBarThemeData theme,
    BottomBarLayout l, {
    required bool animate,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final edgeSurface = _effectiveSurface(theme.scrollEdgeSurface);
        final surface = _effectiveSurface(
          theme.surface ??
              (edgeSurface == null ? null : _decorationSurface(theme, l)),
        );
        final fadesItself =
            surface != null &&
            _motion.transitionBuilder == null &&
            (_motion.transition == BottomBarTransition.fade ||
                _motion.transition == BottomBarTransition.slideAndFade);
        final radius = _effectiveBarBorderRadius(theme, l);
        Widget piece(
          String slot,
          Widget child, {
          Animation<double>? minimize,
          Animation<double>? capsule,
        }) {
          final childKey = switch (slot) {
            'leading' => _leadingPieceKey,
            'trailing' => _trailingPieceKey,
            _ => null,
          };
          if (childKey != null) {
            child = KeyedSubtree(key: childKey, child: child);
          }
          if (widget.accessory != null) {
            final rank = switch (slot) {
              'leading' => _pill ? 0.0 : 1.0,
              'pill' => _pill ? 1.0 : 2.0,
              'accessory' => _pill ? 2.0 : 0.0,
              _ => 3.0,
            };
            child = FocusTraversalOrder(
              order: NumericFocusOrder(rank),
              child: Semantics(
                container: true,
                sortKey: OrdinalSortKey(rank),
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: child,
                ),
              ),
            );
          }
          return BarSurface(
            key: ValueKey(slot),
            decoration: surface == null
                ? _effectiveBarDecoration(theme, l)
                : BoxDecoration(borderRadius: radius),
            surface: surface,
            edgeSurface: edgeSurface,
            edge: _edgeController,
            visibility: _motionController,
            fades: fadesItself,
            backdropKey: _backdropKey,
            minimize: minimize,
            capsule: capsule,
            child: Material(
              color: Colors.transparent,
              borderRadius: capsule == null ? radius : null,
              child: child,
            ),
          );
        }

        final leading = l.docked ? null : widget.leading;
        final trailing = l.docked ? null : widget.trailing;
        final accessory = widget.accessory;
        final sides = l.docked && l.respectSafeArea
            ? MediaQuery.maybePaddingOf(context) ?? EdgeInsets.zero
            : EdgeInsets.zero;
        final content = MinimizeHost(
          key: _minimizeHostKey,
          progress: _minimizeController,
          minimized: _pill,
          flushStart: leading != null,
          full: Focus(focusNode: _fullFocusNode, child: widget.child),
          compact: _pill || _minimizeController.value != 0
              ? _buildCompact()
              : null,
        );
        Widget orderGroup(Widget group) => accessory == null
            ? group
            : FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: group,
              );
        final bar = Semantics(
          textDirection: Directionality.of(context),
          child: Focus(
            focusNode: _barFocusNode,
            child: ItemThemeScope(
              items: theme.items,
              scrollToStart: _scrollToStartOnReselect,
              child: SizedBox(
                width: _effectiveBarWidth(constraints, l),
                child: orderGroup(
                  BarGroup(
                    key: _barRenderKey,
                    pillIndex: leading == null ? 0 : 1,
                    spacing: l.groupSpacing,
                    hasAccessory: accessory != null,
                    accessoryInset: l.docked
                        ? EdgeInsets.only(
                            left: l.groupSpacing + sides.left,
                            right: l.groupSpacing + sides.right,
                          )
                        : EdgeInsets.zero,
                    minimize: accessory == null ? null : _minimizeController,
                    children: [
                      if (leading != null)
                        piece('leading', _GroupPiece(child: leading)),
                      piece(
                        'pill',
                        minimize: _minimizeController,
                        MediaQuery.maybeOf(context) != null
                            ? SafeArea(
                                top: false,
                                bottom: l.docked && l.respectSafeArea,
                                left: l.docked && l.respectSafeArea,
                                right: l.docked && l.respectSafeArea,
                                child: content,
                              )
                            : content,
                      ),
                      if (trailing != null)
                        piece('trailing', _GroupPiece(child: trailing)),
                      if (accessory != null)
                        piece(
                          'accessory',
                          capsule: _minimizeController,
                          ValueListenableBuilder(
                            valueListenable: _accessoryPlacement,
                            builder: (context, placement, child) =>
                                AccessoryPlacementScope(
                                  placement: placement,
                                  child: child!,
                                ),
                            child: Semantics(
                              container: true,
                              child: _GroupPiece(child: accessory),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final paintedBar = surface == null ? bar : RepaintBoundary(child: bar);
        if (!animate) return paintedBar;
        return AnimatedBuilder(
          animation: _follows(_scrollBehavior)
              ? _motionController
              : kAlwaysCompleteAnimation,
          child: paintedBar,
          builder: (context, child) => VisibilityAnimator(
            animation: _motionController,
            isVisible: _tracking ? _motionController.value > 0 : _targetVisible,
            motion: _motion,
            fade: !fadesItself,
            child: child!,
          ),
        );
      },
    );
  }

  /// [surface] with its colours filled in from the [ColorScheme]. High
  /// contrast swaps the glass for an opaque fill.
  BottomBarSurface? _effectiveSurface(BottomBarSurface? surface) {
    if (surface == null) return null;
    final fill = Theme.of(context).colorScheme.surfaceContainer;
    if (MediaQuery.maybeHighContrastOf(context) == true) {
      final fallback = surface.fallbackColor ?? fill;
      return BottomBarSurface(
        tint: fallback.a == 1 ? fallback : fallback.withValues(alpha: 1),
        border: surface.border,
        shadows: surface.shadows,
      );
    }
    return surface.copyWith(tint: surface.tint ?? fill);
  }

  /// The fill, gradient, border and shadows of the bar decoration as a
  /// surface, so a bar without one can still blend to the scroll edge surface.
  BottomBarSurface _decorationSurface(
    BottomBarThemeData theme,
    BottomBarLayout layout,
  ) {
    final decoration = _effectiveBarDecoration(theme, layout);
    return BottomBarSurface(
      tint: decoration?.color ?? const Color(0x00000000),
      gradient: decoration?.gradient,
      border: decoration?.border,
      shadows: decoration?.boxShadow,
    );
  }

  double _effectiveBarWidth(
    BoxConstraints constraints,
    BottomBarLayout layout,
  ) {
    final maxWidth = layout.maxWidth;
    if (maxWidth != null &&
        (maxWidth.isNaN || maxWidth.isInfinite || maxWidth < 0)) {
      throw ArgumentError.value(
        maxWidth,
        'layout.maxWidth',
        'BottomBarLayout.maxWidth must be finite and non-negative.',
      );
    }
    return math.min(
      constraints.maxWidth,
      math.min(layout.width, maxWidth ?? double.infinity),
    );
  }

  BoxDecoration? _effectiveBarDecoration(
    BottomBarThemeData theme,
    BottomBarLayout layout,
  ) {
    final decoration = theme.barDecoration;
    if (decoration == null || decoration.shape != BoxShape.rectangle) {
      return decoration;
    }
    final radius = _effectiveBarBorderRadius(theme, layout);
    return decoration.copyWith(borderRadius: radius);
  }

  BorderRadiusGeometry? _effectiveBarBorderRadius(
    BottomBarThemeData theme,
    BottomBarLayout layout,
  ) {
    final decoration = theme.barDecoration;
    final hasExplicitLayoutOverride =
        widget.layout != null || theme.layout != null;
    if (hasExplicitLayoutOverride) return layout.effectiveBorderRadius;
    return decoration?.borderRadius;
  }
}

/// Colours and sizes a side piece's icons like the bar's unselected items.
class _GroupPiece extends StatelessWidget {
  const _GroupPiece({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = itemThemeOf(context);
    return IconTheme.merge(
      data: IconThemeData(
        color: items.color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        size: items.iconSize,
      ),
      child: child,
    );
  }
}
