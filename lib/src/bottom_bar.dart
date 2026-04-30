import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

import 'bottom_bar_controller.dart';
import 'bottom_bar_scope.dart';
import 'bottom_bar_theme.dart';
import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'config/bottom_bar_scroll_behavior.dart';
import 'internal/scroll_notification_dispatcher.dart';
import 'internal/visibility_animator.dart';

/// Builds the back-to-top icon child. `width` and `height` reflect the
/// animated size at the moment of build; ignore them to keep a constant size.
typedef BackToTopIconBuilder = Widget Function(double width, double height);

/// A floating bar widget that hosts a child (tab bar, search bar, custom row,
/// anything) over a body, and can react to scrolling in the body's subtree.
class BottomBar extends StatefulWidget {
  const BottomBar({
    required this.child,
    required this.body,
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

  final Widget child;
  final Widget body;
  final BottomBarController? controller;
  final BottomBarLayout? layout;
  final BottomBarMotion? motion;
  final BottomBarScrollBehavior? scrollBehavior;
  final BottomBarThemeData? theme;
  final BackToTopIconBuilder? icon;
  final bool showIcon;
  final String? iconSemanticLabel;
  final String? iconTooltip;
  final ValueChanged<bool>? onVisibilityChanged;
  final VoidCallback? onBottomBarShown;
  final VoidCallback? onBottomBarHidden;

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin
    implements BottomBarBindingForController {
  late BoundedSingleMotionController _motionController;
  late ScrollNotificationDispatcher _dispatcher;
  late BottomBarMotion _motion;
  late BottomBarScrollBehavior _scrollBehavior;

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
  final GlobalKey _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _motion = widget.motion ?? widget.theme?.motion ?? const BottomBarMotion();
    _scrollBehavior = widget.scrollBehavior ??
        widget.theme?.scrollBehavior ??
        const BottomBarScrollBehavior();

    _motionController = BoundedSingleMotionController(
      motion: _motion.resolveMotion(),
      vsync: this,
      initialValue: 1,
    );

    _dispatcher = ScrollNotificationDispatcher(
      deltaThreshold: _scrollBehavior.deltaThreshold,
      reverse: _scrollBehavior.reverse,
      predicate: _scrollBehavior.predicate,
      onShouldHide: (hide) => _setBarVisible(!hide, notifyCallbacks: true),
    );

    widget.controller?.attach(this);
    widget.controller?.updateVisibility(true, shouldNotify: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotionAndScroll(_resolvedTheme(context));
  }

  void _measureBar() {
    final ctx = _barKey.currentContext;
    if (ctx == null) return;
    final renderBox = ctx.findRenderObject();
    if (renderBox is RenderBox && renderBox.hasSize) {
      final h = renderBox.size.height;
      if (_barHeight.value != h) _barHeight.value = h;
    }
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }

    _syncMotionAndScroll(_resolvedTheme(context));
  }

  void _syncMotionAndScroll(BottomBarThemeData theme) {
    final newMotion = _effectiveMotion(theme);
    final newScroll = _effectiveScrollBehavior(theme);

    if (_motion != newMotion) {
      _motionController.motion = newMotion.resolveMotion();
    }

    if (_scrollBehavior != newScroll) {
      _dispatcher.deltaThreshold = newScroll.deltaThreshold;
      _dispatcher.reverse = newScroll.reverse;
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
    if (_targetVisible == visible) return;

    setState(() {
      _targetVisible = visible;
    });

    _isVisibleNotifier.value = visible;

    _motionController.animateTo(visible ? 1 : 0, forward: visible);

    widget.controller?.updateVisibility(visible);

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
    final position = _dispatcher.lastActivePosition;
    if (position == null) {
      assert(() {
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(
            'BottomBarController.scrollToStart/scrollToEnd called before any '
            'scroll notification was observed; nothing to scroll.',
          ),
          library: 'flutter_floating_bottom_bar',
        ));
        return true;
      }());
      return;
    }
    await position.animateTo(
      toEnd ? position.maxScrollExtent : position.minScrollExtent,
      duration: _motion.duration,
      curve: _motion.curve,
    );
    _setBarVisible(true, notifyCallbacks: true, fromController: true);
  }

  // -- theme resolution ------------------------------------------------------

  BottomBarThemeData _resolvedTheme(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final builtIn = BottomBarThemeData(
      barDecoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      iconDecoration: BoxDecoration(
        color: cs.primary,
        shape: BoxShape.circle,
      ),
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
    _barHeight.dispose();
    _isVisibleNotifier.dispose();
    super.dispose();
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = _resolvedTheme(context);
    final l = _effectiveLayout(theme);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        _dispatcher.handle(n);
        return false; // do not absorb
      },
      child: Stack(
        fit: l.fit,
        alignment: l.alignment,
        clipBehavior: l.clip,
        children: [
          BottomBarScope(
            barHeight: _barHeight,
            isVisible: _isVisibleNotifier,
            child: widget.body,
          ),
          if (widget.showIcon) _wrapWithSafeArea(l, child: _buildIcon(theme)),
          _wrapWithSafeArea(l, child: _buildBottomBar(theme)),
        ],
      ),
    );
  }

  Widget _wrapWithSafeArea(BottomBarLayout l, {required Widget child}) {
    final padded = Padding(padding: EdgeInsets.all(l.offset), child: child);
    return Align(
      alignment: l.alignment,
      child: l.respectSafeArea ? SafeArea(child: padded) : padded,
    );
  }

  Widget _buildIcon(BottomBarThemeData theme) {
    final iconWidth = theme.iconWidth ?? 30;
    final iconHeight = theme.iconHeight ?? 30;

    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, _) {
        final iconProgress = (1 - _motionController.value).clamp(0.0, 1.0);
        return Opacity(
          opacity: iconProgress,
          child: SizedBox(
            width: iconWidth * iconProgress,
            height: iconHeight * iconProgress,
            child: DecoratedBox(
              decoration: theme.iconDecoration ?? const BoxDecoration(),
              child: ClipOval(
                child: Material(
                  color: Colors.transparent,
                  child: Semantics(
                    button: true,
                    label: widget.iconSemanticLabel,
                    child: Tooltip(
                      message: widget.iconTooltip ?? 'Scroll to top',
                      child: InkWell(
                        onTap: () => scrollToBoundary(
                          toEnd: _scrollBehavior.scrollOpposite,
                        ),
                        child: _buildIconChild(
                          iconWidth,
                          iconHeight,
                          iconProgress,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconChild(
    double iconWidth,
    double iconHeight,
    double progress,
  ) {
    if (widget.icon != null) {
      return widget.icon!(
        iconWidth / 2 * progress,
        iconHeight / 2 * progress,
      );
    }
    return Center(
      child: Icon(
        Icons.arrow_upward_rounded,
        color: Colors.white,
        size: iconWidth / 2 * progress,
      ),
    );
  }

  Widget _buildBottomBar(BottomBarThemeData theme) {
    final l = _effectiveLayout(theme);
    return VisibilityAnimator(
      animation: _motionController,
      motion: _motion,
      child: Container(
        key: _barKey,
        width: l.width,
        decoration: _effectiveBarDecoration(theme, l),
        child: Material(
          color: Colors.transparent,
          borderRadius: _effectiveBarBorderRadius(theme, l),
          child: widget.child,
        ),
      ),
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
    if (layout.borderRadius != BorderRadius.zero) return layout.borderRadius;
    return decoration?.borderRadius;
  }
}
