import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

enum _Host { indexedStack, pageView, tabBarView }

const _counts = [60, 3, 40];
const _restore = BottomBarScrollBehavior(
  visibilityOnTabChange: BottomBarTabVisibility.restore,
);

final _tabs = GlobalKey<_TabsState>();

Widget _app({
  required _Host host,
  required BottomBarController controller,
  BottomBarScrollBehavior scrollBehavior = const BottomBarScrollBehavior(),
  bool keepAlive = true,
  List<double> offsets = const [0, 0, 0],
}) => MaterialApp(
  home: Scaffold(
    body: BottomBar(
      controller: controller,
      motion: const BottomBarMotion.curved(
        duration: Duration(milliseconds: 200),
        curve: Curves.linear,
      ),
      scrollBehavior: scrollBehavior,
      theme: const BottomBarThemeData(
        surface: BottomBarSurface.glass(),
        scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
      ),
      body: _Tabs(
        key: _tabs,
        host: host,
        keepAlive: keepAlive,
        offsets: offsets,
      ),
      child: const SizedBox(height: 56, width: 300),
    ),
  ),
);

class _Tabs extends StatefulWidget {
  const _Tabs({
    required this.host,
    required this.keepAlive,
    required this.offsets,
    super.key,
  });

  final _Host host;
  final bool keepAlive;
  final List<double> offsets;

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> with SingleTickerProviderStateMixin {
  int index = 0;
  final pages = PageController();
  late final TabController tabs;
  late final lists = [
    for (final offset in widget.offsets)
      ScrollController(initialScrollOffset: offset),
  ];

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
  }

  void select(int i) {
    switch (widget.host) {
      case _Host.indexedStack:
        setState(() => index = i);
      case _Host.pageView:
        pages.jumpToPage(i);
      case _Host.tabBarView:
        tabs.index = i;
    }
  }

  @override
  void dispose() {
    pages.dispose();
    tabs.dispose();
    for (final list in lists) {
      list.dispose();
    }
    super.dispose();
  }

  Widget _list(int i) {
    final list = ListView.builder(
      key: ValueKey('list-$i'),
      controller: lists[i],
      itemCount: _counts[i],
      itemBuilder: (_, row) => SizedBox(height: 50, child: Text('$i:$row')),
    );
    return widget.keepAlive ? _KeepAlive(child: list) : list;
  }

  @override
  Widget build(BuildContext context) {
    final children = [for (var i = 0; i < 3; i++) _list(i)];
    return switch (widget.host) {
      _Host.indexedStack => IndexedStack(index: index, children: children),
      _Host.pageView => PageView(controller: pages, children: children),
      _Host.tabBarView => TabBarView(controller: tabs, children: children),
    };
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

double _edge(WidgetTester tester) =>
    tester.widget<BarSurface>(find.byType(BarSurface)).edge!.value;

Finder _listFinder(int i) =>
    find.byKey(ValueKey('list-$i'), skipOffstage: false);

ScrollPosition _position(WidgetTester tester, int i) =>
    _tabs.currentState!.lists[i].position;

Future<void> _scrollDown(WidgetTester tester, int i) async {
  await tester.drag(_listFinder(i), const Offset(0, -300));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, int i) async {
  _tabs.currentState!.select(i);
  await tester.pumpAndSettle();
}

/// Drags the page host sideways by [pages] page widths without lifting.
Future<TestGesture> _swipe(WidgetTester tester, double pages) async {
  final width = tester.getSize(find.byType(_Tabs)).width;
  final gesture = await tester.startGesture(const Offset(400, 300));
  const steps = 10;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(-width * pages / steps, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return gesture;
}

void main() {
  for (final host in _Host.values) {
    group('$host', () {
      testWidgets('a tab switch snaps the edge surface to the new list on '
          'the next frame', (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(host: host, controller: controller));
        await tester.pumpAndSettle();
        expect(_edge(tester), 0, reason: 'tab 0 is a long list at its start');
        final edge = tester.widget<BarSurface>(find.byType(BarSurface)).edge!;
        final fades = <double>[];
        void recordFade() {
          if (edge.value > 0 && edge.value < 1) fades.add(edge.value);
        }

        edge.addListener(recordFade);
        addTearDown(() => edge.removeListener(recordFade));

        // TabBarView animates even a programmatic switch, so it switches
        // when the page settles.
        Future<void> switchTo(int i) async {
          _tabs.currentState!.select(i);
          if (host == _Host.tabBarView) {
            await tester.pumpAndSettle();
          } else {
            await tester.pump();
            await tester.pump();
          }
        }

        await switchTo(1);
        expect(_edge(tester), 1, reason: 'tab 1 is short, read unscrolled');
        await switchTo(0);
        expect(_edge(tester), 0);
        expect(fades, isEmpty, reason: 'the surface snaps between tabs');
      });

      testWidgets('a tab change shows the bar with no controller call', (
        tester,
      ) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(host: host, controller: controller));
        await tester.pumpAndSettle();

        await _scrollDown(tester, 0);
        expect(controller.isVisible, isFalse);

        await _select(tester, 2);
        expect(controller.isVisible, isTrue);

        await _scrollDown(tester, 2);
        expect(controller.isVisible, isFalse, reason: 'tab 2 drives the bar');
      });

      testWidgets('restore gives each tab back its own visibility', (
        tester,
      ) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(host: host, controller: controller, scrollBehavior: _restore),
        );
        await tester.pumpAndSettle();

        await _scrollDown(tester, 0);
        expect(controller.isVisible, isFalse);

        await _select(tester, 2);
        expect(controller.isVisible, isTrue, reason: 'tab 2 not seen yet');

        await _select(tester, 0);
        expect(controller.isVisible, isFalse, reason: 'tab 0 was hidden');

        await _select(tester, 2);
        expect(controller.isVisible, isTrue, reason: 'tab 2 was shown');
      });

      testWidgets('an inactive tab scrolling does not drive the bar', (
        tester,
      ) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(host: host, controller: controller));
        await tester.pumpAndSettle();
        await _select(tester, 2);

        _position(tester, 0).animateTo(
          600,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
        await tester.pumpAndSettle();
        expect(_position(tester, 0).pixels, 600);
        expect(controller.isVisible, isTrue);
      });

