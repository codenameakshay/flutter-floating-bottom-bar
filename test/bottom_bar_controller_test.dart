import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/bottom_bar_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('controller asserts on a second binding and keeps the first owner',
      () async {
    final controller = BottomBarController();
    final first = _FakeBinding(isVisible: true);
    final second = _FakeBinding(isVisible: false);

    controller.attach(first);
    expect(controller.isAttached, isTrue);
    expect(controller.isVisible, isTrue);

    expect(
      () => controller.attach(second),
      throwsA(isA<AssertionError>()),
    );

    controller.hide();
    expect(first.requestedVisibility, isFalse);
    expect(second.requestedVisibility, isNull);

    controller.updateVisibility(first, false);
    expect(controller.isVisible, isFalse);

    controller.updateVisibility(second, true);
    expect(controller.isVisible, isFalse);

    controller.toggle();
    expect(first.requestedVisibility, isTrue);
    expect(second.requestedVisibility, isNull);

    await controller.scrollToStart();
    expect(first.lastScrollToEnd, isFalse);
    expect(second.lastScrollToEnd, isNull);

    await controller.scrollToEnd();
    expect(first.lastScrollToEnd, isTrue);
    expect(second.lastScrollToEnd, isNull);
  });

  testWidgets('controller asserts on double attachment in debug mode',
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

    expect(
      tester.takeException(),
      isA<AssertionError>(),
    );
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

class _FakeBinding implements BottomBarBindingForController {
  _FakeBinding({required this.isVisible});

  @override
  bool isVisible;

  bool? requestedVisibility;
  bool? lastScrollToEnd;

  @override
  void requestVisible(bool visible) {
    requestedVisibility = visible;
  }

  @override
  Future<void> scrollToBoundary({required bool toEnd}) async {
    lastScrollToEnd = toEnd;
  }
}
