import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_group.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

RenderBarPanel panel(WidgetTester tester) =>
    tester.renderObject<RenderBarPanel>(find.byType(PanelBox));

RenderBarSurface source(WidgetTester tester) => tester
    .renderObjectList<RenderBarSurface>(find.byType(BarSurface))
    .firstWhere((surface) => surface.minimizeHost != null);

RenderBarSurface surfaceFor(WidgetTester tester, Finder descendant) {
  for (
    RenderObject? object = tester.renderObject(descendant);
    object != null;
    object = object.parent
  ) {
    if (object is RenderBarSurface) return object;
  }
  throw StateError('No RenderBarSurface above $descendant');
}

RenderBarGroup groupFor(RenderBarSurface surface) {
  for (RenderObject? object = surface; object != null; object = object.parent) {
    if (object is RenderBarGroup) return object;
  }
  throw StateError('No RenderBarGroup above $surface');
}

Rect rectOf(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

BarPanelRoute<dynamic> routeFor(Element element) =>
    ModalRoute.of(element)! as BarPanelRoute<dynamic>;

RenderBarPanel panelForRoute(BarPanelRoute route) {
  final element = find
      .byType(PanelBox)
      .evaluate()
      .firstWhere((candidate) => identical(ModalRoute.of(candidate), route));
  return element.findRenderObject()! as RenderBarPanel;
}

Rect outlineOf(WidgetTester tester, RenderBarSurface surface) =>
    MatrixUtils.transformRect(
      surface.getTransformTo(null),
      surface.outlineRect,
    );

void expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.5));
  expect(actual.top, closeTo(expected.top, 0.5));
  expect(actual.right, closeTo(expected.right, 0.5));
  expect(actual.bottom, closeTo(expected.bottom, 0.5));
}

Set<String> semanticsLabels(WidgetTester tester) {
  final labels = <String>{};
  bool visit(SemanticsNode node) {
    labels.add(node.label);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return labels;
}

void useView(WidgetTester tester, [Size size = const Size(400, 800)]) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<Duration> moveDownSlowly(
  WidgetTester tester,
  TestGesture gesture,
  double distance, {
  Duration elapsed = Duration.zero,
}) async {
  while (distance > 0) {
    final step = math.min(1.0, distance);
    elapsed += const Duration(milliseconds: 20);
    await gesture.moveBy(Offset(0, step), timeStamp: elapsed);
    distance -= step;
  }
  await tester.pump();
  return elapsed;
}

Widget defaultPanel(BuildContext context) => SizedBox(
  height: 300,
  child: Column(
    children: [
      TextButton(
        onPressed: () => Navigator.pop(context, 'done'),
        child: const Text('Done'),
      ),
      TextButton(onPressed: () {}, child: const Text('Second')),
    ],
  ),
);

Widget fieldPanel(BuildContext context) =>
    const SizedBox(height: 200, child: TextField());

Widget shortPanel(BuildContext context) =>
    const SizedBox(height: 40, child: Center(child: Text('Short')));

Future<String?> openPanel(
  WidgetTester tester, {
  WidgetBuilder builder = defaultPanel,
  String semanticLabel = 'Create',
  bool dismissible = true,
  BuildContext? context,
}) => showBottomBarPanel<String>(
  context ?? tester.element(find.byType(BottomBarItems)),
  builder: builder,
  semanticLabel: semanticLabel,
  dismissible: dismissible,
);

Future<void> backGesture(
  WidgetTester tester,
  String method, [
  double progress = 0,
]) async {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(
      method,
      method == 'startBackGesture' || method == 'updateBackGestureProgress'
          ? <String, dynamic>{
              'touchOffset': <double>[5.0, 300.0],
              'progress': progress,
              'swipeEdge': 0,
            }
          : null,
    ),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    message,
    (_) {},
  );
}

class _Harness extends StatefulWidget {
  const _Harness({
    this.layout,
    this.direction = TextDirection.ltr,
    this.glass = true,
    this.controller,
    this.motion,
    this.body = const Center(child: Text('Behind')),
  });

