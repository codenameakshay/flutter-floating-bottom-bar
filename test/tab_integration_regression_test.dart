import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _restore = BottomBarScrollBehavior(
  visibilityOnTabChange: BottomBarTabVisibility.restore,
);

void main() {
  testWidgets('pushing a route inside a tab does not restore tab visibility', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndexedStack(
            index: 0,
            children: [
              BottomBar(
                controller: controller,
                scrollBehavior: _restore,
                body: Navigator(
                  key: navigatorKey,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const _LongList(label: 'root'),
                  ),
                ),
                child: const SizedBox(height: 56, width: 300),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const _LongList(label: 'detail')),
    );
    await tester.pumpAndSettle();
    expect(
      controller.isVisible,
      isFalse,
      reason: 'a route push is not a tab switch',
    );

    controller.show();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      controller.isVisible,
      isFalse,
      reason: 'the top route list can still drive scroll behavior',
    );
  });

  testWidgets('a Visibility above BottomBar does not create a tab switch', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final hostKey = GlobalKey<_VisibilityHostState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _VisibilityHost(key: hostKey, controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    hostKey.currentState!.setVisible(false);
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);
    hostKey.currentState!.setVisible(true);
    await tester.pumpAndSettle();

    expect(
      controller.isVisible,
      isFalse,
      reason: 'restoring the surrounding Visibility is not a tab change',
    );
  });

  testWidgets('an ancestor IndexedStack change does not create a tab switch', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final hostKey = GlobalKey<_IndexedHostState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _IndexedHost(key: hostKey, controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    hostKey.currentState!.selectOtherChild();
    await tester.pumpAndSettle();
    hostKey.currentState!.selectBarChild();
    await tester.pumpAndSettle();

    expect(
      controller.isVisible,
      isFalse,
      reason: 'the bar remains in the same tab when its ancestor hides it',
    );
  });

  testWidgets('reverse NestedScrollView controller action targets min extent', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final inner = ScrollController();
    final outer = ScrollController();
    addTearDown(inner.dispose);
    addTearDown(outer.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            scrollBehavior: const BottomBarScrollBehavior(reverse: true),
            body: NestedScrollView(
              reverse: true,
              controller: outer,
              headerSliverBuilder: (_, _) => [
                const SliverToBoxAdapter(child: SizedBox(height: 180)),
              ],
              body: ListView.builder(
                controller: inner,
                itemCount: 40,
                itemBuilder: (_, index) =>
                    SizedBox(height: 50, child: Text('row $index')),
              ),
            ),
            child: const SizedBox(height: 56, width: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    inner.jumpTo(inner.position.maxScrollExtent);
    await tester.pumpAndSettle();
    controller.scrollToStart();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(inner.position.pixels, inner.position.minScrollExtent);
  });

  testWidgets(
    'NestedScrollView with TabBarView follows the visible inner tab',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final tabsKey = GlobalKey<_NestedTabsState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              body: _NestedTabs(key: tabsKey),
              child: const SizedBox(height: 56, width: 300),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('tab0:4'), const Offset(0, -400));
      await tester.pumpAndSettle();
      tabsKey.currentState!.select(1);
      await tester.pumpAndSettle();
      await tester.drag(find.text('tab1:4'), const Offset(0, -400));
      await tester.pumpAndSettle();

      final tabOnePosition = Scrollable.of(
        tester.element(find.text('tab1:8')),
      ).position;
      controller.scrollToStart();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tabOnePosition.pixels,
        tabOnePosition.minScrollExtent,
        reason: 'scrollToStart follows the selected inner tab',
      );
    },
  );

  testWidgets('NestedScrollView header scroll does not pin tab selection', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final tabsKey = GlobalKey<_NestedTabsState>();
    final outer = ScrollController();
    addTearDown(outer.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            body: _NestedTabs(key: tabsKey, outerController: outer),
            child: const SizedBox(height: 56, width: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    outer.animateTo(
      80,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse, reason: 'the header scroll hides');
    final edge = tester.widget<BarSurface>(find.byType(BarSurface)).edge!;
    final edgeBeforeSwipe = edge.value;

    tabsKey.currentState!.select(1);
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      controller.isVisible,
      isFalse,
      reason: 'the current tab remains active during the page motion',
    );
    expect(edge.value, edgeBeforeSwipe, reason: 'edge follows no partial page');
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue, reason: 'the new tab is selected');
    final activeInner = Scrollable.of(
      tester.element(find.text('tab1:0')),
    ).position;
    controller.scrollToStart();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(outer.position.pixels, outer.position.minScrollExtent);
    expect(activeInner.pixels, activeInner.minScrollExtent);
  });

  testWidgets(
    'a horizontal carousel inside a vertical list is not a tab host',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final list = ScrollController();
      final carousel = PageController();
      addTearDown(list.dispose);
      addTearDown(carousel.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              body: ListView.builder(
                controller: list,
                itemCount: 30,
                itemBuilder: (_, index) => SizedBox(
                  height: index == 0 ? 900 : 50,
                  child: index == 0
                      ? PageView(
                          key: const ValueKey('carousel'),
                          controller: carousel,
                          children: const [
                            Center(child: Text('carousel 0')),
                            Center(child: Text('carousel 1')),
                          ],
                        )
                      : Text('row $index'),
                ),
              ),
              child: const SizedBox(height: 56, width: 300),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(controller.isVisible, isFalse);

      carousel.animateToPage(
        1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.linear,
      );
      await tester.pumpAndSettle();

      expect(carousel.page, 1);
      expect(
        controller.isVisible,
        isFalse,
        reason: 'horizontal page motion is not a vertical tab change',
      );
      controller.scrollToStart();
      await tester.pumpAndSettle();
      expect(list.position.pixels, list.position.minScrollExtent);
    },
  );

  testWidgets('reverse ListView controller actions still use min and max', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final list = ScrollController();
    addTearDown(list.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            body: ListView.builder(
              reverse: true,
              controller: list,
              itemCount: 40,
              itemBuilder: (_, index) =>
                  SizedBox(height: 50, child: Text('reverse row $index')),
            ),
            child: const SizedBox(height: 56, width: 300),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    list.jumpTo(list.position.maxScrollExtent);
    await tester.pumpAndSettle();
    controller.scrollToStart();
    await tester.pumpAndSettle();
    expect(list.position.pixels, list.position.minScrollExtent);

    controller.scrollToEnd();
    await tester.pumpAndSettle();
    expect(list.position.pixels, list.position.maxScrollExtent);
  });
}

