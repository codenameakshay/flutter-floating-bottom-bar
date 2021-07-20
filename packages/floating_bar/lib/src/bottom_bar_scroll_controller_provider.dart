import 'package:flutter/material.dart';

/// Scroll Controller provider for the `child` widget.
class BottomBarScrollControllerProvider extends InheritedWidget {
  ///
  /// The `ScrollController` that gets exposed through the `child`
  /// property in the `BottomBar` will be used to control the `child`
  /// and to react on how it scrolls.
  final ScrollController scrollController;
  const BottomBarScrollControllerProvider({
    required Widget child,
    required this.scrollController,
  }) : super(child: child);
  @override
  bool updateShouldNotify(BottomBarScrollControllerProvider oldWidget) =>
      scrollController != oldWidget.scrollController;
  static BottomBarScrollControllerProvider of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BottomBarScrollControllerProvider>()!;
}
