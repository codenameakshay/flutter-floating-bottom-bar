import 'package:floating_bar/provider/inherited_data_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BottomBar extends StatefulWidget {
  final Widget child;
  final int currentPage;
  final TabController tabController;
  const BottomBar({
    required this.child,
    required this.currentPage,
    required this.tabController,
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
  bool result = true;

  @override
  void initState() {
    myScroll();
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
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
        InheritedDataProvider(
          scrollController: scrollBottomBarController,
          child: widget.child,
        ),
        Positioned(
          bottom: 0,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      border: Border(
                        top: BorderSide(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black.withOpacity(0.16)
                                  : Colors.white.withOpacity(0.16),
                          // width: 1.0
                        ),
                      ),
                    ),
                    child: TabBar(
                      indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                      labelStyle: Theme.of(context).textTheme.caption!.copyWith(
                            color: Colors.white,
                          ),
                      controller: widget.tabController,
                      indicator: UnderlineTabIndicator(),
                      tabs: [
                        SizedBox(
                          height: 55,
                          width: 40,
                          child: Center(child: Icon(Icons.home)),
                        ),
                        SizedBox(
                          height: 55,
                          width: 40,
                          child: Center(child: Icon(Icons.home)),
                        ),
                        SizedBox(
                          height: 55,
                          width: 40,
                          child: Center(child: Icon(Icons.home)),
                        ),
                        SizedBox(
                          height: 55,
                          width: 40,
                          child: Center(child: Icon(Icons.home)),
                        ),
                        SizedBox(
                          height: 55,
                          width: 40,
                          child: Center(child: Icon(Icons.home)),
                        ),
                      ],
                    )),
              ],
            ),
          ),
        ),
        if (isOnTop == true)
          Container()
        else
          Positioned(
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              child: ClipOval(
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        scrollBottomBarController
                            .animateTo(
                          scrollBottomBarController.position.minScrollExtent,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.linear,
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
                      icon: Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
