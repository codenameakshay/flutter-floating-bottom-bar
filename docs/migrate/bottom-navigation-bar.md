# Migrate from `BottomNavigationBar`

Switch if you want the bar to float above your content and hide while people
scroll. Keep `BottomNavigationBar` if you want a fixed, full-width Material 2
bar.

## Before

```dart
class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [_Page('Home'), _Page('Search'), _Page('Profile')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
```

## After

The `BottomBar` goes in `Scaffold.body`. Your pages go in `BottomBar.body`, and
the items go in `BottomBar.child`. Remove `bottomNavigationBar`.

<!-- example/lib/migrate/bottom_navigation_bar.dart -->
```dart
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [_Page('Home'), _Page('Search'), _Page('Profile')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(maxWidth: 420),
        body: BottomBarBodyPadding(child: _pages[_index]),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: BottomBarItems(
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: PageStorageKey(title),
      itemCount: 40,
      itemBuilder: (_, i) => ListTile(title: Text('$title row $i')),
    );
  }
}
```

`BottomBarItems.selectedIndex` and `onSelected` are since 3.1.0. On 3.0.1, set
`selected: _index == i` and `onTap` on each `BottomBarItem` instead.

## Property mapping

| `BottomNavigationBar` | `flutter_floating_bottom_bar` |
| --- | --- |
| `items` | `BottomBarItems.children` |
| `currentIndex` | `BottomBarItems.selectedIndex` (since 3.1.0) |
| `onTap` | `BottomBarItems.onSelected` (since 3.1.0) |
| `type` | No equivalent. `BottomBarItems.labelBehavior` with `BottomBarLabelBehavior.onlySelected` is closest to `shifting`. |
| `backgroundColor` | `BottomBarThemeData.barDecoration`, or `BottomBarThemeData.surface` with `BottomBarSurface.solid(color: ...)` (since 3.1.0) |
| `elevation` | `boxShadow` in `BottomBarThemeData.barDecoration` |
| `fixedColor`, `selectedItemColor` | `BottomBarItem.selectedColor`, or `BottomBarItemThemeData.selectedColor` (since 3.1.0) for every item |
| `unselectedItemColor` | `BottomBarItem.color`, or `BottomBarItemThemeData.color` (since 3.1.0) |
| `iconSize` | `BottomBarItemThemeData.iconSize` and `selectedIconSize` (since 3.1.0) |
| `selectedIconTheme`, `unselectedIconTheme` | `BottomBarItemThemeData.selectedIconSize`, `iconSize`, `selectedColor` and `color` (since 3.1.0) |
| `selectedFontSize`, `unselectedFontSize` | `fontSize` in `BottomBarItemThemeData.selectedLabelStyle` and `labelStyle` (since 3.1.0) |
| `selectedLabelStyle`, `unselectedLabelStyle` | `BottomBarItemThemeData.selectedLabelStyle` and `labelStyle` (since 3.1.0) |
| `showSelectedLabels`, `showUnselectedLabels` | `BottomBarItems.labelBehavior`: `alwaysShow`, `onlySelected` or `alwaysHide` |
| `mouseCursor` | No equivalent. Items use the `InkWell` default cursor. |
| `enableFeedback` | No equivalent. Items keep the `InkWell` platform feedback. `BottomBarItemThemeData.haptics` (since 3.1.0) adds a selection haptic. |
| `landscapeLayout` | No equivalent. `BottomBarLayout.adaptive(maxWidth: ...)` caps the bar width on wide screens. |
| `useLegacyColorScheme` | No equivalent. Item colours come from `ColorScheme` or the item theme. |
| `BottomNavigationBarItem.icon` | `BottomBarItem.icon` |
| `BottomNavigationBarItem.activeIcon` | `BottomBarItem.selectedIcon` |
| `BottomNavigationBarItem.label` (a `String`) | `BottomBarItem.label` (a widget, such as `Text('Home')`) |
| `BottomNavigationBarItem.tooltip` | `BottomBarItem.tooltip` |
| `BottomNavigationBarItem.semanticsLabel` | `BottomBarItem.semanticLabel` |
| `BottomNavigationBarItem.backgroundColor` | No equivalent. Change `barDecoration` with `_index` to tint the bar per tab. |

## Behaviour differences

- **Hide on scroll.** The bar hides when the list scrolls down and shows when
  it scrolls up. `BottomNavigationBar` never hides. To keep the bar on screen,
  set `scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)`.
  While the bar is hidden, a scroll-to-top button shows. Set `showIcon: false`
  to remove it.
- **Safe area.** `BottomNavigationBar` grows by the bottom safe-area inset.
  `BottomBar` wraps the bar in a `SafeArea` and floats it `layout.offset` (10 by
  default) above that. Set `BottomBarLayout.respectSafeArea` to `false` to turn
  this off.
- **Body padding.** `Scaffold` lays out `body` above `bottomNavigationBar`.
  `BottomBar` stacks the bar on top of its body. Wrap the body in
  `BottomBarBodyPadding` so the last row stays clear of the bar.
- **Floating action button.** With `bottomNavigationBar`, the `Scaffold` puts
  its FAB above the bar. Now the FAB sits at the screen's bottom edge, over the
  bar. Move the action into the bar with `BottomBarItems.centerAction` (since
  3.1.0), or pad the FAB.
- **Back button.** No change. Neither widget handles the Android back button.
- **State per tab.** `_pages[_index]` builds a new page on every switch, in
  both versions. To keep each tab's state, put the pages in an `IndexedStack`
  inside `BottomBarBodyPadding`. The scroll-to-top button and
  `BottomBarController.scrollToStart()` act on the visible tab only.

## Live demo

The [item theme demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/item-theme)
shows the label behaviours and per-item colours.

[All migration guides](README.md)
