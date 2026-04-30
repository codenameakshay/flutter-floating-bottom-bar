import 'package:flutter/widgets.dart';

/// A thin row layout helper for [BottomBarItem]s (or any other widgets).
class BottomBarItems extends StatelessWidget {
  const BottomBarItems({
    super.key,
    required this.children,
    this.spacing = MainAxisAlignment.spaceAround,
  });

  final List<Widget> children;
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
