import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/tooltip_finder.dart';

void main() {
  testWidgets('hidden action shows the bar for a reportScroll-only body', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            layout: const BottomBarLayout(respectSafeArea: false),
            body: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
            child: const SizedBox(height: 56),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.reportScroll(delta: 80);
    await tester.pumpAndSettle();
    expect(
      controller.isVisible,
      isFalse,
      reason: 'bar should hide after a reported scroll',
    );

    await tester.tap(findByTooltip('Scroll to top'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      controller.isVisible,
      isTrue,
      reason: 'tapping the hidden action should show the bar',
    );
  });

  testWidgets(
    'hidden action survives a body swap that disposes the scrolled list',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final showA = ValueNotifier<bool>(true);
      addTearDown(showA.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              layout: const BottomBarLayout(respectSafeArea: false),
              body: ValueListenableBuilder<bool>(
                valueListenable: showA,
                builder: (_, a, _) => a
                    ? ListView.builder(
                        key: const ValueKey('A'),
                        itemCount: 200,
                        itemBuilder: (_, i) => ListTile(title: Text('A $i')),
                      )
                    : ListView.builder(
                        key: const ValueKey('B'),
                        itemCount: 200,
                        itemBuilder: (_, i) => ListTile(title: Text('B $i')),
                      ),
              ),
              child: const SizedBox(height: 56),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const ValueKey('A')), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        controller.isVisible,
        isFalse,
        reason: 'bar should hide after scrolling list A',
      );

      showA.value = false;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('A')), findsNothing);
      expect(
        controller.isVisible,
        isFalse,
        reason: 'swapping the body alone should not show the bar',
      );

      await tester.tap(findByTooltip('Scroll to top'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        controller.isVisible,
        isTrue,
        reason: 'tapping the hidden action should show the bar',
      );
    },
  );

  group('IndexedStack scrolls only the visible list', () {
    Widget buildHarness({
      required BottomBarController controller,
      required ScrollController a,
      required ScrollController b,
      required ValueNotifier<int> index,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            layout: const BottomBarLayout(respectSafeArea: false),
            body: ValueListenableBuilder<int>(
              valueListenable: index,
              builder: (_, i, _) => IndexedStack(
                index: i,
                children: [
                  ListView.builder(
                    key: const ValueKey('A'),
                    controller: a,
                    itemCount: 200,
                    itemBuilder: (_, n) => ListTile(title: Text('A $n')),
                  ),
                  ListView.builder(
                    key: const ValueKey('B'),
                    controller: b,
                    itemCount: 200,
                    itemBuilder: (_, n) => ListTile(title: Text('B $n')),
                  ),
                ],
              ),
            ),
            child: const SizedBox(height: 56),
          ),
        ),
      );
    }

    testWidgets(
      'offstage list is not scrolled when the visible one never scrolled',
      (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        final a = ScrollController();
        addTearDown(a.dispose);
        final b = ScrollController();
        addTearDown(b.dispose);
        final index = ValueNotifier<int>(0);
        addTearDown(index.dispose);

        await tester.pumpWidget(
          buildHarness(controller: controller, a: a, b: b, index: index),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byKey(const ValueKey('A')),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        expect(
          controller.isVisible,
          isFalse,
          reason: 'bar should hide after scrolling list A',
        );
        final aOffset = a.offset;
        expect(aOffset, greaterThan(0));

        index.value = 1;
        await tester.pumpAndSettle();

        await tester.tap(findByTooltip('Scroll to top'));
        await tester.pumpAndSettle();

        expect(
          a.offset,
          equals(aOffset),
          reason: 'hidden list A should keep its offset',
        );
        expect(
          b.offset,
          equals(0),
          reason: 'list B never scrolled and should stay at the top',
        );
        expect(controller.isVisible, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('falls back to the visible list after another tab scrolled', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final a = ScrollController();
      addTearDown(a.dispose);
      final b = ScrollController();
      addTearDown(b.dispose);
      final index = ValueNotifier<int>(0);
      addTearDown(index.dispose);

      await tester.pumpWidget(
        buildHarness(controller: controller, a: a, b: b, index: index),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const ValueKey('A')), const Offset(0, -500));
      await tester.pumpAndSettle();

      index.value = 1;
      await tester.pumpAndSettle();

      controller.show();
      await tester.pumpAndSettle();

      await tester.drag(find.byKey(const ValueKey('B')), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(
        controller.isVisible,
        isFalse,
        reason: 'bar should hide after scrolling list B',
      );
      final bOffset = b.offset;

      index.value = 0;
      await tester.pumpAndSettle();

      if (controller.isVisible) {
        controller.hide();
        await tester.pumpAndSettle();
      }

      await tester.tap(findByTooltip('Scroll to top'));
      await tester.pumpAndSettle();

      expect(
        a.offset,
        closeTo(0, 0.5),
        reason: 'visible list A should scroll to the top',
      );
      expect(
        b.offset,
        equals(bOffset),
        reason: 'offstage list B should keep its offset',
      );
      expect(controller.isVisible, isTrue);
    });
  });
}
