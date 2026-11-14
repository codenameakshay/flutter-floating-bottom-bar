import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _horizontal = [
  Rect.fromLTWH(0, 0, 40, 30),
  Rect.fromLTWH(100, 0, 40, 30),
  Rect.fromLTWH(200, 0, 40, 30),
];
Rect _transpose(Rect rect) =>
    Rect.fromLTRB(rect.top, rect.left, rect.bottom, rect.right);
final _vertical = _horizontal.map(_transpose).toList();

IndicatorMotion _motion(Axis axis) => IndicatorMotion(
  vsync: const TestVSync(),
  index: 0,
  axis: axis,
  motion: const CupertinoMotion.snappy(duration: Duration(milliseconds: 450)),
);

void main() {
  for (final axis in Axis.values) {
    testWidgets('changing axis from $axis moves the stretch trailing edge', (
      tester,
    ) async {
      final targetAxis = axis == Axis.horizontal
          ? Axis.vertical
          : Axis.horizontal;
      final fromRects = axis == Axis.horizontal ? _horizontal : _vertical;
      final targetRects = axis == Axis.horizontal ? _vertical : _horizontal;
      final changed = _motion(axis)..stretch = true;
      final reference = _motion(targetAxis)..stretch = true;
      addTearDown(changed.dispose);
      addTearDown(reference.dispose);
      changed.resolve(fromRects);
      reference.resolve(targetRects);
      changed.animateTo(2);
      reference.animateTo(2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      changed.axis = targetAxis;
      expect(changed.resolve(targetRects), reference.resolve(targetRects));
      await tester.pumpAndSettle();
    });
  }

  for (final velocity in [-600.0, 600.0]) {
    testWidgets('vertical release carries velocity $velocity', (tester) async {
      final motion = _motion(Axis.vertical);
      addTearDown(motion.dispose);
      motion.resolve(_vertical);
      expect(motion.indexAt(120), 1);
      motion.follow(120);
      await tester.pumpAndSettle();
      expect(motion.resolve(_vertical), _vertical[1]);
      motion.release(1, velocity: velocity);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final displacement = motion.resolve(_vertical)!.center.dy - 120;
      expect(displacement * velocity, greaterThan(0));
      expect(displacement, closeTo(velocity / 1000, 0.05));
      await tester.pumpAndSettle();
      expect(motion.resolve(_vertical), _vertical[1]);
    });
  }
}