  final BottomBarLayout? layout;
  final TextDirection direction;
  final bool glass;
  final BottomBarController? controller;
  final BottomBarMotion? motion;
  final Widget body;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  @override
  Widget build(BuildContext context) {
    final harness = widget;
    return MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: harness.direction, child: child!),
      home: BottomBar(
        controller: harness.controller,
        layout: harness.layout,
        theme: BottomBarThemeData(
          surface: harness.glass
              ? const BottomBarSurface.glass()
              : const BottomBarSurface.solid(),
        ),
        motion:
            harness.motion ??
            const BottomBarMotion.curved(
              duration: Duration(milliseconds: 400),
              curve: Curves.linear,
            ),
        body: harness.body,
        child: BottomBarItems(
          selectedIndex: 0,
          onSelected: (_) {},
          children: const [
            BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
            BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
            BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('morph from the full bar: outline, midpoint and settled panel', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final barRect = outlineOf(tester, source(tester));
    final result = openPanel(tester);
    await tester.pump();
    final p = panel(tester);
    expect(p.currentRect, barRect);
    final startRadius = math.min(28.0, barRect.shortestSide / 2);
    expect(p.currentRadius.topLeft.x, closeTo(startRadius, 0.5));
    await tester.pump(const Duration(milliseconds: 200));
    expectRect(p.currentRect, Rect.lerp(barRect, p.panelRect, 0.5)!);
    expect(p.currentRadius.topLeft.x, closeTo((startRadius + 32) / 2, 0.5));
    await tester.pumpAndSettle();
    expect(p.currentRect, p.panelRect);
    expect(p.panelRect.height, 300);
    expect(p.panelRect.bottom, barRect.bottom);
    expect(p.currentRadius.topLeft.x, 32);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, 'done');
  });

  testWidgets('a BottomBar element context can open its panel', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(
      tester,
      context: tester.element(find.byType(BottomBar)),
    );
    await tester.pumpAndSettle();
    expect(panel(tester).currentRect, panel(tester).panelRect);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('morph from the minimized pill', (tester) async {
    useView(tester);
    final controller = BottomBarController();
    await tester.pumpWidget(_Harness(controller: controller));
    controller.minimize();
    await tester.pumpAndSettle();
    final pill = outlineOf(tester, source(tester));
    final result = openPanel(tester);
    await tester.pump();
    final p = panel(tester);
    expect(p.currentRect, pill);
    await tester.pumpAndSettle();
    expect(p.currentRect, p.panelRect);
    expect(p.panelRect.height, 300);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, 'done');
  });

  testWidgets('morph from a hidden bar slides up from its resting edge', (
    tester,
  ) async {
    useView(tester);
    final controller = BottomBarController();
    await tester.pumpWidget(_Harness(controller: controller));
    final first = openPanel(tester);
    await tester.pumpAndSettle();
    final restingBottom = panel(tester).panelRect.bottom;
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await first, 'done');

    controller.hide();
    await tester.pumpAndSettle();
    final result = openPanel(tester);
    await tester.pump();
    final p = panel(tester);
    expect(source(tester).lift, isNull);
    expect(p.currentRect.top, closeTo(restingBottom, 0.5));
    await tester.pumpAndSettle();
    expect(p.currentRect, p.panelRect);
    expect(p.currentRect.width, p.panelRect.width);
    expect(source(tester).lift, isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, 'done');
  });

  testWidgets('interrupted close reverses from the current morph', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final barRect = outlineOf(tester, source(tester));
    final result = openPanel(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    Navigator.of(tester.element(find.byType(PanelBox))).pop();
    await tester.pump();
    final p = panel(tester);
    final afterPop = p.currentRect.height;
    expect(afterPop, greaterThan(barRect.height));
    expect(afterPop, lessThan(p.panelRect.height));
    await tester.pump(const Duration(milliseconds: 100));
    expect(p.currentRect.height, lessThan(afterPop));
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(source(tester).lift, isNull);
    expect(await result, isNull);
  });

  testWidgets('popping during a spring preserves its current velocity', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(_Harness(motion: const BottomBarMotion()));
    final result = openPanel(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 64));
    final route =
        ModalRoute.of(tester.element(find.byType(PanelBox)))! as BarPanelRoute;
    final animation = route.animation!;
    final progressAtVelocityStart = animation.value;
    await tester.pump(const Duration(milliseconds: 1));
    final valueBeforePop = animation.value;
    final velocityBeforePop =
        (valueBeforePop - progressAtVelocityStart) / 0.001;
    expect(velocityBeforePop, greaterThan(0));
    Navigator.of(tester.element(find.byType(PanelBox))).pop();
    await tester.pump();
    expect(animation.value, closeTo(valueBeforePop, 0.001));
    await tester.pump(const Duration(milliseconds: 1));
    final velocityAfterPop = (animation.value - valueBeforePop) / 0.001;
    expect(
      velocityAfterPop,
      closeTo(velocityBeforePop, 0.15),
      reason: 'popping replaced the active opening spring velocity',
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('replacement panel inherits the closing panel morph', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(_Harness(motion: const BottomBarMotion()));
    final oldResult = openPanel(tester);
    await tester.pumpAndSettle();
    final oldContext = tester.element(find.byType(PanelBox));
    final oldRoute = routeFor(oldContext);
    final oldPanel = panelForRoute(oldRoute);
    var oldCompleted = false;
    oldResult.then((_) => oldCompleted = true);

    Navigator.of(oldContext).pop();
    await tester.pump(const Duration(milliseconds: 64));
    final closingAnimation = oldRoute.animation!;
    final progressAtVelocityStart = closingAnimation.value;
    await tester.pump(const Duration(milliseconds: 8));
    final progressBeforeHandoff = closingAnimation.value;
    final velocityBeforeHandoff =
        (progressBeforeHandoff - progressAtVelocityStart) / 0.008;
    final rectBeforeHandoff = oldPanel.currentRect;
    expect(progressBeforeHandoff, inInclusiveRange(0, 1));
    expect(progressBeforeHandoff, lessThan(1));
    expect(velocityBeforeHandoff, lessThan(0));

    final replacementResult = openPanel(tester);
    await tester.pump();
    final replacementContext = tester.element(find.byType(PanelBox).last);
    final replacementRoute = routeFor(replacementContext);
    final replacementPanel = panelForRoute(replacementRoute);
    final replacementAnimation = replacementRoute.animation!;
    expect(find.byType(PanelBox), findsOneWidget);
    expect(replacementAnimation.value, closeTo(progressBeforeHandoff, 0.01));
    expectRect(replacementPanel.currentRect, rectBeforeHandoff);
    expect(tester.layers.whereType<BackdropFilterLayer>().length, 1);
    final replacementProgressAtVelocityStart = replacementAnimation.value;
    await tester.pump(const Duration(milliseconds: 8));
    final replacementVelocity =
        (replacementAnimation.value - replacementProgressAtVelocityStart) /
        0.008;
    expect(replacementVelocity, closeTo(velocityBeforeHandoff, 0.5));

    await tester.pumpAndSettle();
    expect(oldCompleted, isTrue);
    expect(await oldResult, isNull);
    expect(replacementAnimation.value, 1);
    expect(tester.layers.whereType<BackdropFilterLayer>().length, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await replacementResult, isNull);
  });

