import 'package:flutter/gestures.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('column updates overflow and drag selection after resizing', (
    tester,
  ) async {
    var height = 100.0;
    late StateSetter resize;
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              resize = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 80,
                  height: height,
                  child: BottomBarItems(
                    direction: Axis.vertical,
                    selectedIndex: 0,
                    indicator: const BottomBarIndicator.pill(),
                    dragToSelect: true,
                    onSelected: selected.add,
                    children: [
                      for (var i = 0; i < 4; i++)
                        BottomBarItem(
                          key: ValueKey(i),
                          icon: const Icon(Icons.home),
                          label: Text('Tab $i'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    RawGestureDetector track() => tester.widget<RawGestureDetector>(
      find
          .ancestor(
            of: find.byType(BottomBarItem).first,
            matching: find.byType(RawGestureDetector),
          )
          .first,
    );
    expect(track().gestures, isEmpty);
    resize(() => height = 400);
    await tester.pumpAndSettle();
    expect(track().gestures, contains(VerticalDragGestureRecognizer));
    resize(() => height = 100);
    await tester.pumpAndSettle();
    expect(track().gestures, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing direction cancels an active selection drag', (
    tester,
  ) async {
    var direction = Axis.horizontal;
    late StateSetter rotate;
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rotate = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 240,
                  height: 400,
                  child: BottomBarItems(
                    direction: direction,
                    selectedIndex: 0,
                    indicator: const BottomBarIndicator.pill(),
                    dragToSelect: true,
                    onSelected: selected.add,
                    children: [
                      for (var i = 0; i < 3; i++)
                        BottomBarItem(
                          key: ValueKey(i),
                          icon: const Icon(Icons.home),
                          label: Text('Tab $i'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey(0))),
    );
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    rotate(() => direction = Axis.vertical);
    await tester.pumpAndSettle();
    final selectedScopes = tester.widgetList<BottomBarItemSelectionScope>(
      find.byType(BottomBarItemSelectionScope),
    );
    expect(selectedScopes.singleWhere((scope) => scope.selected).index, 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final boundedWidth in [true, false]) {
    testWidgets(
      'column tolerates unbounded height, width bounded $boundedWidth',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: boundedWidth ? Axis.vertical : Axis.horizontal,
                child: UnconstrainedBox(
                  child: BottomBarItems(
                    direction: Axis.vertical,
                    selectedIndex: 0,
                    indicator: const BottomBarIndicator.pill(),
                    centerAction: BottomBarCenterAction(
                      icon: const Icon(Icons.add),
                      tooltip: 'Add',
                      onPressed: () {},
                    ),
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
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getBottomLeft(find.byType(BottomBarCenterAction)).dy,
          lessThanOrEqualTo(
            tester.getTopLeft(find.byType(BottomBarItem).first).dy,
          ),
        );
      },
    );
  }
}
