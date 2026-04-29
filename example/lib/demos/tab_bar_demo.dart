import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../widgets/infinite_list_page.dart';

class TabBarDemoPage extends StatefulWidget {
  const TabBarDemoPage({super.key});

  @override
  State<TabBarDemoPage> createState() => _TabBarDemoPageState();
}

class _TabBarDemoPageState extends State<TabBarDemoPage>
    with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;
  final List<Color> colors = [
    Colors.yellow,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 5, vsync: this);
    tabController.animation?.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        setState(() => currentPage = value);
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselectedColor =
        colors[currentPage].computeLuminance() < 0.5 ? Colors.black : Colors.white;
    final unselectedColorReverse =
        colors[currentPage].computeLuminance() < 0.5 ? Colors.white : Colors.black;
    final barFillColor = colors[currentPage].computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Tab bar demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width * 0.8,
          offset: 10,
          borderRadius: BorderRadius.circular(500),
          alignment: Alignment.bottomCenter,
          fit: StackFit.expand,
          clip: Clip.none,
        ),
        motion: const BottomBarMotion(
          duration: Duration(milliseconds: 500),
          curve: Curves.decelerate,
          slideStart: Offset(0, 3),
        ),
        scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: true),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: colors[currentPage],
            borderRadius: BorderRadius.circular(500),
          ),
          iconDecoration: BoxDecoration(
            color: unselectedColor,
            borderRadius: BorderRadius.circular(500),
          ),
          iconWidth: 30,
          iconHeight: 30,
        ),
        icon: (width, height) => Center(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: colors[currentPage],
              size: width,
            ),
          ),
        ),
        body: TabBarView(
          controller: tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(),
          children: colors
              .map((c) => InfiniteListPage(
                    key: ValueKey('infinite_list_$c'),
                    color: c,
                  ))
              .toList(),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              controller: tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: barFillColor,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              tabs: [
                _tab(Icons.home, 0, unselectedColor),
                _tab(Icons.search, 1, unselectedColor),
                _tab(Icons.add, 2, unselectedColorReverse),
                _tab(Icons.favorite, 3, unselectedColor),
                _tab(Icons.settings, 4, unselectedColor),
              ],
            ),
            Positioned(
              top: -20,
              child: FloatingActionButton(
                elevation: 0,
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, int idx, Color unselected) {
    return SizedBox(
      height: 55,
      width: 40,
      child: Center(
        child: Icon(
          icon,
          color: currentPage == idx ? colors[idx] : unselected,
        ),
      ),
    );
  }
}
