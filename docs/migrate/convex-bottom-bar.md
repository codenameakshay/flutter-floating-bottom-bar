# Migrate from `convex_bottom_bar`

Switch if you want the bar to float above your content and hide while people
scroll. Keep `convex_bottom_bar` if you want the convex bump in the bar's top
edge, or its `react` and `flip` tab styles.

## Before

```dart
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    _Page('Home'),
    _Page('Search'),
    _Page('Add'),
    _Page('Inbox'),
    _Page('Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.fixedCircle,
        items: const [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.search, title: 'Search'),
          TabItem(icon: Icons.add, title: 'Add'),
          TabItem(icon: Icons.inbox, title: 'Inbox'),
          TabItem(icon: Icons.person, title: 'Profile'),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
```

## After

The `BottomBar` goes in `Scaffold.body`, with your pages in `BottomBar.body`
and the items in `BottomBar.child`. The Add button becomes
`BottomBarItems.centerAction`. It is a button, not a tab, so the Add page goes
away. Remove `bottomNavigationBar`, then remove the old package with
`flutter pub remove convex_bottom_bar`.

<!-- example/lib/migrate/convex_bottom_bar.dart -->
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

  static const _pages = [
    _Page('Home'),
    _Page('Search'),
    _Page('Inbox'),
    _Page('Profile'),
  ];

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
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Add',
              style: BottomBarCenterActionStyle.raised,
              onPressed: () {},
            ),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
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

`BottomBarItems.selectedIndex`, `onSelected`, `indicator` and `centerAction`
are since 3.1.0. On 3.0.1, set `selected: _index == i` and `onTap` on each
`BottomBarItem` instead, and leave out the indicator and the centre action.

## Property mapping

| `ConvexAppBar` | `flutter_floating_bottom_bar` |
| --- | --- |
| `items` | `BottomBarItems.children`, a list of `BottomBarItem` widgets |
| `initialActiveIndex` | `BottomBarItems.selectedIndex` (since 3.1.0). Start `_index` at the value you want. |
| `disableDefaultTabController` | No equivalent. The bar never reads a `DefaultTabController`, so there is nothing to turn off. |
| `onTap` | `BottomBarItems.onSelected` (since 3.1.0) |
| `onTabNotify` | No equivalent for blocking a tap. `BottomBarItems.onSelected` (since 3.1.0) is the closest. It runs after the selection changes, so it cannot block a tap. |
| `controller` | No equivalent. Pass `controller.index` as `BottomBarItems.selectedIndex` (since 3.1.0), call `controller.animateTo` in `onSelected`, and rebuild when the controller changes. |
| `color` | `BottomBarItem.color`, or `BottomBarItemThemeData.color` (since 3.1.0) for every item |
| `activeColor` | `BottomBarItem.selectedColor`, or `BottomBarItemThemeData.selectedColor` (since 3.1.0) for every item |
| `backgroundColor` | `BottomBarThemeData.barDecoration` with `BoxDecoration(color: ...)`, or `BottomBarThemeData.surface` with `BottomBarSurface.solid(color: ...)` (since 3.1.0) |
| `shadowColor` | The `color` of the `boxShadow` in `BottomBarThemeData.barDecoration` |
| `gradient` | `BoxDecoration(gradient: ...)` in `BottomBarThemeData.barDecoration` |
| `height` | No equivalent. The bar sizes itself to its items. Change `BottomBarItemThemeData.padding` or `iconSize` (both since 3.1.0) instead. |
| `curveSize` | `BottomBarCenterActionThemeData.size` (since 3.1.0). It sets the button's side length, not the curve. |
| `top` | `BottomBarCenterActionThemeData.raise` (since 3.1.0). Convex takes a negative value, so `top: -30` becomes `raise: 30`. |
| `elevation` | `boxShadow` in `BottomBarThemeData.barDecoration` |
| `cornerRadius` | `BottomBarLayout.borderRadius`. It rounds all four corners, not only the top two. |
| `style` | `fixed` and `fixedCircle` map to `BottomBarItems.centerAction` with `BottomBarCenterActionStyle.raised` or `notched` (since 3.1.0). `react`, `reactCircle`, `flip`, `textIn` and `titled` have no equivalent. The closest is an indicator, such as `BottomBarIndicator.pill()` (since 3.1.0). `custom` has no equivalent. Build each item with `BottomBarItem`. |
| `curve` | No equivalent. The indicator moves on a spring. Set `BottomBarItemThemeData.indicatorMotion` (since 3.1.0) instead. |
| `chipBuilder` | `BottomBarItem.badge`. Pass any widget, or a `BottomBarBadge` (since 3.1.0). |
| `TabItem.fontFamily` | No direct parameter. Set `fontFamily` in the `TextStyle` of the label `Text`, or in `BottomBarItemThemeData.labelStyle` (since 3.1.0). |
| `TabItem.title` | `BottomBarItem.label`, a `Text` widget |
| `TabItem.icon` | `BottomBarItem.icon`. It must be a widget, so `Icons.home` becomes `Icon(Icons.home)`. |
| `TabItem.activeIcon` | `BottomBarItem.selectedIcon` |
| `TabItem.isIconBlend` | No equivalent. `Icon` widgets take `BottomBarItem.color` and `selectedColor` through `IconTheme`. Other widgets keep their own colours. |