class _LongList extends StatelessWidget {
  const _LongList({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: 40,
    itemBuilder: (_, index) =>
        SizedBox(height: 50, child: Text('$label $index')),
  );
}

class _VisibilityHost extends StatefulWidget {
  const _VisibilityHost({required this.controller, super.key});

  final BottomBarController controller;

  @override
  State<_VisibilityHost> createState() => _VisibilityHostState();
}

class _VisibilityHostState extends State<_VisibilityHost> {
  bool visible = true;

  void setVisible(bool value) => setState(() => visible = value);

  @override
  Widget build(BuildContext context) => Visibility(
    visible: visible,
    maintainState: true,
    child: BottomBar(
      controller: widget.controller,
      scrollBehavior: _restore,
      body: const _LongList(label: 'list'),
      child: const SizedBox(height: 56, width: 300),
    ),
  );
}

class _IndexedHost extends StatefulWidget {
  const _IndexedHost({required this.controller, super.key});

  final BottomBarController controller;

  @override
  State<_IndexedHost> createState() => _IndexedHostState();
}

class _IndexedHostState extends State<_IndexedHost> {
  int index = 0;

  void selectOtherChild() => setState(() => index = 1);
  void selectBarChild() => setState(() => index = 0);

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: index,
    children: [
      BottomBar(
        controller: widget.controller,
        scrollBehavior: _restore,
        body: const _LongList(label: 'stacked'),
        child: const SizedBox(height: 56, width: 300),
      ),
      const SizedBox.expand(),
    ],
  );
}

class _NestedTabs extends StatefulWidget {
  const _NestedTabs({super.key, this.outerController});

  final ScrollController? outerController;

  @override
  State<_NestedTabs> createState() => _NestedTabsState();
}

class _NestedTabsState extends State<_NestedTabs>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 2, vsync: this);

  void select(int index) => tabs.animateTo(index);

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NestedScrollView(
    controller: widget.outerController,
    headerSliverBuilder: (_, _) => [
      const SliverAppBar(
        pinned: true,
        expandedHeight: 160,
        flexibleSpace: FlexibleSpaceBar(title: Text('Nested header')),
      ),
    ],
    body: TabBarView(
      controller: tabs,
      children: [
        for (var tab = 0; tab < 2; tab++)
          ListView.builder(
            key: ValueKey('nested-tab-$tab'),
            itemCount: 40,
            itemBuilder: (_, row) =>
                SizedBox(height: 50, child: Text('tab$tab:$row')),
          ),
      ],
    ),
  );
}
