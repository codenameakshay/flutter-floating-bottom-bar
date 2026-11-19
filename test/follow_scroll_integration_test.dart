import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _barKey = Key('bar');
const _follow = BottomBarScrollBehavior(followScroll: true);
const _travel = 76.0;

Widget _defaultBody() => ListView.builder(
  itemCount: 200,
  itemBuilder: (context, index) =>
      SizedBox(height: 50, child: Text('Item $index')),
);

Widget harness({
  BottomBarController? controller,
  BottomBarScrollBehavior scrollBehavior = _follow,
  BottomBarLayout? layout,
  BottomBarMotion? motion,
  Widget? accessory,
  Widget? child,
  Widget? body,
  ValueChanged<bool>? onVisibilityChanged,
  VoidCallback? onBottomBarShown,
  VoidCallback? onBottomBarHidden,
  MediaQueryData? media,
}) {
  final scaffold = Scaffold(
    body: BottomBar(
      controller: controller,
      layout: layout,
      motion: motion,
      scrollBehavior: scrollBehavior,
      accessory: accessory,
      onVisibilityChanged: onVisibilityChanged,
      onBottomBarShown: onBottomBarShown,
      onBottomBarHidden: onBottomBarHidden,
      body: body ?? _defaultBody(),
      child: child ?? const SizedBox(key: _barKey, height: 56),
    ),
  );
  return MaterialApp(
    home: media == null ? scaffold : MediaQuery(data: media, child: scaffold),
  );
}

BottomBarItems _items() => BottomBarItems(
  key: _barKey,
  selectedIndex: 0,
  onSelected: (_) {},
  children: const [
    BottomBarItem(icon: Icon(Icons.circle_outlined), label: Text('Home')),
    BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
  ],
);

double barTop(WidgetTester tester) => tester.getTopLeft(find.byKey(_barKey)).dy;

double barBottom(WidgetTester tester) =>
    tester.getBottomLeft(find.byKey(_barKey)).dy;

double listPixels(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

Finder findByTooltip(String message) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == message,
  description: 'Tooltip("$message")',
);

List<bool> excludingAncestors(WidgetTester tester, Key key) => [
  for (final element
      in find
          .ancestor(
            of: find.byKey(key),
            matching: find.byType(ExcludeSemantics),
          )
          .evaluate())
    (element.widget as ExcludeSemantics).excluding,
];

List<bool> ignoringAncestors(WidgetTester tester, Key key) => [
  for (final element
      in find
          .ancestor(of: find.byKey(key), matching: find.byType(IgnorePointer))
          .evaluate())
    (element.widget as IgnorePointer).ignoring,
];

/// Holds the gesture and moves in small steps until the list has scrolled
/// [pixels]. Compares against the list's real scroll, not finger distance,
/// since touch slop absorbs the first few pixels of a drag.
Future<void> dragTo(
  WidgetTester tester,
  TestGesture gesture,
  double pixels, {
  double step = 4,
}) async {
  var steps = 0;
  while (listPixels(tester) < pixels) {
    expect(++steps, lessThan(500), reason: 'list never reached $pixels px');
    await gesture.moveBy(Offset(0, -step));
    await tester.pump();
  }
}

