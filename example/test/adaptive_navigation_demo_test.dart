import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter_floating_bottom_bar_example/demos/adaptive_navigation_demo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _destinations = <(String, String)>[
  ('Home overview', 'A quick view of today and the activity that needs you.'),
  ('Saved recipes', 'Recipes you saved to come back to later.'),
  ('Weekly progress', 'Your progress across the current week.'),
  (
    'Notifications center',
    'Updates and reminders that are ready for your attention.',
  ),
  ('Account settings', 'Preferences, profile details, and account controls.'),
];

void main() {
  testWidgets('wraps five destinations at 320px with 2x text in LTR and RTL', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildHarness(textScale: 2));
      await tester.pumpAndSettle();

      for (var direction = 0; direction < 2; direction++) {
        for (final (label, description) in _destinations) {
          final destination = find.bySemanticsLabel(label);
          expect(destination, findsOneWidget);
          final targetSize = tester.getSize(destination);
          expect(targetSize.width, greaterThanOrEqualTo(48));
          expect(targetSize.height, greaterThanOrEqualTo(48));

          await tester.tap(destination);
          await tester.pumpAndSettle();

          _expectSelected(tester, label, true);
          expect(find.text(description), findsOneWidget);
          expect(tester.takeException(), isNull);
        }

        if (direction == 0) {
          await tester.tap(find.byTooltip('Toggle right-to-left layout'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('large text preview increases text without lowering user scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_buildHarness(textScale: 1));
    await tester.pumpAndSettle();
    final normalHeight = tester
        .getSize(find.text('Adaptive navigation'))
        .height;

    await tester.tap(find.byTooltip('Toggle large text preview'));
    await tester.pumpAndSettle();

    final largeHeight = tester.getSize(find.text('Adaptive navigation')).height;
    expect(largeHeight, greaterThan(normalHeight));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_buildHarness(textScale: 3));
    await tester.pumpAndSettle();
    final inheritedHeight = tester
        .getSize(find.text('Adaptive navigation'))
        .height;

    await tester.tap(find.byTooltip('Toggle large text preview'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.text('Adaptive navigation')).height,
      inheritedHeight,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _buildHarness({required double textScale}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const AdaptiveNavigationDemoPage(),
  );
}

void _expectSelected(WidgetTester tester, String label, bool selected) {
  final data = tester
      .getSemantics(find.bySemanticsLabel(label))
      .getSemanticsData();
  expect(
    data.flagsCollection.isSelected,
    selected ? ui.Tristate.isTrue : ui.Tristate.isFalse,
  );
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(SemanticsAction.tap), isTrue);
}
