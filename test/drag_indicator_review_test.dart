import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _rects = [
  Rect.fromLTWH(0, 5, 30, 20),
  Rect.fromLTWH(100, 0, 50, 30),
  Rect.fromLTWH(220, 10, 20, 10),
];

IndicatorMotion _motion() => IndicatorMotion(
  vsync: const TestVSync(),
  index: 0,
  motion: const CupertinoMotion.snappy(duration: Duration(milliseconds: 450)),
);

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 1e-6));
  expect(actual.top, closeTo(expected.top, 1e-6));
  expect(actual.right, closeTo(expected.right, 1e-6));
  expect(actual.bottom, closeTo(expected.bottom, 1e-6));
}

void main() {
  testWidgets('animateTo the selected index ends an active drag', (
    tester,
  ) async {
    final motion = _motion();
    addTearDown(motion.dispose);
    motion.resolve(_rects);
    motion.follow(170);
    await tester.pumpAndSettle();
    expect(motion.dragging, isTrue);
    motion.animateTo(0);
    expect(motion.dragging, isFalse);
    await tester.pumpAndSettle();
    expect(motion.settled, isTrue);
    _expectRect(motion.resolve(_rects)!, _rects[0]);
  });

  for (final stretch in [false, true]) {
    testWidgets(
      'release preserves a partially followed rect, stretch $stretch',
      (tester) async {
        final motion = _motion()..stretch = stretch;
        addTearDown(motion.dispose);
        motion.resolve(_rects);
        motion.follow(170);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        final before = motion.resolve(_rects)!;
        motion.release(2, velocity: 500);
        _expectRect(motion.resolve(_rects)!, before);
        await tester.pumpAndSettle();
        expect(motion.settled, isTrue);
        _expectRect(motion.resolve(_rects)!, _rects[2]);
      },
    );
  }

  for (final stretch in [false, true]) {
    testWidgets(
      'retargeting an interrupted drag preserves its blend, stretch $stretch',
      (tester) async {
        final motion = _motion()..stretch = stretch;
        addTearDown(motion.dispose);
        motion.resolve(_rects);
        motion.animateTo(2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        final beforeDrag = motion.resolve(_rects)!;
        motion.follow(170);
        _expectRect(motion.resolve(_rects)!, beforeDrag);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        final beforeSelection = motion.resolve(_rects)!;
        motion.animateTo(1);
        expect(motion.dragging, isFalse);
        _expectRect(motion.resolve(_rects)!, beforeSelection);
        await tester.pumpAndSettle();
        _expectRect(motion.resolve(_rects)!, _rects[1]);
      },
    );
  }

  for (final stretch in [false, true]) {
    testWidgets(
      'a completed follow spring reaches the finger exactly, stretch $stretch',
      (tester) async {
        final motion = _motion()..stretch = stretch;
        addTearDown(motion.dispose);
        motion.resolve(_rects);
        motion.follow(_rects[1].center.dx);
        await tester.pumpAndSettle();
        expect(motion.settled, isFalse);
        _expectRect(motion.resolve(_rects)!, _rects[1]);
        motion.release(1, velocity: 600);
        await tester.pump();
        for (var frame = 0; frame < 20; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final rect = motion.resolve(_rects)!;
          expect(rect.width, greaterThanOrEqualTo(0));
          expect(rect.height, greaterThanOrEqualTo(0));
        }
        await tester.pumpAndSettle();
        _expectRect(motion.resolve(_rects)!, _rects[1]);
      },
    );
  }

  for (final mirrored in [false, true]) {
    for (final velocity in [-600.0, 600.0]) {
      testWidgets(
        'release at an item centre carries velocity $velocity, mirror $mirrored',
        (tester) async {
          final motion = _motion();
          addTearDown(motion.dispose);
          final rects = _rects
              .map(
                (rect) => mirrored
                    ? Rect.fromLTRB(
                        300 - rect.right,
                        rect.top,
                        300 - rect.left,
                        rect.bottom,
                      )
                    : rect,
              )
              .toList();
          motion.resolve(rects);
          motion.follow(rects[1].center.dx);
          await tester.pumpAndSettle();
          motion.release(1, velocity: velocity);
          _expectRect(motion.resolve(rects)!, rects[1]);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));
          final displacement =
              motion.resolve(rects)!.center.dx - rects[1].center.dx;
          expect(displacement * velocity, greaterThan(0));
          expect(displacement, closeTo(velocity / 1000, 0.05));
          await tester.pumpAndSettle();
          _expectRect(motion.resolve(rects)!, rects[1]);
        },
      );
    }
  }

  testWidgets('changing stretch during a drag preserves the current rect', (
    tester,
  ) async {
    final motion = _motion();
    addTearDown(motion.dispose);
    motion.resolve(_rects);
    motion.follow(170);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final before = motion.resolve(_rects)!;
    motion.stretch = true;
    expect(motion.dragging, isTrue);
    _expectRect(motion.resolve(_rects)!, before);
    motion.release(1);
    await tester.pumpAndSettle();
    _expectRect(motion.resolve(_rects)!, _rects[1]);
  });
}
