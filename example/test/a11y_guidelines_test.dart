import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

void main() {
  for (final demo in demos) {
    testWidgets('${demo.slug} meets the accessibility guidelines', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const ExampleApp());
        await tester.pumpAndSettle();

        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .pushNamed('/${demo.slug}');
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      } finally {
        handle.dispose();
      }
    });
  }
}
