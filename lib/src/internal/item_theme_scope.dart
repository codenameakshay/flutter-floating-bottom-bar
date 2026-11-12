import 'package:material_ui/material_ui.dart';

import '../bottom_bar_theme.dart';
import '../widgets/bottom_bar_item_theme.dart';

/// Carries a [BottomBar]'s resolved [BottomBarThemeData.items] to its child.
class ItemThemeScope extends InheritedWidget {
  const ItemThemeScope({super.key, required this.items, required super.child});

  final BottomBarItemThemeData? items;

  @override
  bool updateShouldNotify(ItemThemeScope oldWidget) => items != oldWidget.items;
}

/// The item theme in effect at [context]: the enclosing [BottomBar]'s, or the
/// `ThemeData.extensions` one outside a [BottomBar].
BottomBarItemThemeData itemThemeOf(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<ItemThemeScope>();
  return (scope != null
          ? scope.items
          : Theme.of(context).extension<BottomBarThemeData>()?.items) ??
      const BottomBarItemThemeData();
}
