import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final expanding in [false, true]) {
    testWidgets(
      'enabling reduced motion settles an in-flight morph expanding=$expanding',
      (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        late StateSetter update;
        var reduced = false;
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
                    body: const SizedBox.expand(),
                    child: const SizedBox(width: 300, height: 64),
                  ),
                );
              },
            ),
          ),
        );
        controller.minimize();
        if (expanding) {
          await tester.pumpAndSettle();
          controller.expand();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        RenderBarSurface surface() =>
            tester.renderObject(find.byType(BarSurface));
        expect(surface().morph, inExclusiveRange(0, 1));
        update(() => reduced = true);
        await tester.pump();
        expect(surface().morph, expanding ? 0 : 1);
        expect(
          controller.visibility.value,
          expanding ? BottomBarVisibility.shown : BottomBarVisibility.minimized,
        );
        controller.expand();
        await tester.pump();
        expect(surface().morph, 0);
        expect(find.byType(CompactPillButton), findsNothing);
      },
    );
  }

  for (final source in ['visibility', 'visibleHeight', 'controller']) {
    testWidgets(
      'reentrant $source commands keep scope and controller aligned',
      (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        late BottomBarScope scope;
        await tester.pumpWidget(
          MaterialApp(
            home: BottomBar(
              controller: controller,
              compactChild: const SizedBox.square(dimension: 48),
              body: Builder(
                builder: (context) {
                  scope = BottomBarScope.of(context);
                  return const SizedBox.expand();
                },
              ),
              child: const SizedBox(width: 300, height: 64),
            ),
          ),
        );
        final listenable = switch (source) {
          'visibility' => scope.visibility,
          'visibleHeight' => scope.visibleHeight,
          _ => controller.visibility,
        };
        var redirected = false;
        listenable.addListener(() {
          if (!redirected) {
            redirected = true;
            if (source == 'visibleHeight') {
              controller.minimize();
            } else {
              controller.hide();
            }
          }
        });
        if (source == 'visibleHeight') {
          controller.hide();
        } else {
          controller.minimize();
        }
        await tester.pumpAndSettle();
        final expected = source == 'visibleHeight'
            ? BottomBarVisibility.minimized
            : BottomBarVisibility.hidden;
        expect(scope.visibility.value, expected);
        expect(scope.isVisible.value, source == 'visibleHeight');
        expect(
          scope.visibleHeight.value,
          source == 'visibleHeight' ? greaterThan(0) : 0,
        );
        expect(controller.visibility.value, expected);
      },
    );
  }

  for (final pageView in [false, true]) {
    for (final restore in [false, true]) {
      testWidgets(
        'mid-morph ${pageView ? 'PageView' : 'IndexedStack'} tab change restore=$restore',
        (tester) async {
          final controller = BottomBarController();
          final pages = PageController();
          addTearDown(controller.dispose);
          addTearDown(pages.dispose);
          var tab = 0;
          late StateSetter update;
          Widget list() => ListView.builder(
            itemCount: 100,
            itemBuilder: (_, i) => SizedBox(height: 64, child: Text('Row $i')),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return BottomBar(
                    controller: controller,
                    scrollBehavior: BottomBarScrollBehavior(
                      visibilityOnTabChange: restore
                          ? BottomBarTabVisibility.restore
                          : BottomBarTabVisibility.show,
                    ),
                    body: pageView
                        ? PageView(
                            controller: pages,
                            children: [list(), list()],
                          )
                        : IndexedStack(index: tab, children: [list(), list()]),
                    child: BottomBarItems(
                      selectedIndex: tab,
                      onSelected: (_) {},
                      children: const [
                        BottomBarItem(
                          icon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
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
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 32));
          expect(
            tester
                .renderObject<RenderBarSurface>(find.byType(BarSurface))
                .morph,
            inExclusiveRange(0, 1),
          );
          update(() => tab = 1);
          if (pageView) pages.jumpToPage(1);
          await tester.pump();
          final pill = tester.widget<DefaultCompactPill>(
            find.byType(DefaultCompactPill),
          );
          expect((pill.item.icon as Icon).icon, Icons.search);
          await tester.pumpAndSettle();
          expect(controller.visibility.value, BottomBarVisibility.shown);
          expect(find.byType(CompactPillButton), findsNothing);
          update(() => tab = 0);
          if (pageView) pages.jumpToPage(0);
          await tester.pumpAndSettle();
          expect(
            controller.visibility.value,
            restore ? BottomBarVisibility.minimized : BottomBarVisibility.shown,
          );
          expect(
            tester
                .renderObject<RenderBarSurface>(find.byType(BarSurface))
                .morph,
            restore ? 1 : 0,
          );
        },
      );
    }
  }

  testWidgets(
    'compact removal and replacement preserve visibility on retries',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      late StateSetter update;
      var compact = true;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return BottomBar(
                controller: controller,
                compactChild: compact
                    ? const SizedBox.square(dimension: 48)
                    : null,
                body: const SizedBox.expand(),
                child: const SizedBox(width: 300, height: 64),
              );
            },
          ),
        ),
      );
      controller.minimize();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      update(() => compact = false);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.hidden);
      update(() => compact = true);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.hidden);
      controller.minimize();
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.minimized);
      expect(
        tester.renderObject<RenderBarSurface>(find.byType(BarSurface)).morph,
        1,
      );
      controller.show();
      await tester.pumpAndSettle();
      expect(find.byType(CompactPillButton), findsNothing);
    },
  );

  testWidgets(
    'sub-threshold reversals interleaved with commands settle consistently',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      late BottomBarScope scope;
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBar(
            controller: controller,
            scrollBehavior: const BottomBarScrollBehavior(
              minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
              deltaThreshold: 20,
            ),
            compactChild: const SizedBox.square(dimension: 48),
            body: Builder(
              builder: (context) {
                scope = BottomBarScope.of(context);
                return const SizedBox.expand();
              },
            ),
            child: const SizedBox(width: 300, height: 64),
          ),
        ),
      );
      controller.reportScroll(delta: 25);
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        controller.reportScroll(delta: i.isEven ? -5 : 5);
        await tester.pump(const Duration(milliseconds: 16));
        expect(scope.visibility.value, BottomBarVisibility.minimized);
      }
      controller.show();
      controller.reportScroll(delta: 25);
      await tester.pump(const Duration(milliseconds: 16));
      controller.hide();
      controller.reportScroll(delta: -25);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.shown);
      expect(scope.visibility.value, BottomBarVisibility.shown);
      expect(scope.isVisible.value, isTrue);
      expect(scope.visibleHeight.value, scope.barHeight.value);
      expect(
        tester.renderObject<RenderBarSurface>(find.byType(BarSurface)).morph,
        0,
      );
      expect(find.byType(CompactPillButton), findsNothing);
    },
  );
}
