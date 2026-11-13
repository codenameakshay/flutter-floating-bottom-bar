import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a timer-triggered PageView keeps the old edge while paging', (
    tester,
  ) async {
    final pages = GlobalKey<_TimedPagesState>();
    final controller = BottomBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            theme: const BottomBarThemeData(
              surface: BottomBarSurface.glass(),
              scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
            ),
            body: _TimedPages(key: pages),
            child: const SizedBox(height: 56),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'the edge watcher must not schedule its own idle frames',
    );

    pages.currentState!.scheduleNextPage();
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 16));

    expect(_edge(tester), 0, reason: 'paging keeps the settled list active');
    await tester.pumpAndSettle();
    expect(_edge(tester), 1, reason: 'the short landing list is at its end');
    expect(
      tester.binding.hasScheduledFrame,
      isFalse,
      reason: 'the settled edge watcher must not request another frame',
    );
  });

  testWidgets('a nonadjacent TabBarView animateTo follows the landing tab', (
    tester,
  ) async {
    final tabs = GlobalKey<_AnimatedTabsState>();
    final controller = BottomBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            theme: const BottomBarThemeData(
              surface: BottomBarSurface.glass(),
              scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
            ),
            body: _AnimatedTabs(key: tabs),
            child: const SizedBox(height: 56),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);

    tabs.currentState!.selectLastTab();
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      _edge(tester),
      0,
      reason: 'a nonadjacent page warp must hold the prior edge while moving',
    );
    await tester.pumpAndSettle();

    expect(
      _edge(tester),
      1,
      reason: 'TabBarView settled on the last short list',
    );
    expect(controller.isVisible, isTrue, reason: 'the new tab is visible');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a lazily mounted IndexedStack tab snaps the edge surface', (
    tester,
  ) async {
    final tabs = GlobalKey<_LazyTabsState>();
    final controller = BottomBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            motion: const BottomBarMotion.curved(
              duration: Duration(milliseconds: 200),
              curve: Curves.linear,
            ),
            theme: const BottomBarThemeData(
              surface: BottomBarSurface.glass(),
              scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
            ),
            body: _LazyTabs(key: tabs),
            child: const SizedBox(height: 56),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);

    final edge = tester.widget<BarSurface>(find.byType(BarSurface)).edge!;
    final intermediateValues = <double>[];
    void recordIntermediateValue() {
      if (edge.value > 0 && edge.value < 1) intermediateValues.add(edge.value);
    }

    edge.addListener(recordIntermediateValue);
    addTearDown(() => edge.removeListener(recordIntermediateValue));

    tabs.currentState!.selectEmptyTab();
    await tester.pump();
    expect(_edge(tester), 0, reason: 'an empty tab has no edge target');

    tabs.currentState!.mountShortList();
    await tester.pump();

    expect(_edge(tester), 1, reason: 'the first metrics frame sets the edge');
    tabs.currentState!.selectLongTab();
    await tester.pumpAndSettle();

    expect(_edge(tester), 0);
    expect(
      intermediateValues,
      isEmpty,
      reason: 'a newly active tab must not fade from the previous list edge',
    );
  });
}

class _TimedPages extends StatefulWidget {
  const _TimedPages({super.key});

  @override
  State<_TimedPages> createState() => _TimedPagesState();
}

class _TimedPagesState extends State<_TimedPages> {
  final _pages = PageController();

  void scheduleNextPage() {
    Timer(const Duration(milliseconds: 10), () {
      _pages.animateToPage(
        1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
    controller: _pages,
    children: [_list('long-page', 60), _list('short-page', 3)],
  );
}

class _AnimatedTabs extends StatefulWidget {
  const _AnimatedTabs({super.key});

  @override
  State<_AnimatedTabs> createState() => _AnimatedTabsState();
}

class _AnimatedTabsState extends State<_AnimatedTabs>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 3, vsync: this);

  void selectLastTab() => _tabs.animateTo(2);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TabBarView(
    controller: _tabs,
    children: [
      _list('long-tab-0', 60),
      _list('long-tab-1', 60),
      _list('short-tab-2', 3),
    ],
  );
}

Widget _list(String key, int count) => ListView.builder(
  key: ValueKey(key),
  itemCount: count,
  itemBuilder: (_, index) => SizedBox(height: 50, child: Text('$key:$index')),
);

class _LazyTabs extends StatefulWidget {
  const _LazyTabs({super.key});

  @override
  State<_LazyTabs> createState() => _LazyTabsState();
}

class _LazyTabsState extends State<_LazyTabs> {
  int _index = 0;
  bool _shortTabBuilt = false;

  void selectEmptyTab() => setState(() => _index = 1);

  void mountShortList() => setState(() => _shortTabBuilt = true);

  void selectLongTab() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _index,
    children: [
      ListView.builder(
        key: const ValueKey('long-list'),
        itemCount: 60,
        itemBuilder: (_, index) => SizedBox(height: 50, child: Text('$index')),
      ),
      if (_shortTabBuilt)
        ListView.builder(
          key: const ValueKey('short-list'),
          itemCount: 3,
          itemBuilder: (_, index) =>
              SizedBox(height: 50, child: Text('$index')),
        )
      else
        const SizedBox.shrink(key: ValueKey('not-built')),
    ],
  );
}

double _edge(WidgetTester tester) =>
    tester.widget<BarSurface>(find.byType(BarSurface)).edge!.value;
