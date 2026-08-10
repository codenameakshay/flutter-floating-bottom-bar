import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarItem', () {
    testWidgets('renders icon, swaps to selectedIcon when selected',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BottomBarItem(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: const Text('Home'),
            selected: true,
          ),
        ),
      ));
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('renders badge when supplied', (tester) async {
      await tester.pumpWidget(MaterialApp(
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
      ));
      expect(find.byKey(const Key('badge')), findsOneWidget);
    });

    testWidgets(
        'uses the explicit tooltip name once when label and tooltip are both present',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildItemHarness(
          item: BottomBarItem(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: const Text('Home'),
            selected: true,
            tooltip: 'Go home',
            onTap: () {},
          ),
        ));

        final data = tester
            .getSemantics(find.bySemanticsLabel('Go home'))
            .getSemanticsData();

        expect(data.label, 'Go home');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(
          _semanticsLabels(tester).where((label) => label == 'Go home'),
          hasLength(1),
        );
        expect(_semanticsLabels(tester), isNot(contains('Home')));
        expect(find.byTooltip('Go home'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('exposes unselected enabled button semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildItemHarness(
          item: BottomBarItem(
            icon: const Icon(Icons.search),
            label: const Text('Search'),
            onTap: () {},
          ),
        ));

        final data =
            tester.getSemantics(find.text('Search')).getSemanticsData();

        expect(data.label, 'Search');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isSelected, ui.Tristate.isFalse);
        expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('exposes disabled button semantics when onTap is null',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_buildItemHarness(
          item: BottomBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Settings'),
          ),
        ));

        final data =
            tester.getSemantics(find.text('Settings')).getSemanticsData();

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
        await tester.pumpWidget(_buildItemHarness(
          item: BottomBarItem(
            icon: const Icon(Icons.info_outline),
            label: const ExcludeSemantics(
              child: Text('Visual only'),
            ),
            semanticLabel: 'Open info',
            tooltip: 'More info',
            onTap: () => taps++,
          ),
        ));

        final data = tester
            .getSemantics(find.bySemanticsLabel('Open info'))
            .getSemanticsData();

        expect(data.label, 'Open info');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(
          _semanticsLabels(tester).where((label) => label == 'Open info'),
          hasLength(1),
        );
        expect(_semanticsLabels(tester), isNot(contains('More info')));
        expect(_semanticsLabels(tester), isNot(contains('Visual only')));
        expect(find.byTooltip('More info'), findsOneWidget);

        tester.semantics.tap(find.semantics.byLabel('Open info'));
        await tester.pump();
        expect(taps, 1);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('keeps the tap target at least 48 by 48', (tester) async {
      await tester.pumpWidget(_buildItemHarness(
        item: BottomBarItem(
          icon: const Icon(Icons.add),
          onTap: () {},
        ),
      ));

      final size = tester.getSize(find.byType(InkWell));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('onTap fires on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_buildItemHarness(
        item: BottomBarItem(
          icon: const Icon(Icons.add),
          onTap: () => taps++,
        ),
      ));
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    });

    testWidgets('places the badge on the visual right in LTR', (tester) async {
      await tester.pumpWidget(_buildItemHarness(
        item: BottomBarItem(
          icon: const Icon(Icons.inbox),
          badge: Container(
            key: const Key('badge'),
            width: 8,
            height: 8,
            color: const Color(0xFFFF0000),
          ),
        ),
      ));

      final iconRect = tester.getRect(find.byIcon(Icons.inbox));
      final badgeRect = tester.getRect(find.byKey(const Key('badge')));

      expect(badgeRect.center.dx, greaterThan(iconRect.center.dx));
      expect(badgeRect.center.dy, lessThan(iconRect.center.dy));
    });

    testWidgets('places the badge on the visual left in RTL', (tester) async {
      await tester.pumpWidget(_buildItemHarness(
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
      ));

      final iconRect = tester.getRect(find.byIcon(Icons.inbox));
      final badgeRect = tester.getRect(find.byKey(const Key('badge')));

      expect(badgeRect.center.dx, lessThan(iconRect.center.dx));
      expect(badgeRect.center.dy, lessThan(iconRect.center.dy));
    });
  });

  testWidgets('BottomBarItems renders children in a Row', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBarItems(
          children: [
            BottomBarItem(icon: const Icon(Icons.home)),
            BottomBarItem(icon: const Icon(Icons.search)),
          ],
        ),
      ),
    ));
    expect(find.byType(Row), findsOneWidget);
    expect(find.byType(BottomBarItem), findsNWidgets(2));
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

Iterable<String> _semanticsLabels(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty);
}
