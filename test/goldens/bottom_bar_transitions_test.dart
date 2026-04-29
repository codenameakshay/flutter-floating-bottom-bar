import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final t in BottomBarTransition.values) {
    testWidgets('transition: ${t.name} at 50% progress', (tester) async {
      final controller = BottomBarController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            motion: BottomBarMotion(
              transition: t,
              duration: const Duration(milliseconds: 400),
            ),
            body: const SizedBox.shrink(),
            child: const SizedBox(
              height: 56,
              child: Center(child: Text('Bar')),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      controller.hide();
      await tester.pump(const Duration(milliseconds: 200));

      await expectLater(
        find.byType(BottomBar),
        matchesGoldenFile('bottom_bar_transition_${t.name}.png'),
      );
    });
  }
}
