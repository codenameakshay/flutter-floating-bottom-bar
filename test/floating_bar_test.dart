import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor/motor.dart' as motor;

void main() {
  Widget buildHarness({
    BottomBarController? controller,
    ValueChanged<bool>? onVisibilityChanged,
    BottomBarScrollBehavior scrollBehavior = const BottomBarScrollBehavior(),
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

  testWidgets('show redirects naturally while hide animation is in flight',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(buildHarness(controller: controller));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final hiddenProgress = _barProgress(tester);
    expect(hiddenProgress, greaterThan(0));
    expect(hiddenProgress, lessThan(1));

    controller.show();
    await tester.pump();
    final redirectedProgress = _barProgress(tester);
    expect(redirectedProgress, closeTo(hiddenProgress, 0.08));

    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);
    expect(_barProgress(tester).clamp(0.0, 1.0), closeTo(1, 0.001));
  });

  testWidgets('hide redirects naturally while show animation is in flight',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(buildHarness(controller: controller));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    controller.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final shownProgress = _barProgress(tester);
    expect(shownProgress, greaterThan(0));
    expect(shownProgress, lessThan(1));

    controller.hide();
    await tester.pump();
    final redirectedProgress = _barProgress(tester);
    expect(redirectedProgress, closeTo(shownProgress, 0.08));

    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);
    expect(_barProgress(tester).clamp(0.0, 1.0), closeTo(0, 0.001));
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

  testWidgets('theme extension controls motion and scroll behavior',
      (tester) async {
    final controller = BottomBarController();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        extensions: const [
          BottomBarThemeData(
            motion: BottomBarMotion(
              duration: Duration(seconds: 1),
              transition: BottomBarTransition.fade,
            ),
            scrollBehavior: BottomBarScrollBehavior(hideOnScroll: false),
          ),
        ],
      ),
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
          ),
          child: const SizedBox(
            key: Key('themed-bar-child'),
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
        ),
      ),
    ));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);

    controller.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final fades = find.ancestor(
      of: find.byKey(const Key('themed-bar-child')),
      matching: find.byType(FadeTransition),
    );
    final fade = fades
        .evaluate()
        .map((e) => e.widget)
        .cast<FadeTransition>()
        .firstWhere((widget) => widget.child is Container);
    expect(fade.opacity.value, greaterThan(0.1));
  });

  testWidgets('theme-provided Motor motion updates the controller',
      (tester) async {
    final controller = BottomBarController();

    Widget appWithMotion(BottomBarMotion motion) {
      return MaterialApp(
        theme: ThemeData(
          extensions: [
            BottomBarThemeData(motion: motion),
          ],
        ),
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            body: const SizedBox.shrink(),
            child: const SizedBox(
              height: 56,
              child: Center(child: Text('Bottom Bar Child')),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(appWithMotion(
      const BottomBarMotion.motor(
        motor.Motion.linear(Duration(seconds: 1)),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.pumpWidget(appWithMotion(
      const BottomBarMotion.motor(
        motor.Motion.linear(Duration(milliseconds: 100)),
      ),
    ));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(_barProgress(tester).clamp(0.0, 1.0), lessThan(0.3));
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

  testWidgets('sibling scrollables keep independent scroll offsets',
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
                key: const Key('list-a'),
                itemCount: 200,
                itemBuilder: (_, i) => ListTile(title: Text('A $i')),
              ),
              ListView.builder(
                key: const Key('list-b'),
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

    await tester.drag(find.byKey(const Key('list-a')), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    tabController.animateTo(1);
    await tester.pumpAndSettle();

    await tester.drag(find.byKey(const Key('list-b')), const Offset(0, -5));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);
  });
}

double _barProgress(WidgetTester tester) {
  final slide = tester
      .widgetList<SlideTransition>(find.byType(SlideTransition))
      .where((widget) => widget.child is Container)
      .first;
  return 1 - (slide.position.value.dy / 2);
}
