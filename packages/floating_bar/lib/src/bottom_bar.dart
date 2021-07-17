import 'package:floating_bar/src/bottom_bar_scroll_controller_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A floating bottom navigation bar that hides on scroll
/// up and down on the page, with powerful options
/// for controlling the look and feel.
class BottomBar extends StatefulWidget {
  /// The widget displayed below the `BottomBar`.
  ///
  /// This is useful, if the `BottomBar` should react
  /// to scroll events (i.e. hide from view when a [Scrollable]
  /// is being scrolled down and show it again when scrolled up).
  final Widget Function(BuildContext context, ScrollController controller) body;

  ///
  /// This is the child inside the `BottomBar`.
  /// Add a TabBar or any other thing that you want to be floating here.
  final Widget child;

  ///
  /// This is the scroll to top button. It will be hidden when the
  /// `BottomBar` is scrolled up. It will be shown when the `BottomBar`
  /// is scrolled down. Clicking it will scroll the bar on top.
  final Widget icon;
  final Color barColor;
  final double end;
  final double start;
  final double bottom;
  final Duration duration;
  final Curve curve;
  final double width;
  final bool showIcon;
  const BottomBar({
    required this.body,
    required this.child,
    required this.icon,
    required this.barColor,
    this.end = 0,
    this.start = 2,
    this.bottom = 10,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.linear,
    this.width = 100,
    this.showIcon = true,
    Key? key,
  }) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  ScrollController scrollBottomBarController = ScrollController();
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  bool isScrollingDown = false;
  bool isOnTop = true;

  @override
  void initState() {
    myScroll();
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, widget.start),
      end: Offset(0, widget.end),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ))
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _controller.forward();
  }

  void showBottomBar() {
    if (mounted) {
      setState(() {
        _controller.forward();
      });
    }
  }

  void hideBottomBar() {
    if (mounted) {
      setState(() {
        _controller.reverse();
      });
    }
  }

  Future<void> myScroll() async {
    scrollBottomBarController.addListener(() {
      if (scrollBottomBarController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          isOnTop = false;
          hideBottomBar();
        }
      }
      if (scrollBottomBarController.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          isOnTop = true;
          showBottomBar();
        }
      }
    });
  }

  @override
  void dispose() {
    scrollBottomBarController.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.bottomCenter,
      children: [
        BottomBarScrollControllerProvider(
          scrollController: scrollBottomBarController,
          child: widget.body(context, scrollBottomBarController),
        ),
        Positioned(
          bottom: widget.bottom,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
            width: isOnTop == true ? 0 : 40,
            height: isOnTop == true ? 0 : 40,
            decoration: BoxDecoration(
              color: widget.barColor,
              shape: BoxShape.circle,
            ),
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: ClipOval(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    scrollBottomBarController
                        .animateTo(
                      scrollBottomBarController.position.minScrollExtent,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                    )
                        .then((value) {
                      if (mounted) {
                        setState(() {
                          isOnTop = true;
                          isScrollingDown = false;
                        });
                      }
                      showBottomBar();
                    });
                  },
                  child: widget.icon,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: widget.bottom,
          child: SlideTransition(
            position: _offsetAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(500),
              child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(500),
                  ),
                  child: Material(
                    color: widget.barColor,
                    child: widget.child,
                  )),
            ),
          ),
        ),
      ],
    );
  }
}
