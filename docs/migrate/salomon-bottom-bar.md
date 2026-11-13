# Migrate from `salomon_bottom_bar`

Switch if you want the bar to float above your content and hide while people
scroll. Keep `SalomonBottomBar` if you want a bar that stays fixed in the
`Scaffold` and opens the selected item to show its title beside the icon.

## Before

```dart
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [_Page('Home'), _Page('Search'), _Page('Profile')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text('Home'),
            selectedColor: Colors.purple,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.search),
            title: const Text('Search'),
            selectedColor: Colors.orange,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: const Text('Profile'),
            selectedColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}
```

## After

The `BottomBar` goes in `Scaffold.body`. Your pages go in `BottomBar.body`, and
the items go in `BottomBar.child`. Remove `bottomNavigationBar`. Each
`BottomBarItem` keeps its `selectedColor`. `BottomBarItems` sets the label
behaviour and the indicator.

<!-- example/lib/migrate/salomon_bottom_bar.dart -->
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
            labelBehavior: BottomBarLabelBehavior.onlySelected,
            indicator: const BottomBarIndicator.tint(),
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            children: const [
              BottomBarItem(
                icon: Icon(Icons.home),
                label: Text('Home'),
                selectedColor: Colors.purple,
              ),
              BottomBarItem(
                icon: Icon(Icons.search),
                label: Text('Search'),
                selectedColor: Colors.orange,
              ),
              BottomBarItem(
                icon: Icon(Icons.person),
                label: Text('Profile'),
                selectedColor: Colors.teal,
              ),
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

`BottomBarItems.selectedIndex`, `onSelected`, `indicator` and
`BottomBarIndicator` are since 3.1.0. On 3.0.1, drop `indicator`, and set
`selected: _index == i` and `onTap` on each `BottomBarItem` instead.

Remove the old package with `flutter pub remove salomon_bottom_bar`.

## Property mapping

| `SalomonBottomBar` | `flutter_floating_bottom_bar` |
| --- | --- |
| `items` | `BottomBarItems.children` |
| `currentIndex` | `BottomBarItems.selectedIndex` (since 3.1.0) |
| `onTap` | `BottomBarItems.onSelected` (since 3.1.0) |
| `backgroundColor` | `BottomBarThemeData.barDecoration`, or `BottomBarThemeData.surface` with `BottomBarSurface.solid(color: ...)` (since 3.1.0) |
| `selectedItemColor` | `BottomBarItem.selectedColor`, or `BottomBarItemThemeData.selectedColor` (since 3.1.0) for every item |
| `unselectedItemColor` | `BottomBarItem.color`, or `BottomBarItemThemeData.color` (since 3.1.0) for every item |
| `selectedColorOpacity` | No equivalent. Closest is `BottomBarIndicator.tint(color: ...)` (since 3.1.0) with a colour at the opacity you want. |
| `itemShape` | `BottomBarIndicator.tint(borderRadius: ...)` (since 3.1.0). A stadium has no direct match, so use a large radius. |
| `margin` | `Padding` around `BottomBarItems`, as in the after file. The bar handles the bottom safe area itself. |
| `itemPadding` | `BottomBarItemThemeData.padding` (since 3.1.0) |
| `duration` | No equivalent. `BottomBarItemThemeData.motion` (since 3.1.0) takes a spring `Motion`, so there is no fixed length. |
| `curve` | No equivalent. Springs have no curve. Set `BottomBarItemThemeData.motion` (since 3.1.0) instead. |
| `SalomonBottomBarItem.icon` | `BottomBarItem.icon` |
| `SalomonBottomBarItem.title` (a `Widget`) | `BottomBarItem.label` (a widget, such as `Text('Home')`) |
| `SalomonBottomBarItem.selectedColor` | `BottomBarItem.selectedColor` |
| `SalomonBottomBarItem.unselectedColor` | `BottomBarItem.color` |
| `SalomonBottomBarItem.activeIcon` | `BottomBarItem.selectedIcon` |

## Behaviour differences

- **Hide on scroll.** The bar never hides in Salomon. `BottomBar` hides when
  the list scrolls down and shows when it scrolls up. To keep the bar on
  screen, set
  `scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)`.
  While the bar is hidden, a scroll-to-top button shows. Set `showIcon: false`
  to remove it.
- **Safe area.** Salomon wraps its content in a `SafeArea` with `margin` as the
  minimum padding. `BottomBar` wraps the bar in a `SafeArea` and floats it
  `layout.offset` (10 by default) above that. Set
  `BottomBarLayout.respectSafeArea` to `false` to turn this off.
- **Body padding.** `Scaffold` lays out `body` above `bottomNavigationBar`.
  `BottomBar` stacks the bar on top of its body. Wrap the body in
  `BottomBarBodyPadding` so the last row stays clear of the bar.
- **Back button.** No change. Neither widget handles the Android back button.
- **State per tab.** `_pages[_index]` builds a new page on every switch, in
  both versions. To keep each tab's state, put the pages in an `IndexedStack`
  inside `BottomBarBodyPadding`. The scroll-to-top button and
  `BottomBarController.scrollToStart()` act on the visible tab only.
- **Selected item.** Salomon's selected item grows to show its title beside
  the icon. `BottomBar` shows each label under its icon. With
  `BottomBarLabelBehavior.onlySelected`, the selected label grows in and the
  indicator follows it. Reduced motion skips the animation.

## Live demo

The [item theme demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/item-theme)
shows the label behaviours and per-item colours.

[All migration guides](README.md)
