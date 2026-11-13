import 'dart:collection';

import 'package:flutter/widgets.dart';

/// The tab a list sits in: the nearest [Visibility] above it with index 0
/// (how [IndexedStack] hides inactive children), or the nearest page host
/// with the page in view.
typedef ScrollTab = (Object anchor, int index);

typedef ActiveScrollable = ({
  ScrollPosition position,
  BuildContext context,
  ScrollTab? tab,
});

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
    this.restoreTabVisibility = false,
  });

  final ValueChanged<bool> onShouldHide;
  double deltaThreshold;
  bool reverse;
  bool showAtStart;
  bool showOnScrollEnd;
  bool Function(ScrollNotification)? predicate;

  /// When true, [enterTab] gives a tab back the visibility it had when the
  /// bar left it. When false, a new tab always shows the bar.
  bool restoreTabVisibility;

  static const int _maxTracked = 16;
  final LinkedHashMap<int, _TrackedScrollState> _trackedScrollables =
      LinkedHashMap<int, _TrackedScrollState>();

  _TrackedScrollState? _externalState;

  ScrollTab? _tab;
  final Expando<Map<int, bool>> _tabVisibility = Expando();

  /// The most recently scrolled scrollable that is still attached and in
  /// view, or `null` when there is none.
  ///
  /// Drops tracked scrollables that were disposed or got a new position.
  /// Skips ones hidden by an ancestor [Visibility] (such as an inactive
  /// [IndexedStack] child), an [Offstage], or a disabled [TickerMode] (such as
  /// a route covered by an opaque one), and ones on a page of a [PageView] or
  /// `TabBarView` that is not the page in view. Before any visible list has
  /// scrolled, falls back to the most recently laid out visible list. The
  /// returned context lets callers locate an enclosing [NestedScrollView].
  ActiveScrollable? activeScrollable() => resolve().active;

  /// [activeScrollable], plus whether it skipped a list because a page host
  /// above it was still moving. While [paging], the page in view is not
  /// known yet, so callers should keep what they show.
  ({ActiveScrollable? active, bool paging}) resolve() {
    ActiveScrollable? fallback;
    var paging = false;
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
      if (!position.hasPixels ||
          !position.hasContentDimensions ||
          !isPositionVisible(position)) {
        continue;
      }
      final page = _pagePlacement(position);
      if (page.moving) {
        paging = true;
        continue;
      }
      if (!page.inView) continue;
      final active = (position: position, context: context, tab: page.tab);
      if (state.interacted) return (active: active, paging: paging);
      fallback ??= active;
    }
    return (active: fallback, paging: paging);
  }

  /// Records [tab] as the tab the bar follows, with the bar at [barVisible].
  ///
  /// Returns `null` when the tab did not change. Otherwise returns the
  /// visibility the bar should take: `true`, or with [restoreTabVisibility]
  /// the visibility the bar had when it last left [tab].
  bool? enterTab(ScrollTab? tab, {required bool barVisible}) {
    final previous = _tab;
    if (tab == null || tab == previous) return null;
    _tab = tab;
    if (previous == null) return null;
    (_tabVisibility[previous.$1] ??= {})[previous.$2] = barVisible;
    return !restoreTabVisibility || (_tabVisibility[tab.$1]?[tab.$2] ?? true);
  }

  /// Content this close to a page host's edge still counts as inside it.
  static const double _pageTolerance = 1;

  /// Where [position]'s list sits among the page hosts above it: a
  /// [ScrollPosition] that is a [PageMetrics], as in [PageView] and
  /// `TabBarView`.
  ///
  /// [moving] is true while any page host above is scrolling. Otherwise
  /// [inView] is true when every page host shows the list in full along its
  /// axis. [tab] is the nearest [ScrollTab] above the list.
  static ({bool moving, bool inView, ScrollTab? tab}) _pagePlacement(
    ScrollPosition position,
  ) {
    final list = position.context.storageContext;
    var moving = false;
    var inView = true;
    ScrollTab? tab;
    list.visitAncestorElements((element) {
      if (element.widget is Visibility) {
        tab ??= (element, 0);
        return true;
      }
      if (element is! StatefulElement) return true;
      final host = element.state;
      if (host is! ScrollableState) return true;
      final hostPosition = host.position;
      if (hostPosition is! PageMetrics) return true;
      if (hostPosition.isScrollingNotifier.value) {
        moving = true;
        return false;
      }
      inView &= _showsInFull(host, list);
      final page = (hostPosition as PageMetrics).page;
      if (page != null) tab ??= (hostPosition, page.round());
      return true;
    });
    return (moving: moving, inView: inView, tab: tab);
  }

  /// Whether [list] lies inside [host]'s viewport along [host]'s axis.
  /// A kept-alive page that is off screen paints with a zero transform.
  static bool _showsInFull(ScrollableState host, BuildContext list) {
    final hostBox = host.context.findRenderObject();
    final listBox = list.findRenderObject();
    if (hostBox is! RenderBox ||
        listBox is! RenderBox ||
        !hostBox.hasSize ||
        !listBox.hasSize ||
        !listBox.attached) {
      return false;
    }
    final transform = listBox.getTransformTo(hostBox);
    if (transform.determinant() == 0) return false;
    final rect = MatrixUtils.transformRect(
      transform,
      Offset.zero & listBox.size,
    );
    final size = hostBox.size;
    return switch (host.position.axis) {
      Axis.horizontal =>
        rect.left >= -_pageTolerance &&
            rect.right <= size.width + _pageTolerance,
      Axis.vertical =>
        rect.top >= -_pageTolerance &&
            rect.bottom <= size.height + _pageTolerance,
    };
  }

  /// Whether a scroll of [position] may drive the bar: its list is visible
  /// and on the settled page in view.
  static bool _drives(ScrollPosition position) {
    if (!isPositionVisible(position)) return false;
    final page = _pagePlacement(position);
    return !page.moving && page.inView;
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

    // Only the list on the page in view drives the bar: not a kept-alive
    // page swiped away, an inactive tab, or any list while its page moves.
    final position = _positionOf(notification);
    if (position != null && !_drives(position)) return;

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
    final state = _track(notification, position, pixels, touch: true);

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
      _positionOf(update),
      metrics.pixels
          .clamp(metrics.minScrollExtent, metrics.maxScrollExtent)
          .toDouble(),
      touch: false,
    );
  }

  static ScrollPosition? _positionOf(ScrollNotification notification) {
    final context = notification.context;
    return context != null && context.mounted
        ? Scrollable.maybeOf(context)?.position
        : null;
  }

  _TrackedScrollState _track(
    ScrollNotification notification,
    ScrollPosition? position,
    double pixels, {
    required bool touch,
  }) {
    final context = notification.context;
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
