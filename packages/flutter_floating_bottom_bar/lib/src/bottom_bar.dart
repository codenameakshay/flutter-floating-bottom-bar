import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/src/bottom_bar_scroll_controller_provider.dart';

/// [width] & [height] can be used to animate the size of the back to top icon.
/// You can also not use them to keep your icon a constant size.
typedef BackToTopIconBuilder = Widget Function(double width, double height);

/// Imperative controller for [BottomBar].
class BottomBarController extends ChangeNotifier {
  _BottomBarState? _state;
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  bool get isAttached => _state != null;

  void show() =>
      _state?._setBarVisible(true, notifyCallbacks: true, fromController: true);

  void hide() => _state?._setBarVisible(
        false,
        notifyCallbacks: true,
        fromController: true,
      );

  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  Future<void> scrollToStart() async {
    await _state?._scrollToBoundary(scrollOpposite: false);
  }

  Future<void> scrollToEnd() async {
    await _state?._scrollToBoundary(scrollOpposite: true);
  }

  void _attach(_BottomBarState state) {
    _state = state;
    _updateVisibility(state._isBarVisible, shouldNotify: false);
  }

  void _detach(_BottomBarState state) {
    if (_state == state) {
      _state = null;
    }
  }

  void _updateVisibility(bool value, {bool shouldNotify = true}) {
    if (_isVisible == value) {
      return;
    }

    _isVisible = value;
    if (shouldNotify) {
      notifyListeners();
    }
  }
}

/// A floating bottom navigation bar that hides on scroll
/// up and down on the page, with powerful options
/// for controlling the look and feel.
class BottomBar extends StatefulWidget {
  /// The widget displayed below the `BottomBar`.
  ///
  /// This is useful, if the `BottomBar` should react
  /// to scroll events (i.e. hide from view when a [Scrollable]
  /// is being scrolled down and show it again when scrolled up).
  ///
  /// For that, use this exposed `ScrollController` and
  /// you can also add listeners on this `ScrollController`.
  final Widget Function(BuildContext context, ScrollController controller) body;

  ///
  /// This is the child inside the `BottomBar`.
  /// Add a TabBar or any other thing that you want to be floating here.
  final Widget child;

  ///
  /// This is the scroll to top button. It will be hidden when the
  /// `BottomBar` is scrolled up. It will be shown when the `BottomBar`
  /// is scrolled down. Clicking it will scroll the bar on top.
  ///
  /// You can hide this by using the `showIcon` property.
  ///
  /// `width` & `height` can be used to animate the size of the back to top icon.
  /// You can also not use them to keep your icon a constant size.
  final BackToTopIconBuilder? icon;

  ///
  /// The width of the scroll to top button.
  final double iconWidth;

  ///
  /// The height of the scroll to top button.
  final double iconHeight;

  ///
  /// The color of the `BottomBar`.
  final Color barColor;

  ///
  /// The BoxDecoration for the `BottomBar`.
  final BoxDecoration? barDecoration;

  ///
  /// The BoxDecoration for the scroll to top icon shown when `BottomBar` is hidden.
  final BoxDecoration? iconDecoration;

  ///
  /// The end position in `y-axis` of the SlideTransition of the `BottomBar`.
  final double end;

  ///
  /// The start position in `y-axis` of the SlideTransition of the `BottomBar`.
  final double start;

  ///
  /// The padding/offset from all sides of the bar in double.
  final double offset;

  ///
  /// The duration of the `SlideTransition` of the `BottomBar`.
  final Duration duration;

  ///
  /// The curve of the `SlideTransition` of the `BottomBar`.
  final Curve curve;

  ///
  /// The width of the `BottomBar`.
  final double width;

  ///
  /// The border radius of the `BottomBar`.
  final BorderRadius borderRadius;

  ///
  /// If you don't want the scroll to top button to be visible,
  /// set this to `false`.
  final bool showIcon;

  ///
  /// The alignment of the Bar and the icon in the Stack in which the `BottomBar` is placed.
  final Alignment barAlignment;

  ///
  /// The callback when the `BottomBar` is shown i.e. on response to scroll events.
  final VoidCallback? onBottomBarShown;

  ///
  /// The callback when the `BottomBar` is hidden i.e. on response to scroll events.
  final VoidCallback? onBottomBarHidden;

  /// Callback fired when visibility changes.
  final ValueChanged<bool>? onVisibilityChanged;

  /// Optional imperative controller for show/hide and scroll actions.
  final BottomBarController? controller;

  ///
  /// To reverse the direction in which the scroll reacts, i.e. if you want to make
  /// the bar visible when you scroll down and hide it when you scroll up, set this
  /// to `true`.
  final bool reverse;

  ///
  /// To reverse the direction in which the scroll to top button scrolls, i.e. if
  /// you want to scroll to bottom, set this to `true`.
  final bool scrollOpposite;

  ///
  /// If you don't want the bar to be hidden ever, set this to `false`.
  final bool hideOnScroll;

  /// The minimum absolute pixel delta required to react to scroll changes.
  final double scrollDeltaThreshold;

  /// The fit property of the `Stack` in which the `BottomBar` is placed.
  final StackFit fit;

  ///
  /// The clipBehaviour property of the `Stack` in which the `BottomBar` is placed.
  final Clip clip;

  ///
  /// Whether the BottomBar should respect the SafeArea.
  /// If set to false, the BottomBar will extend into the system UI areas.
  final bool respectSafeArea;

