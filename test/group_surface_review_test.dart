import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final opacity in [1.0, 0.5]) {
    testWidgets('a lone backdrop key preserves pixels at opacity $opacity', (
      tester,
    ) async {
      final boundary = GlobalKey();
      Future<List<int>> pixels(BackdropKey? key) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(
                key: boundary,
                child: SizedBox(
                  width: 180,
                  height: 100,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFCC3355), Color(0xFF22CC99)],
                      ),
                    ),
                    child: Center(
                      child: BarSurface(
                        backdropKey: key,
                        surface: const BottomBarSurface.glass(),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        fades: true,
                        visibility: AlwaysStoppedAnimation(opacity),
                        child: const SizedBox(width: 100, height: 60),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final image = (await tester.runAsync(
          () =>
              (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(),
        ))!;
        final bytes = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final result = bytes.buffer.asUint8List().toList();
        image.dispose();
        return result;
      }

      final independent = await pixels(null);
      expect(await pixels(BackdropKey()), independent);
    });
  }

  test('layout lerp steps infinite width without producing NaN', () {
    const finite = BottomBarLayout(width: 200);
    const infinite = BottomBarLayout.adaptive(maxWidth: 360);
    for (final t in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      expect(
        BottomBarLayout.lerp(finite, infinite, t)!.width,
        t < 0.5 ? 200 : double.infinity,
      );
      expect(
        BottomBarLayout.lerp(infinite, finite, t)!.width,
        t < 0.5 ? double.infinity : 200,
      );
    }
    expect(BottomBarLayout.lerp(infinite, infinite, 0.5), infinite);
  });

  test('layout lerp steps nullable maxWidth and interpolates finite caps', () {
    const uncapped = BottomBarLayout();
    const capped = BottomBarLayout(maxWidth: 360);
    expect(BottomBarLayout.lerp(uncapped, capped, 0.25)!.maxWidth, isNull);
    expect(BottomBarLayout.lerp(uncapped, capped, 0.5)!.maxWidth, 360);
    expect(BottomBarLayout.lerp(capped, uncapped, 0.25)!.maxWidth, 360);
    expect(BottomBarLayout.lerp(capped, uncapped, 0.5)!.maxWidth, isNull);
    expect(
      BottomBarLayout.lerp(
        capped,
        const BottomBarLayout(maxWidth: 200),
        0.5,
      )!.maxWidth,
      280,
    );
  });
}
