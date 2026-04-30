import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BottomBarScope.barHeight reports rendered height',
      (tester) async {
    double? observed;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          body: Builder(
            builder: (ctx) {
              final h = BottomBarScope.of(ctx).barHeight;
              return ValueListenableBuilder<double>(
                valueListenable: h,
                builder: (_, value, __) {
                  observed = value;
                  return ListView(children: const [SizedBox(height: 1000)]);
                },
              );
            },
          ),
          child: const SizedBox(height: 56, width: 200),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(observed, isNotNull);
    expect(observed!, greaterThan(0));
  });

  testWidgets('BottomBarScope.isVisible reflects controller', (tester) async {
    final controller = BottomBarController();
    bool? observed;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: Builder(
            builder: (ctx) {
              final v = BottomBarScope.of(ctx).isVisible;
              return ValueListenableBuilder<bool>(
                valueListenable: v,
                builder: (_, value, __) {
                  observed = value;
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          child: const SizedBox(height: 56, width: 200),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(observed, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(observed, isFalse);
  });
}
