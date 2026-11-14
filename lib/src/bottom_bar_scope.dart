import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'bottom_bar_controller.dart';

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
    this._visibility,
    this._visibleHeight,
  });

  /// Live rendered layout footprint of the bar in logical pixels.
  ///
  /// The value includes the bar child, vertical [BottomBarLayout.offset]
  /// padding, and any bottom safe-area inset contributed by the bar wrapper.
  /// Starts at 0 for the first frame; updates after layout.
  ///
  /// It stays the full bar's footprint while the bar is hidden or minimized,
  /// so content padded by it never jumps. [visibleHeight] is what the bar
  /// covers right now.
  final ValueListenable<double> barHeight;

  /// Live visibility state — equivalent to `BottomBarController.isVisible`,
  /// but available without owning a controller. A minimized bar counts as
  /// visible.
  final ValueListenable<bool> isVisible;

  /// Live bar state: shown, minimized or hidden — equivalent to
  /// `BottomBarController.visibility`.
  ValueListenable<BottomBarVisibility> get visibility =>
      _visibility ?? _VisibilityFromBool(isVisible);
  final ValueListenable<BottomBarVisibility>? _visibility;

  /// How much of the screen's bottom the bar covers in its current state,
  /// in logical pixels, measured like [barHeight].
  ///
  /// [barHeight] while shown, 0 while hidden, and the height from the
  /// minimized pill's top edge down while minimized. It takes the new state's
  /// value when the state changes, not frame by frame during the animation.
  /// Use it for things that float above the bar, like a button; pad content
  /// with [barHeight] instead.
  ValueListenable<double> get visibleHeight => _visibleHeight ?? barHeight;
  final ValueListenable<double>? _visibleHeight;

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
        bottomInset != oldWidget.bottomInset ||
        _visibility != oldWidget._visibility ||
        _visibleHeight != oldWidget._visibleHeight;
  }
}

class _VisibilityFromBool implements ValueListenable<BottomBarVisibility> {
  _VisibilityFromBool(this._visible);

  final ValueListenable<bool> _visible;

  @override
  BottomBarVisibility get value =>
      _visible.value ? BottomBarVisibility.shown : BottomBarVisibility.hidden;

  @override
  void addListener(VoidCallback listener) => _visible.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _visible.removeListener(listener);
}
