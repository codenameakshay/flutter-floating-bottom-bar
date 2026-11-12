import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _ringKey = Key('ind');

Widget _ring(BuildContext context, Rect rect, bool settled) =>
    const ColoredBox(key: _ringKey, color: Colors.red);

Offset _ringCentre(WidgetTester tester) =>
    tester.getCenter(find.byKey(_ringKey));

Offset _itemCentre(WidgetTester tester, int index) =>
    tester.getCenter(find.byKey(ValueKey(index)));

Widget _row({
  required int initial,
  required List<int> selected,
  List<int>? reselected,
  int count = 4,
  bool dragToSelect = true,
  BottomBarIndicator indicator = const BottomBarIndicator.builder(_ring),
}) {
  var index = initial;
  return StatefulBuilder(
    builder: (context, setState) => BottomBarItems(
      selectedIndex: index,
      dragToSelect: dragToSelect,
      indicator: indicator,
      onSelected: (i) => setState(() {
        selected.add(i);
        index = i;
      }),
      onReselected: reselected == null ? null : (i) => reselected.add(i),
      children: [
        for (var i = 0; i < count; i++)
          BottomBarItem(
            key: ValueKey(i),
            icon: const Icon(Icons.home),
            label: Text('L$i'),
          ),
      ],
    ),
  );
}

Widget _host(
  Widget row, {
  double width = 400,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    builder: (context, child) => reduceMotion
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          )
        : child!,
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(width: width, child: row),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('indicator follows the pointer', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(_row(initial: 0, selected: selected)));
    final c0 = _itemCentre(tester, 0);
    final c1 = _itemCentre(tester, 1);
    final c2 = _itemCentre(tester, 2);
    final c3 = _itemCentre(tester, 3);

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    expect(_ringCentre(tester).dx, closeTo(c0.dx + 30, 1));

    final between = Offset((c1.dx + c2.dx) / 2, c1.dy);
    await gesture.moveTo(between);
    await tester.pump();
    expect(_ringCentre(tester).dx, closeTo(between.dx, 1));

    await gesture.moveTo(c3 + const Offset(60, 0));
    await tester.pump();
    expect(_ringCentre(tester).dx, closeTo(c3.dx, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, [3]);
  });

  testWidgets('release selects the item under the finger', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(_row(initial: 0, selected: selected)));
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    await gesture.moveTo(c2 + const Offset(5, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, [2]);
    expect(_ringCentre(tester).dx, closeTo(c2.dx, 1));
  });

  testWidgets('release springs from the finger, not from the old item', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(_row(initial: 0, selected: selected)));
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    final finger = c2 + const Offset(40, 0);
    await gesture.moveTo(finger);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(_ringCentre(tester).dx, closeTo(finger.dx, 8));

    await tester.pumpAndSettle();
    expect(_ringCentre(tester).dx, closeTo(c2.dx, 1));
    expect(selected, [2]);
  });

  testWidgets('releasing on the selected item reselects it', (tester) async {
    final selected = <int>[];
    final reselected = <int>[];
    await tester.pumpWidget(
      _host(_row(initial: 1, selected: selected, reselected: reselected)),
    );
    final c1 = _itemCentre(tester, 1);

    final gesture = await tester.startGesture(c1);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    await gesture.moveTo(c1);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reselected, [1]);
    expect(selected, [1]);
    expect(_ringCentre(tester).dx, closeTo(c1.dx, 1));
  });

  testWidgets('a plain tap still selects with dragToSelect on', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(_row(initial: 0, selected: selected)));

    await tester.tap(find.byKey(const ValueKey(3)));
    await tester.pumpAndSettle();

    expect(selected, [3]);
    expect(_ringCentre(tester).dx, closeTo(_itemCentre(tester, 3).dx, 1));
  });

  testWidgets('dragging above the row cancels and springs back', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(_row(initial: 0, selected: selected)));
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);
    final rowHeight = tester.getSize(find.byType(BottomBarItems)).height;

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    await gesture.moveTo(c2);
    await tester.pump();
    await gesture.moveBy(Offset(0, -(rowHeight / 2 + 60)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(_ringCentre(tester).dx, closeTo(c0.dx, 1));
  });

  testWidgets('gesture cancel mid-drag springs back to the selected item', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(_row(initial: 0, selected: selected)));
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    await gesture.moveTo(c2);
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(_ringCentre(tester).dx, closeTo(c0.dx, 1));
  });

  testWidgets('drag does not select in a narrow scrolling row', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _host(_row(initial: 0, selected: selected, count: 6), width: 200),
    );
    final c0 = _itemCentre(tester, 0);

    await tester.dragFrom(c0, const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, greaterThan(0));
  });

  testWidgets('drag does not select without an indicator', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _host(
        _row(
          initial: 0,
          selected: selected,
          indicator: const BottomBarIndicator.none(),
        ),
      ),
    );
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveTo(c2);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);

    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.pumpAndSettle();
    expect(selected, [2]);
  });

  testWidgets('vertical drags scroll the body and do not select', (
    tester,
  ) async {
    final selected = <int>[];
    final controller = ScrollController();
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            body: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemBuilder: (context, i) => ListTile(title: Text('Row $i')),
            ),
            child: StatefulBuilder(
              builder: (context, setState) => BottomBarItems(
                selectedIndex: index,
                dragToSelect: true,
                indicator: const BottomBarIndicator.builder(_ring),
                onSelected: (i) => setState(() {
                  selected.add(i);
                  index = i;
                }),
                children: [
                  for (var i = 0; i < 4; i++)
                    BottomBarItem(
                      key: ValueKey(i),
                      icon: const Icon(Icons.home),
                      label: Text('L$i'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final c0 = _itemCentre(tester, 0);

    await tester.drag(find.byKey(const ValueKey(2)), const Offset(0, -30));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(_ringCentre(tester).dx, closeTo(c0.dx, 1));

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
  });

  testWidgets('drag follows the finger in RTL, item 0 on the right', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _host(_row(initial: 0, selected: selected), direction: TextDirection.rtl),
    );
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);
    expect(c0.dx, greaterThan(c2.dx));

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pumpAndSettle();
    await gesture.moveTo(c2);
    await tester.pump();
    expect(_ringCentre(tester).dx, closeTo(c2.dx, 1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, [2]);
  });

  testWidgets('reduced motion holds the indicator during a drag', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _host(_row(initial: 0, selected: selected), reduceMotion: true),
    );
    final c0 = _itemCentre(tester, 0);
    final c2 = _itemCentre(tester, 2);

    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveTo(c2);
    await tester.pump();
    expect(_ringCentre(tester).dx, closeTo(c0.dx, 1));

    await gesture.up();
    await tester.pump();
    expect(selected, [2]);
    expect(_ringCentre(tester).dx, closeTo(c2.dx, 1));
  });
}
