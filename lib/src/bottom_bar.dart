import 'package:flutter/material.dart';

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
  late AnimationController _animationController;
  late Animation<double> _curvedAnimation;
  late ScrollNotificationDispatcher _dispatcher;

  bool _isBarVisible = true;
  bool _showIconButton = false;

  BottomBarLayout _effectiveLayout(BottomBarThemeData theme) {
    return widget.layout ?? theme.layout ?? const BottomBarLayout();
  }

  BottomBarMotion _effectiveMotion(BottomBarThemeData theme) {
    return widget.motion ?? theme.motion ?? const BottomBarMotion();
  }

  BottomBarScrollBehavior _effectiveScrollBehavior(BottomBarThemeData theme) {
    return widget.scrollBehavior ?? theme.scrollBehavior ?? const BottomBarScrollBehavior();
  }

  final ValueNotifier<double> _barHeight = ValueNotifier<double>(0);
  final ValueNotifier<bool> _isVisibleNotifier = ValueNotifier<bool>(true);
  final GlobalKey _barKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    final initialMotion = widget.motion ?? const BottomBarMotion();
    final initialScroll = widget.scrollBehavior ?? const BottomBarScrollBehavior();

    _animationController = AnimationController(
      duration: initialMotion.duration,
      vsync: this,
    );
    _curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: initialMotion.curve,
    );

    _dispatcher = ScrollNotificationDispatcher(
      deltaThreshold: initialScroll.deltaThreshold,
      reverse: initialScroll.reverse,
      predicate: initialScroll.predicate,
      onShouldHide: (hide) =>
          _setBarVisible(!hide, notifyCallbacks: true),
    );

    widget.controller?.attach(this);
    _animationController.forward();
    widget.controller?.updateVisibility(true, shouldNotify: false);

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBar());
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

    final oldMotion = oldWidget.motion ?? const BottomBarMotion();
    final newMotion = widget.motion ?? const BottomBarMotion();
    final oldScroll = oldWidget.scrollBehavior ?? const BottomBarScrollBehavior();
    final newScroll = widget.scrollBehavior ?? const BottomBarScrollBehavior();

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }

    if (oldMotion.duration != newMotion.duration) {
      _animationController.duration = newMotion.duration;
    }

    if (oldMotion.curve != newMotion.curve) {
      _curvedAnimation = CurvedAnimation(
        parent: _animationController,
        curve: newMotion.curve,
      );
    }

    if (oldScroll != newScroll) {
      _dispatcher.deltaThreshold = newScroll.deltaThreshold;
      _dispatcher.reverse = newScroll.reverse;
      _dispatcher.predicate = newScroll.predicate;
    }
  }

  // -- visibility plumbing ---------------------------------------------------

  void _setBarVisible(
    bool visible, {
    required bool notifyCallbacks,
    bool fromController = false,
  }) {
    if (!mounted) return;
    final scroll = widget.scrollBehavior ?? const BottomBarScrollBehavior();
    if (!visible && !scroll.hideOnScroll && !fromController) {
      return;
    }
    if (_isBarVisible == visible) return;

    setState(() {
      _isBarVisible = visible;
      _showIconButton = !visible;
    });

    _isVisibleNotifier.value = visible;

    if (visible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

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
  bool get isVisible => _isBarVisible;

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
    final motion = widget.motion ?? const BottomBarMotion();
    await position.animateTo(
      toEnd ? position.maxScrollExtent : position.minScrollExtent,
      duration: motion.duration,
      curve: motion.curve,
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
    _animationController.dispose();
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
          if (widget.showIcon)
            _wrapWithSafeArea(l, child: _buildIcon(theme)),
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
    final motion = _effectiveMotion(theme);
    final scroll = _effectiveScrollBehavior(theme);

    return AnimatedOpacity(
      duration: motion.duration,
      curve: motion.curve,
      opacity: _showIconButton ? 1 : 0,
      child: AnimatedContainer(
        duration: motion.duration,
        curve: motion.curve,
        width: _showIconButton ? iconWidth : 0,
        height: _showIconButton ? iconHeight : 0,
        decoration: theme.iconDecoration,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
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
                    toEnd: scroll.scrollOpposite,
                  ),
                  child: _buildIconChild(iconWidth, iconHeight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconChild(double iconWidth, double iconHeight) {
    if (widget.icon != null) {
      return widget.icon!(
        _showIconButton ? iconWidth / 2 : 0,
        _showIconButton ? iconHeight / 2 : 0,
      );
    }
    return Center(
      child: Icon(
        Icons.arrow_upward_rounded,
        color: Colors.white,
        size: _showIconButton ? iconWidth / 2 : 0,
      ),
    );
  }

  Widget _buildBottomBar(BottomBarThemeData theme) {
    final l = _effectiveLayout(theme);
    final motion = _effectiveMotion(theme);
    return VisibilityAnimator(
      animation: _curvedAnimation,
      motion: motion,
      child: Container(
        key: _barKey,
        width: l.width,
        decoration: theme.barDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: l.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