  /// Optional semantic label applied to the icon button.
  final String? iconSemanticLabel;

  /// Optional tooltip shown for the icon button.
  final String? iconTooltip;

  const BottomBar({
    required this.body,
    required this.child,
    this.icon,
    this.iconWidth = 30,
    this.iconHeight = 30,
    this.barColor = Colors.black,
    this.barDecoration,
    this.iconDecoration,
    this.end = 0,
    this.start = 2,
    this.offset = 10,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.linear,
    this.width = 300,
    this.borderRadius = BorderRadius.zero,
    this.showIcon = true,
    this.barAlignment = Alignment.bottomCenter,
    this.onBottomBarShown,
    this.onBottomBarHidden,
    this.onVisibilityChanged,
    this.controller,
    this.reverse = false,
    this.scrollOpposite = false,
    this.hideOnScroll = true,
    this.scrollDeltaThreshold = 8,
    this.fit = StackFit.loose,
    this.clip = Clip.hardEdge,
    this.respectSafeArea = true,
    this.iconSemanticLabel,
    this.iconTooltip,
    super.key,
  }) : assert(scrollDeltaThreshold >= 0, 'scrollDeltaThreshold must be >= 0');

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  late final ScrollController bodyScrollController;
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  bool _isBarVisible = true;
  bool _showIconButton = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    bodyScrollController = ScrollController();
    bodyScrollController.addListener(_handleScroll);

    _controller = AnimationController(duration: widget.duration, vsync: this);
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, widget.start),
      end: Offset(0, widget.end),
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    widget.controller?._attach(this);
    _controller.forward();
    widget.controller?._updateVisibility(true, shouldNotify: false);
  }

  @override
  void didUpdateWidget(covariant BottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  void _handleScroll() {
    if (!bodyScrollController.hasClients) {
      return;
    }

    final position = bodyScrollController.position;
    final currentOffset = position.pixels;
    final delta = currentOffset - _lastOffset;
    _lastOffset = currentOffset;

    if (delta.abs() < widget.scrollDeltaThreshold) {
      return;
    }

    final shouldHide = widget.reverse ? delta < 0 : delta > 0;
    if (shouldHide) {
      _setBarVisible(false, notifyCallbacks: true);
      return;
    }

    _setBarVisible(true, notifyCallbacks: true);
  }

  void _setBarVisible(
    bool visible, {
    required bool notifyCallbacks,
    bool fromController = false,
  }) {
    if (!mounted) {
      return;
    }

    if (!visible && !widget.hideOnScroll && !fromController) {
      return;
    }

    if (_isBarVisible == visible) {
      return;
    }

    setState(() {
      _isBarVisible = visible;
      _showIconButton = !visible;
    });

    if (visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    widget.controller?._updateVisibility(visible);

    if (notifyCallbacks) {
      widget.onVisibilityChanged?.call(visible);
      if (visible) {
        widget.onBottomBarShown?.call();
      } else {
        widget.onBottomBarHidden?.call();
      }
    }
  }

  Future<void> _scrollToBoundary({required bool scrollOpposite}) async {
    if (!bodyScrollController.hasClients) {
      return;
    }

    await bodyScrollController.animateTo(
      scrollOpposite
          ? bodyScrollController.position.maxScrollExtent
          : bodyScrollController.position.minScrollExtent,
      duration: widget.duration,
      curve: widget.curve,
    );

    _setBarVisible(true, notifyCallbacks: true, fromController: true);
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    bodyScrollController.removeListener(_handleScroll);
    bodyScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: widget.fit,
      alignment: widget.barAlignment,
      clipBehavior: widget.clip,
      children: [
        BottomBarScrollControllerProvider(
          scrollController: bodyScrollController,
          child: widget.body(context, bodyScrollController),
        ),
        if (widget.showIcon)
          Align(
            alignment: widget.barAlignment,
            child: widget.respectSafeArea
                ? SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(widget.offset),
                      child: _buildIcon(),
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(widget.offset),
                    child: _buildIcon(),
                  ),
          ),
        Align(
          alignment: widget.barAlignment,
          child: widget.respectSafeArea
              ? SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(widget.offset),
                    child: _buildBottomBar(),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(widget.offset),
                  child: _buildBottomBar(),
                ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    return AnimatedOpacity(
      duration: widget.duration,
      curve: widget.curve,
      opacity: _showIconButton ? 1 : 0,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        width: _showIconButton ? widget.iconWidth : 0,
        height: _showIconButton ? widget.iconHeight : 0,
        decoration: widget.iconDecoration ??
            BoxDecoration(color: widget.barColor, shape: BoxShape.circle),
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
                  onTap: () =>
                      _scrollToBoundary(scrollOpposite: widget.scrollOpposite),
                  child: _buildIconChild(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconChild() {
    if (widget.icon != null) {
      return widget.icon!(
        _showIconButton ? widget.iconWidth / 2 : 0,
        _showIconButton ? widget.iconHeight / 2 : 0,
      );
    }

    return Center(
      child: Icon(
        Icons.arrow_upward_rounded,
        color: Colors.white,
        size: _showIconButton ? widget.iconWidth / 2 : 0,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        width: widget.width,
        decoration: widget.barDecoration ??
            BoxDecoration(
              color: widget.barColor,
              borderRadius: widget.borderRadius,
            ),
        child: Material(
          color: widget.barColor,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
