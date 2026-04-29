import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness({
    BottomBarController? controller,
    ValueChanged<bool>? onVisibilityChanged,
    BottomBarScrollBehavior scrollBehavior =
        const BottomBarScrollBehavior(),
    String? iconTooltip,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          scrollBehavior: scrollBehavior,
          iconTooltip: iconTooltip,
          onVisibilityChanged: onVisibilityChanged,
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
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

  testWidgets('scroll delta threshold suppresses tiny movements',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        scrollBehavior: const BottomBarScrollBehavior(deltaThreshold: 200),
      ),
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

  testWidgets('hide-on-scroll works with NestedScrollView', (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => const [
              SliverAppBar(title: Text('Nested')),
            ],
            body: ListView.builder(
              itemCount: 200,
              itemBuilder: (_, i) => ListTile(title: Text('I $i')),
            ),
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('child')),
          ),
        ),
      ),
    ));

    expect(controller.isVisible, isTrue);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);
  });

  testWidgets('switching between sibling scrollables does not false-hide',
      (tester) async {
    final controller = BottomBarController();
    final tabController = TabController(length: 2, vsync: const TestVSync());
    addTearDown(tabController.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: TabBarView(
            controller: tabController,
            children: [
              ListView.builder(
                itemCount: 200,
                itemBuilder: (_, i) => ListTile(title: Text('A $i')),
              ),
              ListView.builder(
                itemCount: 200,
                itemBuilder: (_, i) => ListTile(title: Text('B $i')),
              ),
            ],
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('child')),
          ),
        ),
      ),
    ));

    // Scroll list A by a tiny amount (below threshold).
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5));
    await tester.pumpAndSettle();

    // Switch to tab B.
    tabController.animateTo(1);
    await tester.pumpAndSettle();

    // The bar should still be visible (no false hide on tab switch).
    expect(controller.isVisible, isTrue);
  });
}
