import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('placement follows every spring sample across reversals', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final placements = <BottomBarAccessoryPlacement>[];
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          compactChild: const SizedBox.square(dimension: 48),
          accessory: Builder(
            builder: (context) {
              placements.add(BottomBarAccessoryPlacement.of(context));
              return const SizedBox(height: 56);
            },
          ),
          body: const SizedBox.expand(),
          child: const SizedBox(height: 64, width: 300),
        ),
      ),
    );
    await tester.pumpAndSettle();

    RenderBarSurface surface() => tester.renderObject<RenderBarSurface>(
      find.byKey(const ValueKey('pill')),
    );
    Future<void> checkSample(Duration duration) async {
      await tester.pump(duration);
      expect(surface().morph, inInclusiveRange(0, 1));
      expect(
        placements.last,
        surface().morph >= 0.5
            ? BottomBarAccessoryPlacement.inline
            : BottomBarAccessoryPlacement.expanded,
      );
    }

    controller.minimize();
    await checkSample(Duration.zero);
    await checkSample(const Duration(milliseconds: 24));
    expect(surface().morph, inExclusiveRange(0, .5));
    controller.expand();
    for (var i = 0; i < 16; i++) {
      await checkSample(const Duration(milliseconds: 8));
    }
    await tester.pumpAndSettle();
    expect(placements.last, BottomBarAccessoryPlacement.expanded);
    controller.minimize();
    for (final step in [8, 16, 32, 8, 16, 32, 8, 16, 32, 8, 16, 32]) {
      await checkSample(Duration(milliseconds: step));
    }
    expect(surface().morph, greaterThan(.5));
    controller.expand();
    await checkSample(const Duration(milliseconds: 8));
    expect(surface().morph, lessThan(1));
    controller.minimize();
    for (var i = 0; i < 8; i++) {
      await checkSample(const Duration(milliseconds: 8));
    }
    expect(surface().morph, greaterThan(.5));
    controller.expand();
    for (final step in [8, 16, 32, 8, 16, 32, 8, 16, 32, 8, 16, 32]) {
      await checkSample(Duration(milliseconds: step));
    }
    controller.minimize();
    await tester.pumpAndSettle();
    expect(surface().morph, closeTo(1, 0.01));
    expect(placements.last, BottomBarAccessoryPlacement.inline);

    controller.expand();
    await tester.pumpAndSettle();
    expect(surface().morph, closeTo(0, 0.01));
    expect(placements.last, BottomBarAccessoryPlacement.expanded);
  });

  testWidgets(
    'accessory footprint is stable during minimize, expand and visibility',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      late BottomBarScope scope;
      final paddingKey = GlobalKey();
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBar(
            controller: controller,
            compactChild: const SizedBox.square(dimension: 48),
            accessory: const SizedBox(height: 56),
            body: Builder(
              builder: (context) {
                scope = BottomBarScope.of(context);
                return BottomBarBodyPadding(
                  key: paddingKey,
                  child: const SizedBox.expand(),
                );
              },
            ),
            child: const SizedBox(height: 64, width: 300),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(scope.barHeight.value, 148);
      final heights = <double>[];
      scope.barHeight.addListener(() => heights.add(scope.barHeight.value));
      Future<void> sample(Duration duration) async {
        await tester.pump(duration);
        expect(scope.barHeight.value, 148);
        expect(_bodyBottomPadding(tester, paddingKey), 148);
        expect(scope.visibleHeight.value, switch (scope.visibility.value) {
          BottomBarVisibility.shown => 148,
          BottomBarVisibility.minimized => 76,
          BottomBarVisibility.hidden => 0,
        });
      }

      controller.minimize();
      for (var i = 0; i < 25; i++) {
        await sample(const Duration(milliseconds: 8));
      }
      await tester.pumpAndSettle();
      expect(scope.visibleHeight.value, 76);
      expect(_bodyBottomPadding(tester, paddingKey), 148);
      controller.expand();
      for (var i = 0; i < 25; i++) {
        await sample(const Duration(milliseconds: 8));
      }
      await tester.pumpAndSettle();
      expect(scope.visibleHeight.value, 148);
      controller.hide();
      for (final step in [8, 16, 32, 8, 16]) {
        await sample(Duration(milliseconds: step));
        expect(_bodyBottomPadding(tester, paddingKey), 148);
      }
      await tester.pumpAndSettle();
      expect(scope.visibleHeight.value, 0);
      expect(_bodyBottomPadding(tester, paddingKey), 148);
      expect(scope.barHeight.value, 148);
      controller.show();
      for (final step in [8, 16, 32, 8, 16]) {
        await sample(Duration(milliseconds: step));
        expect(_bodyBottomPadding(tester, paddingKey), 148);
      }
      await tester.pumpAndSettle();
      expect(scope.visibleHeight.value, 148);
      expect(scope.barHeight.value, 148);
      expect(heights, isEmpty);
    },
  );

  for (final expanding in [false, true]) {
    testWidgets(
      'reduced motion settles accessory placement mid-morph expanding=$expanding',
      (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        late StateSetter update;
        var reduced = false;
        final placements = <BottomBarAccessoryPlacement>[];
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: reduced),
                  child: BottomBar(
                    controller: controller,
                    compactChild: const SizedBox.square(dimension: 48),
                    accessory: Builder(
                      builder: (context) {
                        placements.add(BottomBarAccessoryPlacement.of(context));
                        return const SizedBox(height: 56);
                      },
                    ),
                    body: const SizedBox.expand(),
                    child: const SizedBox(width: 300, height: 64),
                  ),
                );
              },
            ),
          ),
        );
        if (expanding) {
          controller.minimize();
          await tester.pumpAndSettle();
          controller.expand();
        } else {
          controller.minimize();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        if (expanding) {
          controller.minimize();
        } else {
          controller.expand();
        }
        await tester.pump(const Duration(milliseconds: 32));
        final surface = tester.renderObject<RenderBarSurface>(
          find.byKey(const ValueKey('pill')),
        );
        expect(surface.morph, inExclusiveRange(0, 1));
        update(() => reduced = true);
        await tester.pump();
        expect(surface.morph, expanding ? 1 : 0);
        expect(
          placements.last,
          expanding
              ? BottomBarAccessoryPlacement.inline
              : BottomBarAccessoryPlacement.expanded,
        );
      },
    );
  }

  testWidgets('showing a hidden minimized bar restores expanded placement', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final placements = <BottomBarAccessoryPlacement>[];
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          compactChild: const SizedBox.square(dimension: 48),
          accessory: Builder(
            builder: (context) {
              placements.add(BottomBarAccessoryPlacement.of(context));
              return const SizedBox(height: 56);
            },
          ),
          body: const SizedBox.expand(),
          child: const SizedBox(width: 300, height: 64),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    controller.hide();
    await tester.pumpAndSettle();
    controller.show();
    await tester.pumpAndSettle();
    expect(placements.last, BottomBarAccessoryPlacement.expanded);
    expect(
      tester
          .renderObject<RenderBarSurface>(find.byKey(const ValueKey('pill')))
          .morph,
      closeTo(0, .01),
    );
  });

  testWidgets('IndexedStack restore returns to the final accessory placement', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    var tab = 0;
    late StateSetter update;
    final placements = <BottomBarAccessoryPlacement>[];
    Widget list() => ListView.builder(
      itemCount: 100,
      itemBuilder: (_, index) =>
          SizedBox(height: 64, child: Text('Row $index')),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return BottomBar(
              controller: controller,
              scrollBehavior: const BottomBarScrollBehavior(
                visibilityOnTabChange: BottomBarTabVisibility.restore,
              ),
              accessory: Builder(
                builder: (context) {
                  placements.add(BottomBarAccessoryPlacement.of(context));
                  return const SizedBox(height: 56);
                },
              ),
              body: IndexedStack(index: tab, children: [list(), list()]),
              child: BottomBarItems(
                selectedIndex: tab,
                onSelected: (_) {},
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    update(() => tab = 1);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(placements.last, BottomBarAccessoryPlacement.expanded);
    update(() => tab = 0);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(placements.last, BottomBarAccessoryPlacement.inline);
    expect(
      tester
          .renderObject<RenderBarSurface>(find.byKey(const ValueKey('pill')))
          .morph,
      closeTo(1, .01),
    );
  });
}

double _bodyBottomPadding(WidgetTester tester, GlobalKey key) {
  final padding = tester.widget<Padding>(
    find.descendant(of: find.byKey(key), matching: find.byType(Padding)),
  );
  return padding.padding.resolve(TextDirection.ltr).bottom;
}
