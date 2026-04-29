import 'package:flutter/foundation.dart';

import 'bottom_bar.dart';

/// Imperative controller for [BottomBar].
///
/// Lets you `show`, `hide`, `toggle` the bar, or scroll the most-recently-active
/// scrollable to its start or end. Attach by passing the controller to
/// [BottomBar.controller].
class BottomBarController extends ChangeNotifier {
  BottomBarBindingForController? _binding;
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  bool get isAttached => _binding != null;

  void show() => _binding?.requestVisible(true);
  void hide() => _binding?.requestVisible(false);

  void toggle() {
    if (_isVisible) {
      hide();
    } else {
      show();
    }
  }

  Future<void> scrollToStart() async {
    await _binding?.scrollToBoundary(toEnd: false);
  }

  Future<void> scrollToEnd() async {
    await _binding?.scrollToBoundary(toEnd: true);
  }

  void attach(BottomBarBindingForController binding) {
    assert(
      _binding == null || _binding == binding,
      'BottomBarController is already attached to a BottomBar. '
      'A controller may only drive one BottomBar at a time.',
    );
    _binding = binding;
    updateVisibility(binding.isVisible, shouldNotify: false);
  }

  void detach(BottomBarBindingForController binding) {
    if (_binding == binding) {
      _binding = null;
    }
  }

  void updateVisibility(bool value, {bool shouldNotify = true}) {
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
