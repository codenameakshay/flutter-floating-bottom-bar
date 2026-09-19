import 'package:flutter_floating_bottom_bar_example/demos/issues_dock_demo.dart';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('selecting issues switches the dock to contextual actions', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byKey(const Key('issue-checkbox-HBT-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byKey(const Key('archive-selected')), findsOneWidget);
    expect(find.byKey(const Key('clear-selection')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('archive-selected')))
          .tooltip,
      'Archive',
    );

    await tester.tap(find.byKey(const Key('issue-checkbox-HBT-4')));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('archive removes selected issues and reports the result', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byKey(const Key('issue-checkbox-HBT-1')));
    await tester.tap(find.byKey(const Key('issue-checkbox-HBT-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('archive-selected')));
    await tester.pumpAndSettle();

    expect(find.text('HBT-1: Create habit creation flow'), findsNothing);
    expect(find.text('HBT-2: Implement habit completion toast'), findsNothing);
    expect(find.text('Archived 2 issues'), findsOneWidget);
    expect(find.bySemanticsLabel('All issues'), findsOneWidget);
  });

  testWidgets('clear selection restores normal navigation', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.byKey(const Key('issue-checkbox-HBT-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-selection')));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsNothing);
    expect(find.bySemanticsLabel('All issues'), findsOneWidget);
    expect(find.byKey(const Key('clear-selection')), findsNothing);
  });

  testWidgets(
    'selection survives scrolling and navigation semantics stay current',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_harness());

      final allIssues = find.byKey(const Key('dock-filter-all'));
      expect(
        tester.getSemantics(allIssues).flagsCollection.isSelected,
        ui.Tristate.isTrue,
      );

      await tester.tap(find.byKey(const Key('dock-filter-open')));
      await tester.pumpAndSettle();
      expect(find.text('HBT-1: Create habit creation flow'), findsOneWidget);
      expect(
        find.text('HBT-2: Implement habit completion toast'),
        findsNothing,
      );
      expect(
        tester
            .getSemantics(find.byKey(const Key('dock-filter-open')))
            .flagsCollection
            .isSelected,
        ui.Tristate.isTrue,
      );

      await tester.tap(find.byKey(const Key('dock-filter-all')));
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const Key('issues-scroll')),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      final initial = position.pixels;
      await tester.scrollUntilVisible(
        find.byKey(const Key('issue-checkbox-HBT-1')),
        180,
        scrollable: find.descendant(
          of: find.byKey(const Key('issues-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(initial));
      await tester.ensureVisible(find.byKey(const Key('issue-checkbox-HBT-1')));
      await tester.tap(find.byKey(const Key('issue-checkbox-HBT-1')));
      await tester.pumpAndSettle();
      final selectedOffset = position.pixels;
      await tester.dragFrom(const Offset(200, 180), const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(position.pixels, lessThan(selectedOffset));
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.byKey(const Key('archive-selected')), findsOneWidget);
      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('issue-checkbox-HBT-1')))
            .value,
        isTrue,
      );
    },
  );

  testWidgets('contextual dock fits a compact phone at 2x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const IssuesDockDemoPage(),
        ),
      ),
    );
    expect(
      tester.getRect(find.byKey(const Key('normal-dock'))).height,
      lessThanOrEqualTo(84),
    );
    final checkboxRect = tester.getRect(
      find.byKey(const Key('issue-checkbox-HBT-1')),
    );
    expect(
      checkboxRect.bottom,
      lessThan(tester.getRect(find.byKey(const Key('normal-dock'))).top),
    );
    await tester.tap(find.byKey(const Key('issue-checkbox-HBT-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('1 selected'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('issue-checkbox-HBT-1'))).bottom,
      lessThan(tester.getRect(find.byKey(const Key('archive-selected'))).top),
    );
    expect(tester.widget<Text>(find.text('1 selected')).overflow, isNull);
    expect(
      tester.getSize(find.byKey(const Key('archive-selected'))).width,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('clear-selection'))).width,
      greaterThanOrEqualTo(48),
    );
  });
}

Widget _harness() {
  return const MaterialApp(home: IssuesDockDemoPage());
}
