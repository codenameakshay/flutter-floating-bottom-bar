import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/semantics.dart';
import 'helpers/tooltip_finder.dart';

void main() {
  group('BottomBarItem', () {
    testWidgets('renders icon, swaps to selectedIcon when selected', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarItem(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: const Text('Home'),
              selected: true,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('renders badge when supplied', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarItem(
              icon: const Icon(Icons.inbox),
              badge: Container(
                key: const Key('badge'),
                width: 8,
                height: 8,
                color: const Color(0xFFFF0000),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('badge')), findsOneWidget);
    });

    testWidgets(
      'uses the explicit tooltip name once when label and tooltip are both present',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _buildItemHarness(
              item: BottomBarItem(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: const Text('Home'),
                selected: true,
                tooltip: 'Go home',
                onTap: () {},
              ),
            ),
          );

          final data = tester
              .getSemantics(find.bySemanticsLabel('Go home'))
              .getSemanticsData();

          expect(data.label, 'Go home');
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isSelected, ui.Tristate.isTrue);
          expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(
            semanticsLabels(tester).where((label) => label == 'Go home'),
            hasLength(1),
          );
          expect(semanticsLabels(tester), isNot(contains('Home')));
          expect(findByTooltip('Go home'), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('exposes unselected enabled button semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildItemHarness(
            item: BottomBarItem(
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              onTap: () {},
            ),
          ),
        );

        final data = tester
            .getSemantics(find.text('Search'))
            .getSemanticsData();

        expect(data.label, 'Search');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, ui.Tristate.isFalse);
        expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('exposes disabled button semantics when onTap is null', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildItemHarness(
            item: BottomBarItem(
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Settings'),
            ),
          ),
        );

        final data = tester
            .getSemantics(find.text('Settings'))
            .getSemanticsData();

        expect(data.label, 'Settings');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'uses semanticLabel as the only accessible name and semantics activation triggers onTap once',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var taps = 0;
        try {
          await tester.pumpWidget(
            _buildItemHarness(
              item: BottomBarItem(
                icon: const Icon(Icons.info_outline),
                label: const ExcludeSemantics(child: Text('Visual only')),
                semanticLabel: 'Open info',
                tooltip: 'More info',
                onTap: () => taps++,
              ),
            ),
          );

          final data = tester
              .getSemantics(find.bySemanticsLabel('Open info'))
              .getSemanticsData();

          expect(data.label, 'Open info');
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
          expect(
            semanticsLabels(tester).where((label) => label == 'Open info'),
            hasLength(1),
          );
          expect(semanticsLabels(tester), isNot(contains('More info')));
          expect(semanticsLabels(tester), isNot(contains('Visual only')));
          expect(findByTooltip('More info'), findsOneWidget);

          tester.semantics.tap(find.semantics.byLabel('Open info'));
          await tester.pump();
          expect(taps, 1);
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('keeps the tap target at least 48 by 48', (tester) async {
      await tester.pumpWidget(
        _buildItemHarness(
          item: BottomBarItem(icon: const Icon(Icons.add), onTap: () {}),
        ),
      );

      final size = tester.getSize(find.byType(InkWell));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('sizes to its content inside a floating BottomBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              body: const SizedBox.expand(),
              child: BottomBarItems(
                children: [
                  BottomBarItem(
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                  ),
                  BottomBarItem(icon: const Icon(Icons.inbox)),
                ],
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(BottomBarItem).first);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.height, lessThan(100));
    });

    testWidgets('onTap fires on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _buildItemHarness(
          item: BottomBarItem(icon: const Icon(Icons.add), onTap: () => taps++),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    });

    testWidgets('places the badge on the visual right in LTR', (tester) async {
      await tester.pumpWidget(
        _buildItemHarness(
          item: BottomBarItem(
            icon: const Icon(Icons.inbox),
            badge: Container(
              key: const Key('badge'),
              width: 8,
              height: 8,
              color: const Color(0xFFFF0000),
            ),
          ),
        ),
      );

      final iconRect = tester.getRect(find.byIcon(Icons.inbox));
      final badgeRect = tester.getRect(find.byKey(const Key('badge')));

      expect(badgeRect.center.dx, greaterThan(iconRect.center.dx));
      expect(badgeRect.center.dy, lessThan(iconRect.center.dy));
    });

    testWidgets('places the badge on the visual left in RTL', (tester) async {
      await tester.pumpWidget(
        _buildItemHarness(
          textDirection: TextDirection.rtl,
          item: BottomBarItem(
            icon: const Icon(Icons.inbox),
            badge: Container(
              key: const Key('badge'),
              width: 8,
              height: 8,
              color: const Color(0xFFFF0000),
            ),
          ),
        ),
      );

      final iconRect = tester.getRect(find.byIcon(Icons.inbox));
      final badgeRect = tester.getRect(find.byKey(const Key('badge')));

      expect(badgeRect.center.dx, lessThan(iconRect.center.dx));
      expect(badgeRect.center.dy, lessThan(iconRect.center.dy));
    });
  });

  testWidgets('BottomBarItems renders children in a Row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBarItems(
            children: [
              BottomBarItem(icon: const Icon(Icons.home)),
              BottomBarItem(icon: const Icon(Icons.search)),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(Row), findsOneWidget);
    expect(find.byType(BottomBarItem), findsNWidgets(2));
  });

  group('BottomBarItems overflow safety', () {
    testWidgets('fixed-height rows preserve the full item hit area', (
      tester,
    ) async {
      for (final behavior in BottomBarLabelBehavior.values) {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 80,
                child: BottomBarItems(
                  labelBehavior: behavior,
                  children: [
                    BottomBarItem(
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      selected: true,
                      onTap: () => taps++,
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final itemRects = tester
            .widgetList<InkWell>(find.byType(InkWell))
            .map((inkWell) => tester.getRect(find.byWidget(inkWell)))
            .toList();
        expect(itemRects, hasLength(2));
        for (final rect in itemRects) {
          expect(rect.height, 80);
          expect(rect.width, 150);
          await tester.tapAt(Offset(rect.center.dx, rect.top + 1));
          await tester.tapAt(Offset(rect.center.dx, rect.bottom - 1));
          await tester.tapAt(Offset(rect.left + 1, rect.center.dy));
          await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
        }
        expect(taps, 8);
      }
    });

    testWidgets('fixed-height rows keep arbitrary children centered', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 80,
              child: BottomBarItems(
                children: [
                  SizedBox(
                    key: const Key('small-child'),
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final rect = tester.getRect(find.byKey(const Key('small-child')));
      expect(rect.size, const Size(300, 20));
      expect(rect.center.dx, 150);
      expect(rect.center.dy, 40);
    });

    testWidgets('fixed-height rows size wrapped BottomBarItems', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 80,
              child: BottomBarItems(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: BottomBarItem(
                      icon: const Icon(Icons.home),
                      onTap: () => taps++,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final slot = tester.getRect(find.byType(Padding).first);
      final item = tester.getRect(find.byType(InkWell));
      expect(slot.height, 80);
      expect(item.height, 72);
      await tester.tapAt(Offset(item.center.dx, item.top + 1));
      expect(taps, 1);
    });

    testWidgets('item height follows a tight-to-loose parent change', (
      tester,
    ) async {
      Widget build({required bool tight}) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: tight ? 80 : null,
            child: const BottomBarItems(
              children: [BottomBarItem(icon: Icon(Icons.home))],
            ),
          ),
        ),
      );

      await tester.pumpWidget(build(tight: true));
      expect(tester.getSize(find.byType(InkWell)).height, 80);

      await tester.pumpWidget(build(tight: false));
      final height = tester.getSize(find.byType(InkWell)).height;
      expect(height, greaterThanOrEqualTo(48));
      expect(height, lessThan(80));
    });

    testWidgets('fixed-height narrow rows scroll in RTL with full hit areas', (
      tester,
    ) async {
      var tappedIndex = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: 100,
                height: 80,
                child: BottomBarItems(
                  children: List.generate(
                    3,
                    (index) => BottomBarItem(
                      icon: const Icon(Icons.home),
                      onTap: () => tappedIndex = index,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      var rects = tester
          .widgetList<InkWell>(find.byType(InkWell))
          .map((inkWell) => tester.getRect(find.byWidget(inkWell)))
          .toList();
      expect(rects, hasLength(3));
      expect(rects[0].center.dx, greaterThan(rects[1].center.dx));
      for (final rect in rects) {
        expect(rect.height, 80);
        expect(rect.width, greaterThanOrEqualTo(48));
      }
      await tester.tapAt(Offset(rects[0].center.dx, rects[0].center.dy));
      expect(tappedIndex, 0);

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(80, 0),
      );
      await tester.pumpAndSettle();
      rects = tester
          .widgetList<InkWell>(find.byType(InkWell))
          .map((inkWell) => tester.getRect(find.byWidget(inkWell)))
          .toList();
      expect(rects[2].left, greaterThanOrEqualTo(0));
      expect(rects[2].right, lessThanOrEqualTo(100));
      await tester.tapAt(Offset(rects[2].center.dx, rects[2].top + 1));
      expect(tappedIndex, 2);
    });

    testWidgets('fixed-height unbounded rows stretch items across the slot', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 80,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: BottomBarItems(
                  children: [
                    BottomBarItem(
                      icon: const Icon(Icons.home),
                      onTap: () => taps++,
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.search),
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
      final itemRects = tester
          .widgetList<InkWell>(find.byType(InkWell))
          .map((inkWell) => tester.getRect(find.byWidget(inkWell)))
          .toList();
      expect(itemRects, hasLength(2));
      for (final rect in itemRects) {
        expect(rect.height, 80);
        await tester.tapAt(Offset(rect.center.dx, rect.top + 1));
        await tester.tapAt(Offset(rect.center.dx, rect.bottom - 1));
      }
      expect(taps, 4);
    });

    testWidgets('loose-height rows remain content-tall for every label mode', (
      tester,
    ) async {
      for (final behavior in BottomBarLabelBehavior.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: BottomBarItems(
                  labelBehavior: behavior,
                  children: [
                    BottomBarItem(
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      selected: true,
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        for (final item in tester.widgetList<BottomBarItem>(
          find.byType(BottomBarItem),
        )) {
          final size = tester.getSize(find.byWidget(item));
          expect(size.height, greaterThanOrEqualTo(48));
          expect(size.height, lessThan(100));
        }
      }
    });

    testWidgets(
      'wraps items in Expanded and ellipsizes labels instead of overflowing',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: BottomBarItems(
                    children: List.generate(
                      5,
                      (_) => BottomBarItem(
                        icon: const Icon(Icons.home),
                        label: const Text('Settings'),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Expanded), findsNWidgets(5));

        final settingsTexts = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(BottomBarItem),
            matching: find.text('Settings'),
          ),
        );
        for (final text in settingsTexts) {
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
        }
      },
    );

    testWidgets(
      'scrolls narrow bounded rows to preserve minimum item targets',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: BottomBarItems(
                    children: List.generate(
                      7,
                      (_) => BottomBarItem(
                        icon: const Icon(Icons.home),
                        label: const Text('Settings'),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(Expanded), findsNothing);
        for (final inkWell in tester.widgetList<InkWell>(
          find.byType(InkWell),
        )) {
          final size = tester.getSize(find.byWidget(inkWell));
          expect(size.width, greaterThanOrEqualTo(48));
          expect(size.height, greaterThanOrEqualTo(48));
        }
      },
    );

    testWidgets('preserves plain Text configuration while ellipsizing', (
      tester,
    ) async {
      const labelKey = Key('configured-label');
      const textScaler = TextScaler.linear(1.25);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: BottomBarItems(
                children: [
                  BottomBarItem(
                    icon: const Icon(Icons.home),
                    label: const Text(
                      'Settings',
                      key: labelKey,
                      style: TextStyle(color: Color(0xFFFF0000)),
                      textAlign: TextAlign.end,
                      textDirection: TextDirection.rtl,
                      softWrap: false,
                      textScaler: textScaler,
                      maxLines: 3,
                      overflow: TextOverflow.clip,
                      semanticsLabel: 'Preferences',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final rendered = tester.widget<Text>(find.byKey(labelKey));
      expect(rendered.semanticsLabel, 'Preferences');
      expect(rendered.style, const TextStyle(color: Color(0xFFFF0000)));
      expect(rendered.textAlign, TextAlign.end);
      expect(rendered.textDirection, TextDirection.rtl);
      expect(rendered.softWrap, isFalse);
      expect(rendered.textScaler, textScaler);
      expect(rendered.maxLines, 1);
      expect(rendered.overflow, TextOverflow.ellipsis);
    });

    testWidgets('keeps children raw in an unbounded row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: BottomBarItems(
                children: [
                  BottomBarItem(icon: const Icon(Icons.home)),
                  BottomBarItem(icon: const Icon(Icons.search)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
    });

    testWidgets('keeps each item at least 48 by 48 inside a crowded row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: BottomBarItems(
                  children: List.generate(
                    5,
                    (_) => BottomBarItem(
                      icon: const Icon(Icons.home),
                      label: const Text('Settings'),
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      for (final inkWell in tester.widgetList<InkWell>(find.byType(InkWell))) {
        final size = tester.getSize(find.byWidget(inkWell));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('onlySelected shows only the selected item\'s label', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarItems(
              labelBehavior: BottomBarLabelBehavior.onlySelected,
              children: [
                BottomBarItem(
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
                BottomBarItem(
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  selected: true,
                ),
                BottomBarItem(
                  icon: const Icon(Icons.person),
                  label: const Text('Profile'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsNothing);
      expect(find.text('Profile'), findsNothing);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('alwaysHide renders no labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarItems(
              labelBehavior: BottomBarLabelBehavior.alwaysHide,
              children: [
                BottomBarItem(
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                  selected: true,
                ),
                BottomBarItem(
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsNothing);
      expect(find.text('Search'), findsNothing);
    });

    testWidgets(
      'hidden plain Text labels stay accessible for onlySelected and alwaysHide',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          for (final behavior in [
            BottomBarLabelBehavior.onlySelected,
            BottomBarLabelBehavior.alwaysHide,
          ]) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: BottomBarItems(
                    labelBehavior: behavior,
                    children: [
                      BottomBarItem(
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            );

            final data = tester
                .getSemantics(find.bySemanticsLabel('Home'))
                .getSemanticsData();
            expect(data.label, 'Home');
            expect(data.flagsCollection.isButton, isTrue);
            expect(data.hasAction(SemanticsAction.tap), isTrue);
            expect(
              semanticsLabels(tester).where((label) => label == 'Home'),
              hasLength(1),
            );
            expect(find.text('Home'), findsNothing);
          }
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'a lone BottomBarItem outside BottomBarItems still shows its label',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BottomBarItem(
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
      },
    );
  });
}

Widget _buildItemHarness({
  required BottomBarItem item,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Directionality(
        textDirection: textDirection,
        child: Center(child: item),
      ),
    ),
  );
}
