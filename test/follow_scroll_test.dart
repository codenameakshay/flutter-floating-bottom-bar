import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _barKey = Key('bar');
const _follow = BottomBarScrollBehavior(followScroll: true);

void main() {
  Widget harness({
    BottomBarController? controller,
    BottomBarScrollBehavior scrollBehavior = _follow,
    BottomBarLayout? layout,
    Widget? body,
    ScrollController? scrollController,
    ScrollPhysics? physics,
    int itemCount = 200,
    bool reverse = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          layout: layout,
          scrollBehavior: scrollBehavior,
          body:
              body ??
              ListView.builder(
                controller: scrollController,
                physics: physics,
                reverse: reverse,
                itemCount: itemCount,
                itemBuilder: (context, index) =>
                    SizedBox(height: 50, child: Text('Item $index')),
              ),
          child: const SizedBox(key: _barKey, height: 56),
        ),
      ),
    );
  }

  double barTop(WidgetTester tester) =>
      tester.getTopLeft(find.byKey(_barKey)).dy;

  double pixelsOf(WidgetTester tester) => tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .pixels;

  testWidgets('moves the bar one pixel per pixel of scroll', (tester) async {
    await tester.pumpWidget(harness());
    final shownTop = barTop(tester);
    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    final scrolled = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(scrolled, greaterThan(0));
    expect(barTop(tester) - shownTop, moreOrLessEquals(scrolled));

    await gesture.moveBy(const Offset(0, 10));
    await tester.pump();
    final back = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(barTop(tester) - shownTop, moreOrLessEquals(back));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
  });

  testWidgets('clamps at the bar footprint and ignores drags at the start', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    final shownTop = barTop(tester);

    final start = await tester.startGesture(const Offset(200, 300));
    await start.moveBy(const Offset(0, 50));
    await tester.pump();
    expect(pixelsOf(tester), 0.0);
    expect(barTop(tester), shownTop);
    await start.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);

    final far = await tester.startGesture(const Offset(200, 300));
    await far.moveBy(const Offset(0, -300));
    await tester.pump();
    expect(pixelsOf(tester), greaterThan(76));
    expect(barTop(tester), shownTop + 76);
    await far.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop + 76);
  });

  testWidgets('a direction change mid-drag keeps the bar on the list', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    final shownTop = barTop(tester);
    final gesture = await tester.startGesture(const Offset(200, 300));

    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    final first = pixelsOf(tester);
    final firstOffset = barTop(tester) - shownTop;
    expect(first, greaterThan(0));
    expect(firstOffset, moreOrLessEquals(first));

    await gesture.moveBy(const Offset(0, 15));
    await tester.pump();
    final second = pixelsOf(tester);
    final secondOffset = barTop(tester) - shownTop;
    expect(second, lessThan(first));
    expect(second, greaterThan(0));
    expect(secondOffset, moreOrLessEquals(second));
    expect(firstOffset - secondOffset, moreOrLessEquals(first - second));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
  });

  testWidgets('a release settles to the nearer state', (tester) async {
    final controller = BottomBarController();
    final scroll = ScrollController();
    await tester.pumpWidget(
      harness(controller: controller, scrollController: scroll),
    );
    final shownTop = barTop(tester);

    final near = await tester.startGesture(const Offset(200, 300));
    await near.moveBy(const Offset(0, -20));
    await tester.pump();
    expect(pixelsOf(tester), moreOrLessEquals(20));
    await near.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
    expect(controller.isVisible, isTrue);

    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    controller.show();
    await tester.pumpAndSettle();

    final far = await tester.startGesture(const Offset(200, 300));
    await far.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(pixelsOf(tester), moreOrLessEquals(60));
    await far.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop + 76);
    expect(controller.isVisible, isFalse);
  });

  testWidgets('a fling tracks 1:1 and then hides the bar', (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(harness(controller: controller));
    final shownTop = barTop(tester);

    await tester.fling(find.byType(Scrollable), const Offset(0, -400), 2000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.isScrollingNotifier.value, isTrue);
    expect(pixelsOf(tester), greaterThan(0));
    expect(
      barTop(tester) - shownTop,
      moreOrLessEquals(pixelsOf(tester) < 76 ? pixelsOf(tester) : 76),
    );

    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop + 76);
    expect(controller.isVisible, isFalse);
  });

  testWidgets('a fling into the end settles the way it was going', (
    tester,
  ) async {
    final controller = BottomBarController();
    final scroll = ScrollController();
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollController: scroll,
        physics: const ClampingScrollPhysics(),
        itemCount: 40,
      ),
    );
    final shownTop = barTop(tester);

    scroll.jumpTo(scroll.position.maxScrollExtent - 36);
    await tester.pumpAndSettle();
    controller.show();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);

    // The bar can move 36px at most, short of the 38px that would hide it by
    // itself, so only the fling's velocity can hide it.
    final gesture = await tester.createGesture();
    await gesture.down(const Offset(200, 300));
    for (var step = 1; step <= 6; step++) {
      await gesture.moveBy(
        const Offset(0, -5),
        timeStamp: Duration(milliseconds: 8 * step),
      );
      await tester.pump(const Duration(milliseconds: 8));
    }
    await gesture.up(timeStamp: const Duration(milliseconds: 56));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse);
    expect(barTop(tester), shownTop + 76);
  });

  testWidgets('overscroll at either end does not move the bar', (tester) async {
    final controller = BottomBarController();
    final scroll = ScrollController();
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollController: scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
    );
    final shownTop = barTop(tester);

    final top = await tester.startGesture(const Offset(200, 300));
    await top.moveBy(const Offset(0, 120));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(barTop(tester), shownTop);
    await top.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    controller.show();
    await tester.pumpAndSettle();
    expect(controller.isVisible, isTrue);
    expect(barTop(tester), shownTop);

    final bottom = await tester.startGesture(const Offset(200, 300));
    await bottom.moveBy(const Offset(0, -120));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(barTop(tester), shownTop);
    await bottom.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
  });

  testWidgets('showAtStart shows the bar as the list reaches its start', (
    tester,
  ) async {
    final controller = BottomBarController();
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollBehavior: const BottomBarScrollBehavior(
          followScroll: true,
          showAtStart: true,
        ),
      ),
    );
    final shownTop = barTop(tester);

    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop + 76);
    expect(controller.isVisible, isFalse);

    final back = await tester.startGesture(const Offset(200, 300));
    await back.moveBy(const Offset(0, 400));
    await tester.pump();
    expect(pixelsOf(tester), 0.0);
    expect(controller.isVisible, isTrue);

    await back.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
  });

  testWidgets('a list shorter than the viewport never moves the bar', (
    tester,
  ) async {
    final controller = BottomBarController();
    await tester.pumpWidget(
      harness(
        controller: controller,
        itemCount: 3,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
    );
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(barTop(tester), shownTop);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
    expect(controller.isVisible, isTrue);
  });

  testWidgets('a reverse list moves the bar with its pixels', (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(harness(controller: controller, reverse: true));
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();
    final pixels = pixelsOf(tester);
    expect(pixels, greaterThan(0));
    expect(barTop(tester) - shownTop, moreOrLessEquals(pixels));

    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(pixelsOf(tester), moreOrLessEquals(20));
    expect(barTop(tester) - shownTop, moreOrLessEquals(20));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
    expect(controller.isVisible, isTrue);
  });

  testWidgets('a NestedScrollView moves the bar with outer plus inner offset', (
    tester,
  ) async {
    final nestedKey = GlobalKey<NestedScrollViewState>();
    await tester.pumpWidget(
      harness(
        body: NestedScrollView(
          key: nestedKey,
          headerSliverBuilder: (_, _) => const [
            SliverAppBar(expandedHeight: 200, pinned: false),
          ],
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (_, index) =>
                SizedBox(height: 50, child: Text('Item $index')),
          ),
        ),
      ),
    );
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    final nested = nestedKey.currentState!;
    final outer = nested.outerController.offset;
    final inner = nested.innerController.offset;
    expect(outer + inner, greaterThan(0));
    expect(barTop(tester) - shownTop, moreOrLessEquals(outer + inner));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a tab switch mid-track shows the bar', (tester) async {
    final controller = BottomBarController();
    final tab = ValueNotifier<int>(0);
    Widget list(String label) => ListView.builder(
      itemCount: 200,
      itemBuilder: (_, index) =>
          SizedBox(height: 50, child: Text('$label $index')),
    );
    await tester.pumpWidget(
      harness(
        controller: controller,
        body: ValueListenableBuilder<int>(
          valueListenable: tab,
          builder: (_, index, _) => IndexedStack(
            index: index,
            children: [list('First'), list('Second')],
          ),
        ),
      ),
    );
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    expect(barTop(tester) - shownTop, greaterThan(0));
    expect(controller.isVisible, isTrue);

    tab.value = 1;
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
    expect(controller.isVisible, isTrue);
  });

  testWidgets('a programmatic hide mid-drag wins over the scroll', (
    tester,
  ) async {
    final controller = BottomBarController();
    await tester.pumpWidget(harness(controller: controller));
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    controller.hide();
    await tester.pump();

    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(controller.isVisible, isFalse);
    await gesture.moveBy(const Offset(0, -10));
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop + 76);
    expect(controller.isVisible, isFalse);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop + 76);
    expect(controller.isVisible, isFalse);
  });

  testWidgets('a programmatic show mid-drag wins over the scroll', (
    tester,
  ) async {
    final controller = BottomBarController();
    await tester.pumpWidget(harness(controller: controller));
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    expect(barTop(tester) - shownTop, moreOrLessEquals(60));

    controller.show();
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();
    expect(barTop(tester), shownTop);
    expect(controller.isVisible, isTrue);
  });

  testWidgets('scrollToStart mid-drag ends at the start with the bar shown', (
    tester,
  ) async {
    final controller = BottomBarController();
    await tester.pumpWidget(harness(controller: controller));
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();

    controller.scrollToStart();
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pixelsOf(tester), 0.0);
    expect(barTop(tester), shownTop);
    expect(controller.isVisible, isTrue);
  });
}
