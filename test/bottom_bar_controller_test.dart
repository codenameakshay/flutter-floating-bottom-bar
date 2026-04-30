import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('controller cannot be attached to two BottomBars at once',
      (tester) async {
    final controller = BottomBarController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: BottomBar(
                controller: controller,
                body: const SizedBox.shrink(),
                child: const SizedBox(height: 56),
              ),
            ),
            Expanded(
              child: BottomBar(
                controller: controller,
                body: const SizedBox.shrink(),
                child: const SizedBox(height: 56),
              ),
            ),
          ],
        ),
      ),
    ));

    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('isAttached/isVisible reflect lifecycle', (tester) async {
    final controller = BottomBarController();
    expect(controller.isAttached, isFalse);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: const SizedBox.shrink(),
          child: const SizedBox(height: 56),
        ),
      ),
    ));
    expect(controller.isAttached, isTrue);
    expect(controller.isVisible, isTrue);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(controller.isAttached, isFalse);
  });
}
