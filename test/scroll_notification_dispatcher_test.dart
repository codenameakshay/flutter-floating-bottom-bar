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
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 30,
        context: context,
      ));

      expect(events, isEmpty);
    });

    test('accumulates small deltas until the threshold is reached', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 3,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 6,
        context: context,
      ));

      expect(events, isEmpty);

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 9,
        context: context,
      ));

      expect(events, [isTrue]);
    });

    test('resets accumulation after crossing the threshold', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 3,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 6,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 9,
        context: context,
      ));

      expect(events, [isTrue]);

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 12,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 15,
        context: context,
      ));

      expect(events, [isTrue]);

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 18,
        context: context,
      ));

      expect(events, [isTrue, isTrue]);
    });

    test('direction reversal resets the accumulated distance', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 3,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 6,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 4,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 7,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 10,
        context: context,
      ));

      expect(events, isEmpty);
    });

    test('emits hide when delta exceeds threshold scrolling forward', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 120,
          context: context,
        ),
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
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 100,
        context: context,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));

      expect(events.last, isTrue);
    });

    test('tracks per-scrollable offsets independently', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 50,
        onShouldHide: events.add,
      );
      final contextA = _DummyBuildContext();
      final contextB = _DummyBuildContext();

      // Scrollable A advances by 30 (below threshold).
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: contextA,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 30,
        context: contextA,
      ));
      // Scrollable B starts at 0 — switching tabs should not register a 30→0 jump.
      dispatcher.handle(_FakeUpdate(
        depth: 1,
        axis: Axis.vertical,
        pixels: 0,
        context: contextB,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 1,
        axis: Axis.vertical,
        pixels: 5,
        context: contextB,
      ));

      expect(events, isEmpty);
    });

    test('does not share offsets for distinct contexts at the same depth', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 50,
        onShouldHide: events.add,
      );

      final contextA = _DummyBuildContext();
      final contextB = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 500,
        context: contextA,
      ));
      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: contextB,
      ));

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

    test('settling decisions reuse the predicate exactly once per notification',
        () {
      final events = <bool>[];
      var predicateCalls = 0;
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        showAtStart: true,
        showOnScrollEnd: true,
        predicate: (_) {
          predicateCalls += 1;
          return false;
        },
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(_FakeUpdate(
        depth: 0,
        axis: Axis.vertical,
        pixels: 0,
        context: context,
      ));
      dispatcher.handle(_FakeEnd(
        axis: Axis.vertical,
        pixels: 120,
        context: context,
      ));

      expect(predicateCalls, 2);
      expect(events, isEmpty);
    });
  });
}

class _FakeUpdate extends ScrollUpdateNotification {
  _FakeUpdate({
    required int depth,
    required Axis axis,
    required double pixels,
    BuildContext? context,
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
          context: context ?? _DummyBuildContext(),
          depth: depth,
        );
}

class _FakeEnd extends ScrollEndNotification {
  _FakeEnd({
    required Axis axis,
    required double pixels,
    BuildContext? context,
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
          context: context ?? _DummyBuildContext(),
        );
}

class _DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