void main() {
  testWidgets('callbacks and the visibility listener fire once per settle', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final changes = <bool>[];
    var shown = 0;
    var hidden = 0;
    var listened = 0;
    controller.visibility.addListener(() => listened++);

    await tester.pumpWidget(
      harness(
        controller: controller,
        onVisibilityChanged: changes.add,
        onBottomBarShown: () => shown++,
        onBottomBarHidden: () => hidden++,
      ),
    );
    await tester.pumpAndSettle();
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    await gesture.moveBy(const Offset(0, 5));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    expect(listPixels(tester), greaterThan(_travel));
    expect(shown, 0);
    expect(hidden, 0);
    expect(changes, isEmpty);
    expect(listened, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(hidden, 1);
    expect(shown, 0);
    expect(changes, [false]);
    expect(listened, 1);
    expect(controller.visibility.value, BottomBarVisibility.hidden);
    expect(barTop(tester) - shownTop, moreOrLessEquals(_travel, epsilon: 0.01));

    final back = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 5; i++) {
      await back.moveBy(const Offset(0, 10));
      await tester.pump();
    }
    expect(shown, 1);
    expect(hidden, 1);
    expect(changes, [false, true]);
    expect(listened, 2);

    await back.up();
    await tester.pumpAndSettle();
    expect(shown, 1);
    expect(hidden, 1);
    expect(changes, [false, true]);
    expect(listened, 2);
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('the reserved body padding stays put while the bar moves', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 200,
            itemBuilder: (context, index) =>
                SizedBox(height: 50, child: Text('Item $index')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double reserved() => tester
        .widget<Padding>(
          find
              .descendant(
                of: find.byType(BottomBarBodyPadding),
                matching: find.byType(Padding),
              )
              .first,
        )
        .padding
        .resolve(TextDirection.ltr)
        .bottom;

    final before = reserved();
    expect(before, 76);
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
      expect(reserved(), before);
    }
    expect(barTop(tester) - shownTop, greaterThan(0));
    expect(barTop(tester) - shownTop, lessThan(_travel));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(reserved(), before);
  });

  testWidgets(
    'a partly shown bar is hittable and in semantics, a hidden one is neither',
    (tester) async {
      final semantics = tester.ensureSemantics();
      const targetKey = Key('tap-target');
      var taps = 0;

      await tester.pumpWidget(
        harness(
          child: Semantics(
            label: 'bar-body',
            container: true,
            child: GestureDetector(
              key: targetKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => taps++,
              child: const SizedBox(key: _barKey, height: 56),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shownTop = barTop(tester);

      final gesture = await tester.startGesture(const Offset(200, 300));
      await dragTo(tester, gesture, 30);
      expect(barTop(tester) - shownTop, greaterThan(0));
      expect(barTop(tester) - shownTop, lessThan(_travel));

      final hit = tester.hitTestOnBinding(
        tester.getCenter(find.byKey(targetKey)),
      );
      final pointerListener = tester.renderObject(
        find
            .descendant(
              of: find.byKey(targetKey),
              matching: find.byType(Listener),
            )
            .first,
      );
      expect(hit.path.map((entry) => entry.target), contains(pointerListener));
      expect(excludingAncestors(tester, targetKey), isNotEmpty);
      expect(excludingAncestors(tester, targetKey), isNot(contains(true)));
      expect(ignoringAncestors(tester, targetKey), isNot(contains(true)));

      await dragTo(tester, gesture, 100);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        barTop(tester) - shownTop,
        moreOrLessEquals(_travel, epsilon: 0.01),
      );
      expect(excludingAncestors(tester, targetKey), contains(true));
      expect(ignoringAncestors(tester, targetKey), contains(true));
      expect(taps, 0);
      semantics.dispose();
    },
  );

  testWidgets('the back-to-top action is tappable after the bar hides', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(harness(controller: controller));
    await tester.pumpAndSettle();
    final shownTop = barTop(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    await dragTo(tester, gesture, 100);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.hidden);
    expect(findByTooltip('Scroll to top'), findsOneWidget);

    await tester.tap(findByTooltip('Scroll to top'));
    await tester.pumpAndSettle();
    expect(listPixels(tester), moreOrLessEquals(0, epsilon: 0.01));
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(barTop(tester) - shownTop, moreOrLessEquals(0, epsilon: 0.01));
  });

  testWidgets('a docked bar travels fully out of the screen, inset included', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final media = MediaQueryData(
      size: const Size(800, 600),
      padding: const EdgeInsets.only(bottom: 34),
      viewPadding: const EdgeInsets.only(bottom: 34),
    );

    await tester.pumpWidget(
      harness(
        controller: controller,
        layout: const BottomBarLayout.docked(),
        media: media,
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(200, 300));
    await dragTo(tester, gesture, 400, step: 10);
    expect(barTop(tester), greaterThanOrEqualTo(600));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.hidden);
    expect(barTop(tester), greaterThanOrEqualTo(600));
  });

  testWidgets('the accessory moves with the scroll and leaves with the bar', (
    tester,
  ) async {
    const accessoryKey = Key('acc');
    await tester.pumpWidget(
      harness(accessory: const SizedBox(key: accessoryKey, height: 40)),
    );
    await tester.pumpAndSettle();
    final accessoryTop0 = tester.getTopLeft(find.byKey(accessoryKey)).dy;

    final gesture = await tester.startGesture(const Offset(200, 300));
    await dragTo(tester, gesture, 20);
    expect(
      tester.getTopLeft(find.byKey(accessoryKey)).dy - accessoryTop0,
      moreOrLessEquals(listPixels(tester), epsilon: 0.01),
    );

    await dragTo(tester, gesture, 400, step: 10);
    expect(
      tester.getTopLeft(find.byKey(accessoryKey)).dy,
      greaterThanOrEqualTo(600),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'under reduced motion the bar tracks 1:1 and snaps to its settled state',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      const media = MediaQueryData(
        size: Size(800, 600),
        disableAnimations: true,
      );
      await tester.pumpWidget(harness(controller: controller, media: media));
      await tester.pumpAndSettle();
      final shownTop = barTop(tester);

      final gesture = await tester.startGesture(const Offset(200, 300));
      await dragTo(tester, gesture, 20);
      expect(
        barTop(tester) - shownTop,
        moreOrLessEquals(listPixels(tester), epsilon: 0.01),
      );

      await dragTo(tester, gesture, 60);
      await gesture.up();
      await tester.pump();
      expect(controller.visibility.value, BottomBarVisibility.hidden);
      expect(
        barTop(tester) - shownTop,
        moreOrLessEquals(_travel, epsilon: 0.01),
      );
    },
  );

  testWidgets('a custom transitionBuilder sees progress 1 - pixels / 76', (
    tester,
  ) async {
    double? last;
    final motion = BottomBarMotion(
      transitionBuilder: (context, animation, child) {
        last = animation.value;
        return child;
      },
    );
    await tester.pumpWidget(harness(motion: motion));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(200, 300));
    await dragTo(tester, gesture, 30);
    expect(listPixels(tester), greaterThan(0));
    expect(
      last,
      moreOrLessEquals(1 - listPixels(tester) / _travel, epsilon: 0.01),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a fade transition fades the bar by the same progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        motion: const BottomBarMotion(transition: BottomBarTransition.fade),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(200, 300));
    await dragTo(tester, gesture, 38);
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byKey(_barKey),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(
      fade.opacity.value,
      moreOrLessEquals(1 - listPixels(tester) / _travel, epsilon: 0.01),
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('with a minimize mode, followScroll is ignored', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollBehavior: const BottomBarScrollBehavior(
          followScroll: true,
          minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
        ),
        child: _items(),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    final bottom = barBottom(tester);

    final gesture = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 3; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    expect(listPixels(tester), greaterThan(0));
    expect(barBottom(tester), moreOrLessEquals(bottom, epsilon: 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
  });

  testWidgets('the child does not rebuild while the bar follows the scroll', (
    tester,
  ) async {
    var builds = 0;
    final child = Builder(
      key: _barKey,
      builder: (_) {
        builds++;
        return const SizedBox(height: 56);
      },
    );
    await tester.pumpWidget(harness(child: child));
    await tester.pumpAndSettle();
    final settledBuilds = builds;

    final gesture = await tester.startGesture(const Offset(200, 300));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -5));
      await tester.pump();
    }
    expect(builds, settledBuilds);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(builds, settledBuilds);
  });
}
