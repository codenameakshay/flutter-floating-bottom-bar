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

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 30,
          context: context,
        ),
      );

      expect(events, isEmpty);
    });

    test('accumulates small deltas until the threshold is reached', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 3, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 6, context: context),
      );

      expect(events, isEmpty);

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 9, context: context),
      );

      expect(events, [isTrue]);
    });

    test('resets accumulation after crossing the threshold', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 3, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 6, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 9, context: context),
      );

      expect(events, [isTrue]);

      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 12,
          context: context,
        ),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 15,
          context: context,
        ),
      );

      expect(events, [isTrue]);

      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 18,
          context: context,
        ),
      );

      expect(events, [isTrue, isTrue]);
    });

    test('direction reversal resets the accumulated distance', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 3, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 6, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 4, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 7, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 10,
          context: context,
        ),
      );

      expect(events, isEmpty);
    });

    test('emits hide when delta exceeds threshold scrolling forward', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );
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

      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 100,
          context: context,
        ),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );

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
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 0,
          context: contextA,
        ),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 30,
          context: contextA,
        ),
      );
      // Scrollable B starts at 0 — switching tabs should not register a 30→0 jump.
      dispatcher.handle(
        _FakeUpdate(
          depth: 1,
          axis: Axis.vertical,
          pixels: 0,
          context: contextB,
        ),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 1,
          axis: Axis.vertical,
          pixels: 5,
          context: contextB,
        ),
      );

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

      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 500,
          context: contextA,
        ),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 0,
          context: contextB,
        ),
      );

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

    test('handleDelta absorbs deltas below threshold', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 50,
        onShouldHide: events.add,
      );

      dispatcher.handleDelta(30);

      expect(events, isEmpty);
    });

    test(
      'handleDelta accumulates positive deltas until crossing the threshold',
      () {
        final events = <bool>[];
        final dispatcher = ScrollNotificationDispatcher(
          deltaThreshold: 8,
          onShouldHide: events.add,
        );

        dispatcher.handleDelta(3);
        dispatcher.handleDelta(3);
        expect(events, isEmpty);

        dispatcher.handleDelta(3);
        expect(events, [isTrue]);
      },
    );

    test('handleDelta emits show after a direction reversal crosses the '
        'threshold', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );

      dispatcher.handleDelta(20);
      expect(events, [isTrue]);

      dispatcher.handleDelta(-20);
      expect(events, [isTrue, isFalse]);
    });

    test('handleDelta reverse=true inverts direction', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        reverse: true,
        onShouldHide: events.add,
      );

      dispatcher.handleDelta(20);

      expect(events, [isFalse]);
    });

    test('handle and handleDelta track independent accumulators', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        deltaThreshold: 8,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 0, context: context),
      );
      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 6, context: context),
      );
      expect(events, isEmpty);

      dispatcher.handleDelta(10);
      expect(events, [isTrue]);

      dispatcher.handle(
        _FakeUpdate(depth: 0, axis: Axis.vertical, pixels: 8, context: context),
      );
      expect(events, [isTrue, isTrue]);
    });

    test(
      'settling decisions reuse the predicate exactly once per notification',
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

        dispatcher.handle(
          _FakeUpdate(
            depth: 0,
            axis: Axis.vertical,
            pixels: 0,
            context: context,
          ),
        );
        dispatcher.handle(
          _FakeEnd(axis: Axis.vertical, pixels: 0, context: context),
        );

        expect(predicateCalls, 2);
        expect(events, isEmpty);
      },
    );

    test('ignores the spring-back from overscroll at the start', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(onShouldHide: events.add);
      final context = _DummyBuildContext();

      for (final pixels in [300.0, 0.0, -60.0, -30.0, -8.0, 0.0]) {
        dispatcher.handle(
          _FakeUpdate(
            depth: 0,
            axis: Axis.vertical,
            pixels: pixels,
            context: context,
          ),
        );
      }

      expect(events, [isFalse]);
    });

    test('scroll start overscrolled at the top does not count spring-back', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(onShouldHide: events.add);
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeStart(axis: Axis.vertical, pixels: -60, context: context),
      );
      for (final pixels in [-30.0, -8.0, 0.0]) {
        dispatcher.handle(
          _FakeUpdate(
            depth: 0,
            axis: Axis.vertical,
            pixels: pixels,
            context: context,
          ),
        );
      }

      expect(events, isEmpty);

      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 12,
          context: context,
        ),
      );

      expect(events, [isTrue]);
    });

    test('clamps updates when the scrollable has an infinite maximum', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(onShouldHide: events.add);
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 0,
          context: context,
          maxScrollExtent: double.infinity,
        ),
      );
      dispatcher.handle(
        _FakeUpdate(
          depth: 0,
          axis: Axis.vertical,
          pixels: 100,
          context: context,
          maxScrollExtent: double.infinity,
        ),
      );

      expect(events, [isTrue]);
    });

    test('ignores the spring-back from overscroll at the end', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(onShouldHide: events.add);
      final context = _DummyBuildContext();

      for (final pixels in [700.0, 1000.0, 1060.0, 1030.0, 1008.0, 1000.0]) {
        dispatcher.handle(
          _FakeUpdate(
            depth: 0,
            axis: Axis.vertical,
            pixels: pixels,
            context: context,
          ),
        );
      }

      expect(events, [isTrue]);
    });

    test('shows the bar when scrolling comes to rest at the start', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(onShouldHide: events.add);

      dispatcher.handle(_FakeEnd(axis: Axis.vertical, pixels: 120));
      expect(events, isEmpty);

      dispatcher.handle(_FakeEnd(axis: Axis.vertical, pixels: 0));
      expect(events, [isFalse]);
    });

    test('reverse does not show the bar at rest at the start', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        reverse: true,
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeEnd(axis: Axis.vertical, pixels: 0));

      expect(events, isEmpty);
    });

    test('predicate can reject the default ScrollEnd-at-start show', () {
      final events = <bool>[];
      var predicateCalls = 0;
      final dispatcher = ScrollNotificationDispatcher(
        predicate: (_) {
          predicateCalls += 1;
          return false;
        },
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeEnd(axis: Axis.vertical, pixels: 0));

      expect(predicateCalls, 1);
      expect(events, isEmpty);
    });

    test('showAtStart remains active with reverse during top overscroll', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        reverse: true,
        showAtStart: true,
        onShouldHide: events.add,
      );

      dispatcher.handle(_FakeStart(axis: Axis.vertical, pixels: -60));

      expect(events, [isFalse]);
    });

    test('showAtStart reports visible while starting in top overscroll', () {
      final events = <bool>[];
      final dispatcher = ScrollNotificationDispatcher(
        showAtStart: true,
        onShouldHide: events.add,
      );
      final context = _DummyBuildContext();

      dispatcher.handle(
        _FakeStart(axis: Axis.vertical, pixels: -60, context: context),
      );
      for (final pixels in [-30.0, -8.0, 0.0]) {
        dispatcher.handle(
          _FakeUpdate(
            depth: 0,
            axis: Axis.vertical,
            pixels: pixels,
            context: context,
          ),
        );
      }

      // showAtStart intentionally reports show at the start edge, including
      // during spring-back; the clamp prevents any intervening hide.
      expect(events, [isFalse, isFalse, isFalse, isFalse]);
    });

    test(
      'showOnScrollEnd takes precedence over reverse away from the start',
      () {
        final events = <bool>[];
        final dispatcher = ScrollNotificationDispatcher(
          reverse: true,
          showOnScrollEnd: true,
          onShouldHide: events.add,
        );

        dispatcher.handle(_FakeEnd(axis: Axis.vertical, pixels: 120));

        expect(events, [isFalse]);
      },
    );
  });
}

class _FakeUpdate extends ScrollUpdateNotification {
  _FakeUpdate({
    required int depth,
    required Axis axis,
    required double pixels,
    BuildContext? context,
    double maxScrollExtent = 1000,
  }) : super(
         metrics: FixedScrollMetrics(
           minScrollExtent: 0,
           maxScrollExtent: maxScrollExtent,
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

class _FakeStart extends ScrollStartNotification {
  _FakeStart({
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

class _FakeEnd extends ScrollEndNotification {
  _FakeEnd({required Axis axis, required double pixels, BuildContext? context})
    : super(
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
  bool get mounted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
