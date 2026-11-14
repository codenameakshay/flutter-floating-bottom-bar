import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _labels = ['Home', 'Search', 'Inbox', 'Profile'];

Widget _items({Key? key}) => BottomBarItems(
  key: key,
  selectedIndex: 0,
  onSelected: (_) {},
  children: [
    for (var i = 0; i < _labels.length; i++)
      BottomBarItem(
        icon: const Icon(Icons.circle_outlined),
        selectedIcon: const Icon(Icons.circle),
        label: Text(_labels[i]),
      ),
  ],
);

Future<void> _pumpGroups(
  WidgetTester tester, {
  required BottomBarController controller,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  VoidCallback? onLeading,
  Widget? body,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            layout: const BottomBarLayout(width: 360),
            scrollBehavior: BottomBarScrollBehavior(
              minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
            ),
            leading: IconButton(
              onPressed: onLeading ?? () {},
              icon: const Icon(Icons.person),
            ),
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            body: body ?? const SizedBox.expand(),
            child: _items(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderBarSurface _pillSurface(WidgetTester tester) =>
    tester.renderObject<RenderBarSurface>(find.byKey(const ValueKey('pill')));

Rect _pillOutline(WidgetTester tester) {
  final surface = _pillSurface(tester);
  return MatrixUtils.transformRect(
    surface.getTransformTo(null),
    surface.outlineRect,
  );
}

Rect _piece(WidgetTester tester, String slot) =>
    tester.getRect(find.byKey(ValueKey(slot)));

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.5));
  expect(actual.top, closeTo(expected.top, 0.5));
  expect(actual.right, closeTo(expected.right, 0.5));
  expect(actual.bottom, closeTo(expected.bottom, 0.5));
}

Future<void> _pumpUntilMorph(
  WidgetTester tester,
  double target, {
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < 300 && _pillSurface(tester).morph < target; i++) {
    await tester.pump(step);
  }
}