  testWidgets('tapping Done pops with the value', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, 'done');
    expect(find.byType(PanelBox), findsNothing);
  });

  testWidgets('closes when the scrim is tapped', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(source(tester).lift, isNull);
    expect(await result, isNull);
  });

  testWidgets('closes on Escape', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('closes on the Android back button', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('predictive back gesture follows the finger and commits', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final barRect = outlineOf(tester, source(tester));
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final p = panel(tester);
    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', 0.5);
    await tester.pump();
    expect(p.currentRect.height, greaterThan(barRect.height));
    expect(p.currentRect.height, lessThan(p.panelRect.height));
    await backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('predictive cancel interrupts a spring open without a jump', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(_Harness(motion: const BottomBarMotion()));
    final result = openPanel(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 64));
    final context = tester.element(find.byType(PanelBox));
    final route = routeFor(context);
    final animation = route.animation!;
    final navigator = Navigator.of(context);
    final panelBeforeGesture = panel(tester);
    final progressBeforeGesture = animation.value;
    final rectBeforeGesture = panelBeforeGesture.currentRect;
    expect(progressBeforeGesture, greaterThan(0));
    expect(progressBeforeGesture, lessThan(1));

    await backGesture(tester, 'startBackGesture');
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);
    expect(animation.value, closeTo(progressBeforeGesture, 0.001));
    expectRect(panel(tester).currentRect, rectBeforeGesture);
    await backGesture(tester, 'updateBackGestureProgress', 0.2);
    await tester.pump();
    expect(animation.value, closeTo(progressBeforeGesture * 0.8, 0.01));
    await backGesture(tester, 'cancelBackGesture');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(animation.value, 1);
    expectRect(panel(tester).currentRect, panel(tester).panelRect);
    expect(navigator.userGestureInProgress, isFalse);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('predictive commit interrupts a spring open without a jump', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(_Harness(motion: const BottomBarMotion()));
    final result = openPanel(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 64));
    final context = tester.element(find.byType(PanelBox));
    final route = routeFor(context);
    final animation = route.animation!;
    final navigator = Navigator.of(context);
    final progressBeforeGesture = animation.value;
    final rectBeforeGesture = panel(tester).currentRect;
    expect(progressBeforeGesture, greaterThan(0));
    expect(progressBeforeGesture, lessThan(1));

    await backGesture(tester, 'startBackGesture');
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);
    expect(animation.value, closeTo(progressBeforeGesture, 0.001));
    expectRect(panel(tester).currentRect, rectBeforeGesture);
    await backGesture(tester, 'updateBackGestureProgress', 0.2);
    await tester.pump();
    final progressAtCommit = progressBeforeGesture * 0.8;
    expect(animation.value, closeTo(progressAtCommit, 0.01));
    await backGesture(tester, 'commitBackGesture');
    await tester.pump();
    expect(animation.value, closeTo(progressAtCommit, 0.01));
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(navigator.userGestureInProgress, isFalse);
    expect(await result, isNull);
  });

  testWidgets('cancelled predictive back gesture springs back open', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final p = panel(tester);
    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', 0.5);
    await tester.pump();
    await backGesture(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    expect(p.currentRect, p.panelRect);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('predictive back commit does not pop a newer route', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final navigator = Navigator.of(tester.element(find.byType(PanelBox)));
    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', 0.4);
    await tester.pump();
    navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('New route')),
      ),
    );
    await tester.pumpAndSettle();
    await backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.text('New route'), findsOneWidget);
    expect(navigator.userGestureInProgress, isFalse);
    navigator.pop();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('predictive back commit rechecks a changed PopScope', (
    tester,
  ) async {
    useView(tester);
    final canPop = ValueNotifier(true);
    addTearDown(canPop.dispose);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(
      tester,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: canPop,
        builder: (context, allowed, child) =>
            PopScope<void>(canPop: allowed, child: child!),
        child: defaultPanel(context),
      ),
    );
    await tester.pumpAndSettle();
    final navigator = Navigator.of(tester.element(find.byType(PanelBox)));
    final focusBeforeGesture = FocusManager.instance.primaryFocus;
    expect(focusBeforeGesture, isNotNull);
    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', 0.4);
    await tester.pump();
    canPop.value = false;
    await tester.pump();
    await backGesture(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    expect(navigator.userGestureInProgress, isFalse);
    expect(panel(tester).currentRect, panel(tester).panelRect);
    expect(FocusManager.instance.primaryFocus, same(focusBeforeGesture));
    canPop.value = true;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('non-dismissible panel ignores the scrim but closes on Escape', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester, dismissible: false);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('drag down closes past halfway and settles open before it', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final p = panel(tester);
    final span = p.dragSpan;
    expect(span, greaterThan(0));

    await tester.timedDrag(
      find.text('Second'),
      Offset(0, 0.3 * span),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    expect(p.currentRect, p.panelRect);

    await tester.timedDrag(
      find.text('Second'),
      Offset(0, 0.7 * span),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('a short panel moves down and reopens after a cancelled drag', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester, builder: shortPanel);
    await tester.pumpAndSettle();
    final p = panel(tester);
    final open = p.currentRect;
    final gesture = await tester.startGesture(
      Offset(open.center.dx, open.top + 2),
    );
    final elapsed = await moveDownSlowly(tester, gesture, 27);
    final draggedTop = p.currentRect.top;
    await gesture.cancel(timeStamp: elapsed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    final settlingTop = p.currentRect.top;
    await tester.pumpAndSettle();

    expect(draggedTop, greaterThan(open.top));
    expect(find.text('Short'), findsOneWidget);
    expect(settlingTop, inInclusiveRange(open.top, draggedTop));
    expectRect(p.currentRect, open);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });

  testWidgets(
    'a replacement short panel starts from the drag interrupted by Escape',
    (tester) async {
      useView(tester);
      await tester.pumpWidget(const _Harness());
      final result = openPanel(tester, builder: shortPanel);
      await tester.pumpAndSettle();
      final first = panel(tester);
      final open = first.currentRect;
      final gesture = await tester.startGesture(
        Offset(open.center.dx, open.top + 2),
      );
      final elapsed = await moveDownSlowly(tester, gesture, 27);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(await result, isNull);
      final closing = first.currentRect;
      final replacement = openPanel(tester, builder: shortPanel);
      await tester.pump();
      expectRect(panel(tester).currentRect, closing);
      await gesture.up(timeStamp: elapsed);
      await tester.pumpAndSettle();
      expectRect(panel(tester).currentRect, open);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(await replacement, isNull);
    },
  );

  for (final hidden in [false, true]) {
    final source = hidden ? 'hidden' : 'shown';
    testWidgets(
      'a short panel closes with a slow onscreen drag from a $source bar',
      (tester) async {
        useView(tester);
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_Harness(controller: controller));
        if (hidden) {
          controller.hide();
          await tester.pumpAndSettle();
        }
        final result = openPanel(tester, builder: shortPanel);
        await tester.pumpAndSettle();
        final p = panel(tester);
        final open = p.currentRect;
        final start = Offset(open.center.dx, open.top + 2);
        final lastOnscreenY =
            tester.view.physicalSize.height / tester.view.devicePixelRatio - 1;

        final short = await tester.startGesture(start);
        final shortElapsed = await moveDownSlowly(tester, short, 21);
        await short.up(timeStamp: shortElapsed);
        await tester.pumpAndSettle();
        expect(find.text('Short'), findsOneWidget);
        expectRect(p.currentRect, open);

        await tester.flingFrom(start, const Offset(0, 21), 225);
        await tester.pumpAndSettle();
        expect(find.text('Short'), findsOneWidget);
        expectRect(p.currentRect, open);

        final long = await tester.startGesture(start);
        final longElapsed = await moveDownSlowly(
          tester,
          long,
          lastOnscreenY - start.dy,
        );
        await long.up(timeStamp: longElapsed);
        await tester.pumpAndSettle();
        expect(find.text('Short'), findsNothing);
        expect(await result, isNull);
      },
    );
  }

  testWidgets('a tall panel from a hidden bar tracks the finger and closes', (
    tester,
  ) async {
    useView(tester);
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Harness(controller: controller));
    controller.hide();
    await tester.pumpAndSettle();
    final result = openPanel(tester);
    await tester.pump();
    final p = panel(tester);
    expect(p.currentRect.top, closeTo(p.panelRect.bottom, 0.5));
    await tester.pumpAndSettle();
    final open = p.currentRect;
    final gesture = await tester.startGesture(
      Offset(open.center.dx, open.top + 8),
    );
    var elapsed = await moveDownSlowly(tester, gesture, 30);
    final topAfterSlop = p.currentRect.top;
    elapsed = await moveDownSlowly(tester, gesture, 40, elapsed: elapsed);
    final heldDisplacement = p.currentRect.top - topAfterSlop;
    elapsed = await moveDownSlowly(tester, gesture, 135, elapsed: elapsed);
    await gesture.up(timeStamp: elapsed);
    await tester.pumpAndSettle();
    expect(heldDisplacement, closeTo(40, 0.5));
    expect(find.text('Second'), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('fast fling down closes the panel', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final p = panel(tester);
    expect(80 / p.dragSpan, lessThan(0.5));
    await tester.fling(find.text('Second'), const Offset(0, 80), 2000);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('cancelled vertical drag springs the panel fully open', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final p = panel(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Second')),
    );
    final step = p.dragSpan * 0.7 / 6;
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(Offset(0, step));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      (ModalRoute.of(tester.element(find.byType(PanelBox)))! as BarPanelRoute)
          .animation!
          .value,
      lessThan(0.5),
    );
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(p.currentRect, p.panelRect);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('disposing a predictive gesture route stops the gesture', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PanelBox));
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context)!;
    await backGesture(tester, 'startBackGesture');
    await backGesture(tester, 'updateBackGestureProgress', 0.4);
    await tester.pump();
    expect(navigator.userGestureInProgress, isTrue);
    navigator.removeRoute(route);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    await backGesture(tester, 'commitBackGesture');
    await tester.pump();
    expect(navigator.userGestureInProgress, isFalse);
    expect(await result, isNull);
  });

  testWidgets('local history keeps the panel visible and focused', (
    tester,
  ) async {
    useView(tester);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final opener = FocusNode();
    addTearDown(opener.dispose);
    await tester.pumpWidget(
      _Harness(
        body: Center(
          child: TextButton(
            focusNode: opener,
            onPressed: () {},
            child: const Text('Opener'),
          ),
        ),
      ),
    );
    opener.requestFocus();
    await tester.pump();
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final panelContext = tester.element(find.byType(PanelBox));
    ModalRoute.of(panelContext)!.addLocalHistoryEntry(LocalHistoryEntry());
    Navigator.of(panelContext).pop();
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    expect(panel(tester).currentRect, panel(tester).panelRect);
    expect(
      FocusManager.instance.primaryFocus!.context!
          .findAncestorWidgetOfExactType<PanelBox>(),
      isNotNull,
    );
    Navigator.of(tester.element(find.byType(PanelBox))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('drag veto dialog restores the panel before another drag', (
    tester,
  ) async {
    useView(tester);
    final canPop = ValueNotifier(false);
    addTearDown(canPop.dispose);
    var popAttempted = false;
    var didPop = true;
    await tester.pumpWidget(const _Harness());
    final result = openPanel(
      tester,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: canPop,
        builder: (context, allowed, child) => PopScope<String>(
          canPop: allowed,
          onPopInvokedWithResult: (popped, _) {
            popAttempted = true;
            didPop = popped;
            if (!popped) {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  content: const Text('Keep editing?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Dismiss dialog'),
                    ),
                  ],
                ),
              );
            }
          },
          child: child!,
        ),
        child: defaultPanel(context),
      ),
    );
    await tester.pumpAndSettle();
    final p = panel(tester);
    await tester.timedDrag(
      find.text('Second'),
      Offset(0, p.dragSpan * 0.7),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(popAttempted, isTrue);
    expect(didPop, isFalse);
    expect(find.text('Keep editing?'), findsOneWidget);
    await tester.tap(find.text('Dismiss dialog'));
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    expect(p.currentRect, p.panelRect);
    canPop.value = true;
    await tester.pump();
    await tester.timedDrag(
      find.text('Second'),
      Offset(0, p.dragSpan * 0.7),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('focus moves into the panel, stays trapped and returns', (
    tester,
  ) async {
    useView(tester);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final opener = FocusNode();
    addTearDown(opener.dispose);
    await tester.pumpWidget(
      _Harness(
        body: Center(
          child: TextButton(
            focusNode: opener,
            onPressed: () {},
            child: const Text('Opener'),
          ),
        ),
      ),
    );
    opener.requestFocus();
    await tester.pump();
    final result = openPanel(tester);
    await tester.pumpAndSettle();

    bool insidePanel() =>
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<PanelBox>() !=
        null;

    expect(insidePanel(), isTrue);
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(insidePanel(), isTrue);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(opener.hasFocus, isTrue);
    expect(await result, isNull);
  });

  testWidgets('focus falls back when the opener is unmounted', (tester) async {
    useView(tester);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    final showOpener = ValueNotifier(true);
    addTearDown(showOpener.dispose);
    final opener = FocusNode();
    final fallback = FocusNode();
    addTearDown(opener.dispose);
    addTearDown(fallback.dispose);
    await tester.pumpWidget(
      _Harness(
        body: ValueListenableBuilder<bool>(
          valueListenable: showOpener,
          builder: (context, visible, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (visible)
                  TextButton(
                    focusNode: opener,
                    onPressed: () {},
                    child: const Text('Opener'),
                  ),
                TextButton(
                  focusNode: fallback,
                  autofocus: true,
                  onPressed: () {},
                  child: const Text('Fallback'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    opener.requestFocus();
    await tester.pump();
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    showOpener.value = false;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(fallback.hasFocus, isTrue);
    expect(await result, isNull);
  });

  testWidgets('semantics name the panel and the scrim, and hide the bar', (
    tester,
  ) async {
    useView(tester);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final labels = semanticsLabels(tester);
    expect(labels, contains('Create'));
    expect(labels, contains('Dismiss'));
    expect(labels.where((label) => label.contains('Behind')), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
    handle.dispose();
  });

  testWidgets(
    'panel controls keep their own semantics and the scrim can dismiss',
    (tester) async {
      useView(tester);
      await tester.pumpWidget(const _Harness());
      final result = openPanel(
        tester,
        semanticLabel: 'More',
        builder: (context) => Column(
          children: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            const TextField(decoration: InputDecoration(hintText: 'Search')),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < 20; i++)
                    ListTile(title: Text('Row $i'), onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
      final nodes = <({SemanticsNode node, Rect rect})>[];
      void visit(SemanticsNode node, Matrix4 toRoot) {
        final transform = node.transform == null
            ? toRoot
            : (toRoot.clone()..multiply(node.transform!));
        nodes.add((
          node: node,
          rect: MatrixUtils.transformRect(transform, node.rect),
        ));
        node.visitChildren((child) {
          visit(child, transform);
          return true;
        });
      }

      visit(owner.rootSemanticsNode!, Matrix4.identity());

      final field = nodes.singleWhere(
        (entry) => entry.node.getSemanticsData().flagsCollection.isTextField,
      );
      expect(field.node.label, 'Search');
      final fieldBounds = tester.getRect(find.byType(TextField)).inflate(0.5);
      expect(fieldBounds.contains(field.rect.topLeft), isTrue);
      expect(fieldBounds.contains(field.rect.bottomRight), isTrue);

      final close = nodes.singleWhere((entry) {
        final data = entry.node.getSemanticsData();
        return data.label == 'Close' || data.tooltip == 'Close';
      });
      final row = nodes.singleWhere((entry) => entry.node.label == 'Row 0');
      for (final entry in [close, row]) {
        expect(entry.node.isMergedIntoParent, isFalse);
        expect(
          entry.node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
      expect(
        tester.getRect(find.byTooltip('Close')).contains(close.rect.center),
        isTrue,
      );
      expect(
        tester
            .getRect(find.widgetWithText(ListTile, 'Row 0'))
            .contains(row.rect.center),
        isTrue,
      );

      final scrolling = nodes.where((entry) {
        final data = entry.node.getSemanticsData();
        return data.hasAction(SemanticsAction.scrollUp) ||
            data.hasAction(SemanticsAction.scrollDown);
      });
      expect(scrolling, hasLength(1));
      expectRect(scrolling.single.rect, tester.getRect(find.byType(ListView)));

      final dismiss = nodes.singleWhere(
        (entry) => entry.node.label == 'Dismiss',
      );
      expect(
        dismiss.node.getSemanticsData().hasAction(SemanticsAction.dismiss),
        isTrue,
      );
      owner.performAction(dismiss.node.id, SemanticsAction.dismiss);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(await result, isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('keyboard lifts the panel above the inset', (tester) async {
    useView(tester);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester, builder: fieldPanel);
    await tester.pumpAndSettle();
    final p = panel(tester);
    final before = p.panelRect.bottom;

    tester.view.viewInsets = FakeViewPadding(bottom: 300);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(p.panelRect.bottom, lessThanOrEqualTo(800 - 300));
    expect(p.panelRect.bottom, lessThan(before));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('docked layout spans the full width to the bottom edge', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness(layout: BottomBarLayout.docked()));
    final result = openPanel(tester);
    await tester.pump();
    final p = panel(tester);
    await tester.pumpAndSettle();
    expect(p.panelRect.width, 400);
    expect(p.panelRect.left, 0);
    expect(p.panelRect.bottom, 800);
    expect(p.currentRadius.bottomLeft, Radius.zero);
    expect(p.currentRadius.topLeft.x, 32);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, 'done');
  });

  testWidgets('docked panel without safe area keeps content height', (
    tester,
  ) async {
    useView(tester);
    tester.view.viewPadding = const FakeViewPadding(bottom: 30);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(
      const _Harness(layout: BottomBarLayout.docked(respectSafeArea: false)),
    );
    final result = openPanel(
      tester,
      builder: (_) => const SizedBox(height: 300),
    );
    await tester.pumpAndSettle();
    expect(panel(tester).panelRect.height, 300);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('RTL settles to the same panel rect as LTR', (tester) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    openPanel(tester);
    await tester.pumpAndSettle();
    final ltrRect = panel(tester).panelRect;
    await tester.pumpWidget(const SizedBox());

    await tester.pumpWidget(const _Harness(direction: TextDirection.rtl));
    openPanel(tester);
    await tester.pumpAndSettle();
    expectRect(panel(tester).panelRect, ltrRect);
  });

  testWidgets('rail panel is centred and grows from the rail', (tester) async {
    useView(tester, const Size(1000, 800));
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBarAdaptive(
          items: const BottomBarItems(
            selectedIndex: 0,
            onSelected: _ignoreIndex,
            children: [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
            ],
          ),
          body: const Center(child: Text('Body text')),
        ),
      ),
    );
    final railRect = outlineOf(
      tester,
      tester.renderObjectList<RenderBarSurface>(find.byType(BarSurface)).first,
    );
    final result = openPanel(
      tester,
      context: tester.element(find.text('Body text')),
    );
    await tester.pump();
    final p = panel(tester);
    expectRect(p.currentRect, railRect);
    await tester.pumpAndSettle();
    expect(p.panelRect.center.dx, closeTo(500, 1));
    expect(p.panelRect.width, lessThanOrEqualTo(560));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(await result, 'done');
  });

  testWidgets('ancestor-opened narrow adaptive panel follows the bar', (
    tester,
  ) async {
    useView(tester);
    late BuildContext outsideAdaptive;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            outsideAdaptive = context;
            return BottomBarAdaptive(
              layout: const BottomBarLayout.adaptive(maxWidth: 560),
              items: const BottomBarItems(
                selectedIndex: 0,
                onSelected: _ignoreIndex,
                children: [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                ],
              ),
              body: const Center(child: Text('Adaptive body')),
            );
          },
        ),
      ),
    );
    final barRect = outlineOf(tester, source(tester));
    final result = openPanel(tester, context: outsideAdaptive);
    await tester.pump();
    expect(panel(tester).currentRect, barRect);
    await tester.pumpAndSettle();
    expect(panel(tester).panelRect.width, closeTo(barRect.width, 0.5));
    expect(panel(tester).panelRect.left, closeTo(barRect.left, 0.5));
    expect(panel(tester).panelRect.bottom, closeTo(barRect.bottom, 0.5));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('adaptive panel follows a rail when the window widens', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBarAdaptive(
          layout: const BottomBarLayout.adaptive(maxWidth: 560),
          theme: BottomBarThemeData.glass(),
          items: const BottomBarItems(
            selectedIndex: 0,
            onSelected: _ignoreIndex,
            children: [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
            ],
          ),
          body: const Center(child: Text('Adaptive body')),
        ),
      ),
    );
    final result = openPanel(
      tester,
      context: tester.element(find.byType(BottomBarItems)),
    );
    await tester.pumpAndSettle();
    expect(panel(tester).panelRect.center.dx, closeTo(200, 1));

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pump();
    await tester.pumpAndSettle();
    final railSurfaces = tester.renderObjectList<RenderBarSurface>(
      find.byType(BarSurface),
    );
    expect(railSurfaces, hasLength(1));
    final railSurface = railSurfaces.single;
    expect(panel(tester).panelRect.center.dx, closeTo(500, 1));
    expect(panel(tester).panelRect.width, lessThanOrEqualTo(560));
    expect(railSurface.lift, isNotNull);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pump();
    await tester.pumpAndSettle();
    final compactSurface = source(tester);
    expect(panel(tester).panelRect.center.dx, closeTo(200, 1));
    expect(railSurface.lift, isNull);
    expect(compactSurface.lift, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(compactSurface.lift, isNull);
    expect(railSurface.lift, isNull);
    expect(tester.layers.whereType<BackdropFilterLayer>(), hasLength(1));
    expect(await result, isNull);
  });

  testWidgets('outer opener ignores a nested BottomBar in its body', (
    tester,
  ) async {
    useView(tester);
    const outerTrigger = ValueKey<String>('outer trigger');
    late BuildContext outerContext;
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          layout: const BottomBarLayout(width: 320),
          trailing: Builder(
            builder: (context) {
              outerContext = context;
              return const SizedBox(
                key: outerTrigger,
                width: 40,
                height: 40,
                child: Text('Open outer'),
              );
            },
          ),
          body: BottomBar(
            layout: const BottomBarLayout(width: 180),
            body: const Center(child: Text('Nested bar body')),
            child: const BottomBarItems(
              selectedIndex: 0,
              onSelected: _ignoreIndex,
              children: [
                BottomBarItem(
                  icon: Icon(Icons.home),
                  label: Text('Inner home'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.search),
                  label: Text('Inner search'),
                ),
              ],
            ),
          ),
          child: const BottomBarItems(
            selectedIndex: 0,
            onSelected: _ignoreIndex,
            children: [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Outer home')),
              BottomBarItem(
                icon: Icon(Icons.search),
                label: Text('Outer search'),
              ),
            ],
          ),
        ),
      ),
    );
    final outerSurface = surfaceFor(tester, find.byKey(outerTrigger));
    final outerRect = outlineOf(tester, outerSurface);
    final outerGroupRect = rectOf(groupFor(outerSurface));
    final result = openPanel(tester, context: outerContext);
    await tester.pump();
    expectRect(panel(tester).currentRect, outerRect);
    await tester.pumpAndSettle();
    expect(panel(tester).panelRect.width, closeTo(outerGroupRect.width, 0.5));
    expect(panel(tester).panelRect.left, closeTo(outerGroupRect.left, 0.5));
    expect(panel(tester).panelRect.bottom, closeTo(outerGroupRect.bottom, 0.5));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('reduced motion: no size morph, no glass lift, fades in place', (
    tester,
  ) async {
    useView(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pump();
    final p = panel(tester);
    expect(p.currentRect, p.panelRect);
    expect(source(tester).lift, isNull);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      ModalRoute.of(
        tester.element(find.byType(PanelBox)),
      )!.animation!.isCompleted,
      isTrue,
    );
    expect(p.currentRect, p.panelRect);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('mid-morph the bar lifts and only the panel paints glass', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    await tester.pump();
    expect(tester.layers.whereType<BackdropFilterLayer>().length, 1);
    final result = openPanel(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(source(tester).lift, isNotNull);
    expect(tester.layers.whereType<BackdropFilterLayer>().length, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('removing the source bar releases its lift layer', (
    tester,
  ) async {
    useView(tester);
    final showBar = ValueNotifier(true);
    addTearDown(showBar.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: showBar,
          builder: (context, visible, _) => visible
              ? BottomBar(
                  body: const Center(child: Text('Behind')),
                  child: BottomBarItems(
                    selectedIndex: 0,
                    onSelected: (_) {},
                    children: const [
                      BottomBarItem(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      BottomBarItem(
                        icon: Icon(Icons.search),
                        label: Text('Search'),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text('Bar removed')),
        ),
      ),
    );
    final oldSurface = source(tester);
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    expect(oldSurface.lift, isNotNull);
    showBar.value = false;
    await tester.pump();
    expect(oldSurface.attached, isFalse);
    expect(oldSurface.lift, isNull);
    oldSurface.lift = OffsetLayer();
    expect(oldSurface.lift, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('glass layers are released after the panel closes', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final initialBackdrops = tester.layers
        .whereType<BackdropFilterLayer>()
        .toList();
    expect(initialBackdrops, hasLength(1));
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    final openBackdrops = tester.layers
        .whereType<BackdropFilterLayer>()
        .toList();
    final panelBackdrop = openBackdrops.firstWhere(
      (layer) => !initialBackdrops.contains(layer),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    for (
      var frame = 0;
      frame < 100 && find.byType(PanelBox).evaluate().isNotEmpty;
      frame++
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(PanelBox), findsNothing);
    final backdropsOnRemovalFrame = tester.layers
        .whereType<BackdropFilterLayer>()
        .toList();
    expect(backdropsOnRemovalFrame, hasLength(1));
    expect(panelBackdrop.attached, isFalse);
    final baseBackdrop = backdropsOnRemovalFrame.single;
    await tester.pumpAndSettle();
    expect(
      tester.layers.whereType<BackdropFilterLayer>().single,
      same(baseBackdrop),
    );
    expect(await result, isNull);
    expect(tester.layers.whereType<BackdropFilterLayer>().length, 1);
    expect(source(tester).lift, isNull);
  });

  testWidgets('a solid bar opens a panel without any backdrop blur', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness(glass: false));
    final result = openPanel(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(source(tester).lift, isNotNull);
    expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(await result, isNull);
  });

  testWidgets('an unlaid bar reports a useful error then opens after layout', (
    tester,
  ) async {
    useView(tester);
    late BuildContext bodyContext;
    FlutterError? earlyError;
    var attemptedDuringBuild = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          body: Builder(
            builder: (context) {
              bodyContext = context;
              if (!attemptedDuringBuild) {
                attemptedDuringBuild = true;
                try {
                  showBottomBarPanel<void>(
                    context,
                    builder: (_) => const SizedBox(height: 100),
                  );
                } on FlutterError catch (error) {
                  earlyError = error;
                }
              }
              return const Center(child: Text('First layout'));
            },
          ),
          child: const BottomBarItems(
            selectedIndex: 0,
            onSelected: _ignoreIndex,
            children: [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
            ],
          ),
        ),
      ),
    );
    expect(earlyError, isNotNull);
    expect(earlyError!.message, contains('before its BottomBar was laid out'));
    final result = showBottomBarPanel<void>(
      bodyContext,
      builder: (_) => const SizedBox(height: 100),
    );
    var completed = false;
    result.then((_) => completed = true);
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsOneWidget);
    Navigator.of(bodyContext).pop();
    await tester.pumpAndSettle();
    expect(find.byType(PanelBox), findsNothing);
    expect(completed, isTrue);
  });

  testWidgets('throws when there is no BottomBar above or below the context', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(MaterialApp(home: const Text('x')));
    expect(
      () => showBottomBarPanel<void>(
        tester.element(find.text('x')),
        builder: defaultPanel,
      ),
      throwsA(isA<FlutterError>()),
    );
  });
}

void _ignoreIndex(int _) {}
