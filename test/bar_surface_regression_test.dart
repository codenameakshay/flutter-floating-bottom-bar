import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _surface(Animation<double> visibility) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: RepaintBoundary(
      child: BarSurface(
        surface: const BottomBarSurface.glass(),
        visibility: visibility,
        fades: true,
        child: const SizedBox(width: 100, height: 40),
      ),
    ),
  ),
);

class _TrackedAnimation extends AlwaysStoppedAnimation<double> {
  _TrackedAnimation() : super(1);

  int listeners = 0;

  @override
  void addListener(VoidCallback listener) => listeners++;

  @override
  void removeListener(VoidCallback listener) => listeners--;
}

void main() {
  for (final notched in [false, true]) {
    for (final opacity in [1.0, 0.5]) {
      testWidgets(
        'notch=$notched opacity=$opacity blur does not sample the surface shadow into its fill',
        (tester) async {
          final key = GlobalKey();
          Future<List<int>> sample(bool shadow) async {
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: RepaintBoundary(
                    key: key,
                    child: SizedBox(
                      width: 160,
                      height: 120,
                      child: ColoredBox(
                        color: const Color(0xFFFFFFFF),
                        child: Center(
                          child: BarSurface(
                            visibility: AlwaysStoppedAnimation(opacity),
                            fades: true,
                            surface: BottomBarSurface.glass(
                              tint: const Color(0xFFFFFFFF),
                              fillOpacity: 0.2,
                              edgeHighlight: null,
                              shadows: shadow
                                  ? const [
                                      BoxShadow(
                                        color: Color(0xFF000000),
                                        blurRadius: 12,
                                        spreadRadius: 10,
                                        offset: Offset(5, 5),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: notched
                                ? const SizedBox(
                                    width: 60,
                                    height: 20,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CenterActionSlot(
                                          width: 20,
                                          lifted: true,
                                          notched: true,
                                          raise: 10,
                                          notchMargin: 2,
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(width: 60, height: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final image = (await tester.runAsync(
              () =>
                  (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage(),
            ))!;
            final bytes = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final pixel = bytes.buffer
                .asUint8List((65 * 160 + 60) * 4, 4)
                .toList();
            image.dispose();
            return pixel;
          }

          final plain = await sample(false);
          expect(await sample(true), plain);
        },
      );
    }
  }

  testWidgets('swapping fade visibility repaints at the new opacity', (
    tester,
  ) async {
    await tester.pumpWidget(_surface(const AlwaysStoppedAnimation(0.5)));
    expect(tester.layers.whereType<OpacityLayer>().single.alpha, 128);
    tester.renderObject<RenderBarSurface>(find.byType(BarSurface)).visibility =
        const AlwaysStoppedAnimation(0.5);
    await tester.pump();
    tester.renderObject<RenderBarSurface>(find.byType(BarSurface)).visibility =
        const AlwaysStoppedAnimation(0.25);
    await tester.pump();
    expect(tester.layers.whereType<OpacityLayer>().single.alpha, 64);
  });

  for (final stop in ['surface', 'blur', 'visibility', 'child']) {
    testWidgets('$stop change releases unused backdrop handles before paint', (
      tester,
    ) async {
      await tester.pumpWidget(_surface(const AlwaysStoppedAnimation(0.5)));
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      final layers = tester.layers
          .where(
            (layer) => layer is BackdropFilterLayer || layer is ClipPathLayer,
          )
          .toList();
      switch (stop) {
        case 'surface':
          render.surface = null;
        case 'blur':
          render.surface = const BottomBarSurface.glass(blur: 0);
        case 'visibility':
          render.visibility = const AlwaysStoppedAnimation(0);
        case 'child':
          render.child = null;
      }
      for (final layer in layers) {
        expect(layer.debugHandleCount, 1);
      }
    });
  }

  testWidgets(
    'reattach updates compositing after detached visibility changes',
    (tester) async {
      final visibility = AnimationController(vsync: tester, value: 1);
      addTearDown(visibility.dispose);
      await tester.pumpWidget(_surface(visibility));
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      expect(render.needsCompositing, isTrue);
      final owner = render.owner!;
      final root = owner.rootNode!;
      root.detach();
      visibility.value = 0;
      root.attach(owner);
      await tester.pump();
      expect(render.needsCompositing, isFalse);
    },
  );

  for (final stop in ['shown', 'no fade', 'surface', 'child', 'hidden']) {
    testWidgets('$stop releases unused child opacity before paint', (
      tester,
    ) async {
      await tester.pumpWidget(_surface(const AlwaysStoppedAnimation(0.5)));
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      final opacity = tester.layers.whereType<OpacityLayer>().single;
      switch (stop) {
        case 'shown':
          render.visibility = const AlwaysStoppedAnimation(1);
        case 'no fade':
          render.fades = false;
        case 'surface':
          render.surface = null;
        case 'child':
          render.child = null;
        case 'hidden':
          render.visibility = const AlwaysStoppedAnimation(0);
      }
      expect(opacity.debugHandleCount, 1);
    });
  }

  testWidgets('reattach refreshes a fade changed while detached', (
    tester,
  ) async {
    final visibility = AnimationController(vsync: tester, value: 0.5);
    addTearDown(visibility.dispose);
    await tester.pumpWidget(_surface(visibility));
    final render = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    final owner = render.owner!;
    final root = owner.rootNode!;
    root.detach();
    visibility.value = 0.25;
    root.attach(owner);
    await tester.pump();
    expect(tester.layers.whereType<OpacityLayer>().single.alpha, 64);
  });

  testWidgets('visibility listeners balance across swaps and reattachment', (
    tester,
  ) async {
    final first = _TrackedAnimation();
    final second = _TrackedAnimation();
    await tester.pumpWidget(_surface(first));
    final render = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    expect(first.listeners, 1);
    render.visibility = second;
    expect(first.listeners, 0);
    expect(second.listeners, 1);
    final owner = render.owner!;
    final root = owner.rootNode!;
    for (var i = 0; i < 3; i++) {
      root.detach();
      expect(second.listeners, 0);
      root.attach(owner);
      expect(second.listeners, 1);
    }
    await tester.pumpWidget(const SizedBox());
    expect(first.listeners, 0);
    expect(second.listeners, 0);
  });

  testWidgets('detach releases retained surface layers', (tester) async {
    await tester.pumpWidget(_surface(const AlwaysStoppedAnimation(0.5)));
    final layers = tester.layers
        .where(
          (layer) =>
              layer is ClipPathLayer ||
              layer is BackdropFilterLayer ||
              layer is OpacityLayer,
        )
        .toList();
    final render = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    final owner = render.owner!;
    final root = owner.rootNode!;
    root.detach();
    for (final layer in layers) {
      expect(layer.debugHandleCount, 1);
    }
    root.attach(owner);
  });
}
