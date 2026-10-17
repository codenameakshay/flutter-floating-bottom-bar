import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/visibility_animator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('semantics global bounds follow the child during a slide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      var progress = 1.0;
      late StateSetter updateProgress;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateProgress = setState;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      EdgeSlide(
                        start: const Offset(0, 2),
                        end: Offset.zero,
                        progress: progress,
                        child: Semantics(
                          label: 'sliding target',
                          child: const SizedBox(width: 40, height: 40),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      final target = find.bySemanticsLabel('sliding target');
      final stackTop = tester.getTopLeft(find.byType(Stack)).dy;
      expect(_globalSemanticsRect(tester.getSemantics(target)).top, 380);
      updateProgress(() => progress = 0.5);
      await tester.pump();
      expect(_globalSemanticsRect(tester.getSemantics(target)).top, 460);
      expect(stackTop, 300);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('partially shown public bar can be tapped where it is painted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    try {
      final controller = BottomBarController();
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              motion: const BottomBarMotion.curved(
                duration: Duration(milliseconds: 500),
                curve: Curves.linear,
              ),
              body: const SizedBox.expand(),
              child: Semantics(
                label: 'sliding bar button',
                button: true,
                child: SizedBox(
                  height: 56,
                  child: GestureDetector(
                    key: const Key('tap-target'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      controller.hide();
      await tester.pumpAndSettle();
      controller.show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final paintedRect = tester.getRect(find.byKey(const Key('tap-target')));
      final semanticRect = _globalSemanticsRect(
        tester.getSemantics(find.bySemanticsLabel('sliding bar button')),
      );
      expect(paintedRect.top, closeTo(795, 0.5));
      expect(semanticRect.top, closeTo(paintedRect.top, 0.5));
      expect(semanticRect.height, closeTo(56, 0.5));
      expect(paintedRect.contains(const Offset(200, 798)), isTrue);
      await tester.tapAt(const Offset(200, 798));

      expect(taps, 1);
      await tester.pump(const Duration(milliseconds: 150));
      final furtherShownRect = tester.getRect(
        find.byKey(const Key('tap-target')),
      );
      expect(furtherShownRect.top, closeTo(758.4, 0.5));
      expect(
        _globalSemanticsRect(
          tester.getSemantics(find.bySemanticsLabel('sliding bar button')),
        ).top,
        closeTo(furtherShownRect.top, 0.5),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('public negative vertical slide clears the top edge', (
    tester,
  ) async {
    final bounds = await _pumpHiddenEdge(
      tester,
      alignment: Alignment.topCenter,
      slideStart: const Offset(0, -2),
      direction: TextDirection.ltr,
    );
    expect(
      bounds.bar.bottom,
      closeTo(bounds.host.top - bounds.bar.height, 0.5),
    );
  });

  testWidgets(
    'public negative horizontal slide clears the physical left in RTL',
    (tester) async {
      final bounds = await _pumpHiddenEdge(
        tester,
        alignment: Alignment.centerRight,
        slideStart: const Offset(-2, 0),
        direction: TextDirection.rtl,
      );
      expect(
        bounds.bar.right,
        closeTo(bounds.host.left - bounds.bar.width, 0.5),
      );
    },
  );

  testWidgets('positive spring overshoot keeps slide geometry valid', (
    tester,
  ) async {
    final bounds = await _pumpOvershoot(tester, progress: 1.1);
    expect(bounds.child.top, closeTo(bounds.host.top + 64, 0.5));
  });

  testWidgets('negative spring overshoot keeps slide geometry valid', (
    tester,
  ) async {
    final bounds = await _pumpOvershoot(tester, progress: -0.1);
    expect(bounds.child.top, closeTo(bounds.host.top + 256, 0.5));
  });

  testWidgets('ancestor-only transform repaints a reused slide child', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(300, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const boundaryKey = Key('paint-boundary');
    final offset = ValueNotifier<Offset>(Offset.zero);
    addTearDown(offset.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: boundaryKey,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ValueListenableBuilder<Offset>(
                    valueListenable: offset,
                    child: const EdgeSlide(
                      start: Offset(0, 2),
                      end: Offset.zero,
                      progress: 0.5,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: ColoredBox(color: Color(0xFFFF0000)),
                      ),
                    ),
                    builder: (context, value, child) =>
                        Transform.translate(offset: value, child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final renderSlide = tester.renderObject<RenderEdgeSlide>(
      find.byType(EdgeSlide),
    );
    expect(await _hasRedPixelAt(tester, boundaryKey, 240, x: 150), isTrue);

    offset.value = const Offset(0, -40);
    await tester.pump();

    expect(tester.renderObject(find.byType(EdgeSlide)), same(renderSlide));
    expect(await _hasRedPixelAt(tester, boundaryKey, 240, x: 150), isFalse);
    expect(await _hasRedPixelAt(tester, boundaryKey, 200, x: 150), isTrue);
  });

  testWidgets('safe-area and keyboard changes update edge slide mid-flight', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const barKey = Key('bar-child');
    final controller = BottomBarController();

    const boundaryKey = Key('paint-boundary');
    Widget buildHarness(
      double keyboardInset, {
      double safePadding = 0,
      Size size = const Size(400, 800),
    }) {
      return MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(bottom: safePadding),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              body: BottomBar(
                controller: controller,
                motion: const BottomBarMotion.curved(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.linear,
                ),
                body: const SizedBox.expand(),
                child: const SizedBox(
                  key: barKey,
                  height: 54,
                  child: ColoredBox(color: Color(0xFFFF0000)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildHarness(0));
    controller.hide();
    await tester.pumpAndSettle();
    controller.show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final atRestInset = tester.getRect(find.byKey(barKey));
    expect(atRestInset.top, closeTo(795, 0.5));
    expect(await _hasRedPixelAt(tester, boundaryKey, 798), isTrue);

    await tester.pumpWidget(buildHarness(0, safePadding: 34));
    final afterSafeArea = tester.getRect(find.byKey(barKey));
    expect(afterSafeArea.top, closeTo(atRestInset.top - 17, 0.5));

    await tester.pumpWidget(buildHarness(120, safePadding: 34));
    final afterKeyboard = tester.getRect(find.byKey(barKey));
    expect(afterKeyboard.top, closeTo(afterSafeArea.top - 60, 0.5));
    expect(await _hasRedPixelAt(tester, boundaryKey, 798), isFalse);
    expect(await _hasRedPixelAt(tester, boundaryKey, 721), isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(barKey)).top, greaterThan(800));

    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpWidget(
      buildHarness(120, safePadding: 34, size: const Size(800, 400)),
    );
    final rotatedHost = tester.getRect(find.byType(Stack).first);
    final rotatedBar = tester.getRect(find.byKey(barKey));
    expect(rotatedHost.height, closeTo(400, 0.5));
    expect(rotatedBar.top, closeTo(454, 0.5));
  });
}

Future<({Rect host, Rect bar})> _pumpHiddenEdge(
  WidgetTester tester, {
  required Alignment alignment,
  required Offset slideStart,
  required TextDirection direction,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  const barKey = Key('bar-child');
  final controller = BottomBarController();
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            layout: BottomBarLayout(
              width: 120,
              alignment: alignment,
              respectSafeArea: false,
              avoidKeyboard: false,
            ),
            motion: BottomBarMotion.curved(
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
              slideStart: slideStart,
            ),
            body: const SizedBox.expand(),
            child: const SizedBox(key: barKey, width: 120, height: 40),
          ),
        ),
      ),
    ),
  );
  controller.hide();
  await tester.pumpAndSettle();
  return (
    host: tester.getRect(find.byType(Stack).first),
    bar: tester.getRect(find.byKey(barKey)),
  );
}

Future<({Rect host, Rect child})> _pumpOvershoot(
  WidgetTester tester, {
  required double progress,
}) async {
  const hostKey = Key('host-stack');
  const childKey = Key('sliding-child');
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          key: hostKey,
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              EdgeSlide(
                start: const Offset(0, 2),
                end: Offset.zero,
                progress: progress,
                child: const SizedBox(key: childKey, width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return (
    host: tester.getRect(find.byKey(hostKey)),
    child: tester.getRect(find.byKey(childKey)),
  );
}

Future<bool> _hasRedPixelAt(
  WidgetTester tester,
  Key boundaryKey,
  int y, {
  int x = 200,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  if (image == null) return false;
  try {
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    if (bytes == null) return false;
    final pixel = (y * image.width + x) * 4;
    return bytes.getUint8(pixel) > 200 &&
        bytes.getUint8(pixel + 1) < 30 &&
        bytes.getUint8(pixel + 2) < 30;
  } finally {
    image.dispose();
  }
}

Rect _globalSemanticsRect(SemanticsNode node) {
  final ancestors = <SemanticsNode>[];
  SemanticsNode? current = node;
  while (current != null) {
    ancestors.add(current);
    current = current.parent;
  }

  final transform = Matrix4.identity();
  for (final ancestor in ancestors.reversed) {
    final localTransform = ancestor.transform;
    if (localTransform != null) transform.multiply(localTransform);
  }
  return MatrixUtils.transformRect(transform, node.rect);
}
