import 'package:flutter/foundation.dart';

import 'bottom_bar.dart';

/// Where a [BottomBar] is: full size, shrunk into its compact pill, or
/// hidden.
///
/// See [BottomBarController.visibility] and [BottomBarScope.visibility].
enum BottomBarVisibility {
  /// The full bar is on screen.
  shown,

  /// The bar is shrunk into its compact pill, like an iOS 26 tab bar that
  /// minimized on scroll. See [BottomBarScrollBehavior.minimizeBehavior].
  minimized,

  /// The bar is off screen.
  hidden,
}

/// Imperative controller for [BottomBar].
///
/// Lets you show, hide, or toggle the bar programmatically, or scroll the
/// most-recently-active scrollable inside [BottomBar.body] to its start or end.
///
/// Attach the controller to a [BottomBar] via [BottomBar.controller]. A single
/// controller may only be attached to one live bar at a time. A second
/// attachment fails in both debug and release and leaves the original bar
/// binding in place.
///
/// Remember to [dispose] the controller when it is no longer needed.
///
/// ```dart
/// final _controller = BottomBarController();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// BottomBar(controller: _controller, ...)
/// ```
class BottomBarController extends ChangeNotifier {
  BottomBarBindingForController? _binding;
  final ValueNotifier<BottomBarVisibility> _visibility = ValueNotifier(
    BottomBarVisibility.shown,
  );

  /// Whether the attached bar is not [BottomBarVisibility.hidden]. A
  /// minimized bar counts as visible.
  ///
  /// Reflects the last value set by [show], [hide], or [toggle]. Also updated
  /// automatically when scroll-based hide/show changes the bar state. Updates
  /// are accepted only from the currently attached bar.
  bool get isVisible => _visibility.value != BottomBarVisibility.hidden;

  /// The attached bar's state: shown, minimized or hidden.
  ///
  /// Updates with the bar, from scrolling and from this controller. This
  /// controller also notifies its own listeners on every change.
  ValueListenable<BottomBarVisibility> get visibility => _visibility;

  /// Whether this controller is currently attached to a live [BottomBar].
  ///
  /// [show], [hide], [toggle], [reportScroll], [scrollToStart], and
  /// [scrollToEnd] are no-ops when [isAttached] is `false`.
  bool get isAttached => _binding != null;

  /// Shows the full bar, animating it into view if it is hidden and
  /// expanding it if it is minimized.
  ///
  /// No-op if the bar is already shown or the controller is not attached.
  void show() => _binding?.requestVisible(true);

  /// Hides the bar, animating it out of view.
  ///
  /// No-op if the bar is already hidden or the controller is not attached.
  void hide() => _binding?.requestVisible(false);

  /// Shrinks the bar into its compact pill, from shown or hidden, whatever
  /// [BottomBarScrollBehavior.minimizeBehavior] says.
  ///
  /// A bar with no pill hides instead: see
  /// [BottomBarScrollBehavior.minimizeBehavior]. No-op if the bar is already
  /// minimized or the controller is not attached.
  void minimize() {
    if (_binding case final BottomBarVisibilityBinding binding) {
      binding.requestVisibility(BottomBarVisibility.minimized);
    }
  }

  /// Expands a minimized bar back to full size.
  ///
  /// No-op unless the bar is minimized. Use [show] to bring back a hidden
  /// bar.
  void expand() {
    if (_visibility.value == BottomBarVisibility.minimized) show();
  }

  /// Toggles bar visibility — shows if hidden, hides if visible. A minimized
  /// bar counts as visible.
  void toggle() {
    if (isVisible) {
      hide();
    } else {
      show();
    }
  }

  /// Reports a scroll delta from a source that does not emit
  /// [ScrollNotification]s, such as an embedded WebView.
  ///
  /// [delta] is signed: positive moves toward the end (the usual "hide"
  /// direction), negative moves toward the start (the usual "show"
  /// direction) — for example `newPixels - oldPixels` from the WebView's own
  /// scroll callback. Drives the same threshold/reverse/
  /// [BottomBarScrollBehavior.hideOnScroll] visibility rules as body
  /// [ScrollNotification]s.
  ///
  /// This only affects visibility. It never affects [scrollToStart] or
  /// [scrollToEnd], which require a real [ScrollPosition] to have been
  /// observed via a [ScrollNotification] first.
  ///
  /// No-op if the controller is not attached.
  void reportScroll({required double delta}) =>
      _binding?.reportScroll(delta: delta);

