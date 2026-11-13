import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import 'bottom_bar_controller.dart';
import 'bottom_bar_scope.dart';
import 'bottom_bar_theme.dart';
import 'internal/bar_group.dart';
import 'internal/bar_surface.dart';
import 'internal/item_theme_scope.dart';
import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'internal/reduce_motion.dart';
import 'config/bottom_bar_scroll_behavior.dart';
import 'internal/scroll_notification_dispatcher.dart';
import 'internal/size_observer.dart';
import 'internal/bottom_bar_action.dart';
import 'internal/visibility_animator.dart';
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
  /// `'Scroll to top'` or `'Scroll to bottom'`.
  final String? iconSemanticLabel;

  /// Tooltip text shown on long-press of the hidden action.
  ///
  /// Defaults to `'Scroll to top'` or `'Scroll to bottom'`, depending on
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
    implements BottomBarBindingForController {
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

  /// Every piece of the bar reads the backdrop under it once, together.
  final BackdropKey _backdropKey = BackdropKey();

  bool _targetVisible = true;
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

    _dispatcher = ScrollNotificationDispatcher(
      deltaThreshold: _scrollBehavior.deltaThreshold,
      reverse: _scrollBehavior.reverse,
      showAtStart: _scrollBehavior.showAtStart,
      showOnScrollEnd: _scrollBehavior.showOnScrollEnd,
      predicate: _scrollBehavior.predicate,
      onShouldHide: (hide) => _setBarVisible(!hide, notifyCallbacks: true),
    );

    widget.controller?.attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionAndScroll(_resolvedTheme(context));
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      widget.controller?.attach(this);
      oldWidget.controller?.detach(this);
    }

    _syncMotionAndScroll(_resolvedTheme(context));
  }

  void _syncMotionAndScroll(BottomBarThemeData theme) {
    final newMotion = _effectiveMotion(theme);
    final newScroll = _effectiveScrollBehavior(theme);

    if (_motion != newMotion) {
      _motionController.motion = newMotion.resolveMotion();
      _edgeController.motion = newMotion.resolveMotion();
    }

    if (_scrollBehavior != newScroll) {
      _dispatcher.deltaThreshold = newScroll.deltaThreshold;
      _dispatcher.reverse = newScroll.reverse;
      _dispatcher.showAtStart = newScroll.showAtStart;
      _dispatcher.showOnScrollEnd = newScroll.showOnScrollEnd;
      _dispatcher.predicate = newScroll.predicate;
    }

    _motion = newMotion;
    _scrollBehavior = newScroll;
  }

  // -- visibility plumbing ---------------------------------------------------

  void _setBarVisible(
    bool visible, {
    required bool notifyCallbacks,
    bool fromController = false,
  }) {
    if (!mounted) return;
    if (!visible && !_scrollBehavior.hideOnScroll && !fromController) {
      return;
    }
    if (!visible &&
        !fromController &&
        _scrollBehavior.keepVisibleOnFocus &&
        _barFocusNode.hasFocus) {
      return;
    }
    if (_targetVisible == visible) return;

    setState(() {
      _targetVisible = visible;
    });

    _isVisibleNotifier.value = visible;

    _animateBarTo(visible);

    widget.controller?.updateVisibility(this, visible);

    if (notifyCallbacks) {
      widget.onVisibilityChanged?.call(visible);
      if (visible) {
        widget.onBottomBarShown?.call();
      } else {
        widget.onBottomBarHidden?.call();
      }
    }
  }

  // -- BottomBarBindingForController -----------------------------------------

  @override
  bool get isVisible => _targetVisible;

  @override
  void requestVisible(bool visible) {
    _setBarVisible(visible, notifyCallbacks: true, fromController: true);
  }

  @override
  Future<void> scrollToBoundary({required bool toEnd}) async {
    if (await _scrollActiveToBoundary(toEnd: toEnd)) {
      _setBarVisible(true, notifyCallbacks: true, fromController: true);
      return;
    }
    assert(() {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError(
            'BottomBarController.scrollToStart/scrollToEnd found no attached, '
            'visible scrollable in BottomBar.body; nothing to scroll.',
          ),
          library: 'flutter_floating_bottom_bar',
        ),
      );
      return true;
    }());
  }

  void _scrollToStartOnReselect() {
    _setBarVisible(true, notifyCallbacks: true, fromController: true);
    _scrollActiveToBoundary(toEnd: false);
  }

  Future<void> _handleActionTap() async {
    await _scrollActiveToBoundary(toEnd: _scrollBehavior.scrollOpposite);
    _setBarVisible(true, notifyCallbacks: true, fromController: true);
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
    _barHeight.dispose();
    _isVisibleNotifier.dispose();
    _barFocusNode.dispose();
    super.dispose();
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = _resolvedTheme(context);
    final l = _effectiveLayout(theme);
    _tracksEdge = theme.scrollEdgeSurface != null;
    if (_tracksEdge) _scheduleEdgeCheck();
    final slideOutsideLayout =
        _motion.transition == BottomBarTransition.slide &&
        _motion.transitionBuilder == null;

    Widget bar = _wrapWithSafeArea(
      l,
      onSizeChanged: _handleBarFootprintChanged,
      child: _buildBottomBar(theme, l, animate: !slideOutsideLayout),
    );
    if (slideOutsideLayout) {
      bar = VisibilityAnimator(
        animation: _motionController,
        isVisible: _targetVisible,
        motion: _motion,
        slideTargetResolver: _resolveBarRenderBox,
        child: bar,
      );
    }

    return Stack(
      fit: l.fit,
      alignment: l.alignment,
      clipBehavior: l.clip,
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: _handleScrollMetrics,
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleBodyScrollNotification,
            child: BottomBarScope(
              barHeight: _barHeight,
              isVisible: _isVisibleNotifier,
              child: widget.body,
            ),
          ),
        ),
        if (widget.showIcon)
          _wrapWithSafeArea(
            l,
            translate: l.iconOffset,
            child: _buildIcon(theme),
          ),
        bar,
      ],
    );
  }

  bool _handleBodyScrollNotification(ScrollNotification notification) {
    _dispatcher.handle(notification);
    return false;
  }

  Widget _wrapWithSafeArea(
    BottomBarLayout l, {
    required Widget child,
    Offset translate = Offset.zero,
    ValueChanged<Size>? onSizeChanged,
  }) {
    Widget content = Padding(padding: EdgeInsets.all(l.offset), child: child);
    if (l.respectSafeArea) {
      content = SafeArea(child: content);
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
    content = Align(alignment: l.alignment, child: content);
    if (l.avoidKeyboard) {
      // Always wrap, even at zero inset: inserting the Transform only when the
      // keyboard opens would remount the bar and drop a focused text field.
      content = Transform.translate(
        offset: Offset(0, -MediaQuery.viewInsetsOf(context).bottom),
        child: content,
      );
    }
    return content;
  }

  void _handleBarFootprintChanged(Size size) {
    if (!mounted || _barHeight.value == size.height) return;
    _barHeight.value = size.height;
  }

  Widget _buildIcon(BottomBarThemeData theme) {
    // _resolvedTheme always seeds iconWidth/iconHeight.
    final iconWidth = theme.iconWidth!;
    final iconHeight = theme.iconHeight!;
    return BottomBarAction(
      animation: ReverseAnimation(_motionController),
      enabled: !_targetVisible,
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
    return widget.iconTooltip ??
        (_scrollBehavior.scrollOpposite ? 'Scroll to bottom' : 'Scroll to top');
  }

  String get _defaultIconSemanticLabel {
    return widget.iconSemanticLabel ?? _defaultIconTooltip;
  }

  void _animateBarTo(bool visible) {
    final target = visible ? 1.0 : 0.0;
    if (_disableAnimations) {
      _motionController.stop(canceled: true);
      _motionController.value = target;
      return;
    }
    _motionController.animateTo(target, forward: visible);
  }

  // -- scroll edge -----------------------------------------------------------

  /// Content closer than this to the bar's side of the viewport does not
  /// count as under the bar, so a fling that settles a fraction short of the
  /// end stays at the edge.
  static const double _edgeTolerance = 1;

  bool _tracksEdge = false;
  bool _atEdge = false;
  bool _edgeSeen = false;
  bool _edgeCheckScheduled = false;

  /// Re-reads the edge after every frame while a scroll edge surface is set.
  /// One check covers scrolls, flings, content changes and tab switches,
  /// none of which reliably notify the bar.
  void _scheduleEdgeCheck() {
    if (_edgeCheckScheduled) return;
    _edgeCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _edgeCheckScheduled = false;
      if (!mounted || !_tracksEdge) return;
      _syncEdge();
      _scheduleEdgeCheck();
    });
  }

  bool _handleScrollMetrics(ScrollMetricsNotification notification) {
    _dispatcher.track(notification);
    if (_tracksEdge) _syncEdge();
    return false;
  }

  void _syncEdge() {
    final active = _dispatcher.activeScrollable();
    final atEdge =
        active != null && _isAtScrollEdge(active.position, active.context);
    // The first list the bar sees sets the surface without a transition, so
    // a short list never animates in from the standard surface.
    final snap = !_edgeSeen;
    _edgeSeen |= active != null;
    final target = atEdge ? 1.0 : 0.0;
    if (atEdge == _atEdge) {
      if (_disableAnimations && _edgeController.value != target) {
        _edgeController.stop(canceled: true);
        _edgeController.value = target;
      }
      return;
    }
    _atEdge = atEdge;
    if (snap || _disableAnimations) {
      _edgeController.stop(canceled: true);
      _edgeController.value = target;
      return;
    }
    _edgeController.animateTo(target, forward: atEdge);
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
        Widget piece(String slot, Widget child) => BarSurface(
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
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: child,
          ),
        );
        final leading = widget.leading;
        final trailing = widget.trailing;
        // Semantics sort the pieces by the nearest text direction above
        // them, which the bar would otherwise not set.
        final bar = Semantics(
          textDirection: Directionality.of(context),
          child: Focus(
            focusNode: _barFocusNode,
            child: ItemThemeScope(
              items: theme.items,
              scrollToStart: _scrollToStartOnReselect,
              child: SizedBox(
                width: _effectiveBarWidth(constraints, l),
                child: BarGroup(
                  key: _barRenderKey,
                  pillIndex: leading == null ? 0 : 1,
                  spacing: l.groupSpacing,
                  children: [
                    if (leading != null)
                      piece('leading', _GroupPiece(child: leading)),
                    piece('pill', widget.child),
                    if (trailing != null)
                      piece('trailing', _GroupPiece(child: trailing)),
                  ],
                ),
              ),
            ),
          ),
        );
        final paintedBar = surface == null ? bar : RepaintBoundary(child: bar);
        if (!animate) return paintedBar;
        return VisibilityAnimator(
          animation: _motionController,
          isVisible: _targetVisible,
          motion: _motion,
          fade: !fadesItself,
          child: paintedBar,
        );
      },
    );
  }

  /// [surface] with its colours filled in from the [ColorScheme]. High
  /// contrast swaps the glass for an opaque fill.
  BottomBarSurface? _effectiveSurface(BottomBarSurface? surface) {
    if (surface == null) return null;
    final fill = Theme.of(context).colorScheme.surfaceContainer;
    if (MediaQuery.highContrastOf(context)) {
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
    if (hasExplicitLayoutOverride) return layout.borderRadius;
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
