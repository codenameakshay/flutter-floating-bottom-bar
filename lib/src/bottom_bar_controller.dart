import 'package:flutter/foundation.dart';

import 'bottom_bar.dart';

/// Imperative controller for [BottomBar].
///
/// Lets you show, hide, or toggle the bar programmatically, or scroll the
/// most-recently-active scrollable inside [BottomBar.body] to its start or end.
///
/// Attach the controller to a [BottomBar] via [BottomBar.controller]. A single
/// controller may only be attached to one live bar at a time. A second
/// attachment throws a [FlutterError] and leaves the original bar binding in
/// place.
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
  bool _isVisible = true;

  /// The current visibility of the attached bar.
  ///
  /// Reflects the last value set by [show], [hide], or [toggle]. Also updated
  /// automatically when scroll-based hide/show changes the bar state.
  bool get isVisible => _isVisible;

  /// Whether this controller is currently attached to a live [BottomBar].
  ///
  /// [show], [hide], [toggle], [scrollToStart], and [scrollToEnd] are no-ops
  /// when [isAttached] is `false`.
  bool get isAttached => _binding != null;

  /// Shows the bar, animating it into view if it is currently hidden.
  ///
  /// No-op if the bar is already visible or the controller is not attached.
  void show() => _binding?.requestVisible(true);

  /// Hides the bar, animating it out of view.
  ///
  /// No-op if the bar is already hidden or the controller is not attached.
  void hide() => _binding?.requestVisible(false);

  /// Toggles bar visibility — shows if hidden, hides if visible.
  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  /// Animates the most-recently-active scrollable inside [BottomBar.body] to
  /// its [ScrollPosition.minScrollExtent] (i.e. the top).
  ///
  /// If [BottomBarScrollBehavior.scrollOpposite] is `true` on the associated
  /// bar, this scrolls to [ScrollPosition.maxScrollExtent] instead — use
  /// [scrollToEnd] for the opposite direction in that case.
  ///
  /// No-op and logs a [FlutterError] in debug mode if no scroll notification
  /// has been observed yet.
  Future<void> scrollToStart() async {
    await _binding?.scrollToBoundary(toEnd: false);
  }

  /// Animates the most-recently-active scrollable inside [BottomBar.body] to
  /// its [ScrollPosition.maxScrollExtent] (i.e. the bottom).
  ///
  /// No-op and logs a [FlutterError] in debug mode if no scroll notification
  /// has been observed yet.
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
    updateVisibility(binding, binding.isVisible, shouldNotify: false);
  }

  /// @nodoc — called by [BottomBar] when it unmounts or the controller changes.
  void detach(BottomBarBindingForController binding) {
    if (_binding == binding) {
      _binding = null;
    }
  }

  /// @nodoc — called by [BottomBar] to keep [isVisible] in sync with actual
  /// bar state; notifies listeners so external [AnimatedBuilder]s / [ListenableBuilder]s
  /// react automatically.
  void updateVisibility(
    BottomBarBindingForController binding,
    bool value, {
    bool shouldNotify = true,
  }) {
    if (_binding != binding) return;
    if (_isVisible == value) return;
    _isVisible = value;
    if (shouldNotify) notifyListeners();
  }
}

/// Internal binding interface implemented by `_BottomBarState`.
/// Not part of the public API.
abstract class BottomBarBindingForController {
  bool get isVisible;
  void requestVisible(bool visible);
  Future<void> scrollToBoundary({required bool toEnd});
}
