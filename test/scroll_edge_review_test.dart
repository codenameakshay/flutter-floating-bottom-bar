import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _motion = BottomBarMotion.curved(
  duration: Duration(milliseconds: 200),
  curve: Curves.linear,
);

Widget _app(
  Widget body, {
  bool reduced = false,
  bool edgeEnabled = true,
  BottomBarMotion motion = _motion,
  BottomBarController? controller,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: Scaffold(
        body: BottomBar(
          motion: motion,
          controller: controller,
          scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
          theme: BottomBarThemeData(
            surface: const BottomBarSurface.glass(),
            scrollEdgeSurface: edgeEnabled
                ? const BottomBarSurface(fillOpacity: 0)
                : null,
          ),
          body: body,
          child: const SizedBox(height: 56, width: 300),
        ),
      ),
    ),
  ),
);

double _edge(WidgetTester tester) =>
    tester.widget<BarSurface>(find.byType(BarSurface)).edge!.value;

void main() {
  testWidgets('nested outer scrolling ignores inactive inner lists', (
    tester,
  ) async {
    final nested = GlobalKey<NestedScrollViewState>();
    await tester.pumpWidget(
      _app(
        NestedScrollView(
          key: nested,
          headerSliverBuilder: (_, _) => const [
            SliverAppBar(expandedHeight: 200),
          ],
          body: IndexedStack(
            index: 1,
            children: [
              ListView.builder(
                itemCount: 60,
                itemBuilder: (_, i) =>
                    SizedBox(height: 50, child: Text('Item $i')),
              ),
              ListView(children: const [SizedBox(height: 50)]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final outer = nested.currentState!.outerController.position;
    outer.jumpTo(outer.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(outer.extentAfter, 0);
    expect(nested.currentState!.innerController.positions, hasLength(2));
    expect(
      nested.currentState!.innerController.positions.map((p) => p.extentAfter),
      containsAll([0, greaterThan(0)]),
    );
    expect(_edge(tester), 1);
  });

  testWidgets('reenabling the edge theme rechecks a list moved while off', (
    tester,
  ) async {
    final body = ListView.builder(
      itemCount: 60,
      itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Item $i')),
    );
    await tester.pumpWidget(_app(body));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);
    await tester.pumpWidget(_app(body, edgeEnabled: false));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BarSurface>(find.byType(BarSurface)).edgeSurface,
      isNull,
    );
    position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(body));
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('changing motion during a blend still reaches both targets', (
    tester,
  ) async {
    final body = ListView.builder(
      itemCount: 60,
      itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Item $i')),
    );
    await tester.pumpWidget(_app(body));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_edge(tester), inExclusiveRange(0, 1));
    await tester.pumpWidget(_app(body, motion: const BottomBarMotion()));
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);
    position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('popping the last tracked route resets the edge state', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _app(
        Navigator(
          key: navigator,
          onGenerateRoute: (_) =>
              MaterialPageRoute<void>(builder: (_) => const SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => ListView(children: const [SizedBox(height: 50)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a hidden bar follows lazy Offstage and TickerMode branches', (
    tester,
  ) async {
    final controller = BottomBarController();
    final branches = GlobalKey<_LazyBranchesState>();
    await tester.pumpWidget(
      _app(_LazyBranches(key: branches), controller: controller),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
    controller.hide();
    await tester.pumpAndSettle();
    branches.currentState!.select(1);
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);
    branches.currentState!.select(0);
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
    controller.show();
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a bouncing fling near the end never reverses the blend', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: 60,
          itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Item $i')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    for (final speed in [100.0, 500.0, 1500.0]) {
      position.jumpTo(position.maxScrollExtent - 10);
      await tester.pumpAndSettle();
      expect(_edge(tester), 0);
      await tester.fling(find.byType(ListView), const Offset(0, -30), speed);
      var previous = _edge(tester);
      while (tester.binding.hasScheduledFrame) {
        await tester.pump(const Duration(milliseconds: 8));
        final current = _edge(tester);
        expect(current, greaterThanOrEqualTo(previous));
        previous = current;
      }
      expect(_edge(tester), 1);
      expect(position.extentAfter, lessThanOrEqualTo(1));
    }
  });

  testWidgets('fractional end offsets stay at the edge', (tester) async {
    await tester.pumpWidget(
      _app(
        ListView.builder(
          itemCount: 60,
          itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Item $i')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    for (final offset in [0.0, 0.2, 0.9, 0.1]) {
      position.jumpTo(position.maxScrollExtent - offset);
      await tester.pumpAndSettle();
      expect(_edge(tester), 1);
    }
  });

  testWidgets('disposing with an edge check queued is safe', (tester) async {
    await tester.pumpWidget(
      _app(ListView(children: const [SizedBox(height: 50)])),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('enabling reduced motion snaps an in-flight edge blend', (
    tester,
  ) async {
    final body = ListView.builder(
      itemCount: 60,
      itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Item $i')),
    );
    await tester.pumpWidget(_app(body));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_edge(tester), inExclusiveRange(0, 1));

    await tester.pumpWidget(_app(body, reduced: true));
    expect(_edge(tester), 1);
    await tester.pump(const Duration(milliseconds: 16));
    expect(_edge(tester), 1);
  });
}

class _LazyBranches extends StatefulWidget {
  const _LazyBranches({super.key});

  @override
  State<_LazyBranches> createState() => _LazyBranchesState();
}

class _LazyBranchesState extends State<_LazyBranches> {
  int index = 0;
  final built = <int>{0};

  void select(int value) => setState(() {
    index = value;
    built.add(value);
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (var branch = 0; branch < 2; branch++)
        if (built.contains(branch))
          Offstage(
            offstage: index != branch,
            child: TickerMode(
              enabled: index == branch,
              child: ListView.builder(
                itemCount: branch == 0 ? 60 : 1,
                itemBuilder: (_, i) =>
                    SizedBox(height: 50, child: Text('Item $i')),
              ),
            ),
          ),
    ],
  );
}
