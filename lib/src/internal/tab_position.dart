import 'package:flutter/widgets.dart';

/// A [BottomBarItems] child's place among the row's tabs. The centre action
/// is not a tab, so it is never counted.
class TabPosition extends InheritedWidget {
  const TabPosition({
    super.key,
    required this.index,
    required this.count,
    required super.child,
  });

  final int index;
  final int count;

  static TabPosition? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabPosition>();

  @override
  bool updateShouldNotify(TabPosition oldWidget) =>
      index != oldWidget.index || count != oldWidget.count;
}
