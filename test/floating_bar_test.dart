import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    BottomBarController? controller,
    ValueChanged<bool>? onVisibilityChanged,
    double scrollDeltaThreshold = 8,
    String? iconTooltip,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          scrollDeltaThreshold: scrollDeltaThreshold,
          iconTooltip: iconTooltip,
          onVisibilityChanged: onVisibilityChanged,
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
          body: (context, scrollController) => ListView.builder(
            controller: scrollController,
            itemCount: 200,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          ),
        ),
      ),
    );
  }

  testWidgets('renders with default constructor usage', (tester) async {
    await tester.pumpWidget(buildHarness());
    expect(find.text('Bottom Bar Child'), findsOneWidget);
  });

  testWidgets('controller can hide and show the bar', (tester) async {
    final controller = BottomBarController();

    await tester.pumpWidget(buildHarness(controller: controller));
    expect(controller.isAttached, isTrue);
    expect(controller.isVisible, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    controller.show();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);
  });

  testWidgets('scroll emits visibility changes', (tester) async {
    final visibilityEvents = <bool>[];

    await tester.pumpWidget(
      buildHarness(onVisibilityChanged: visibilityEvents.add),
    );

    final scrollable = find.byType(Scrollable).first;

    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();

    await tester.drag(scrollable, const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(visibilityEvents, contains(false));
    expect(visibilityEvents, contains(true));
  });

  testWidgets('scroll delta threshold suppresses tiny movements', (
    tester,
  ) async {
    final controller = BottomBarController();

    await tester.pumpWidget(
      buildHarness(controller: controller, scrollDeltaThreshold: 200),
    );

    final scrollable = find.byType(Scrollable).first;

    await tester.drag(scrollable, const Offset(0, -50));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);

    await tester.drag(scrollable, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);
  });

  testWidgets('custom tooltip is attached to the icon action', (tester) async {
    final controller = BottomBarController();

    await tester.pumpWidget(
      buildHarness(controller: controller, iconTooltip: 'Go to top'),
    );

    controller.hide();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Go to top'), findsOneWidget);
  });
}
