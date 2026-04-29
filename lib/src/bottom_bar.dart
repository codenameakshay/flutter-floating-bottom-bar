import 'package:flutter/material.dart';

import 'bottom_bar_controller.dart';
import 'bottom_bar_scroll_controller_provider.dart';
import 'bottom_bar_theme.dart';
import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'config/bottom_bar_scroll_behavior.dart';

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
    this.layout = const BottomBarLayout(),
    this.motion = const BottomBarMotion(),
    this.scrollBehavior = const BottomBarScrollBehavior(),
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
  final BottomBarLayout layout;
  final BottomBarMotion motion;
  final BottomBarScrollBehavior scrollBehavior;
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
  late ScrollController _legacyScrollController;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  bool _isBarVisible = true;
  bool _showIconButton = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();

    _legacyScrollController = ScrollController();
    _legacyScrollController.addListener(_handleLegacyScroll);

    _animationController = AnimationController(
      duration: widget.motion.duration,
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: widget.motion.slideStart,
      end: widget.motion.slideEnd,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: widget.motion.curve),
    );

    widget.controller?.attach(this);
    _animationController.forward();
    widget.controller?.updateVisibility(true, shouldNotify: false);
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }

    if (oldWidget.motion.duration != widget.motion.duration) {
      _animationController.duration = widget.motion.duration;
    }

    if (oldWidget.motion.slideStart != widget.motion.slideStart ||
        oldWidget.motion.slideEnd != widget.motion.slideEnd ||
        oldWidget.motion.curve != widget.motion.curve) {
      _slideAnimation = Tween<Offset>(
        begin: widget.motion.slideStart,
        end: widget.motion.slideEnd,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: widget.motion.curve,
        ),
      );
    }
  }

  // -- v1.x scroll-controller path (replaced in Phase 4) ----------------------

  void _handleLegacyScroll() {
    if (!_legacyScrollController.hasClients) return;

    final position = _legacyScrollController.position;
    final delta = position.pixels - _lastOffset;
    _lastOffset = position.pixels;

    if (delta.abs() < widget.scrollBehavior.deltaThreshold) return;

    final shouldHide = widget.scrollBehavior.reverse ? delta < 0 : delta > 0;
    _setBarVisible(!shouldHide, notifyCallbacks: true);
  }

  // -- visibility plumbing ---------------------------------------------------

  void _setBarVisible(
    bool visible, {
    required bool notifyCallbacks,
    bool fromController = false,
  }) {
    if (!mounted) return;
    if (!visible && !widget.scrollBehavior.hideOnScroll && !fromController) {
      return;
    }
    if (_isBarVisible == visible) return;

    setState(() {
      _isBarVisible = visible;
      _showIconButton = !visible;
    });

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
    if (!_legacyScrollController.hasClients) return;
    await _legacyScrollController.animateTo(
      toEnd
          ? _legacyScrollController.position.maxScrollExtent
          : _legacyScrollController.position.minScrollExtent,
      duration: widget.motion.duration,
      curve: widget.motion.curve,
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
    _legacyScrollController.removeListener(_handleLegacyScroll);
    _legacyScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // -- build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = _resolvedTheme(context);
    final l = widget.layout;

    return Stack(
      fit: l.fit,
      alignment: l.alignment,
      clipBehavior: l.clip,
      children: [
        BottomBarScrollControllerProvider(
          scrollController: _legacyScrollController,
          child: widget.body,
        ),
        if (widget.showIcon)
          _wrapWithSafeArea(
            l,
            child: _buildIcon(theme),
          ),
        _wrapWithSafeArea(
          l,
          child: _buildBottomBar(theme),
        ),
      ],
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

    return AnimatedOpacity(
      duration: widget.motion.duration,
      curve: widget.motion.curve,
      opacity: _showIconButton ? 1 : 0,
      child: AnimatedContainer(
        duration: widget.motion.duration,
        curve: widget.motion.curve,
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
                    toEnd: widget.scrollBehavior.scrollOpposite,
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
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: widget.layout.width,
        decoration: theme.barDecoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: widget.layout.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
