# Migrate from `NavigationBar`

Switch if you want the bar to float above your content and hide while people
scroll. Keep `NavigationBar` if you want the Material 3 bar, fixed full width
at the bottom edge of the screen.

## Before

```dart
class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [_Page('Home'), _Page('Search'), _Page('Profile')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

## After

The `BottomBar` goes in `Scaffold.body`, with your pages in `BottomBar.body`
and the items in `BottomBar.child`. Remove `bottomNavigationBar`, and use the
pill `indicator` as the closest match to the Material 3 indicator.

<!-- example/lib/migrate/navigation_bar.dart -->
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
            indicator: const BottomBarIndicator.pill(),
            children: const [
              BottomBarItem(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
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
`BottomBarIndicator` are since 3.1.0. On 3.0.1, set `selected: _index == i` and
`onTap` on each `BottomBarItem` instead, and leave out `indicator`.

## Property mapping

| `NavigationBar` | `flutter_floating_bottom_bar` |
| --- | --- |
| `animationDuration` | `BottomBarItems.indicatorMotion` (since 3.1.0) for the indicator, or `BottomBarItemThemeData.motion` (since 3.1.0) for the item. Both take a `Motion` spring, not a `Duration`, so tune a spring instead. |
| `selectedIndex` | `BottomBarItems.selectedIndex` (since 3.1.0) |
| `destinations` | `BottomBarItems.children` |
| `onDestinationSelected` | `BottomBarItems.onSelected` (since 3.1.0) |
| `backgroundColor` | `BottomBarThemeData.barDecoration`, or `BottomBarThemeData.surface` with `BottomBarSurface.solid(color: ...)` (since 3.1.0) |
| `elevation` | `boxShadow` in `BottomBarThemeData.barDecoration` |
| `shadowColor` | `boxShadow` in `BottomBarThemeData.barDecoration`, set on each `BoxShadow` |
| `surfaceTintColor` | No equivalent. Set the final colour in `barDecoration`. |
| `indicatorColor` | `BottomBarIndicator.pill(color: ...)` (since 3.1.0) |
| `indicatorShape` | `BottomBarIndicator.pill(borderRadius: ...)` (since 3.1.0). It takes a border radius, not a `ShapeBorder`. |
| `height` | No equivalent. The bar sizes to its child, so wrap `BottomBarItems` in a `SizedBox`. |
| `labelBehavior` | `BottomBarItems.labelBehavior`. `alwaysShow` maps to `alwaysShow`, `onlyShowSelected` to `onlySelected`, and `alwaysHide` to `alwaysHide`. |
| `overlayColor` | `BottomBarItemThemeData.overlayColor` (since 3.1.0) |
| `labelTextStyle` | `BottomBarItemThemeData.labelStyle` and `selectedLabelStyle` (since 3.1.0). Split the `WidgetStateProperty` into an unselected and a selected `TextStyle`. |
| `labelPadding` | `BottomBarItemThemeData.iconLabelGap` (since 3.1.0). It takes a `double` gap, not `EdgeInsets`, so set the gap only. |
| `maintainBottomViewPadding` | No equivalent. `BottomBarLayout.respectSafeArea` turns the safe area on or off, and has no view padding mode. |
| `NavigationDestination.icon` | `BottomBarItem.icon` |
| `NavigationDestination.selectedIcon` | `BottomBarItem.selectedIcon` |
| `NavigationDestination.label` (a `String`) | `BottomBarItem.label` (a widget, such as `Text('Home')`) |
| `NavigationDestination.tooltip` | `BottomBarItem.tooltip` |
| `NavigationDestination.enabled` | No equivalent. Every item selects on tap. Ignore the index in `BottomBarItems.onSelected` (since 3.1.0), or leave the item out of `children`. |

## Behaviour differences

- **Hide on scroll.** The bar hides when the list scrolls down and shows when
  it scrolls up. `NavigationBar` never hides. To keep the bar on screen, set
  `scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)`. While
  the bar is hidden, a scroll-to-top button shows. Set `showIcon: false` to
  remove it.
- **Safe area.** `NavigationBar` wraps its row in a `SafeArea`, so the bar
  grows by the bottom safe-area inset. Set `maintainBottomViewPadding` to keep
  that inset from changing when the keyboard opens. `BottomBar` wraps the bar
  in a `SafeArea` and floats it `layout.offset` (10 by default) above that. Set
  `BottomBarLayout.respectSafeArea` to `false` to turn this off.
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

The [indicators demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/indicators)
shows the selection indicators on the bar.

[All migration guides](README.md)
