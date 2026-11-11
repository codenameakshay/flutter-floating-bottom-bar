import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Tab = (IconData, String);

const _five = <_Tab>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
  (Icons.settings, 'Settings'),
];

final _four = _five.sublist(0, 4);
final _three = _five.sublist(0, 3);

const _ringKey = Key('ind');

Widget _ringBuilder(BuildContext context, Rect rect, bool settled) =>
    const ColoredBox(key: _ringKey, color: Colors.red);

const _ring = BottomBarIndicator.builder(_ringBuilder);

BottomBarItem _item(
  int index,
  _Tab tab, {
  bool selected = false,
  VoidCallback? onTap,
  Color? selectedColor,
}) {
  return BottomBarItem(
    key: ValueKey(index),
    icon: Icon(tab.$1),
    label: Text(tab.$2),
    selected: selected,
    onTap: onTap,
    selectedColor: selectedColor,
  );
}

List<Widget> _children(List<_Tab> tabs) => [
  for (var i = 0; i < tabs.length; i++) _item(i, tabs[i]),
];

Widget _app(
  Widget body, {
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    builder: (context, child) => reduceMotion
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          )
        : child!,
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: body),
      ),
    ),
  );
}

Widget _bar({
  List<_Tab> tabs = _five,
  List<Widget>? children,
  double width = 400,
  int? selectedIndex,
  BottomBarIndicator? indicator,
  BottomBarLabelBehavior labelBehavior = BottomBarLabelBehavior.alwaysShow,
  ValueChanged<int>? onSelected,
}) {
  return SizedBox(
    width: width,
    height: 64,
    child: BottomBarItems(
      selectedIndex: selectedIndex,
      indicator: indicator,
      labelBehavior: labelBehavior,
      onSelected: onSelected,
      children: children ?? _children(tabs),
    ),
  );
}

Rect _indicatorRect(WidgetTester tester) =>
    tester.getRect(find.byKey(_ringKey));

Rect _contentRect(WidgetTester tester, int index, String label) {
  final icon = find.descendant(
    of: find.byKey(ValueKey(index)),
    matching: find.byType(Icon),
  );
  return tester.getRect(icon).expandToInclude(tester.getRect(find.text(label)));
}

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.01));
  expect(actual.top, closeTo(expected.top, 0.01));
  expect(actual.right, closeTo(expected.right, 0.01));
  expect(actual.bottom, closeTo(expected.bottom, 0.01));
}

void _expectPill(WidgetTester tester, Rect content) {
  expect(
    find.byType(BottomBarItems),
    paints..rrect(
      rrect: RRect.fromRectAndRadius(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
            .inflateRect(content)
            .shift(-tester.getTopLeft(find.byType(BottomBarItems))),
        const Radius.circular(16),
      ),
    ),
  );
}

