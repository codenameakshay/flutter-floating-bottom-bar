import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _TrackedAnimation extends AnimationController {
  _TrackedAnimation({required super.vsync}) : super(value: 0);

  int listeners = 0;

  @override
  void addListener(VoidCallback listener) {
    listeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners--;
    super.removeListener(listener);
  }
}

Future<List<int>> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(boundary.toImage))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final pixels = bytes.buffer.asUint8List().toList();
  image.dispose();
  return pixels;
}

Future<List<int>> _pixel(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Offset point,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(boundary.toImage))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final local = boundary.globalToLocal(point);
  final pixel = bytes.buffer
      .asUint8List((local.dy.floor() * image.width + local.dx.floor()) * 4, 4)
      .toList();
  image.dispose();
  return pixel;
}

void main() {
  testWidgets('capsule listeners balance on swaps, detach and reattach', (
    tester,
  ) async {
    final first = _TrackedAnimation(vsync: tester);
    final second = _TrackedAnimation(vsync: tester);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    Widget harness(Animation<double>? capsule) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: BarSurface(
          capsule: capsule,
          child: const SizedBox(width: 200, height: 48),
        ),
      ),
    );
    await tester.pumpWidget(harness(first));
    expect(first.listeners, 1);
    await tester.pumpWidget(harness(first));
    expect(first.listeners, 1);
    await tester.pumpWidget(harness(second));
    expect(first.listeners, 0);
    expect(second.listeners, 1);
    final render = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    final owner = render.owner!;
    final root = owner.rootNode!;
    root.detach();
    expect(second.listeners, 0);
    render.capsule = first;
    first.value = 1;
    expect(first.listeners, 0);
    root.attach(owner);
    await tester.pump();
    expect(first.listeners, 1);
    expect(render.outline.borderRadius, BorderRadius.circular(24));
    await tester.pumpWidget(harness(null));
    expect(first.listeners, 0);
    expect(render.outline.borderRadius, BorderRadius.zero);
    await tester.pumpWidget(harness(second));
    await tester.pumpWidget(const SizedBox());
    expect(second.listeners, 0);
  });

  for (final direction in TextDirection.values) {
    for (final glass in [false, true]) {
      testWidgets(
        'capsule repaints fill, border and shadow $direction glass=$glass',
        (tester) async {
          final progress = AnimationController(vsync: tester);
          addTearDown(progress.dispose);
          final actual = GlobalKey();
          final expected = GlobalKey();
          const radius = BorderRadiusDirectional.only(
            topStart: Radius.circular(4),
            topEnd: Radius.circular(16),
            bottomStart: Radius.circular(8),
          );
          const border = Border.fromBorderSide(
            BorderSide(color: Color(0xFFFF0000), width: 2),
          );
          const shadows = [
            BoxShadow(blurRadius: 4, spreadRadius: 2, offset: Offset(2, 3)),
          ];
          Widget sample(
            GlobalKey key,
            BorderRadiusGeometry radius, {
            Animation<double>? capsule,
          }) => RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 240,
              height: 100,
              child: Center(
                child: BarSurface(
                  capsule: capsule,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF00),
                    borderRadius: radius,
                    border: border,
                    boxShadow: shadows,
                  ),
                  surface: glass
                      ? const BottomBarSurface.glass(
                          tint: Color(0xFF00FF00),
                          border: border,
                          shadows: shadows,
                        )
                      : null,
                  child: const SizedBox(width: 200, height: 48),
                ),
              ),
            ),
          );
          await tester.pumpWidget(
            Directionality(
              textDirection: direction,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    sample(actual, radius, capsule: progress),
                    AnimatedBuilder(
                      animation: progress,
                      builder: (_, _) => sample(
                        expected,
                        BorderRadiusGeometry.lerp(
                          radius,
                          BorderRadius.circular(24),
                          progress.value,
                        )!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          for (final t in [0.0, 0.25, 0.5, 1.0, 0.5, 0.0]) {
            progress.value = t;
            await tester.pump();
            expect(
              await _pixels(tester, actual),
              await _pixels(tester, expected),
            );
          }
        },
      );
    }
  }

  testWidgets('capsule composes with minimize radius and closes its notch', (
    tester,
  ) async {
    for (final capsule in [null, 0.0, 0.5, 1.0]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: BarSurface(
              decoration: const BoxDecoration(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(8),
                ),
              ),
              minimize: const AlwaysStoppedAnimation(0.5),
              capsule: capsule == null ? null : AlwaysStoppedAnimation(capsule),
              child: MinimizeHost(
                progress: const AlwaysStoppedAnimation(0.5),
                minimized: false,
                full: const SizedBox(
                  width: 300,
                  height: 64,
                  child: Center(
                    child: CenterActionSlot(
                      width: 48,
                      lifted: true,
                      notched: true,
                      raise: 16,
                      notchMargin: 4,
                      child: SizedBox.square(dimension: 48),
                    ),
                  ),
                ),
                compact: const SizedBox.square(dimension: 48),
              ),
            ),
          ),
        ),
      );
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      final morphed = BorderRadiusGeometry.lerp(
        const BorderRadiusDirectional.only(topStart: Radius.circular(8)),
        BorderRadius.circular(24),
        0.5,
      )!;
      expect(
        render.outline.borderRadius.resolve(TextDirection.rtl),
        BorderRadiusGeometry.lerp(
          morphed,
          BorderRadius.circular(render.outlineRect.shortestSide / 2),
          capsule ?? 0,
        )!.resolve(TextDirection.rtl),
      );
      expect(render.outline.notch, isNotNull);
      render.minimize = const AlwaysStoppedAnimation(1);
      await tester.pump();
      expect(render.outline.notch, isNull);
    }
  });

  for (final layout in [
    const BottomBarLayout.docked(),
    BottomBarLayout(width: 360, borderRadius: BorderRadius.circular(999)),
    const BottomBarLayout(
      width: 360,
      directionalBorderRadius: BorderRadiusDirectional.only(
        topStart: Radius.circular(48),
      ),
    ),
  ]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'accessory content follows its capsule in $direction radius=${layout.directionalBorderRadius ?? layout.borderRadius}',
        (tester) async {
          tester.view
            ..physicalSize = const Size(400, 800)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final controller = BottomBarController();
          addTearDown(controller.dispose);
          final boundary = GlobalKey();
          var bodyTaps = 0;
          var accessoryTaps = 0;
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                home: Directionality(
                  textDirection: direction,
                  child: BottomBar(
                    controller: controller,
                    layout: layout,
                    motion: const BottomBarMotion.curved(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.linear,
                    ),
                    body: GestureDetector(
                      onTap: () => bodyTaps++,
                      child: const ColoredBox(
                        color: Colors.white,
                        child: SizedBox.expand(),
                      ),
                    ),
                    accessory: GestureDetector(
                      onTap: () => accessoryTaps++,
                      child: const ColoredBox(
                        color: Color(0xFF00FF00),
                        child: SizedBox(height: 56),
                      ),
                    ),
                    child: const BottomBarItems(
                      selectedIndex: 0,
                      children: [
                        BottomBarItem(
                          icon: Icon(Icons.home),
                          label: Text('Home'),
                        ),
                        BottomBarItem(
                          icon: Icon(Icons.person),
                          label: Text('Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final accessory = tester.renderObject<RenderBarSurface>(
            find.byKey(const ValueKey('accessory')),
          );
          Offset fromStart(Offset point) => accessory.localToGlobal(
            direction == TextDirection.ltr
                ? accessory.outlineRect.topLeft + point
                : accessory.outlineRect.topRight + Offset(-point.dx, point.dy),
          );
          Offset corner() => fromStart(const Offset(1, 1));
          final expandedCorner = layout.docked
              ? [0, 255, 0, 255]
              : [255, 255, 255, 255];
          expect(await _pixel(tester, boundary, corner()), expandedCorner);
          controller.minimize();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(await _pixel(tester, boundary, corner()), [
            255,
            255,
            255,
            255,
          ]);
          await tester.pumpAndSettle();
          expect(await _pixel(tester, boundary, corner()), [
            255,
            255,
            255,
            255,
          ]);
          expect(
            accessory.outline.borderRadius.resolve(direction),
            BorderRadius.circular(accessory.outlineRect.shortestSide / 2),
          );
          await tester.tapAt(corner());
          expect(bodyTaps, 1);
          expect(accessoryTaps, 0);
          await tester.tapAt(
            accessory.localToGlobal(accessory.outlineRect.center),
          );
          expect(accessoryTaps, 1);
          await tester.tapAt(fromStart(const Offset(10, 10)));
          expect(accessoryTaps, 2);
          controller.expand();
          await tester.pumpAndSettle();
          expect(await _pixel(tester, boundary, corner()), expandedCorner);
        },
      );
    }
  }

  testWidgets('capsule corners do not intercept body taps', (tester) async {
    var bodyTaps = 0;
    var accessoryTaps = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => bodyTaps++,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: BarSurface(
                capsule: const AlwaysStoppedAnimation(1),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => accessoryTaps++,
                  child: const SizedBox(width: 200, height: 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tapAt(const Offset(1, 1));
    expect(bodyTaps, 1);
    expect(accessoryTaps, 0);
    await tester.tapAt(const Offset(100, 24));
    expect(accessoryTaps, 1);
  });
}
