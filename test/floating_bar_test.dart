import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motor/motor.dart' as motor;

void main() {
  Widget buildHarness({
    BottomBarController? controller,
    ValueChanged<bool>? onVisibilityChanged,
    BottomBarScrollBehavior scrollBehavior = const BottomBarScrollBehavior(),
    BottomBarMotion motion = const BottomBarMotion(),
    BottomBarThemeData? theme,
    String? iconTooltip,
    String? iconSemanticLabel,
    BackToTopIconBuilder? icon,
    Widget child = const SizedBox(
      height: 56,
      child: Center(child: Text('Bottom Bar Child')),
    ),
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          scrollBehavior: scrollBehavior,
          motion: motion,
          theme: theme,
          iconTooltip: iconTooltip,
          iconSemanticLabel: iconSemanticLabel,
          icon: icon,
          onVisibilityChanged: onVisibilityChanged,
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          ),
          child: child,
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

  testWidgets('showAtStart forces the bar visible at the top boundary',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        scrollBehavior: const BottomBarScrollBehavior(
          reverse: true,
          showAtStart: true,
        ),
      ),
    );

    final scrollable = find.byType(Scrollable).first;

    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    await tester.drag(scrollable, const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue);
  });

  testWidgets('showOnScrollEnd forces the bar visible when scrolling settles',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        scrollBehavior: const BottomBarScrollBehavior(
          reverse: true,
          showOnScrollEnd: true,
        ),
      ),
    );

    final scrollable = find.byType(Scrollable).first;

    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    await tester.drag(scrollable, const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue);
  });

  testWidgets(
      'predicate false suppresses showAtStart and showOnScrollEnd settling',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        scrollBehavior: BottomBarScrollBehavior(
          reverse: true,
          showAtStart: true,
          showOnScrollEnd: true,
          predicate: (_) => false,
        ),
      ),
    );

    final scrollable = find.byType(Scrollable).first;

    controller.hide();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);

    await tester.drag(scrollable, const Offset(0, 300));
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

  testWidgets(
      'fade transition hides the floating bar from hit testing immediately',
      (tester) async {
    final controller = BottomBarController();
    var bodyTaps = 0;
    var barTaps = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          motion: const BottomBarMotion(
            duration: Duration(milliseconds: 240),
            transition: BottomBarTransition.fade,
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => bodyTaps++,
            child: ListView(
              children: const [
                SizedBox(height: 600),
              ],
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => barTaps++,
            child: const SizedBox(height: 56, width: 200),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final barCenter = tester.getCenter(find.byType(GestureDetector).last);
    final overlapPoint = barCenter + const Offset(80, 0);

    await tester.tapAt(barCenter);
    await tester.pump();
    expect(barTaps, 1);
    expect(bodyTaps, 0);

    controller.hide();
    await tester.pump();

    await tester.tapAt(overlapPoint);
    await tester.pump();

    expect(barTaps, 1);
    expect(bodyTaps, 1);
  });

  testWidgets(
      'custom transition hides the floating bar from semantics immediately',
      (tester) async {
    final controller = BottomBarController();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          motion: BottomBarMotion(
            transitionBuilder: (context, animation, child) {
              return Opacity(opacity: animation.value, child: child);
            },
          ),
          child: Semantics(
            container: true,
            label: 'Floating bar content',
            child: SizedBox(height: 56, width: 200),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_semanticsLabels(tester), contains('Floating bar content'));

      controller.hide();
      await tester.pump();

      expect(_semanticsLabels(tester), isNot(contains('Floating bar content')));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
      'back action is excluded while the bar is visible and appears when hidden',
      (tester) async {
    final controller = BottomBarController();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          iconSemanticLabel: 'Scroll to top',
        ),
      );
      await tester.pumpAndSettle();

      expect(_semanticsLabels(tester), isNot(contains('Scroll to top')));

      controller.hide();
      await tester.pumpAndSettle();

      expect(find.byTooltip('Scroll to top'), findsOneWidget);
      expect(_semanticsLabels(tester), contains('Scroll to top'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('back action keeps a fixed minimum 48 pixel target while hidden',
      (tester) async {
    final controller = BottomBarController();

    await tester.pumpWidget(buildHarness(controller: controller));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();

    final tooltip = find.byTooltip('Scroll to top');
    expect(tooltip, findsOneWidget);

    final targetRect = tester.getRect(tooltip);
    expect(targetRect.width, greaterThanOrEqualTo(48));
    expect(targetRect.height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'scrollOpposite flips the default action direction, tooltip, and semantics',
      (tester) async {
    final controller = BottomBarController();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          scrollBehavior: const BottomBarScrollBehavior(scrollOpposite: true),
        ),
      );
      await tester.pumpAndSettle();

      controller.hide();
      await tester.pumpAndSettle();

      expect(find.byTooltip('Scroll to bottom'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(_semanticsLabels(tester), contains('Scroll to bottom'));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('user tooltip and semantics labels override directional defaults',
      (tester) async {
    final controller = BottomBarController();
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        buildHarness(
          controller: controller,
          scrollBehavior: const BottomBarScrollBehavior(scrollOpposite: true),
          iconTooltip: 'Jump to end',
          iconSemanticLabel: 'Jump to the bottom',
        ),
      );
      await tester.pumpAndSettle();

      controller.hide();
      await tester.pumpAndSettle();

      expect(find.byTooltip('Jump to end'), findsOneWidget);
      expect(_semanticsLabels(tester), contains('Jump to the bottom'));
      expect(find.byTooltip('Scroll to bottom'), findsNothing);
      expect(_semanticsLabels(tester), isNot(contains('Scroll to bottom')));
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('default glyph color follows colorScheme.onPrimary',
      (tester) async {
    final controller = BottomBarController();
    const onPrimary = Color(0xFF123456);

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFABCDEF),
          onPrimary: onPrimary,
        ),
      ),
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: ListView(
            children: const [
              SizedBox(height: 1200),
            ],
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward_rounded));
    expect(icon.color, onPrimary);
  });

  testWidgets('custom icon builder receives the animated visual dimensions',
      (tester) async {
    final controller = BottomBarController();
    final dimensions = <Size>[];

    await tester.pumpWidget(
      buildHarness(
        controller: controller,
        theme: const BottomBarThemeData(iconWidth: 40, iconHeight: 36),
        icon: (width, height) {
          dimensions.add(Size(width, height));
          return SizedBox(
            key: const Key('custom-icon'),
            width: width,
            height: height,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();

    final iconRect = tester.getRect(find.byKey(const Key('custom-icon')));
    final animated = dimensions.last;
    expect(animated.width, moreOrLessEquals(40, epsilon: 0.01));
    expect(animated.height, moreOrLessEquals(36, epsilon: 0.01));
    expect(iconRect.width, moreOrLessEquals(40, epsilon: 0.01));
    expect(iconRect.height, moreOrLessEquals(36, epsilon: 0.01));
  });

  testWidgets('visibility callbacks fire exactly once per target state change',
      (tester) async {
    final controller = BottomBarController();
    final visibilityEvents = <bool>[];
    var shownCount = 0;
    var hiddenCount = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          onVisibilityChanged: visibilityEvents.add,
          onBottomBarShown: () => shownCount++,
          onBottomBarHidden: () => hiddenCount++,
          body: ListView(
            children: const [
              SizedBox(height: 1200),
            ],
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    controller.hide();
    controller.hide();
    await tester.pumpAndSettle();

    controller.show();
    controller.show();
    await tester.pumpAndSettle();

    expect(visibilityEvents, <bool>[false, true]);
    expect(hiddenCount, 1);
    expect(shownCount, 1);
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

  testWidgets(
      'scrollables inside the floating child do not drive visibility '
      'or scroll target', (tester) async {
    final controller = BottomBarController();
    final bodyScrollController = ScrollController();
    final childScrollController = ScrollController();
    addTearDown(bodyScrollController.dispose);
    addTearDown(childScrollController.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: ListView.builder(
            key: const Key('body-list'),
            controller: bodyScrollController,
            itemCount: 200,
            itemBuilder: (_, i) => ListTile(title: Text('Body $i')),
          ),
          child: SizedBox(
            height: 120,
            child: Material(
              child: ListView.builder(
                key: const Key('child-list'),
                controller: childScrollController,
                itemCount: 50,
                itemBuilder: (_, i) => SizedBox(
                  height: 40,
                  child: Center(child: Text('Child $i')),
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.drag(
        find.byKey(const Key('body-list')), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isFalse);
    expect(bodyScrollController.offset, greaterThan(0));

    controller.show();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);

    await tester.drag(
        find.byKey(const Key('child-list')), const Offset(0, -80));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue);
    expect(childScrollController.offset, greaterThan(0));

    unawaited(controller.scrollToStart());
    await tester.pumpAndSettle();

    expect(bodyScrollController.offset, morePreciselyEquals(0));
    expect(childScrollController.offset, greaterThan(0));
  });

  testWidgets(
      'scrollToStart fully resets both header and body of a NestedScrollView',
      (tester) async {
    final controller = BottomBarController();
    final nestedKey = GlobalKey<NestedScrollViewState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: NestedScrollView(
            key: nestedKey,
            headerSliverBuilder: (_, __) => const [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(title: Text('Nested')),
              ),
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

    // Scroll far enough to collapse the header (outer) and move the list
    // (inner) past its top.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
    await tester.pumpAndSettle();

    final outer = nestedKey.currentState!.outerController.position;
    final inner = nestedKey.currentState!.innerController.position;
    // Sanity: both positions are scrolled away from the top.
    expect(outer.pixels, greaterThan(0));
    expect(inner.pixels, greaterThan(0));

    // Not awaited: the animation only advances as the test pumps.
    unawaited(controller.scrollToStart());
    await tester.pumpAndSettle();

    // Both the collapsed header and the list must return to the very top so
    // the FlexibleSpaceBar is fully expanded again.
    expect(outer.pixels, morePreciselyEquals(outer.minScrollExtent));
    expect(inner.pixels, morePreciselyEquals(inner.minScrollExtent));
  });

  testWidgets('scrollToEnd collapses the header and scrolls the body to bottom',
      (tester) async {
    final controller = BottomBarController();
    final nestedKey = GlobalKey<NestedScrollViewState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: NestedScrollView(
            key: nestedKey,
            headerSliverBuilder: (_, __) => const [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(title: Text('Nested')),
              ),
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

    // A small scroll registers the active scrollable's context without
    // reaching either boundary.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -50));
    await tester.pumpAndSettle();

    final outer = nestedKey.currentState!.outerController.position;
    final inner = nestedKey.currentState!.innerController.position;

    unawaited(controller.scrollToEnd());
    await tester.pumpAndSettle();

    // Header fully collapsed and body scrolled to its bottom.
    expect(outer.pixels, morePreciselyEquals(outer.maxScrollExtent));
    expect(inner.pixels, morePreciselyEquals(inner.maxScrollExtent));
  });

  testWidgets(
      'independent descendant list inside NestedScrollView stays the scroll target',
      (tester) async {
    final controller = BottomBarController();
    final nestedKey = GlobalKey<NestedScrollViewState>();
    final descendantController = ScrollController();
    addTearDown(descendantController.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: NestedScrollView(
            key: nestedKey,
            headerSliverBuilder: (_, __) => const [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(title: Text('Nested')),
              ),
            ],
            body: ListView(
              key: const Key('nested-body-list'),
              children: [
                const SizedBox(height: 200),
                SizedBox(
                  height: 220,
                  child: Material(
                    child: ListView.builder(
                      key: const Key('descendant-list'),
                      controller: descendantController,
                      itemCount: 60,
                      itemBuilder: (_, i) => SizedBox(
                        height: 48,
                        child: Center(child: Text('Inner $i')),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 800),
              ],
            ),
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('child')),
          ),
        ),
      ),
    ));

    final outer = nestedKey.currentState!.outerController.position;
    final inner = nestedKey.currentState!.innerController.position;
    expect(outer.pixels, morePreciselyEquals(outer.minScrollExtent));
    expect(inner.pixels, morePreciselyEquals(inner.minScrollExtent));

    await tester.drag(
        find.byKey(const Key('descendant-list')), const Offset(0, -180));
    await tester.pumpAndSettle();

    final outerBeforeStart = outer.pixels;
    final innerBeforeStart = inner.pixels;
    expect(descendantController.offset, greaterThan(0));

    unawaited(controller.scrollToStart());
    await tester.pumpAndSettle();

    expect(descendantController.offset, morePreciselyEquals(0));
    expect(outer.pixels, morePreciselyEquals(outerBeforeStart));
    expect(inner.pixels, morePreciselyEquals(innerBeforeStart));

    await tester.drag(
        find.byKey(const Key('descendant-list')), const Offset(0, -180));
    await tester.pumpAndSettle();

    final outerBeforeEnd = outer.pixels;
    final innerBeforeEnd = inner.pixels;
    final descendantMax = descendantController.position.maxScrollExtent;
    expect(descendantController.offset, lessThan(descendantMax));

    unawaited(controller.scrollToEnd());
    await tester.pumpAndSettle();

    expect(descendantController.offset, morePreciselyEquals(descendantMax));
    expect(outer.pixels, morePreciselyEquals(outerBeforeEnd));
    expect(inner.pixels, morePreciselyEquals(innerBeforeEnd));
  });
}

Matcher morePreciselyEquals(double value) => closeTo(value, 0.5);

Iterable<String> _semanticsLabels(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty);
}

double _barProgress(WidgetTester tester) {
  final slide = tester
      .widgetList<SlideTransition>(find.byType(SlideTransition))
      .where((widget) => widget.child is Container)
      .first;
  return 1 - (slide.position.value.dy / 2);
}
