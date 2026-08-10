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
    this.showAtStart = false,
    this.showOnScrollEnd = false,
    this.predicate,
  });

  final ValueChanged<bool> onShouldHide;
  double deltaThreshold;
  bool reverse;
  bool showAtStart;
  bool showOnScrollEnd;
  bool Function(ScrollNotification)? predicate;

  static const int _maxTracked = 16;
  final LinkedHashMap<int, _TrackedScrollState> _trackedScrollables =
      LinkedHashMap<int, _TrackedScrollState>();

  ScrollPosition? _lastActivePosition;
  ScrollPosition? get lastActivePosition => _lastActivePosition;

  BuildContext? _lastActiveContext;

  /// The [BuildContext] of the most recently active scrollable.
  ///
  /// Used by `BottomBarController.scrollToStart`/`scrollToEnd` to locate an
  /// enclosing [NestedScrollView], whose header and body scroll on two
  /// coordinated [ScrollPosition]s that must both be animated to fully return
  /// to the top.
  BuildContext? get lastActiveContext => _lastActiveContext;

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
      if (showOnScrollEnd) {
        onShouldHide(false);
      }
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
    _lastActiveContext = notification.context;
    final key = _keyFor(notification, position);
    final pixels = notification.metrics.pixels;

    // LRU touch.
    final state = _trackedScrollables.remove(key) ??
        _TrackedScrollState(anchorPixels: pixels, lastPixels: pixels);
    _trackedScrollables[key] = state;

    // Evict oldest if over capacity.
    while (_trackedScrollables.length > _maxTracked) {
      _trackedScrollables.remove(_trackedScrollables.keys.first);
    }

    if (notification is ScrollStartNotification) {
      _resetState(state, pixels);

      if (showAtStart && pixels <= notification.metrics.minScrollExtent) {
        onShouldHide(false);
      }
      return;
    }

    if (showAtStart && pixels <= notification.metrics.minScrollExtent) {
      _resetState(state, pixels);
      onShouldHide(false);
      return;
    }

    final delta = pixels - state.lastPixels;
    state.lastPixels = pixels;
    if (delta == 0) return;

    final direction = delta.sign;
    if (state.direction != direction) {
      state
        ..anchorPixels = state.lastPixels - delta
        ..direction = direction;
    }

    final accumulatedDelta = pixels - state.anchorPixels;
    if (accumulatedDelta.abs() < deltaThreshold) return;

    final shouldHide = reverse ? accumulatedDelta < 0 : accumulatedDelta > 0;
    state.anchorPixels = pixels;
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

  void _resetState(_TrackedScrollState state, double pixels) {
    state
      ..anchorPixels = pixels
      ..lastPixels = pixels
      ..direction = null;
  }
}

class _TrackedScrollState {
  _TrackedScrollState({
    required this.anchorPixels,
    required this.lastPixels,
  });

  double anchorPixels;
  double lastPixels;
  double? direction;
}
