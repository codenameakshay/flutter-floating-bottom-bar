import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_group.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';

const _button = ValueKey('action');

Widget _harness(double t, TextDirection direction) => Directionality(
  textDirection: direction,
  child: Align(
    alignment: Alignment.topLeft,
    child: BarSurface(
      minimize: AlwaysStoppedAnimation(t),
      child: MinimizeHost(
        progress: AlwaysStoppedAnimation(t),
        minimized: false,
        full: const SizedBox(
          width: 300,
          height: 64,
          child: Center(
            child: CenterActionSlot(
              width: 56,
              lifted: true,
              notched: true,
              raise: 16,
              notchMargin: 4,
              child: SizedBox.square(key: _button, dimension: 56),
            ),
          ),
        ),
        compact: const SizedBox.square(dimension: 48),
      ),
    ),
  ),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('raised action follows full-content transform in $direction', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(0, direction));
      final host = tester.renderObject<RenderMinimizeHost>(
        find.byType(MinimizeHost),
      );
      final full = host.firstChild!;
      final button = tester.renderObject<RenderBox>(find.byKey(_button));
      final original = MatrixUtils.transformRect(
        button.getTransformTo(full),
        Offset.zero & button.size,
      );
      for (final t in [0.25, 0.5, 0.2, 0.0]) {
        await tester.pumpWidget(_harness(t, direction));
        final expected = MatrixUtils.transformRect(
          full.getTransformTo(null),
          original,
        );
        final actual = tester.getRect(find.byKey(_button));
        expect(actual.top, closeTo(expected.top, 0.001));
        expect(actual.left, closeTo(expected.left, 0.001));
        expect(actual.width, closeTo(expected.width, 0.001));
        expect(actual.height, closeTo(expected.height, 0.001));
      }
    });
  }
  for (final direction in TextDirection.values) {
    testWidgets(
      'interrupted group morph keeps pieces and hit regions in $direction',
      (tester) async {
        var fullTaps = 0;
        var bodyTaps = 0;
        Widget harness(double t) => Directionality(
          textDirection: direction,
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
                child: SizedBox(
                  width: 360,
                  child: BarGroup(
                    pillIndex: 1,
                    spacing: 8,
                    children: [
                      const SizedBox(
                        key: ValueKey('leading'),
                        width: 64,
                        height: 64,
                      ),
                      BarSurface(
                        minimize: AlwaysStoppedAnimation(t),
                        child: MinimizeHost(
                          progress: AlwaysStoppedAnimation(t),
                          minimized: false,
                          flushStart: true,
                          full: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => fullTaps++,
                            child: const SizedBox(height: 64),
                          ),
                          compact: const SizedBox.square(dimension: 48),
                        ),
                      ),
                      const SizedBox(
                        key: ValueKey('trailing'),
                        width: 64,
                        height: 64,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pumpWidget(harness(0));
        final leading = tester.getRect(find.byKey(const ValueKey('leading')));
        final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
        for (final t in [0.25, 0.5, 0.2, 0.0]) {
          await tester.pumpWidget(harness(t));
          expect(
            tester.getRect(find.byKey(const ValueKey('leading'))),
            leading,
          );
          expect(
            tester.getRect(find.byKey(const ValueKey('trailing'))),
            trailing,
          );
          final surface = tester.renderObject<RenderBarSurface>(
            find.byType(BarSurface),
          );
          final host = tester.renderObject<RenderMinimizeHost>(
            find.byType(MinimizeHost),
          );
          final full = host.firstChild!;
          final painted = MatrixUtils.transformRect(
            full.getTransformTo(null),
            Offset.zero & full.size,
          );
          final outline = MatrixUtils.transformRect(
            surface.getTransformTo(null),
            surface.outlineRect,
          );
          final before = fullTaps;
          await tester.tapAt(painted.center);
          expect(fullTaps, before + 1);
          final gap = direction == TextDirection.ltr
              ? leading.right + 4
              : leading.left - 4;
          final bodyBefore = bodyTaps;
          await tester.tapAt(Offset(gap, leading.center.dy));
          expect(bodyTaps, bodyBefore + 1);
          if (t > 0) {
            expect(painted.top, greaterThan(outline.top + 1));
            await tester.tapAt(Offset(outline.center.dx, outline.top + 1));
            expect(bodyTaps, bodyBefore + 2);
          }
        }
      },
    );
  }
}
