import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_floating_bottom_bar/src/internal/scroll_notification_dispatcher.dart';

void main() {
  group('ScrollNotificationDispatcher', () {
    test('absorbs deltas below threshold', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 50,
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0));
      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 30));

      expect(events, isEmpty);
    });

    test('emits hide when delta exceeds threshold scrolling forward', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0));
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 120),
      );

      expect(events.last, isTrue);
    });

    test('reverse=true inverts direction', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        reverse: true,
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 100));
      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0));

      expect(events.last, isTrue);
    });

    test('tracks per-scrollable offsets independently', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 50,
        onShouldHide: events.add,
      );

      // Scrollable A advances by 30 (below threshold).
      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0));
      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 30));
      // Scrollable B starts at 0 — switching tabs should not register a 30→0 jump.
      dispatcher.handle(_FakeUpdate(depth: 1, axis: Axis.vertical, pixels: 0));
      dispatcher.handle(_FakeUpdate(depth: 1, axis: Axis.vertical, pixels: 5));

      expect(events, isEmpty);
    });

    test('predicate returning false skips the notification entirely', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        predicate: (_) => false,
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0));
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 200),
      );

      expect(events, isEmpty);
    });
  });
}

class _FakeUpdate extends ScrollUpdateNotification {
  _FakeUpdate({
    required int depth,
    required Axis axis,
    required double pixels,
  }) : super(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 1000,
            pixels: pixels,
            viewportDimension: 600,
            axisDirection: axis == Axis.vertical
                ? AxisDirection.down
                : AxisDirection.right,
            devicePixelRatio: 1.0,
          ),
          context: _DummyBuildContext(),
          depth: depth,
        );
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
