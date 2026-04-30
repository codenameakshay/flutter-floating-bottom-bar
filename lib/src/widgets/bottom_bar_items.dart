import 'package:flutter/widgets.dart';

/// A thin row layout helper for [BottomBarItem]s (or any other widgets).
///
/// Arranges [children] horizontally with [spacing] as the main-axis alignment.
/// Designed to be passed as [BottomBar.child]:
///
/// ```dart
/// BottomBar(
///   child: BottomBarItems(
///     children: [
///       BottomBarItem(icon: Icon(Icons.home), selected: true, onTap: () {}),
///       BottomBarItem(icon: Icon(Icons.search), onTap: () {}),
///     ],
///   ),
///   body: ...,
/// )
/// ```
class BottomBarItems extends StatelessWidget {
  /// Creates a [BottomBarItems] row.
  const BottomBarItems({
    super.key,
    required this.children,
    this.spacing = MainAxisAlignment.spaceAround,
  });

  /// The widgets to display in the row — typically [BottomBarItem] instances.
  final List<Widget> children;

  /// Main-axis alignment applied to the [Row].
  ///
  /// Defaults to [MainAxisAlignment.spaceAround].
  final MainAxisAlignment spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: spacing,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}
