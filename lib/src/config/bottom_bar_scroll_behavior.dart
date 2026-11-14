import 'package:flutter/widgets.dart';

/// What [BottomBar] does with its visibility when the active tab changes.
///
/// See [BottomBarScrollBehavior.visibilityOnTabChange].
enum BottomBarTabVisibility {
  /// Shows the bar on every tab change.
  show,

  /// Gives the new tab the visibility it had when the user last left it.
  /// A tab seen for the first time shows the bar.
  restore,
}

/// When scrolling shrinks [BottomBar] into a compact pill instead of hiding
/// it, like iOS 26 `tabBarMinimizeBehavior`.
///
/// See [BottomBarScrollBehavior.minimizeBehavior].
enum BottomBarMinimizeBehavior {
  /// Scrolling never minimizes the bar. It hides it as [BottomBarScrollBehavior]
  /// says.
  never,

  /// Scrolling toward the end of the content minimizes the bar. Scrolling
  /// back toward the start expands it.
  onScrollDown,

  /// Scrolling toward the start of the content minimizes the bar. Scrolling
  /// toward the end expands it.
  onScrollUp,
}

/// Configuration for how [BottomBar] reacts to scrolling in its body subtree.
@immutable
class BottomBarScrollBehavior {
  const BottomBarScrollBehavior({
    this.hideOnScroll = true,
    this.reverse = false,
    this.scrollOpposite = false,
    this.deltaThreshold = 8,
    this.showAtStart = false,
    this.showOnScrollEnd = false,
    this.keepVisibleOnFocus = true,
    this.predicate,
    this.visibilityOnTabChange = BottomBarTabVisibility.show,
    this.minimizeBehavior = BottomBarMinimizeBehavior.never,
  }) : assert(deltaThreshold >= 0, 'deltaThreshold must be >= 0');

  /// When false, scroll events never hide the bar (the [BottomBarController]
  /// can still hide it imperatively).
  ///
  /// Ignored while [minimizeBehavior] is not [BottomBarMinimizeBehavior.never]:
  /// scrolling then minimizes the bar and never hides it.
  final bool hideOnScroll;

  /// When true, the relationship between scroll direction and visibility is
  /// inverted: scrolling down shows the bar, scrolling up hides it.
  ///
  /// Ignored while [minimizeBehavior] is not [BottomBarMinimizeBehavior.never],
  /// which sets the direction itself.
  final bool reverse;

  /// When true, the built-in hidden action scrolls toward
  /// `maxScrollExtent` instead of `minScrollExtent`.
  ///
  /// This affects only the hidden action's default direction, tooltip, and
  /// glyph. It does not change [BottomBarController.scrollToStart] or
  /// [BottomBarController.scrollToEnd].
  final bool scrollOpposite;

  /// The minimum |delta| in logical pixels required before a single
  /// `ScrollNotification` is allowed to flip visibility. Suppresses jitter.
  final double deltaThreshold;

  /// When true, reaching `minScrollExtent` forces the bar visible as soon as
  /// it happens, even mid-scroll and even with [reverse].
  ///
  /// Without it, a scroll that comes to rest at the start still shows the
  /// bar unless [reverse] is true. Direction tracking ignores overscroll
  /// past either end and its spring-back. [showAtStart] still forces the
  /// bar visible at or beyond the start.
  ///
  /// This runs after [predicate] filtering.
  final bool showAtStart;

  /// When true, [ScrollEndNotification] forces the bar visible.
  ///
  /// This runs after [predicate] filtering and is useful when the bar should
  /// reappear whenever scrolling settles.
  final bool showOnScrollEnd;

  /// When true, scroll-driven hide is skipped while the floating [BottomBar]
  /// child holds focus.
  ///
  /// [BottomBarController.hide] still hides the bar regardless of focus.
  /// This does not auto-show the bar when focus is gained.
  final bool keepVisibleOnFocus;