      testWidgets('scrollToStart before any scroll targets the visible tab', (
        tester,
      ) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _app(host: host, controller: controller, offsets: [300, 0, 300]),
        );
        await tester.pumpAndSettle();
        await _select(tester, 2);

        controller.scrollToStart();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(_position(tester, 2).pixels, 0);
        expect(_position(tester, 0).pixels, 300);
      });
    });
  }

  for (final host in [_Host.pageView, _Host.tabBarView]) {
    group('$host swipes', () {
      testWidgets('an abandoned half swipe keeps the page, bar and target', (
        tester,
      ) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(host: host, controller: controller));
        await tester.pumpAndSettle();
        await _scrollDown(tester, 0);
        expect(controller.isVisible, isFalse);

        final gesture = await _swipe(tester, 0.4);
        expect(controller.isVisible, isFalse);
        expect(_edge(tester), 0);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controller.isVisible, isFalse, reason: 'no tab change');
        expect(_edge(tester), 0);
        controller.scrollToStart();
        await tester.pumpAndSettle();
        expect(_position(tester, 0).pixels, 0);
      });

      testWidgets('the neighbour page does not take over mid swipe', (
        tester,
      ) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(host: host, controller: controller));
        await tester.pumpAndSettle();
        expect(_edge(tester), 0);

        final gesture = await _swipe(tester, 0.7);
        await tester.pump();
        expect(_edge(tester), 0, reason: 'short tab 1 is only partly shown');

        await gesture.up();
        await tester.pumpAndSettle();
        expect(_edge(tester), 1, reason: 'tab 1 settled in view');
      });

      for (final keepAlive in [true, false]) {
        testWidgets('a fling across two pages targets the landing page '
            '(keepAlive: $keepAlive)', (tester) async {
          final controller = BottomBarController();
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            _app(
              host: host,
              controller: controller,
              keepAlive: keepAlive,
              scrollBehavior: _restore,
            ),
          );
          await tester.pumpAndSettle();
          await _scrollDown(tester, 0);
          final offset0 = _position(tester, 0).pixels;
          expect(controller.isVisible, isFalse);

          final width = tester.getSize(find.byType(_Tabs)).width;
          await tester.flingFrom(
            const Offset(400, 300),
            Offset(-width * 1.6, 0),
            3000,
          );
          await tester.pumpAndSettle();
          expect(find.text('2:0'), findsOneWidget, reason: 'landed on tab 2');
          expect(controller.isVisible, isTrue, reason: 'tab 2 not seen yet');

          await _scrollDown(tester, 2);
          expect(controller.isVisible, isFalse, reason: 'tab 2 drives the bar');
          controller.scrollToStart();
          await tester.pumpAndSettle();
          expect(_position(tester, 2).pixels, 0);
          expect(tester.takeException(), isNull);
          if (keepAlive) expect(_position(tester, 0).pixels, offset0);
        });
      }
    });
  }

  testWidgets('scrollToStart with no list in the body returns quietly', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          body: const SizedBox.expand(),
          child: const SizedBox(height: 56),
        ),
      ),
    );
    await controller.scrollToStart();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
