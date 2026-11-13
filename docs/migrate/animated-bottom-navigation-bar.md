# Migrate from `animated_bottom_navigation_bar`

Switch if you want the centre action to be part of the bar and the bar to hide
while people scroll. Keep `animated_bottom_navigation_bar` if you want a
`Scaffold` `FloatingActionButton` docked into the notch, or the bubble that
plays on each tap.

## Before

```dart
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

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
      body: _pages[_index],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [Icons.home, Icons.search, Icons.inbox, Icons.person],
        activeIndex: _index,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
```

## After

Put the `BottomBar` in `Scaffold.body`, and remove the `floatingActionButton`,
`floatingActionButtonLocation` and `bottomNavigationBar`. The centre action goes
in `BottomBarItems.centerAction`, in the middle slot.

<!-- example/lib/migrate/animated_bottom_navigation_bar.dart -->
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
            labelBehavior: BottomBarLabelBehavior.alwaysHide,
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Create',
              style: BottomBarCenterActionStyle.notched,
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

`BottomBarItems.selectedIndex`, `BottomBarItems.onSelected`,
`BottomBarItems.centerAction` and `BottomBarCenterAction` are since 3.1.0. On
3.0.1, set `selected: _index == i` and `onTap` on each `BottomBarItem` instead,
and leave out the centre action.

Remove the old package with `flutter pub remove animated_bottom_navigation_bar`.

## Property mapping

| `AnimatedBottomNavigationBar` | `flutter_floating_bottom_bar` |
| --- | --- |
| `icons` | `BottomBarItems.children`, with one `BottomBarItem(icon: Icon(...))` per icon |
| `activeIndex` | `BottomBarItems.selectedIndex` (since 3.1.0) |
| `onTap` | `BottomBarItems.onSelected` (since 3.1.0) |
| `height` | No equivalent. The bar takes the height of its items, with a 48 pixel minimum. |
| `splashRadius` | No equivalent. The bar draws no bubble. |
| `splashSpeedInMilliseconds` | No equivalent. The bar draws no bubble. |
| `notchMargin` | `BottomBarCenterActionThemeData.notchMargin` (since 3.1.0). The default is 6. Theirs is 8. |
| `backgroundColor` | `BottomBarThemeData.barDecoration` with `color`, or `BottomBarThemeData.surface` with `BottomBarSurface.solid(color: ...)` (since 3.1.0) |
| `splashColor` | No equivalent. `BottomBarItemThemeData.overlayColor` (since 3.1.0) tints the ink, not a bubble. |
| `activeColor` | `BottomBarItem.selectedColor`, or `BottomBarItemThemeData.selectedColor` (since 3.1.0) for every item |
| `inactiveColor` | `BottomBarItem.color`, or `BottomBarItemThemeData.color` for every item |
| `notchAndCornersAnimation` | No equivalent. The notch has no animation hook. |
| `leftCornerRadius` | `BottomBarLayout.borderRadius`, a `BorderRadius`, so each corner can differ |
| `rightCornerRadius` | `BottomBarLayout.borderRadius`, as for `leftCornerRadius` |
| `iconSize` | `BottomBarItemThemeData.iconSize` and `selectedIconSize` (since 3.1.0) |
| `notchSmoothness` | No equivalent. Our notch is one smooth circular cut. |
| `gapLocation` | `BottomBarItems.centerAction` (since 3.1.0), with `BottomBarCenterAction` (since 3.1.0), for `GapLocation.center`. `GapLocation.end` has no equivalent. The action always sits in the middle. |
| `gapWidth` | No equivalent. The gap comes from the centre action's size and its notch margin. |
| `elevation` | `boxShadow` in `BottomBarThemeData.barDecoration` |
| `shadow` | `boxShadow` in `BottomBarThemeData.barDecoration`, as a `BoxShadow` |
| `borderColor` | `border` in `BottomBarThemeData.barDecoration`, as `Border.all(color: ...)` |
| `borderWidth` | `border` in `BottomBarThemeData.barDecoration`, as `Border.all(width: ...)` |
| `safeAreaValues` | `BottomBarLayout.respectSafeArea`. Ours has no per-side setting. |
| `hideAnimationCurve` | `BottomBar.motion` with `BottomBarMotion.curved(curve: ...)` |
| `hideAnimationController` | No equivalent. Ours hides on scroll by itself. To hide or show from code, pass a `BottomBarController` to `BottomBar.controller`, then call `hide()` and `show()`. |
| `backgroundGradient` | `gradient` in `BottomBarThemeData.barDecoration` |
| `imageFilter` | No equivalent. `BottomBarSurface.glass(blur: ...)` takes a radius, not an `ImageFilter`. |
| `blurEffect` | `BottomBarThemeData.surface` with `BottomBarSurface.glass()` |
| `scaleFactor` | No equivalent. `BottomBarItemThemeData.pressedScale` scales a pressed item, not the selected one. |
| `itemCount` (`.builder` only) | No equivalent. Use the length of `BottomBarItems.children`. |
| `tabBuilder` (`.builder` only) | No equivalent. Build each `BottomBarItem` yourself in `BottomBarItems.children`. |

## Behaviour differences

- **Hide on scroll.** Their bar never hides on scroll. `hideAnimationController`
  hides the bar only while you drive that controller, and with no controller the
  bar stays visible. Ours hides when the list scrolls down and shows when it
  scrolls up. To keep the bar on screen, set
  `scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)`. While the
  bar is hidden, a scroll-to-top button shows. Set `showIcon: false` to remove
  it.
- **Safe area.** Their bar pads its bottom edge by the device inset, and its
  background covers that padding. The bar sits flush with the bottom of the
  screen, and `safeAreaValues` sets which sides get the padding. Ours floats the
  bar `layout.offset` (10 by default) above the inset. Set
  `BottomBarLayout.respectSafeArea` to `false` to turn this off.
- **Body padding.** `Scaffold` lays out `body` above `bottomNavigationBar`, so
  the body needs no padding. The bar reads the `Scaffold` geometry to cut its
  notch, so it must stay inside a `Scaffold`. `BottomBar` stacks the bar on top
  of its body. Wrap the body in `BottomBarBodyPadding` so the last row stays
  clear of the bar.
- **Floating action button.** In the old bar the FAB is a `Scaffold` widget,
  docked into the gap by `floatingActionButtonLocation`. The bar cuts its notch
  to match, and the bar does not hide the FAB. Ours is part of the bar.
  `BottomBarItems.centerAction` (since 3.1.0) puts the action in the middle
  slot. The action hides with the bar, and the notch follows it. Use
  `style: BottomBarCenterActionStyle.notched` for the notch.
- **Selection animation.** Their bar plays a bubble on the tapped tab and scales
  the active icon up and back. `splashRadius`, `splashSpeedInMilliseconds` and
  `scaleFactor` set this. Ours draws no bubble. The selected colour and icon
  animate on `BottomBarItemThemeData.motion`. Set
  `BottomBarItemThemeData.indicator` to a `BottomBarIndicator` (since 3.1.0) to
  draw a pill, tint, underline or dot behind the selected item.
- **Back button.** No change. Neither bar handles the Android back button.
- **State per tab.** `_pages[_index]` builds a new page on every switch, in
  both versions. To keep each tab's state, put the pages in an `IndexedStack`
  inside `BottomBarBodyPadding`. The scroll-to-top button and
  `BottomBarController.scrollToStart()` act on the visible tab only.

## Live demo

The [centre action demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/center-action)
shows the notched action in the middle of the bar.

[All migration guides](README.md)