Rect _pillRect(WidgetTester tester) {
  late Rect rect;
  expect(
    find.byType(BottomBarItems),
    paints..something((method, arguments) {
      if (method != #drawRRect) return false;
      rect = (arguments.first as RRect).outerRect;
      return true;
    }),
  );
  return rect;
}

Color? _iconColor(WidgetTester tester, int index) {
  final icon = find.descendant(
    of: find.byKey(ValueKey(index)),
    matching: find.byType(Icon),
  );
  return IconTheme.of(tester.element(icon)).color;
}

void main() {
  testWidgets('wide LTR row: settled indicator equals selected content rect', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_bar(selectedIndex: 2, indicator: _ring)));
    await tester.pumpAndSettle();

    _expectRect(_indicatorRect(tester), _contentRect(tester, 2, 'Inbox'));
  });

  testWidgets(
    'wide RTL row: settled indicator equals selected content rect on the correct side',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _bar(selectedIndex: 0, indicator: _ring),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      _expectRect(_indicatorRect(tester), _contentRect(tester, 0, 'Home'));
      expect(
        _indicatorRect(tester).center.dx,
        greaterThan(tester.getCenter(find.text('Search')).dx),
      );
    },
  );

  testWidgets(
    'narrow scrolling row: indicator equals selected content rect inside the viewport',
    (tester) async {
      await tester.pumpWidget(
        _app(_bar(width: 120, selectedIndex: 0, indicator: _ring)),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _app(_bar(width: 120, selectedIndex: 4, indicator: _ring)),
      );
      await tester.pumpAndSettle();

      final content = _contentRect(tester, 4, 'Settings');
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      _expectRect(_indicatorRect(tester), content);
      expect(content.left, greaterThanOrEqualTo(viewport.left));
      expect(content.right, lessThanOrEqualTo(viewport.right));
    },
  );

  testWidgets('unbounded row: settled indicator equals selected content rect', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        UnconstrainedBox(
          child: BottomBarItems(
            selectedIndex: 3,
            indicator: _ring,
            children: _children(_five),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectRect(_indicatorRect(tester), _contentRect(tester, 3, 'Profile'));
  });

  testWidgets(
    'retarget mid-flight keeps velocity and moves at most 60px per 16ms frame',
    (tester) async {
      await tester.pumpWidget(_app(_bar(selectedIndex: 1, indicator: _ring)));
      await tester.pumpAndSettle();

      await tester.pumpWidget(_app(_bar(selectedIndex: 4, indicator: _ring)));
      await tester.pump(const Duration(milliseconds: 60));
      final x = _indicatorRect(tester).center.dx;

      await tester.pump(const Duration(milliseconds: 16));
      final x2 = _indicatorRect(tester).center.dx;
      expect(x2, greaterThan(x));

      // Item 0 is behind the indicator, so only carried momentum can move it
      // further right on the first frame after the retarget.
      await tester.pumpWidget(_app(_bar(selectedIndex: 0, indicator: _ring)));
      await tester.pump(const Duration(milliseconds: 16));
      final x3 = _indicatorRect(tester).center.dx;
      expect(x3, greaterThan(x2));

      await tester.pumpWidget(_app(_bar(selectedIndex: 2, indicator: _ring)));

      final samples = [x2, x3];
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(_indicatorRect(tester).center.dx);
      }
      for (var i = 1; i < samples.length; i++) {
        expect((samples[i] - samples[i - 1]).abs(), lessThanOrEqualTo(60));
      }

      await tester.pumpAndSettle();
      _expectRect(_indicatorRect(tester), _contentRect(tester, 2, 'Inbox'));
    },
  );

  testWidgets('reduced motion jumps to the selected item in one pump', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_bar(selectedIndex: 0, indicator: _ring), reduceMotion: true),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _app(_bar(selectedIndex: 3, indicator: _ring), reduceMotion: true),
    );
    await tester.pump();

    _expectRect(_indicatorRect(tester), _contentRect(tester, 3, 'Profile'));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('same-frame placement after a resize from 400 to 300', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_bar(tabs: _four, selectedIndex: 1, indicator: _ring)),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _app(_bar(tabs: _four, width: 300, selectedIndex: 1, indicator: _ring)),
    );

    _expectRect(_indicatorRect(tester), _contentRect(tester, 1, 'Search'));
  });

  testWidgets(
    'same-frame placement after labelBehavior alwaysShow to onlySelected',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _bar(
            selectedIndex: 1,
            indicator: const BottomBarIndicator.pill(),
            labelBehavior: BottomBarLabelBehavior.alwaysShow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _app(
          _bar(
            selectedIndex: 1,
            indicator: const BottomBarIndicator.pill(),
            labelBehavior: BottomBarLabelBehavior.onlySelected,
          ),
        ),
      );

      _expectPill(tester, _contentRect(tester, 1, 'Search'));
    },
  );

  testWidgets(
    'same-frame placement after inserting an item at index 0 while selection moves 1 to 2',
    (tester) async {
      await tester.pumpWidget(
        _app(_bar(tabs: _four, selectedIndex: 1, indicator: _ring)),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _app(
          _bar(tabs: [_five[4], ..._four], selectedIndex: 2, indicator: _ring),
        ),
      );

      _expectRect(_indicatorRect(tester), _contentRect(tester, 2, 'Search'));
    },
  );

  testWidgets('same-frame placement after removing the last item', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_bar(tabs: _four, selectedIndex: 2, indicator: _ring)),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _app(_bar(tabs: _three, selectedIndex: 2, indicator: _ring)),
    );

    _expectRect(_indicatorRect(tester), _contentRect(tester, 2, 'Inbox'));
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'stretch pill leads with one edge, never overshoots, and settles on the item (${direction.name})',
      (tester) async {
        const stretch = BottomBarIndicator.pill(stretch: true);
        await tester.pumpWidget(
          _app(
            _bar(selectedIndex: 0, indicator: stretch),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          _app(
            _bar(selectedIndex: 3, indicator: stretch),
            direction: direction,
          ),
        );
        final origin = tester.getTopLeft(find.byType(BottomBarItems));
        final start = _pillRect(tester).shift(origin);
        final end = const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ).inflateRect(_contentRect(tester, 3, 'Profile'));
        final towardEnd = end.center.dx > start.center.dx;
        var widest = 0.0;
        for (var frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final pill = _pillRect(tester).shift(origin);
          widest = pill.width > widest ? pill.width : widest;
          if (towardEnd) {
            expect(pill.right, lessThanOrEqualTo(end.right + 0.01));
          } else {
            expect(pill.left, greaterThanOrEqualTo(end.left - 0.01));
          }
        }
        expect(widest, greaterThan(end.width + 40));
        expect(tester.takeException(), isNull);

        await tester.pumpAndSettle();
        _expectPill(tester, _contentRect(tester, 3, 'Profile'));
      },
    );
  }

  testWidgets(
    'selected semantics follow selectedIndex, not BottomBarItem.selected',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _app(
            _bar(
              selectedIndex: 2,
              indicator: _ring,
              children: [
                for (var i = 0; i < 4; i++)
                  _item(i, _five[i], selected: i == 0, onTap: () {}),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (var i = 0; i < 4; i++) {
          final node = tester.getSemantics(
            find
                .descendant(
                  of: find.byKey(ValueKey(i)),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Semantics && widget.properties.button == true,
                  ),
                )
                .first,
          );
          expect(
            node.getSemanticsData().flagsCollection.isSelected,
            i == 2 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
            reason: 'item $i',
          );
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'onTap runs before onSelected, and onSelected runs even when onTap is null',
    (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        _app(
          _bar(
            selectedIndex: 0,
            onSelected: (i) => log.add('select$i'),
            children: [
              for (var i = 0; i < 4; i++)
                _item(
                  i,
                  _five[i],
                  onTap: i == 1 ? null : () => log.add('tap$i'),
                ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(2)));
      await tester.pump();
      expect(log, ['tap2', 'select2']);

      log.clear();
      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pump();
      expect(log, ['select1']);
    },
  );

  testWidgets(
    'a custom child gets the selection scope and its slot is indicated',
    (tester) async {
      BottomBarItemSelectionScope? seen;
      await tester.pumpWidget(
        _app(
          _bar(
            selectedIndex: 2,
            indicator: _ring,
            onSelected: (_) {},
            children: [
              _item(0, _five[0]),
              _item(1, _five[1]),
              Builder(
                builder: (context) {
                  seen = BottomBarItemSelectionScope.maybeOf(context);
                  return const SizedBox(
                    key: Key('custom'),
                    width: 48,
                    height: 48,
                  );
                },
              ),
              _item(3, _five[3]),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(seen, isNotNull);
      expect(seen!.index, 2);
      expect(seen!.selected, isTrue);
      expect(seen!.onSelect, isNotNull);
      _expectRect(
        _indicatorRect(tester),
        tester.getRect(find.byKey(const Key('custom'))),
      );
    },
  );

  testWidgets(
    'without selectedIndex the tree has no selection scope or indicator render objects',
    (tester) async {
      await tester.pumpWidget(_app(_bar()));
      await tester.pumpAndSettle();

      expect(find.byType(BottomBarItemSelectionScope), findsNothing);

      final types = <String>[];
      void visit(RenderObject node) {
        types.add(node.runtimeType.toString());
        node.visitChildren(visit);
      }

      visit(tester.renderObject(find.byType(BottomBarItems)));
      expect(types.where((type) => type.contains('Indicator')), isEmpty);
    },
  );

  testWidgets(
    'an item selected through BottomBarItem.selected without selectedIndex keeps colorScheme.primary',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _bar(
            children: [_item(0, _five[0], selected: true), _item(1, _five[1])],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final primary = Theme.of(
        tester.element(find.byType(BottomBarItems)),
      ).colorScheme.primary;
      expect(_iconColor(tester, 0), primary);
    },
  );

  testWidgets(
    'pill selected content uses onSecondaryContainer when no selectedColor is set',
    (tester) async {
      await tester.pumpWidget(
        _app(
          _bar(selectedIndex: 1, indicator: const BottomBarIndicator.pill()),
        ),
      );
      await tester.pumpAndSettle();

      final colors = Theme.of(
        tester.element(find.byType(BottomBarItems)),
      ).colorScheme;
      expect(_iconColor(tester, 1), colors.onSecondaryContainer);
    },
  );

  testWidgets('pill selected content uses the item selectedColor when set', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _bar(
          indicator: const BottomBarIndicator.pill(),
          selectedIndex: 1,
          children: [
            _item(0, _five[0]),
            _item(1, _five[1], selectedColor: Colors.green),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_iconColor(tester, 1), Colors.green);
  });

  testWidgets('underline selected content uses colorScheme.primary', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _bar(selectedIndex: 1, indicator: const BottomBarIndicator.underline()),
      ),
    );
    await tester.pumpAndSettle();

    final colors = Theme.of(
      tester.element(find.byType(BottomBarItems)),
    ).colorScheme;
    expect(_iconColor(tester, 1), colors.primary);
  });

  testWidgets('out-of-range selectedIndex asserts in debug', (tester) async {
    await tester.pumpWidget(
      _app(_bar(tabs: _three, selectedIndex: 9, indicator: _ring)),
    );

    expect(tester.takeException(), isAssertionError);
  });
}