  /// Animates the most-recently-active scrollable inside [BottomBar.body] to
  /// its [ScrollPosition.minScrollExtent] (i.e. the start/top boundary).
  ///
  /// This always targets the minimum extent. It is not affected by
  /// [BottomBarScrollBehavior.scrollOpposite], which only changes the built-in
  /// hidden action's direction.
  ///
  /// The target is the visible list that scrolled last, or before any list
  /// scrolls, the visible list that laid out last. Inside a [PageView] or
  /// `TabBarView` only the page in view counts. Lists that were disposed, or
  /// that sit in an inactive [IndexedStack] child, a covered route, or a page
  /// swiped away, are skipped. Does nothing when there is no such list.
  Future<void> scrollToStart() async {
    await _binding?.scrollToBoundary(toEnd: false);
  }

  /// Animates the most-recently-active scrollable inside [BottomBar.body] to
  /// its [ScrollPosition.maxScrollExtent] (i.e. the end/bottom boundary).
  ///
  /// This always targets the maximum extent. It is not affected by
  /// [BottomBarScrollBehavior.scrollOpposite], which only changes the built-in
  /// hidden action's direction.
  ///
  /// Picks its list like [scrollToStart]. Does nothing when there is no list.
  Future<void> scrollToEnd() async {
    await _binding?.scrollToBoundary(toEnd: true);
  }

  /// @nodoc — called by [BottomBar] when it mounts or the controller changes.
  void attach(BottomBarBindingForController binding) {
    if (_binding == binding) {
      return;
    }
    if (_binding != null) {
      throw FlutterError(
        'BottomBarController is already attached to a BottomBar. '
        'A controller may only drive one BottomBar at a time.',
      );
    }
    _binding = binding;
    _update(binding, switch (binding) {
      final BottomBarVisibilityBinding binding => binding.visibility,
      _ when binding.isVisible => BottomBarVisibility.shown,
      _ => BottomBarVisibility.hidden,
    }, shouldNotify: false);
  }

  /// @nodoc — called by [BottomBar] when it unmounts or the controller changes.
  void detach(BottomBarBindingForController binding) {
    if (_binding == binding) {
      _binding = null;
    }
  }

  /// @nodoc — kept for compatibility. [BottomBar] calls
  /// [updateVisibilityState].
  void updateVisibility(
    BottomBarBindingForController binding,
    bool value, {
    bool shouldNotify = true,
  }) {
    if (value == isVisible) return;
    _update(
      binding,
      value ? BottomBarVisibility.shown : BottomBarVisibility.hidden,
      shouldNotify: shouldNotify,
    );
  }

  /// @nodoc — called by [BottomBar] to keep [visibility] in sync with actual
  /// bar state; notifies listeners so external [AnimatedBuilder]s / [ListenableBuilder]s
  /// react automatically.
  void updateVisibilityState(
    BottomBarBindingForController binding,
    BottomBarVisibility value,
  ) => _update(binding, value, shouldNotify: true);

  void _update(
    BottomBarBindingForController binding,
    BottomBarVisibility value, {
    required bool shouldNotify,
  }) {
    if (_binding != binding) return;
    if (_visibility.value == value) return;
    _visibility.value = value;
    if (shouldNotify) notifyListeners();
  }

  @override
  void dispose() {
    _visibility.dispose();
    super.dispose();
  }
}

/// Internal binding interface implemented by `_BottomBarState`.
/// Not part of the public API.
abstract class BottomBarBindingForController {
  bool get isVisible;

  /// Shows the full bar, or hides it.
  void requestVisible(bool visible);
  Future<void> scrollToBoundary({required bool toEnd});
  void reportScroll({required double delta});
}

/// The three-state half of the binding, apart from
/// [BottomBarBindingForController] so that interface stays as shipped.
/// Not part of the public API.
abstract class BottomBarVisibilityBinding {
  BottomBarVisibility get visibility;
  void requestVisibility(BottomBarVisibility visibility);
}
