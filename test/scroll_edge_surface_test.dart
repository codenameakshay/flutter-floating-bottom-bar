import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _glass = BottomBarSurface.glass();
const _clear = BottomBarSurface(fillOpacity: 0);
const _linear = BottomBarMotion.curved(
  duration: Duration(milliseconds: 200),
  curve: Curves.linear,
);

/// How far the bar is from `surface` (0) to `scrollEdgeSurface` (1).
double _edge(WidgetTester tester) =>
    tester.widget<BarSurface>(find.byType(BarSurface)).edge!.value;

Widget _list({
  int count = 60,
  bool reverse = false,
  Key? key,
  ScrollPhysics? physics,
}) => ListView.builder(
  key: key,
  reverse: reverse,
  physics: physics,
  itemCount: count,
  itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Item $i')),
);

Widget _app({
  required Widget body,
  BottomBarSurface? surface = _glass,
  BottomBarSurface? scrollEdgeSurface = _clear,
  BottomBarMotion motion = _linear,
  BottomBarController? controller,
  BoxDecoration? barDecoration,
  bool reduceMotion = false,
  bool highContrast = false,
  Widget child = const SizedBox(height: 56, width: 300),
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: reduceMotion, highContrast: highContrast),
      child: Scaffold(
        body: BottomBar(
          controller: controller,
          motion: motion,
          scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
          theme: BottomBarThemeData(
            barDecoration: barDecoration,
            surface: surface,
            scrollEdgeSurface: scrollEdgeSurface,
          ),
          body: body,
          child: child,
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a long list at its start paints the standard surface', (
    tester,
  ) async {
    await tester.pumpWidget(_app(body: _list()));
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a long list at its end paints the edge surface', (tester) async {
    await tester.pumpWidget(_app(body: _list()));
    await tester.pumpAndSettle();
    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    position.position.jumpTo(position.position.maxScrollExtent);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);

    position.position.jumpTo(0);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a short list snaps to the edge with no transition', (
    tester,
  ) async {
    await tester.pumpWidget(_app(body: _list(count: 3)));
    final seen = <double>[_edge(tester)];
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(_edge(tester));
    }
    expect(seen.skip(1), everyElement(1.0));
  });

  testWidgets('the surface animates without rebuilding any widget', (
    tester,
  ) async {
    await tester.pumpWidget(_app(body: _list()));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();
    final rebuilt = <Widget>[];
    debugOnRebuildDirtyWidget = (element, _) => rebuilt.add(element.widget);
    addTearDown(() => debugOnRebuildDirtyWidget = null);
    var frames = 0;
    while (tester.binding.hasScheduledFrame) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    debugOnRebuildDirtyWidget = null;
    expect(frames, greaterThan(5));
    expect(_edge(tester), 1);
    expect(rebuilt, isEmpty);
  });

  testWidgets('blur 0 at the edge leaves no backdrop layer', (tester) async {
    await tester.pumpWidget(_app(body: _list(count: 3)));
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);
    expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
  });

  testWidgets('a reversed list is at the edge at its start', (tester) async {
    await tester.pumpWidget(_app(body: _list(reverse: true)));
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);

    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    position.position.jumpTo(position.position.maxScrollExtent);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a horizontal list never counts toward the edge', (tester) async {
    await tester.pumpWidget(
      _app(
        body: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < 3; i++)
              SizedBox(width: 80, height: 50, child: Text('Item $i')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('no list leaves the bar on the standard surface', (tester) async {
    await tester.pumpWidget(_app(body: const ColoredBox(color: Colors.white)));
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a nested scroll view reaches the edge only at its end', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        body: NestedScrollView(
          headerSliverBuilder: (_, _) => [
            const SliverAppBar(expandedHeight: 200, title: Text('Header')),
          ],
          body: _list(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);

    await tester.fling(
      find.byType(NestedScrollView),
      const Offset(0, -30000),
      8000,
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);

    await tester.fling(
      find.byType(NestedScrollView),
      const Offset(0, 30000),
      8000,
    );
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a bouncing list never dips off the edge surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(body: _list(physics: const BouncingScrollPhysics())),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, -20000), 6000);
    final values = <double>[];
    while (tester.binding.hasScheduledFrame) {
      await tester.pump(const Duration(milliseconds: 16));
      values.add(_edge(tester));
    }
    expect(values, isNotEmpty);
    for (var i = 1; i < values.length; i++) {
      expect(values[i], greaterThanOrEqualTo(values[i - 1] - 1e-9));
    }
    expect(values.last, 1);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    final afterDrag = <double>[];
    while (tester.binding.hasScheduledFrame) {
      await tester.pump(const Duration(milliseconds: 16));
      afterDrag.add(_edge(tester));
    }
    expect(afterDrag, isNotEmpty);
    expect(afterDrag, everyElement(1.0));
  });

  testWidgets('an indexed stack follows the visible branch', (tester) async {
    final branches = GlobalKey<_BranchesState>();
    await tester.pumpWidget(_app(body: _Branches(key: branches)));
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);

    branches.currentState!.select(1);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);

    branches.currentState!.select(0);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('a hidden bar keeps its edge state for the visible branch', (
    tester,
  ) async {
    final branches = GlobalKey<_BranchesState>();
    final controller = BottomBarController();
    await tester.pumpWidget(
      _app(
        body: _Branches(key: branches),
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();
    branches.currentState!.select(1);
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);

    controller.show();
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);
  });

  testWidgets('a retarget mid-flight starts from the current value', (
    tester,
  ) async {
    await tester.pumpWidget(_app(body: _list()));
    await tester.pumpAndSettle();
    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    position.position.jumpTo(position.position.maxScrollExtent);
    await tester.pump();
    // The first ticker frame only sets the animation's start time.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _edge(tester);
    expect(mid, greaterThan(0.3));
    expect(mid, lessThan(0.7));

    position.position.jumpTo(0);
    await tester.pump();
    expect((_edge(tester) - mid).abs(), lessThan(0.15));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_edge(tester), lessThan(mid));

    await tester.pumpAndSettle();
    expect(_edge(tester), 0);
  });

  testWidgets('reduced motion snaps to the edge surface', (tester) async {
    await tester.pumpWidget(_app(body: _list(), reduceMotion: true));
    await tester.pumpAndSettle();
    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    position.position.jumpTo(position.position.maxScrollExtent);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_edge(tester), 1);
  });

  testWidgets('high contrast paints an opaque, unblurred edge surface', (
    tester,
  ) async {
    await tester.pumpWidget(_app(body: _list(count: 3), highContrast: true));
    await tester.pumpAndSettle();
    expect(_edge(tester), 1);

    final bar = tester.widget<BarSurface>(find.byType(BarSurface));
    expect(bar.surface!.tint!.a, 1);
    expect(bar.surface!.blur, 0);
    expect(bar.edgeSurface!.tint!.a, 1);
    expect(bar.edgeSurface!.fillOpacity, 1);
    expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
  });

  testWidgets('the backdrop layer follows the blur at each edge', (
    tester,
  ) async {
    await tester.pumpWidget(_app(body: _list()));
    await tester.pumpAndSettle();
    expect(tester.layers.whereType<BackdropFilterLayer>(), hasLength(1));

    final position = tester.state<ScrollableState>(find.byType(Scrollable));
    position.position.jumpTo(position.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);

    position.position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.layers.whereType<BackdropFilterLayer>(), hasLength(1));
  });

  testWidgets('a null surface still blends from the bar decoration', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        body: _list(),
        surface: null,
        barDecoration: const BoxDecoration(
          color: Color(0xFFFF0000),
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = tester.widget<BarSurface>(find.byType(BarSurface));
    expect(bar.surface!.tint, const Color(0xFFFF0000));
    expect(bar.edgeSurface, isNotNull);
  });

  testWidgets('a null scrollEdgeSurface changes nothing', (tester) async {
    await tester.pumpWidget(
      _app(body: _list(), surface: null, scrollEdgeSurface: null),
    );
    await tester.pumpAndSettle();
    final bar = tester.widget<BarSurface>(find.byType(BarSurface));
    expect(bar.surface, isNull);
    expect(bar.edgeSurface, isNull);
  });

  test(
    'merge takes the other scrollEdgeSurface and keeps this one on null',
    () {
      const a = BottomBarThemeData(
        scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
      );
      const b = BottomBarThemeData(
        scrollEdgeSurface: BottomBarSurface(fillOpacity: 1),
      );
      expect(a.merge(b).scrollEdgeSurface!.fillOpacity, 1);
      expect(
        a.merge(const BottomBarThemeData()).scrollEdgeSurface!.fillOpacity,
        0,
      );
    },
  );

  test('copyWith replaces scrollEdgeSurface', () {
    const theme = BottomBarThemeData(
      scrollEdgeSurface: BottomBarSurface(fillOpacity: 1),
    );
    expect(
      theme.copyWith(scrollEdgeSurface: _clear).scrollEdgeSurface!.fillOpacity,
      0,
    );
  });

  test('lerp blends scrollEdgeSurface', () {
    const a = BottomBarThemeData(
      scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
    );
    const b = BottomBarThemeData(
      scrollEdgeSurface: BottomBarSurface(fillOpacity: 1),
    );
    expect(a.lerp(b, 0.5).scrollEdgeSurface!.fillOpacity, 0.5);
  });

  test('equality and hashCode include scrollEdgeSurface', () {
    const same = BottomBarThemeData(scrollEdgeSurface: _clear);
    const other = BottomBarThemeData(scrollEdgeSurface: _clear);
    const different = BottomBarThemeData(
      scrollEdgeSurface: BottomBarSurface(fillOpacity: 1),
    );
    expect(same == other, isTrue);
    expect(same.hashCode, other.hashCode);
    expect(same == different, isFalse);
  });
}

class _Branches extends StatefulWidget {
  const _Branches({super.key});

  @override
  State<_Branches> createState() => _BranchesState();
}

class _BranchesState extends State<_Branches> {
  int index = 0;

  void select(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) =>
      IndexedStack(index: index, children: [_list(), _list(count: 3)]);
}
