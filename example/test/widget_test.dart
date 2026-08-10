import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

void main() {
  const demoNames = <String>[
    'Issues dock',
    'AI prompt dock',
    'Basic TabBar',
    'Minimal API',
    'Nested scroll',
    'Badged nav',
    'Custom transition',
  ];

  testWidgets('demo picker lists and opens every registered demo', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Demos'), findsOneWidget);

    for (final demoName in demoNames) {
      expect(find.text(demoName), findsOneWidget);
    }

    for (final demoName in demoNames) {
      await tester.tap(find.text(demoName));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'opening $demoName');

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'returning from $demoName');
      expect(find.text('Demos'), findsOneWidget);
    }
  });
}
