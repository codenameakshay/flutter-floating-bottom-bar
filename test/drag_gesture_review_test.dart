import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart'
    show IndicatorTrack;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _indicatorKey = Key('indicator');
Widget _indicator(BuildContext context, Rect rect, bool settled) =>
    const ColoredBox(key: _indicatorKey, color: Colors.red);

void main() {
  testWidgets('drag previews selection and restores it on cancel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: BottomBarItems(
                selectedIndex: 0,
                dragToSelect: true,
                indicator: const BottomBarIndicator.builder(_indicator),
                onSelected: (_) {},
                children: [
                  for (var i = 0; i < 4; i++)
                    Builder(
                      builder: (context) => SizedBox(
                        key: ValueKey(i),
                        height: 48,
                        child: Text(
                          '$i:${BottomBarItemSelectionScope.maybeOf(context)!.selected}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey(0))),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey(2))));
    await tester.pump();
    expect(find.text('2:true'), findsOneWidget);
    expect(find.text('0:false'), findsOneWidget);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(find.text('0:true'), findsOneWidget);
    expect(find.text('2:false'), findsOneWidget);
  });

  testWidgets('ignored drag selection settles back to the parent selection', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: BottomBarItems(
                selectedIndex: 0,
                dragToSelect: true,
                indicator: const BottomBarIndicator.builder(_indicator),
                onSelected: selections.add,
                children: [
                  for (var i = 0; i < 4; i++)
                    BottomBarItem(
                      key: ValueKey(i),
                      icon: const Icon(Icons.home),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final original = tester.getCenter(find.byKey(_indicatorKey));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey(0))),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey(2))));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(_indicatorKey)).dx,
      greaterThan(original.dx),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selections, [2]);
    expect(
      tester.getCenter(find.byKey(_indicatorKey)).dx,
      closeTo(original.dx, 0.01),
    );
    final motion = tester
        .widget<IndicatorTrack>(find.byType(IndicatorTrack))
        .motion;
    expect(motion.target, 0);
    expect(motion.settled, isTrue);
  });

  for (final change in [
    'selection',
    'drag disabled',
    'indicator removed',
    'narrow row',
    'disposed',
  ]) {
    testWidgets('$change cancels an active drag', (tester) async {
      var index = 0;
      var enabled = true;
      var width = 400.0;
      var disposed = false;
      var indicator = true;
      late StateSetter update;
      final selections = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    if (disposed) return const SizedBox();
                    return SizedBox(
                      width: width,
                      child: BottomBarItems(
                        selectedIndex: index,
                        dragToSelect: enabled,
                        indicator: indicator
                            ? const BottomBarIndicator.builder(_indicator)
                            : const BottomBarIndicator.none(),
                        onSelected: selections.add,
                        children: [
                          for (var i = 0; i < 4; i++)
                            BottomBarItem(
                              key: ValueKey(i),
                              icon: const Icon(Icons.home),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey(0))),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey(3))));
      await tester.pump();
      update(() {
        if (change == 'selection') index = 1;
        if (change == 'drag disabled') enabled = false;
        if (change == 'indicator removed') indicator = false;
        if (change == 'narrow row') width = 100;
        if (change == 'disposed') disposed = true;
      });
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selections, isEmpty);
      if (change != 'disposed' && change != 'indicator removed') {
        final scopes = tester.widgetList<BottomBarItemSelectionScope>(
          find.byType(BottomBarItemSelectionScope),
        );
        expect(scopes.where((scope) => scope.selected).single.index, index);
        expect(
          tester
              .widget<IndicatorTrack>(find.byType(IndicatorTrack))
              .motion
              .dragging,
          isFalse,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'removing children cancels a drag before its stale index selects',
    (tester) async {
      var count = 4;
      late StateSetter update;
      final selections = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return BottomBarItems(
                      selectedIndex: 0,
                      dragToSelect: true,
                      indicator: const BottomBarIndicator.builder(_indicator),
                      onSelected: selections.add,
                      children: [
                        for (var i = 0; i < count; i++)
                          BottomBarItem(
                            key: ValueKey(i),
                            icon: const Icon(Icons.home),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      final start = tester.getCenter(find.byKey(const ValueKey(0)));
      final last = tester.getCenter(find.byKey(const ValueKey(3)));
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveTo(last);
      await tester.pump();
      update(() => count = 1);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(selections, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