`ConvexAppBar.badge` adds these parameters, and `ConvexAppBar.builder` takes
`itemBuilder` and `count` in place of `items`.

| `ConvexAppBar` | `flutter_floating_bottom_bar` |
| --- | --- |
| `badge` (a `Map<int, dynamic>`) | `BottomBarItem.badge` on each item. A `String` becomes `BottomBarBadge.label`, or `BottomBarBadge.count` when it is a number. A `Color` becomes `BottomBarBadge.dot` (all since 3.1.0). An `IconData` becomes an `Icon` widget, and a `Widget` stays as it is. Plain widgets are not announced. |
| `badgeTextColor` | `BottomBarBadgeThemeData.textColor` (since 3.1.0) |
| `badgeColor` | `backgroundColor` on `BottomBarBadge` (since 3.1.0), or `color` on `BottomBarBadge.dot`. |
| `badgePadding` | `BottomBarBadgeThemeData.padding` (since 3.1.0) |
| `badgeMargin` | No equivalent. The closest is `offset` on `BottomBarBadge` (since 3.1.0), which moves the badge. |
| `badgeBorderRadius` | No equivalent. Badges are always pill shaped. |
| `itemBuilder` | No equivalent. Build each `BottomBarItem` in `BottomBarItems.children`. |
| `count` | No equivalent. The length of `BottomBarItems.children` sets the count. |

## Behaviour differences

- **Hide on scroll.** `ConvexAppBar` does not hide on scroll. It stays at the
  bottom of the `Scaffold`. `BottomBar` hides when the list scrolls down and
  shows when it scrolls up. To keep the bar on screen, set
  `scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)`. While
  the bar is hidden, a scroll-to-top button shows. Set `showIcon: false` to
  remove it.
- **Safe area.** `ConvexAppBar` adds the bottom safe-area inset to its height.
  Its background reaches the bottom edge, and the tabs sit above the inset.
  `BottomBar` wraps the bar in a `SafeArea` and floats it `layout.offset` (10 by
  default) above that. Set `BottomBarLayout.respectSafeArea` to `false` to turn
  this off.
- **Body padding.** `Scaffold` lays out `body` above `bottomNavigationBar`, so
  the last row stays clear of the bar. `BottomBar` stacks the bar on top of
  its body. Wrap the body in `BottomBarBodyPadding` so the last row stays clear
  of the bar.
- **Centre action.** With `fixed` or `fixedCircle`, the middle item is a tab.
  It has an index, and `onTap` runs for it. `BottomBarItems.centerAction`
  (since 3.1.0) is a button, not a tab. It sits at `children.length ~/ 2`, and
  it is not part of `selectedIndex` or `onSelected`. The Add page goes away,
  and the button runs only `onPressed`.
- **Back button.** No change. Neither widget handles the Android back button.
- **State per tab.** `_pages[_index]` builds a new page on every switch, in
  both versions. To keep each tab's
  state, put the pages in an `IndexedStack` inside `BottomBarBodyPadding`. The
  scroll-to-top button and `BottomBarController.scrollToStart()` act on the
  visible tab only.

## Live demo

The [centre action demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/center-action)
shows the inline, raised and notched styles of the centre action.

[All migration guides](README.md)
