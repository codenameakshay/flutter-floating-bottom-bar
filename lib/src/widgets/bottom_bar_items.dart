import 'package:flutter/widgets.dart';

/// Controls when a [BottomBarItem]'s label is visible when it is placed
/// inside a [BottomBarItems] row.
enum BottomBarLabelBehavior {
  /// Always show the label, regardless of selection state.
  alwaysShow,

  /// Only show the label on the selected item.
  onlySelected,

  /// Never show the label.
  alwaysHide,
}

/// A thin row layout helper for [BottomBarItem]s (or any other widgets).
///
/// Arranges [children] horizontally with [spacing] as the main-axis alignment.
/// Each child is wrapped in [Expanded], so all items share the available
/// width equally — this keeps labels from overflowing the bar as the item
/// count grows or text scales up. Designed to be passed as [BottomBar.child]:
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
    this.labelBehavior = BottomBarLabelBehavior.alwaysShow,
  });

  /// The widgets to display in the row — typically [BottomBarItem] instances.
  final List<Widget> children;

  /// Main-axis alignment applied to the [Row].
  ///
  /// Defaults to [MainAxisAlignment.spaceAround]. Since every child is
  /// wrapped in [Expanded], this only affects layout when [children] is
  /// empty.
  final MainAxisAlignment spacing;

  /// Controls when descendant [BottomBarItem] labels are visible.
  ///
  /// Exposed to descendants via [BottomBarItemsScope]. Defaults to
  /// [BottomBarLabelBehavior.alwaysShow].
  final BottomBarLabelBehavior labelBehavior;

  @override
  Widget build(BuildContext context) {
    return BottomBarItemsScope(
      labelBehavior: labelBehavior,
      child: Row(
        mainAxisAlignment: spacing,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
}

/// Exposes the enclosing [BottomBarItems.labelBehavior] to descendant
/// [BottomBarItem]s.
///
/// [BottomBarItem] reads this via [BottomBarItemsScope.maybeOf] to decide
/// whether to render its label. An item used outside a [BottomBarItems] row
/// falls back to [BottomBarLabelBehavior.alwaysShow].
class BottomBarItemsScope extends InheritedWidget {
  /// Creates a [BottomBarItemsScope].
  const BottomBarItemsScope({
    super.key,
    required this.labelBehavior,
    required super.child,
  });

  /// The label behavior in effect for descendant [BottomBarItem]s.
  final BottomBarLabelBehavior labelBehavior;

  /// Returns the nearest enclosing [BottomBarItemsScope]'s [labelBehavior],
  /// or `null` if there isn't one.
  static BottomBarLabelBehavior? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BottomBarItemsScope>()
        ?.labelBehavior;
  }

  @override
  bool updateShouldNotify(BottomBarItemsScope oldWidget) {
    return labelBehavior != oldWidget.labelBehavior;
  }
}
