import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _labels = ['Home', 'Search', 'Inbox', 'Profile'];

Widget _items({int selected = 0, Widget? badge}) => BottomBarItems(
  selectedIndex: selected,
  onSelected: (_) {},
  children: [
    for (var i = 0; i < _labels.length; i++)
      BottomBarItem(
        icon: const Icon(Icons.circle_outlined),
        selectedIcon: const Icon(Icons.circle),
        label: Text(_labels[i]),
        badge: i == selected ? badge : null,
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  BottomBarController? controller,
  BottomBarMinimizeBehavior minimize = BottomBarMinimizeBehavior.onScrollDown,
  Widget? child,
  Widget? compactChild,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            scrollBehavior: BottomBarScrollBehavior(minimizeBehavior: minimize),
            compactChild: compactChild,
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) =>
                  SizedBox(height: 60, child: Text('Row $i')),
            ),
            child: child ?? _items(),
          ),
        ),
      ),
    ),
  );
}

RenderBarSurface _surface(WidgetTester tester) =>
    tester.renderObject<RenderBarSurface>(find.byType(BarSurface));

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView), Offset(0, dy));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scrolling down minimizes and scrolling up expands', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);
    expect(controller.visibility.value, BottomBarVisibility.shown);

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(controller.isVisible, isTrue);
    expect(_surface(tester).morph, 1);

    await _scroll(tester, 200);
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(_surface(tester).morph, 0);
  });

  testWidgets('the outline lands on the pill at the leading edge', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);
    final bar = _surface(tester).outlineRect;

    controller.minimize();
    await tester.pumpAndSettle();

    final pill = _surface(tester).outlineRect;
    expect(pill.size, const Size(48, 48));
    final inset = (bar.height - 48) / 2;
    expect(pill.left, moreOrLessEquals(bar.left + inset));
    expect(pill.top, moreOrLessEquals(bar.top + inset));
  });

  testWidgets('tapping the pill expands the bar', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);
    controller.minimize();
    await tester.pumpAndSettle();

    final surface = _surface(tester);
    await tester.tapAt(surface.localToGlobal(surface.outlineRect.center));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('a bar with no pill hides instead of minimizing', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      child: const SizedBox(height: 64, child: Text('custom')),
    );

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.hidden);
  });

  testWidgets('body padding keeps the full bar height while minimized', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    late BottomBarScope scope;
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          body: Builder(
            builder: (context) {
              scope = BottomBarScope.of(context);
              return const SizedBox.expand();
            },
          ),
          child: _items(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final full = scope.barHeight.value;
    expect(scope.visibleHeight.value, full);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(scope.barHeight.value, full);
    expect(scope.visibility.value, BottomBarVisibility.minimized);
    expect(scope.visibleHeight.value, lessThan(full));

    controller.hide();
    await tester.pumpAndSettle();
    expect(scope.visibleHeight.value, 0);
  });

  testWidgets('a globally keyed selected icon hides instead of minimizing', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      child: BottomBarItems(
        selectedIndex: 0,
        onSelected: (_) {},
        children: [
          BottomBarItem(
            icon: Icon(Icons.home, key: GlobalKey()),
            label: const Text('Home'),
          ),
          const BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
        ],
      ),
    );

    controller.minimize();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(controller.visibility.value, BottomBarVisibility.hidden);
  });
}