  /// Optional filter. When non-null, returning false skips the notification
  /// entirely (no offset tracking, no visibility change, and no start/end
  /// settling behavior).
  final bool Function(ScrollNotification notification)? predicate;

  /// What happens to the bar's visibility when the active tab changes.
  ///
  /// The bar sees a tab change when the list it follows moves to another
  /// tab: another [IndexedStack] child, or another page of a [PageView] or
  /// `TabBarView` once the swipe settles. Pushing a route inside a tab is not
  /// a tab change.
  ///
  /// [BottomBarTabVisibility.show] (the default) shows the bar.
  /// [BottomBarTabVisibility.restore] gives each tab back the visibility it
  /// had when the user left it.
  final BottomBarTabVisibility visibilityOnTabChange;

  /// Whether scrolling shrinks the bar into a compact pill instead of hiding
  /// it, like iOS 26 `tabBarMinimizeBehavior`.
  ///
  /// [BottomBarMinimizeBehavior.never] (the default) keeps the hide
  /// behaviour. Any other value takes precedence over [hideOnScroll] and
  /// [reverse]: scrolling in the named direction minimizes the bar, and
  /// scrolling the other way expands it. A scroll never minimizes a hidden
  /// bar. [showAtStart], [showOnScrollEnd], [keepVisibleOnFocus],
  /// [deltaThreshold] and [predicate] apply as they do to hiding, with
  /// "show" meaning "expand".
  ///
  /// The pill shows [BottomBar.compactChild], or the selected
  /// [BottomBarItem]'s icon when [BottomBar.child] is a [BottomBarItems] with
  /// a [BottomBarItems.selectedIndex]. With neither, the bar has no pill and
  /// hides instead.
  final BottomBarMinimizeBehavior minimizeBehavior;

  /// Returns a copy of this scroll behaviour with the given fields replaced by
  /// non-null values. Null arguments leave the corresponding field unchanged.
  BottomBarScrollBehavior copyWith({
    bool? hideOnScroll,
    bool? reverse,
    bool? scrollOpposite,
    double? deltaThreshold,
    bool? showAtStart,
    bool? showOnScrollEnd,
    bool? keepVisibleOnFocus,
    bool Function(ScrollNotification notification)? predicate,
    BottomBarTabVisibility? visibilityOnTabChange,
    BottomBarMinimizeBehavior? minimizeBehavior,
  }) {
    return BottomBarScrollBehavior(
      hideOnScroll: hideOnScroll ?? this.hideOnScroll,
      reverse: reverse ?? this.reverse,
      scrollOpposite: scrollOpposite ?? this.scrollOpposite,
      deltaThreshold: deltaThreshold ?? this.deltaThreshold,
      showAtStart: showAtStart ?? this.showAtStart,
      showOnScrollEnd: showOnScrollEnd ?? this.showOnScrollEnd,
      keepVisibleOnFocus: keepVisibleOnFocus ?? this.keepVisibleOnFocus,
      predicate: predicate ?? this.predicate,
      visibilityOnTabChange:
          visibilityOnTabChange ?? this.visibilityOnTabChange,
      minimizeBehavior: minimizeBehavior ?? this.minimizeBehavior,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BottomBarScrollBehavior &&
        other.hideOnScroll == hideOnScroll &&
        other.reverse == reverse &&
        other.scrollOpposite == scrollOpposite &&
        other.deltaThreshold == deltaThreshold &&
        other.showAtStart == showAtStart &&
        other.showOnScrollEnd == showOnScrollEnd &&
        other.keepVisibleOnFocus == keepVisibleOnFocus &&
        other.predicate == predicate &&
        other.visibilityOnTabChange == visibilityOnTabChange &&
        other.minimizeBehavior == minimizeBehavior;
  }

  @override
  int get hashCode => Object.hash(
    hideOnScroll,
    reverse,
    scrollOpposite,
    deltaThreshold,
    showAtStart,
    showOnScrollEnd,
    keepVisibleOnFocus,
    predicate,
    visibilityOnTabChange,
    minimizeBehavior,
  );
}
