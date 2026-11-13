import 'dart:collection';

import 'package:flutter/widgets.dart';

/// Routes [ScrollNotification]s to a single visibility decision per scrollable.
///
/// Tracks per-scrollable last offset, applies a delta threshold, and calls
/// `onShouldHide(true)` when the bar should hide and `onShouldHide(false)`
/// when it should show. Also remembers each scrollable's [ScrollPosition] so
/// [activeScrollable] can pick the target for
/// `BottomBarController.scrollToStart`/`scrollToEnd`.
///
/// Bounded to 16 tracked scrollables. Evicts metrics-only sources before
/// the least recently scrolled source.
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

  _TrackedScrollState? _externalState;

  /// The most recently scrolled scrollable that is still attached and on
  /// stage, or `null` when there is none.
  ///
  /// Drops tracked scrollables that were disposed or got a new position.
  /// Skips ones hidden by an ancestor [Visibility] (such as an inactive
  /// [IndexedStack] child), an [Offstage], or a disabled [TickerMode] (such as
  /// a route covered by an opaque one). Before any visible list has scrolled,
  /// falls back to the most recently laid out visible list. The returned
  /// context lets callers locate an enclosing
  /// [NestedScrollView].
  ({ScrollPosition position, BuildContext context})? activeScrollable() {
    ({ScrollPosition position, BuildContext context})? fallback;
    for (final key in _trackedScrollables.keys.toList().reversed) {
      final state = _trackedScrollables[key]!;
      final position = state.position;
      final context = state.context;
      if (position == null || context == null) continue;
      if (!context.mounted ||
          !identical(Scrollable.maybeOf(context)?.position, position)) {
        _trackedScrollables.remove(key);
        continue;
      }
      if (position.hasPixels &&
          position.hasContentDimensions &&
          isPositionVisible(position)) {
        final active = (position: position, context: context);
        if (state.interacted) return active;
        fallback ??= active;
      }
    }
    return fallback;
  }

  static bool isPositionVisible(ScrollPosition position) {
    final context = position.context.notificationContext;
    return context != null &&
        context.mounted &&
        TickerMode.getValuesNotifier(context).value.enabled &&
        Visibility.of(context) &&
        _isOnstage(context);
  }

  static bool _isOnstage(BuildContext context) {
    var onstage = true;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) {
        onstage = false;
        return false;
      }
      return true;
    });
    return onstage;
  }

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

    final metrics = notification.metrics;
    if (notification is ScrollEndNotification) {
      // Coming to rest at the start shows the bar, unless [reverse] makes
      // scrolling toward the start the hide direction.
      if (showOnScrollEnd ||
          (!reverse && metrics.pixels <= metrics.minScrollExtent)) {
        onShouldHide(false);
      }
      return;
    }

    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollStartNotification) {
      return;
    }

    // Overscroll and its spring-back (BouncingScrollPhysics) aren't the user
    // scrolling: pin tracking to the edge so the rebound off the top doesn't
    // read as a scroll down.
    final pixels = metrics.pixels
        .clamp(metrics.minScrollExtent, metrics.maxScrollExtent)
        .toDouble();
    final state = _track(notification, pixels, touch: true);

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

    _handlePixels(state, pixels);
  }

  /// Tracks the scrollable that sent [notification] without changing the
  /// bar's visibility, so [activeScrollable] knows a list that has laid out
  /// but not scrolled yet. New sources are fallback targets until they scroll;
  /// a known source keeps its place in scroll recency order.
  void track(ScrollMetricsNotification notification) {
    final update = notification.asScrollUpdate();
    final filter = predicate;
    if (filter != null && !filter(update)) return;
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    _track(
      update,
      metrics.pixels
          .clamp(metrics.minScrollExtent, metrics.maxScrollExtent)
          .toDouble(),
      touch: false,
    );
  }

  _TrackedScrollState _track(
    ScrollNotification notification,
    double pixels, {
    required bool touch,
  }) {
    final context = notification.context;
    final position = context != null && context.mounted
        ? Scrollable.maybeOf(context)?.position
        : null;
    final key = _keyFor(notification, position);
    final known = _trackedScrollables[key];
    final state = touch || known == null
        ? (_trackedScrollables.remove(key) ??
              _TrackedScrollState(anchorPixels: pixels, lastPixels: pixels))
        : known;
    _trackedScrollables[key] = state
      ..position = position
      ..context = context
      ..interacted = state.interacted || touch;
    while (_trackedScrollables.length > _maxTracked) {
      final oldest = _trackedScrollables.keys.firstWhere(
        (key) => !_trackedScrollables[key]!.interacted,
        orElse: () => _trackedScrollables.keys.first,
      );
      _trackedScrollables.remove(oldest);
    }
    return state;
  }

  /// Reports a scroll delta from a source that never emits
  /// [ScrollNotification]s (e.g. an embedded WebView).
  ///
  /// [delta] is signed: positive moves toward the end (the usual hide
  /// direction), negative moves toward the start (the usual show direction).
  /// Applies the same [deltaThreshold]/[reverse] accumulation as [handle],
  /// but tracks its own independent accumulator: it never runs [predicate],
  /// never changes [activeScrollable], and does not share state with
  /// notification-tracked scrollables.
  void handleDelta(double delta) {
    if (delta == 0) return;

    final state = _externalState ??= _TrackedScrollState(
      anchorPixels: 0,
      lastPixels: 0,
    );
    _handlePixels(state, state.lastPixels + delta);
  }

  void _handlePixels(_TrackedScrollState state, double pixels) {
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

  void _resetState(_TrackedScrollState state, double pixels) {
    state
      ..anchorPixels = pixels
      ..lastPixels = pixels
      ..direction = null;
  }
}

class _TrackedScrollState {
  _TrackedScrollState({required this.anchorPixels, required this.lastPixels});

  double anchorPixels;
  double lastPixels;
  double? direction;
  bool interacted = false;
  ScrollPosition? position;
  BuildContext? context;
}
