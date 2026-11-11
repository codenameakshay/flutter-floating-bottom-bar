import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _motion = CupertinoMotion.snappy(duration: Duration(milliseconds: 450));

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 1e-6));
  expect(actual.top, closeTo(expected.top, 1e-6));
  expect(actual.right, closeTo(expected.right, 1e-6));
  expect(actual.bottom, closeTo(expected.bottom, 1e-6));
}

void main() {
  for (final invalid in [-1, 3]) {
    testWidgets('invalid index $invalid recovers to a valid selection', (
      tester,
    ) async {
      final motion = IndicatorMotion(
        vsync: const TestVSync(),
        index: 0,
        motion: _motion,
      );
      addTearDown(motion.dispose);
      const rects = [
        Rect.fromLTWH(0, 0, 20, 20),
        Rect.fromLTWH(100, 0, 20, 20),
      ];
      motion.resolve(rects);
      motion.jumpTo(invalid);
      expect(motion.resolve(rects), isNull);
      motion.animateTo(1);
      await tester.pumpAndSettle();
      _expectRect(motion.resolve(rects)!, rects[1]);
    });
  }

  testWidgets('retarget preserves the current rect through an index blend', (
    tester,
  ) async {
    final motion = IndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: _motion,
    );
    addTearDown(motion.dispose);
    const rects = [
      Rect.fromLTWH(0, 5, 24, 20),
      Rect.fromLTWH(100, 0, 50, 30),
      Rect.fromLTWH(200, 10, 30, 10),
    ];
    motion.resolve(rects);
    motion.animateTo(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final before = motion.resolve(rects)!;
    motion.animateTo(1);
    _expectRect(motion.resolve(rects)!, before);
    final resized = rects
        .map(
          (r) => Rect.fromLTRB(
            r.left * 1.5 + 10,
            r.top * 2 + 5,
            r.right * 1.5 + 10,
            r.bottom * 2 + 5,
          ),
        )
        .toList();
    _expectRect(
      motion.resolve(resized)!,
      Rect.fromLTRB(
        before.left * 1.5 + 10,
        before.top * 2 + 5,
        before.right * 1.5 + 10,
        before.bottom * 2 + 5,
      ),
    );
    await tester.pumpAndSettle();
    expect(motion.settled, isTrue);
    _expectRect(motion.resolve(rects)!, rects[1]);
  });

  testWidgets('spring never produces a negative width when content shrinks', (
    tester,
  ) async {
    final motion = IndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: const CupertinoMotion.bouncy(extraBounce: 0.2),
    );
    addTearDown(motion.dispose);
    const rects = [Rect.fromLTWH(0, 0, 200, 24), Rect.fromLTWH(300, 0, 10, 24)];
    motion.resolve(rects);
    motion.animateTo(1);
    await tester.pump();
    var minimumWidth = double.infinity;
    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final rect = motion.resolve(rects)!;
      if (rect.width < minimumWidth) minimumWidth = rect.width;
    }
    _expectRect(motion.resolve(rects)!, rects[1]);
    expect(minimumWidth, greaterThanOrEqualTo(0));
  });

  for (final mirrored in [false, true]) {
    testWidgets(
      'stretch repeated retarget remains nonempty, mirror $mirrored',
      (tester) async {
        final motion = IndicatorMotion(
          vsync: const TestVSync(),
          index: 0,
          motion: _motion,
        )..stretch = true;
        addTearDown(motion.dispose);
        final rects =
            [
                  const Rect.fromLTWH(0, 0, 40, 24),
                  const Rect.fromLTWH(100, 0, 100, 24),
                  const Rect.fromLTWH(250, 0, 24, 24),
                  const Rect.fromLTWH(350, 0, 70, 24),
                ]
                .map(
                  (r) => mirrored
                      ? Rect.fromLTRB(
                          420 - r.right,
                          r.top,
                          420 - r.left,
                          r.bottom,
                        )
                      : r,
                )
                .toList();
        motion.resolve(rects);
        for (final index in [3, 0, 2, 1, 0, 3, 1, 2, 0, 1, 3, 2, 1, 0]) {
          final before = motion.resolve(rects)!;
          motion.animateTo(index);
          _expectRect(motion.resolve(rects)!, before);
          await tester.pump();
          for (var frame = 0; frame < 5; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
            final rect = motion.resolve(rects)!;
            expect(
              rect.width,
              greaterThanOrEqualTo(0),
              reason: 'to $index frame $frame $rect',
            );
          }
        }
        await tester.pumpAndSettle();
        expect(motion.settled, isTrue);
        _expectRect(motion.resolve(rects)!, rects[0]);
      },
    );
  }

  testWidgets('builder indicator stays valid when a bouncy spring shrinks it', (
    tester,
  ) async {
    final frames = <Rect>[];
    var lastSettled = false;
    Widget app(int selected) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            height: 64,
            child: BottomBarItems(
              selectedIndex: selected,
              indicatorMotion: const CupertinoMotion.bouncy(extraBounce: 0.2),
              indicator: BottomBarIndicator.builder((_, rect, settled) {
                frames.add(rect);
                lastSettled = settled;
                return const ColoredBox(color: Colors.red);
              }),
              children: const [
                BottomBarItem(icon: SizedBox(width: 200, height: 24)),
                BottomBarItem(
                  icon: SizedBox(key: Key('small-icon'), width: 10, height: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(1));
    for (var frame = 0; frame < 35; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'frame $frame');
    }
    await tester.pumpAndSettle();
    expect(lastSettled, isTrue);
    _expectRect(
      frames.last,
      tester
          .getRect(find.byKey(const Key('small-icon')))
          .shift(-tester.getTopLeft(find.byType(BottomBarItems))),
    );
    var minimumWidth = double.infinity;
    for (final rect in frames) {
      if (rect.width < minimumWidth) minimumWidth = rect.width;
      expect(rect.height, greaterThanOrEqualTo(0));
    }
    expect(minimumWidth, greaterThanOrEqualTo(0));
  });

  testWidgets('equal-width retarget carries horizontal velocity', (
    tester,
  ) async {
    final motion = IndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: _motion,
    );
    addTearDown(motion.dispose);
    const rects = [
      Rect.fromLTWH(0, 0, 24, 24),
      Rect.fromLTWH(100, 0, 24, 24),
      Rect.fromLTWH(200, 0, 24, 24),
    ];
    motion.resolve(rects);
    motion.animateTo(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final before = motion.resolve(rects)!.left;
    await tester.pump(const Duration(milliseconds: 1));
    final current = motion.resolve(rects)!.left;
    final delta = current - before;
    motion.animateTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    final after = motion.resolve(rects)!.left;
    expect(delta, greaterThan(0));
    expect(after - current, closeTo(delta, delta * .05));
    await tester.pumpAndSettle();
  });
}
