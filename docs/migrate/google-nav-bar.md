# Migrate from `google_nav_bar`

Switch if you want the bar to float above your content, hide while people
scroll, and move a highlight between tabs. Keep `google_nav_bar` if you want
its tab style, where the text opens beside the icon in the active tab.

## Before

```dart
import 'package:google_nav_bar/google_nav_bar.dart';

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [_Page('Home'), _Page('Search'), _Page('Profile')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.black,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              selectedIndex: _index,
              onTabChange: (i) => setState(() => _index = i),
              tabs: const [
                GButton(icon: Icons.home, text: 'Home'),
                GButton(icon: Icons.search, text: 'Search'),
                GButton(icon: Icons.person, text: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## After

The `BottomBar` goes in `Scaffold.body`. Your pages go in `BottomBar.body`, and
the items go in `BottomBar.child`. Remove `bottomNavigationBar`.

<!-- example/lib/migrate/google_nav_bar.dart -->
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
            labelBehavior: BottomBarLabelBehavior.onlySelected,
            indicator: const BottomBarIndicator.tint(),
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

`BottomBarItems.selectedIndex`, `onSelected` and `indicator` are since 3.1.0.
On 3.0.1, set `selected: _index == i` and `onTap` on each `BottomBarItem`
instead, and drop `indicator`.

Remove the old package with `flutter pub remove google_nav_bar`.

## Property mapping

| `GNav` | `flutter_floating_bottom_bar` |
| --- | --- |
| `tabs` | `BottomBarItems.children` |
| `selectedIndex` | `BottomBarItems.selectedIndex` (since 3.1.0) |
| `onTabChange` | `BottomBarItems.onSelected` (since 3.1.0) |
| `gap` | `BottomBarItemThemeData.iconLabelGap` (since 3.1.0). It is the space between the icon and the label. |
| `padding` | `BottomBarItemThemeData.padding` (since 3.1.0). It pads each tab, not the bar. The default is 8 horizontal and 4 vertical, not 25. |
| `activeColor` | `BottomBarItemThemeData.selectedColor` (since 3.1.0), or `BottomBarItem.selectedColor` for one item |
| `color` | `BottomBarItemThemeData.color` (since 3.1.0), or `BottomBarItem.color` for one item |
| `rippleColor` | `BottomBarItemThemeData.overlayColor` (since 3.1.0). It is a `WidgetStateProperty`, so return the ripple colour for `WidgetState.pressed`. |
| `hoverColor` | `BottomBarItemThemeData.overlayColor` (since 3.1.0), for `WidgetState.hovered`. See `rippleColor`. |
| `backgroundColor` | `BottomBarThemeData.barDecoration`, with `color` on the `BoxDecoration` |
| `tabBackgroundColor` | `BottomBarIndicator.tint(color: ...)` (since 3.1.0). It colours the selected tab only. |
| `tabBorderRadius` | `BottomBarIndicator.tint(borderRadius: ...)`. The tint defaults to a radius of 16. Pass `BorderRadius.circular(100)` to match the `GNav` default. |
| `iconSize` | `BottomBarItemThemeData.iconSize` and `selectedIconSize` (since 3.1.0) |
| `textStyle` | `BottomBarItemThemeData.labelStyle` and `selectedLabelStyle` (since 3.1.0) |
| `curve` | No equivalent. The motion is a spring, not a curve. Use `BottomBarItemThemeData.motion` (since 3.1.0) instead. |
| `tabMargin` | No equivalent. The closest is `inset` on `BottomBarIndicator.tint(inset: ...)`, which shrinks the highlight inside its slot. |
| `debug` | No equivalent. Set `debugPaintSizeEnabled` from `package:flutter/rendering.dart` to outline the boxes. |
| `duration` | `BottomBarItemThemeData.motion` and `indicatorMotion` (since 3.1.0). Both take a spring `Motion`, not a duration. |
| `tabBorder` | No equivalent. The closest is `BottomBarIndicator.builder` (since 3.1.0), which draws your own border. |
| `tabActiveBorder` | No equivalent. The closest is `BottomBarIndicator.builder`, which draws your own border on the selected tab. |
| `tabShadow` | No equivalent. The closest is `BottomBarIndicator.builder`, which draws your own `BoxShadow`. |
| `haptic` | `BottomBarItemThemeData.haptics` (since 3.1.0), set to `BottomBarHaptics.selectionClick` or `BottomBarHaptics.none`. It is bar-wide, not per tab. |
| `tabBackgroundGradient` | No equivalent. The closest is `BottomBarIndicator.builder`, which can paint a `Gradient`. |
| `mainAxisAlignment` | `BottomBarItems.spacing`. The default is `spaceAround`, not `spaceBetween`. Items in a bounded row already share the width equally, so `spacing` changes little there. |
| `style` | No equivalent. The label always sits under the icon, as with `GnavStyle.oldSchool`. |
| `textSize` | `fontSize` in `BottomBarItemThemeData.labelStyle` (since 3.1.0) |
| `GButton.icon` | `BottomBarItem.icon`, which takes a widget such as `Icon(Icons.home)` |
| `GButton.text` | `BottomBarItem.label`, which takes a widget such as `Text('Home')` |
| `GButton.active` | No per-item setting. `BottomBarItems.selectedIndex` picks the selected item. |
| `GButton.haptic` | `BottomBarItemThemeData.haptics`. It is bar-wide. See `GNav.haptic`. |
| `GButton.backgroundColor` | No per-tab colour. `BottomBarIndicator.tint(color: ...)` colours the selected tab for every item. |
| `GButton.iconColor` | `BottomBarItem.color`, or `BottomBarItemThemeData.color` for all items |
| `GButton.rippleColor` | `BottomBarItemThemeData.overlayColor`. It is bar-wide. |
| `GButton.hoverColor` | `BottomBarItemThemeData.overlayColor`, for `WidgetState.hovered`. It is bar-wide. |
| `GButton.iconActiveColor` | `BottomBarItem.selectedColor` |
| `GButton.textColor` | No separate label colour. The label follows `BottomBarItem.color` and `selectedColor`. |
| `GButton.padding` | `BottomBarItemThemeData.padding`. It is bar-wide. |
| `GButton.margin` | No equivalent. The closest is `inset` on `BottomBarIndicator.tint(inset: ...)`. |
| `GButton.duration` | `BottomBarItemThemeData.motion`. It is bar-wide. |
| `GButton.debug` | No equivalent. See `GNav.debug`. |
| `GButton.gap` | `BottomBarItemThemeData.iconLabelGap`. It is bar-wide. |
| `GButton.curve` | No equivalent. See `GNav.curve`. |
| `GButton.textStyle` | `BottomBarItemThemeData.labelStyle` and `selectedLabelStyle` |
| `GButton.iconSize` | `BottomBarItemThemeData.iconSize` and `selectedIconSize` |
| `GButton.leading` | `BottomBarItem.icon`, which takes any widget in place of the icon. `BottomBarItem.badge` is for a dot or count on the icon, not a replacement. |
| `GButton.onPressed` | `BottomBarItem.onTap` for one item. `BottomBarItems.onSelected` (since 3.1.0) for the whole row. |
| `GButton.backgroundGradient` | No equivalent. The closest is `BottomBarIndicator.builder`, which can paint a `Gradient`. |
| `GButton.borderRadius` | `BottomBarIndicator.tint(borderRadius: ...)`. It is bar-wide. |
| `GButton.border` | No equivalent. The closest is `BottomBarIndicator.builder`. |
| `GButton.activeBorder` | No equivalent. The closest is `BottomBarIndicator.builder`. |
| `GButton.shadow` | No equivalent. The closest is `BottomBarIndicator.builder`. |
| `GButton.semanticLabel` | `BottomBarItem.semanticLabel` |
| `GButton.style` | No equivalent. See `GNav.style`. |
| `GButton.textSize` | `fontSize` in `BottomBarItemThemeData.labelStyle`. It is bar-wide. |

## Behaviour differences

- **Hide on scroll.** `GNav` never hides. It has no scroll code, so the bar
  stays on screen. Our bar hides when the list scrolls down and shows when it
  scrolls up. To keep the bar on screen, set
  `scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)`. While
  the bar is hidden, a scroll-to-top button shows. Set `showIcon: false` to
  remove it.
- **Safe area.** `GNav` does not handle the bottom inset. Its example wraps the
  bar in `SafeArea`, as in the before snippet. `BottomBar` wraps the bar in a
  `SafeArea` and floats it `layout.offset` (10 by default) above that. Set
  `respectSafeArea` on `BottomBarLayout` to `false` to turn this off.
- **Body padding.** `GNav` sits in `Scaffold.bottomNavigationBar`, so the
  `Scaffold` lays out `body` above it. `BottomBar` stacks the bar on top of its
  body. Wrap the body in `BottomBarBodyPadding` so the last row stays clear of
  the bar.
- **Icon and label layout.** In the active tab, `GNav` puts the icon and the
  text side by side. The text opens beside the icon as the tab is selected.
  Our items put the label under the icon. With
  `BottomBarLabelBehavior.onlySelected`, only the active tab shows its label,
  but the label still sits below the icon.
- **Back button.** No change. Neither widget handles the Android back button.
- **State per tab.** `_pages[_index]` builds a new page on every switch. To keep
  each tab's state, put the pages in an `IndexedStack` inside
  `BottomBarBodyPadding`. The scroll-to-top button and
  `BottomBarController.scrollToStart()` act on the visible tab only.

## Live demo

The [indicators demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/indicators)
shows the tinted pill and the other indicator styles.

[All migration guides](README.md)
