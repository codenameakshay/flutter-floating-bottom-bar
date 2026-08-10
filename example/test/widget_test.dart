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

  testWidgets('issues demo keeps its content readable on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Issues dock'));
    await tester.pumpAndSettle();

    final content = find.byKey(const Key('issues-content'));
    expect(content, findsOneWidget);
    expect(tester.getSize(content).width, lessThanOrEqualTo(760));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI prompt demo explains its empty state on phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('AI prompt dock'));
    await tester.pumpAndSettle();

    expect(find.text('Start with a prompt'), findsOneWidget);
    expect(
      find.text('Ask a question or imagine something new.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
