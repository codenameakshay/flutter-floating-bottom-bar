import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Provides bar metadata to descendants of [BottomBar.body].
///
/// Use to read the live rendered bar footprint (for adding bottom padding to
/// scrollable content) and the current visibility state.
class BottomBarScope extends InheritedWidget {
  const BottomBarScope({
    super.key,
    required super.child,
    required this.barHeight,
    required this.isVisible,
    this.bottomInset = 0,
  });

  /// Live rendered layout footprint of the bar in logical pixels.
  ///
  /// The value includes the bar child, vertical [BottomBarLayout.offset]
  /// padding, and any bottom safe-area inset contributed by the bar wrapper.
  /// Starts at 0 for the first frame; updates after layout.
  final ValueListenable<double> barHeight;

  /// Live visibility state — equivalent to `BottomBarController.isVisible`,
  /// but available without owning a controller.
  final ValueListenable<bool> isVisible;

  /// The bottom safe-area inset that [barHeight] includes, in logical pixels.
  ///
  /// Zero when [BottomBarLayout.respectSafeArea] is false, when an ancestor
  /// `SafeArea` already removed the inset, or while the keyboard covers it.
  /// [BottomBarBodyPadding] uses it to reserve the inset exactly once.
  final double bottomInset;

  /// Returns the nearest [BottomBarScope] ancestor.
  ///
  /// The widget returned is the one inserted by [BottomBar] around [BottomBar.body],
  /// so this must only be called from within the [BottomBar.body] subtree.
  ///
  /// Asserts in debug mode if called outside a [BottomBar.body] subtree. Use
  /// [maybeOf] for a null-safe variant.
  static BottomBarScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'BottomBarScope.of() called outside of a BottomBar.body subtree.',
    );
    return scope!;
  }

  /// Returns the nearest [BottomBarScope] ancestor, or `null` if there is none.
  ///
  /// Prefer [of] inside [BottomBar.body] where the scope is guaranteed to exist.
  static BottomBarScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BottomBarScope>();
  }

  @override
  bool updateShouldNotify(BottomBarScope oldWidget) {
    return barHeight != oldWidget.barHeight ||
        isVisible != oldWidget.isVisible ||
        bottomInset != oldWidget.bottomInset;
  }
}
