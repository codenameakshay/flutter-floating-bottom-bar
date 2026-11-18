import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

RenderBarPanel panel(WidgetTester tester) =>
    tester.renderObject<RenderBarPanel>(find.byType(PanelBox));

RenderBarSurface source(WidgetTester tester) => tester
    .renderObjectList<RenderBarSurface>(find.byType(BarSurface))
    .firstWhere((surface) => surface.minimizeHost != null);

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
    this.body = const Center(child: Text('Behind')),
  });

  final BottomBarLayout? layout;
  final TextDirection direction;
  final bool glass;
  final BottomBarController? controller;
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
        motion: const BottomBarMotion.curved(
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
    expect(await result, isNull);
    handle.dispose();
  });

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
    expect(await result, isNull);
  });

  testWidgets('glass layers are released after the panel closes', (
    tester,
  ) async {
    useView(tester);
    await tester.pumpWidget(const _Harness());
    final result = openPanel(tester);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
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
    expect(await result, isNull);
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