void main() {
  testWidgets('leading and trailing keep their rects minimized and expanded', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(tester, controller: controller);
    final leadingShown = _piece(tester, 'leading');
    final trailingShown = _piece(tester, 'trailing');
    expect(leadingShown.left, closeTo(20, 0.5));
    expect(trailingShown.right, closeTo(380, 0.5));

    controller.minimize();
    await tester.pumpAndSettle();
    expect(_pillSurface(tester).morph, 1);
    _expectRect(_piece(tester, 'leading'), leadingShown);
    _expectRect(_piece(tester, 'trailing'), trailingShown);

    controller.expand();
    await tester.pumpAndSettle();
    expect(_pillSurface(tester).morph, closeTo(0, 0.001));
    _expectRect(_piece(tester, 'leading'), leadingShown);
    _expectRect(_piece(tester, 'trailing'), trailingShown);
  });

  testWidgets('the pill sits one group spacing after the leading piece', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(tester, controller: controller);
    final fullOutline = _pillOutline(tester);

    controller.minimize();
    await tester.pumpAndSettle();

    final leading = _piece(tester, 'leading');
    final trailing = _piece(tester, 'trailing');
    final pill = _pillOutline(tester);
    expect(
      pill.left,
      closeTo(leading.right + const BottomBarLayout().groupSpacing, 0.5),
    );
    expect(trailing.right, closeTo(380, 0.5));
    expect(pill.center.dy, closeTo(fullOutline.center.dy, 0.5));
  });

  testWidgets('RTL mirrors the pill and the leading piece', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(
      tester,
      controller: controller,
      direction: TextDirection.rtl,
    );
    final fullOutline = _pillOutline(tester);

    controller.minimize();
    await tester.pumpAndSettle();

    final leading = _piece(tester, 'leading');
    final trailing = _piece(tester, 'trailing');
    final pill = _pillOutline(tester);
    expect(leading.right, closeTo(380, 0.5));
    expect(leading.left, greaterThan(trailing.right));
    expect(
      pill.right,
      closeTo(leading.left - const BottomBarLayout().groupSpacing, 0.5),
    );
    expect(pill.center.dy, closeTo(fullOutline.center.dy, 0.5));
  });

  testWidgets('the pieces hold still through the morph midpoint', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(tester, controller: controller);
    final leadingShown = _piece(tester, 'leading');
    final trailingShown = _piece(tester, 'trailing');
    final fullOutline = _pillOutline(tester);

    controller.minimize();
    await tester.pump();
    await _pumpUntilMorph(tester, 0.5, step: const Duration(milliseconds: 8));
    expect(_pillSurface(tester).morph, greaterThanOrEqualTo(0.5));
    expect(_pillSurface(tester).morph, lessThan(1));
    _expectRect(_piece(tester, 'leading'), leadingShown);
    _expectRect(_piece(tester, 'trailing'), trailingShown);
    final midLeft = _pillOutline(tester).left;

    await tester.pumpAndSettle();
    final pillLeft = _pillOutline(tester).left;
    final low = fullOutline.left < pillLeft ? fullOutline.left : pillLeft;
    final high = fullOutline.left < pillLeft ? pillLeft : fullOutline.left;
    expect(midLeft, greaterThanOrEqualTo(low - 0.5));
    expect(midLeft, lessThanOrEqualTo(high + 0.5));
  });

  testWidgets('interrupting the morph expands without moving the pieces', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(tester, controller: controller);
    final leadingShown = _piece(tester, 'leading');
    final trailingShown = _piece(tester, 'trailing');

    controller.minimize();
    await tester.pump();
    await _pumpUntilMorph(tester, 0.5);
    expect(_pillSurface(tester).morph, closeTo(0.5, 0.2));

    controller.expand();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      _expectRect(_piece(tester, 'leading'), leadingShown);
      _expectRect(_piece(tester, 'trailing'), trailingShown);
    }
    await tester.pumpAndSettle();
    expect(_pillSurface(tester).morph, closeTo(0, 0.001));
    _expectRect(_piece(tester, 'leading'), leadingShown);
    _expectRect(_piece(tester, 'trailing'), trailingShown);
  });

  testWidgets('reduced motion snaps to the pill with the pieces in place', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(tester, controller: controller, reduceMotion: true);
    final leadingShown = _piece(tester, 'leading');
    final trailingShown = _piece(tester, 'trailing');

    controller.minimize();
    await tester.pump();
    expect(_pillSurface(tester).morph, 1);
    _expectRect(_piece(tester, 'leading'), leadingShown);
    _expectRect(_piece(tester, 'trailing'), trailingShown);
  });

  testWidgets('taps in the gaps reach the body and the leading button works', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    var bodyTaps = 0;
    var leadingTaps = 0;
    await _pumpGroups(
      tester,
      controller: controller,
      onLeading: () => leadingTaps++,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => bodyTaps++,
        child: const SizedBox.expand(),
      ),
    );
    controller.minimize();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(leadingTaps, 1);
    expect(bodyTaps, 0);

    final leading = _piece(tester, 'leading');
    final pill = _pillOutline(tester);
    final leadingGap = Offset((leading.right + pill.left) / 2, pill.center.dy);
    await tester.tapAt(leadingGap);
    await tester.pumpAndSettle();
    expect(bodyTaps, 1);
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    final trailing = _piece(tester, 'trailing');
    final trailingGap = Offset(
      (pill.right + trailing.left) / 2,
      pill.center.dy,
    );
    await tester.tapAt(trailingGap);
    await tester.pumpAndSettle();
    expect(bodyTaps, 2);
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    await tester.tapAt(pill.center);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(leadingTaps, 1);
    expect(bodyTaps, 2);
  });

  testWidgets('visibleHeight with pieces equals the bar footprint minimized', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpGroups(
      tester,
      controller: controller,
      body: Builder(
        key: const ValueKey('probe'),
        builder: (_) => const SizedBox.expand(),
      ),
    );
    final scope = BottomBarScope.of(
      tester.element(find.byKey(const ValueKey('probe'))),
    );
    final footprint = scope.barHeight.value;
    expect(footprint, greaterThan(0));
    expect(scope.visibleHeight.value, closeTo(footprint, 0.5));

    controller.minimize();
    await tester.pumpAndSettle();
    expect(scope.visibleHeight.value, closeTo(scope.barHeight.value, 0.5));
    expect(scope.barHeight.value, closeTo(footprint, 0.5));
  });
}
