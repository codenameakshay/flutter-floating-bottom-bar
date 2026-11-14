import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _icons = <IconData>[Icons.home, Icons.search, Icons.inbox, Icons.person];

BottomBarItem _item(int index, {BottomBarBadge? badge}) => BottomBarItem(
  key: ValueKey(index),
  icon: Icon(_icons[index % _icons.length]),
  label: Text('Tab $index'),
  badge: badge,
);

Widget _host({
  double height = 400,
  int count = 4,
  int initial = 0,
  List<BottomBarItem>? items,
  BottomBarIndicator? indicator = const BottomBarIndicator.pill(),
  bool dragToSelect = false,
  BottomBarCenterAction? centerAction,
  TextDirection direction = TextDirection.ltr,
  List<int>? selected,
  List<int>? reselected,
  List<int>? longPressed,
}) {
  var index = initial;
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 80,
            height: height,
            child: StatefulBuilder(
              builder: (context, setState) => BottomBarItems(
                direction: Axis.vertical,
                selectedIndex: index,
                indicator: indicator,
                dragToSelect: dragToSelect,
                centerAction: centerAction,
                onSelected: (i) {
                  setState(() => index = i);
                  selected?.add(i);
                },
                onReselected: reselected == null
                    ? null
                    : (i) => reselected.add(i),
                onLongPressed: longPressed == null
                    ? null
                    : (i) => longPressed.add(i),
                children: items ?? [for (var i = 0; i < count; i++) _item(i)],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Rect _slot(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey(index)));

/// The first painted rounded rect in the row, in global coordinates.
Rect _paintedRect(WidgetTester tester) {
  final origin = tester.getTopLeft(find.byType(BottomBarItems));
  late Rect rect;
  expect(
    find.byType(BottomBarItems),
    paints..something((method, arguments) {
      if (method != #drawRRect) return false;
      rect = (arguments.first as RRect).outerRect;
      return true;
    }),
  );
  return rect.shift(origin);
}

void main() {
  testWidgets('items stack top to bottom at the full column width', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      expect(tester.getSize(find.byKey(ValueKey(i))).width, 80.0);
      if (i > 0) {
        expect(
          _slot(tester, i).top,
          greaterThanOrEqualTo(_slot(tester, i - 1).bottom),
        );
      }
    }
  });

  testWidgets(
    'the indicator sits on the selected item and slides up on a tap',
    (tester) async {
      await tester.pumpWidget(_host(initial: 2));
      await tester.pumpAndSettle();

      var pill = _paintedRect(tester);
      expect(pill.top, greaterThanOrEqualTo(_slot(tester, 2).top));
      expect(pill.bottom, lessThanOrEqualTo(_slot(tester, 2).bottom));
      expect(pill.top, greaterThan(_slot(tester, 0).bottom));

      await tester.tap(find.byKey(ValueKey(0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      pill = _paintedRect(tester);
      expect(pill.top, greaterThan(_slot(tester, 0).top));
      expect(pill.top, lessThan(_slot(tester, 2).top + 2));

      await tester.pumpAndSettle();
      pill = _paintedRect(tester);
      expect(pill.top, greaterThanOrEqualTo(_slot(tester, 0).top));
      expect(pill.bottom, lessThanOrEqualTo(_slot(tester, 0).bottom));
    },
  );

  testWidgets('a count badge shows its number', (tester) async {
    await tester.pumpWidget(
      _host(
        items: [
          _item(0, badge: const BottomBarBadge.count(3)),
          _item(1),
          _item(2),
          _item(3),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a tap selects, and tapping the selected item reselects it', (
    tester,
  ) async {
    final selected = <int>[];
    final reselected = <int>[];
    await tester.pumpWidget(_host(selected: selected, reselected: reselected));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey(1)));
    await tester.pumpAndSettle();
    expect(selected, [1]);
    expect(reselected, isEmpty);

    await tester.tap(find.byKey(ValueKey(1)));
    await tester.pumpAndSettle();
    expect(reselected, [1]);
    expect(selected, [1, 1]);
  });

  testWidgets('a long-press calls onLongPressed with the index', (
    tester,
  ) async {
    final longPressed = <int>[];
    await tester.pumpWidget(_host(longPressed: longPressed));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(ValueKey(2)));
    await tester.pumpAndSettle();
    expect(longPressed, [2]);
  });

  testWidgets('dragToSelect: sliding down to item 3 and releasing selects it', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(dragToSelect: true, selected: selected));
    await tester.pumpAndSettle();

    final c0 = tester.getCenter(find.byKey(ValueKey(0)));
    final c3 = tester.getCenter(find.byKey(ValueKey(3)));
    final gesture = await tester.startGesture(c0);
    final step = (c3 - c0) / 10;
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(step);
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, [3]);
  });

  testWidgets('dragToSelect: a far sideways drag cancels with no selection', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(_host(dragToSelect: true, selected: selected));
    await tester.pumpAndSettle();

    final c0 = tester.getCenter(find.byKey(ValueKey(0)));
    final gesture = await tester.startGesture(c0);
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
  });

  testWidgets(
    'the centre action sits above item 0 and its tap skips selection',
    (tester) async {
      var pressed = 0;
      final selected = <int>[];
      await tester.pumpWidget(
        _host(
          selected: selected,
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add),
            tooltip: 'Create',
            onPressed: () {
              pressed++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final action = tester.getRect(find.byType(BottomBarCenterAction));
      expect(action.bottom, lessThanOrEqualTo(_slot(tester, 0).top));

      await tester.tap(find.byType(BottomBarCenterAction));
      await tester.pumpAndSettle();
      expect(pressed, 1);
      expect(selected, isEmpty);
    },
  );

  testWidgets('a long column scrolls to reach its last item', (tester) async {
    await tester.pumpWidget(_host(height: 300, count: 12));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    final top = tester.getTopLeft(find.byType(SingleChildScrollView)).dy;
    expect(_slot(tester, 11).top, greaterThan(top + 300));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(_slot(tester, 11).bottom, lessThanOrEqualTo(top + 300));
  });

  testWidgets('dragToSelect does not select while a long column scrolls', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _host(height: 300, count: 12, dragToSelect: true, selected: selected),
    );
    await tester.pumpAndSettle();

    final before = _slot(tester, 1).top;
    await tester.drag(find.byKey(ValueKey(1)), const Offset(0, -150));
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(_slot(tester, 1).top, lessThan(before));
  });

  testWidgets('RTL: a tap still selects the item', (tester) async {
    final selected = <int>[];
    await tester.pumpWidget(
      _host(direction: TextDirection.rtl, selected: selected),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ValueKey(2)));
    await tester.pumpAndSettle();
    expect(selected, [2]);
  });

  testWidgets('RTL: the underline stands on the right, the start side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        direction: TextDirection.rtl,
        indicator: const BottomBarIndicator.underline(),
      ),
    );
    await tester.pumpAndSettle();

    expect(_paintedRect(tester).right, closeTo(_slot(tester, 0).right, 0.01));
  });

  testWidgets('LTR: the underline stands on the left, the start side', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(indicator: const BottomBarIndicator.underline()),
    );
    await tester.pumpAndSettle();

    expect(_paintedRect(tester).left, closeTo(_slot(tester, 0).left, 0.01));
  });
}
