import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
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
  BottomBarScrollBehavior? scrollBehavior,
  ValueChanged<bool>? onVisibilityChanged,
  bool disableAnimations = false,
  Widget? child,
  Widget? compactChild,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: app!,
      ),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            scrollBehavior:
                scrollBehavior ??
                BottomBarScrollBehavior(minimizeBehavior: minimize),
            onVisibilityChanged: onVisibilityChanged,
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

Widget _rowList() => ListView.builder(
  itemCount: 100,
  itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Row $i')),
);

void main() {
  testWidgets('onScrollDown minimizes on scroll toward the end and expands', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(controller.isVisible, isTrue);
    expect(_surface(tester).morph, 1);

    await _scroll(tester, 200);
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(_surface(tester).morph, 0);
  });

  testWidgets('onScrollUp minimizes on scroll toward the start and expands', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      minimize: BottomBarMinimizeBehavior.onScrollUp,
    );

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.shown);

    await _scroll(tester, 100);
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    await _scroll(tester, -100);
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('the default scroll behavior hides instead of minimizing', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      scrollBehavior: const BottomBarScrollBehavior(),
    );

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.hidden);
    expect(find.byType(CompactPillButton), findsNothing);
  });

  testWidgets('minimizeBehavior takes precedence over hideOnScroll', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      scrollBehavior: const BottomBarScrollBehavior(
        hideOnScroll: false,
        minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
      ),
    );

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.minimized);
  });

  testWidgets('showAtStart expands a minimized bar at the top of the list', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      scrollBehavior: const BottomBarScrollBehavior(
        minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
        showAtStart: true,
      ),
    );

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    await _scroll(tester, 2000);
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('showOnScrollEnd expands the bar once the finger lifts', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      scrollBehavior: const BottomBarScrollBehavior(
        minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
        showOnScrollEnd: true,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
    }
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('flings minimize toward the end and expand toward the start', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    await tester.fling(find.byType(ListView), const Offset(0, -400), 2000);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 2000);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('minimize and expand work from the controller', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(_surface(tester).morph, 1);

    controller.expand();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(_surface(tester).morph, 0);

    controller.expand();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);

    controller.hide();
    await tester.pumpAndSettle();
    controller.expand();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.hidden);
  });

  testWidgets('hiding a minimized bar and minimizing a hidden bar', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.hidden);
    expect(controller.isVisible, isFalse);

    controller.show();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(_surface(tester).morph, 0);

    controller.hide();
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(controller.isVisible, isTrue);
  });

  testWidgets('a scroll never minimizes a hidden bar', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    controller.hide();
    await tester.pumpAndSettle();
    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.hidden);
  });

  testWidgets('fast alternating scrolls keep the morph in range and settle', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(Offset(0, i.isEven ? -30 : 30));
      await tester.pump(const Duration(milliseconds: 16));
      final morph = _surface(tester).morph;
      expect(morph, greaterThanOrEqualTo(0));
      expect(morph, lessThanOrEqualTo(1));
    }

    await gesture.up();
    await tester.pumpAndSettle();
    final visibility = controller.visibility.value;
    expect(
      visibility,
      anyOf(BottomBarVisibility.shown, BottomBarVisibility.minimized),
    );
    expect(
      _surface(tester).morph,
      visibility == BottomBarVisibility.minimized ? 1 : 0,
    );
  });

  testWidgets(
    'minimizing notifies the controller but not onVisibilityChanged',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final changes = <bool>[];
      var notifications = 0;
      controller.addListener(() {
        notifications++;
      });
      await _pump(
        tester,
        controller: controller,
        onVisibilityChanged: changes.add,
      );

      await _scroll(tester, -300);
      expect(controller.visibility.value, BottomBarVisibility.minimized);
      expect(changes, isEmpty);
      expect(notifications, 1);

      await _scroll(tester, 200);
      expect(controller.visibility.value, BottomBarVisibility.shown);
      expect(changes, isEmpty);

      controller.hide();
      await tester.pumpAndSettle();
      expect(changes, [false]);
    },
  );

  testWidgets('reduced motion snaps the morph between shown and minimized', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller, disableAnimations: true);

    controller.minimize();
    await tester.pump();
    expect(_surface(tester).morph, 1);

    controller.expand();
    await tester.pump();
    expect(_surface(tester).morph, 0);
  });

  testWidgets('a minimize can be reversed mid-flight in both directions', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);

    controller.minimize();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final partial = _surface(tester).morph;
    expect(partial, greaterThan(0));
    expect(partial, lessThan(1));

    controller.expand();
    await tester.pumpAndSettle();
    expect(_surface(tester).morph, 0);
    expect(controller.visibility.value, BottomBarVisibility.shown);

    controller.minimize();
    await tester.pumpAndSettle();
    controller.expand();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final reversed = _surface(tester).morph;
    expect(reversed, greaterThan(0));
    expect(reversed, lessThan(1));

    controller.minimize();
    await tester.pumpAndSettle();
    expect(_surface(tester).morph, 1);
    expect(controller.visibility.value, BottomBarVisibility.minimized);
  });

  testWidgets('switching to another tab shows a minimized bar', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    late StateSetter setOuter;
    var tab = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            setOuter = setState;
            return Scaffold(
              body: BottomBar(
                controller: controller,
                scrollBehavior: const BottomBarScrollBehavior(
                  minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
                ),
                body: IndexedStack(
                  index: tab,
                  children: [_rowList(), _rowList()],
                ),
                child: _items(selected: tab),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).at(0), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    setOuter(() => tab = 1);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets(
    'restoring tab visibility brings a minimized tab back minimized',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      late StateSetter setOuter;
      var tab = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Scaffold(
                body: BottomBar(
                  controller: controller,
                  scrollBehavior: const BottomBarScrollBehavior(
                    minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
                    visibilityOnTabChange: BottomBarTabVisibility.restore,
                  ),
                  body: IndexedStack(
                    index: tab,
                    children: [_rowList(), _rowList()],
                  ),
                  child: _items(selected: tab),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).at(0), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.minimized);

      setOuter(() => tab = 1);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.shown);

      setOuter(() => tab = 0);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.minimized);
    },
  );
}
