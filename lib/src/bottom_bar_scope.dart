import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Provides bar metadata to descendants of [BottomBar.body].
///
/// Use to read the live rendered bar height (for adding bottom padding to
/// scrollable content) and the current visibility state.
class BottomBarScope extends InheritedWidget {
  const BottomBarScope({
    super.key,
    required super.child,
    required this.barHeight,
    required this.isVisible,
  });

  /// Live rendered height of the bar in logical pixels. Starts at 0 for the
  /// first frame; updates after layout.
  final ValueListenable<double> barHeight;

  /// Live visibility state — equivalent to `BottomBarController.isVisible`,
  /// but available without owning a controller.
  final ValueListenable<bool> isVisible;

  static BottomBarScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(
      scope != null,
      'BottomBarScope.of() called outside of a BottomBar.body subtree.',
    );
    return scope!;
  }

  static BottomBarScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BottomBarScope>();
  }

  @override
  bool updateShouldNotify(BottomBarScope oldWidget) {
    return barHeight != oldWidget.barHeight || isVisible != oldWidget.isVisible;
  }
}
