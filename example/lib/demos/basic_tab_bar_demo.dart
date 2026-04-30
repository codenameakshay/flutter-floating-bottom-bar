import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../widgets/infinite_list_page.dart';

class BasicTabBarDemoPage extends StatefulWidget {
  const BasicTabBarDemoPage({super.key});

  @override
  State<BasicTabBarDemoPage> createState() => _BasicTabBarDemoPageState();
}

class _BasicTabBarDemoPageState extends State<BasicTabBarDemoPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentPage = 0;

  static const _colors = [
    Color(0xFFF5D547),
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFF7AC8),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _colors.length, vsync: this);
    _tabController.animation?.addListener(_handleTabAnimation);
  }

  void _handleTabAnimation() {
    final page = _tabController.animation!.value.round();
    if (page != _currentPage && mounted) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _tabController.animation?.removeListener(_handleTabAnimation);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _colors[_currentPage];
    const barColor = Color(0xFF111111);
    const foreground = Colors.white;
    final mutedForeground = foreground.withValues(alpha: 0.46);

    return Scaffold(
      appBar: AppBar(title: const Text('Basic TabBar bottom bar')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width * 0.82,
          offset: 18,
          borderRadius: BorderRadius.circular(500),
          clip: Clip.none,
          fit: StackFit.expand,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 500),
        ),
        scrollBehavior: const BottomBarScrollBehavior(
          hideOnScroll: true,
          scrollOpposite: false,
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(500),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                offset: Offset(0, 18),
              ),
            ],
          ),
          iconDecoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(500),
          ),
          iconWidth: 34,
          iconHeight: 34,
        ),
        icon: (width, height) => Icon(
          Icons.arrow_upward_rounded,
          color: foreground,
          size: width,
        ),
        body: TabBarView(
          controller: _tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(),
          children: [
            for (final color in _colors)
              InfiniteListPage(
                key: ValueKey('basic_tab_bar_${color.toARGB32()}'),
                color: color,
              ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: activeColor, width: 4),
                  insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                ),
                tabs: [
                  _TabIcon(
                    icon: Icons.home_rounded,
                    color: _currentPage == 0 ? activeColor : mutedForeground,
                  ),
                  _TabIcon(
                    icon: Icons.search_rounded,
                    color: _currentPage == 1 ? activeColor : mutedForeground,
                  ),
                  const _CenterTabGap(),
                  _TabIcon(
                    icon: Icons.favorite_rounded,
                    color: _currentPage == 3 ? activeColor : mutedForeground,
                  ),
                  _TabIcon(
                    icon: Icons.settings_rounded,
                    color: _currentPage == 4 ? activeColor : mutedForeground,
                  ),
                ],
              ),
              Positioned(
                top: -10,
                child: SizedBox.square(
                  dimension: 42,
                  child: FloatingActionButton.small(
                    heroTag: 'basic-tab-bar-fab',
                    elevation: 0,
                    backgroundColor: Colors.white,
                    foregroundColor: activeColor,
                    onPressed: () {},
                    child: const Icon(Icons.add_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterTabGap extends StatelessWidget {
  const _CenterTabGap();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 50, width: 42);
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: 42,
      child: Center(child: Icon(icon, color: color)),
    );
  }
}
