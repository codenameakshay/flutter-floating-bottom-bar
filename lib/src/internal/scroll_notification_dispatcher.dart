import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Routes [ScrollNotification]s to a single visibility decision per scrollable.
///
/// Tracks per-scrollable last offset, applies a delta threshold, and calls
/// `onShouldHide(true)` when the bar should hide and `onShouldHide(false)`
/// when it should show. Also tracks the most recently observed
/// [ScrollPosition] for `BottomBarController.scrollToStart`/`scrollToEnd`.
///
/// Bounded to 16 tracked scrollables (LRU eviction).
class ScrollNotificationDispatcher {
  ScrollNotificationDispatcher({
    required this.onShouldHide,
    this.deltaThreshold = 8,
    this.reverse = false,
    this.predicate,
  });

  final ValueChanged<bool> onShouldHide;
  double deltaThreshold;
  bool reverse;
  bool Function(ScrollNotification)? predicate;

  static const int _maxTracked = 16;
  final LinkedHashMap<int, double> _lastOffsets = LinkedHashMap<int, double>();

  ScrollPosition? _lastActivePosition;
  ScrollPosition? get lastActivePosition => _lastActivePosition;

  int _keyFor(ScrollNotification n, ScrollPosition? position) {
    if (position != null) return identityHashCode(position);
    final context = n.context;
    if (context != null) return identityHashCode(context);
    return Object.hash(n.depth, n.metrics.axis);
  }

  void handle(ScrollNotification notification) {
    final filter = predicate;
    if (filter != null && !filter(notification)) return;

    // Bottom bar visibility is driven by vertical scrolls only. Horizontal
    // scrolls (e.g. PageView/TabBarView between siblings) must not be allowed
    // to flip visibility.
    if (notification.metrics.axis != Axis.vertical) return;

    if (notification is ScrollEndNotification) {
      // Optional: keep history; do not evict here so subsequent updates from
      // the same scrollable retain their tracked offset.
      return;
    }

    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollStartNotification) {
      return;
    }

    final position = _maybePositionOf(notification);
    _lastActivePosition = position;
    final key = _keyFor(notification, position);

    final pixels = notification.metrics.pixels;
    final previous = _lastOffsets[key];

    // LRU touch.
    _lastOffsets.remove(key);
    _lastOffsets[key] = pixels;

    // Evict oldest if over capacity.
    while (_lastOffsets.length > _maxTracked) {
      _lastOffsets.remove(_lastOffsets.keys.first);
    }

    if (previous == null) return; // first sample, no decision yet.

    final delta = pixels - previous;
    if (delta.abs() < deltaThreshold) return;

    final shouldHide = reverse ? delta < 0 : delta > 0;
    onShouldHide(shouldHide);
  }

  ScrollPosition? _maybePositionOf(ScrollNotification n) {
    final ctx = n.context;
    if (ctx == null) return _lastActivePosition;
    try {
      return Scrollable.maybeOf(ctx)?.position;
    } catch (_) {
      return _lastActivePosition;
    }
  }
}
