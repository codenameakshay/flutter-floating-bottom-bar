# Migrate from `persistent_bottom_nav_bar_v2`

Switch if you want a floating bar over your content and are happy to own the
per-tab `Navigator`s yourself. Keep `persistent_bottom_nav_bar_v2` if
you want its sixteen prebuilt bar styles, tab transition animations or swipe
between tabs.

## Before

```dart
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      hideOnScrollVelocity: 200,
      tabs: [
        PersistentTabConfig(
          screen: const _Page('Home'),
          item: ItemConfig(icon: const Icon(Icons.home), title: 'Home'),
        ),
        PersistentTabConfig(
          screen: const _Page('Search'),
          item: ItemConfig(icon: const Icon(Icons.search), title: 'Search'),
        ),
        PersistentTabConfig(
          screen: const _Page('Profile'),
          item: ItemConfig(icon: const Icon(Icons.person), title: 'Profile'),
        ),
      ],
      navBarBuilder: (navBarConfig) =>
          Style1BottomNavBar(navBarConfig: navBarConfig),
    );
  }
}
```

## After

`persistent_bottom_nav_bar_v2` gives each tab its own `Navigator` and handles
back and reselect for you. This package only draws the bar, so the after file
builds the same three things: an `IndexedStack` of `Navigator`s, a `PopScope`
for back, and `onReselected` to pop a tab to its root.

<!-- example/lib/migrate/persistent_bottom_nav_bar_v2.dart -->
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

  static const _tabs = ['Home', 'Search', 'Profile'];
  final _navigators = [for (final _ in _tabs) GlobalKey<NavigatorState>()];

  bool _canPopTab(int i) => _navigators[i].currentState?.canPop() ?? false;

  void _back() {
    if (_canPopTab(_index)) {
      _navigators[_index].currentState!.pop();
    } else {
      setState(() => _index = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<NavigationNotification>(
      onNotification: (_) {
        setState(() {});
        return false;
      },
      child: PopScope(
        canPop: _index == 0 && !_canPopTab(0),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          body: BottomBar(
            layout: const BottomBarLayout.adaptive(maxWidth: 420),
            body: BottomBarBodyPadding(
              child: IndexedStack(
                index: _index,
                children: [
                  for (final (i, tab) in _tabs.indexed)
                    Navigator(
                      key: _navigators[i],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute<void>(builder: (_) => _Page(tab)),
                    ),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: BottomBarItems(
                selectedIndex: _index,
                onSelected: (i) => setState(() => _index = i),
                onReselected: (i) =>
                    _navigators[i].currentState?.popUntil((r) => r.isFirst),
                scrollToStartOnReselect: !_canPopTab(_index),
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                  BottomBarItem(
                    icon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ),
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        key: PageStorageKey(title),
        itemCount: 40,
        itemBuilder: (_, i) => ListTile(
          title: Text('$title row $i'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  Scaffold(appBar: AppBar(title: Text('$title item $i'))),
            ),
          ),
        ),
      ),
    );
  }
}
```

`BottomBarItems.selectedIndex`, `onSelected`, `onReselected` and
`scrollToStartOnReselect` are since 3.1.0. On 3.0.1, set `selected` and
`onTap` on each `BottomBarItem`, and pop the tab in `onTap` when it is already
selected.

If your app uses go_router, use its `StatefulShellRoute` in place of the
`IndexedStack`. It keeps a `Navigator` per tab for you. See the
[go_router recipe](../../EXAMPLES.md#go_router-statefulshellroute).

Remove the old package with `flutter pub remove persistent_bottom_nav_bar_v2`.

## Property mapping

| `persistent_bottom_nav_bar_v2` | `flutter_floating_bottom_bar` |
| --- | --- |
| `PersistentTabView.tabs` | `BottomBarItems.children`, plus one `Navigator` per tab in an `IndexedStack` |
| `PersistentTabView.navBarBuilder` | `BottomBar.child`. Build the row with `BottomBarItems`. |
| `PersistentTabView.controller` | Your own `_index` field. `BottomBarController` shows, hides and scrolls the bar, not the tabs. |
| `PersistentTabView.onTabChanged` | `BottomBarItems.onSelected` (since 3.1.0) |
| `PersistentTabView.navBarOverlap` | No equivalent. The bar always floats over `BottomBar.body`. `BottomBarBodyPadding` reserves its space. |
| `PersistentTabView.margin` | `BottomBarLayout.offset` for the gap below the bar, and `BottomBarLayout.adaptive(maxWidth: ...)` for the width |
| `PersistentTabView.backgroundColor` | `Scaffold.backgroundColor` |
| `PersistentTabView.floatingActionButton`, `floatingActionButtonLocation` | `Scaffold.floatingActionButton`, or `BottomBarItems.centerAction` (since 3.1.0) for an action in the bar |
| `PersistentTabView.resizeToAvoidBottomInset` | `Scaffold.resizeToAvoidBottomInset`. `BottomBarLayout.avoidKeyboard` keeps the bar above the keyboard. |
| `PersistentTabView.stateManagement` | The `IndexedStack`. It keeps every tab and its pushed screens. |
| `PersistentTabView.keepNavigatorHistory` | No equivalent. Call `popUntil((r) => r.isFirst)` on the old tab's `Navigator` in `onSelected`. |
| `PersistentTabView.selectedTabPressConfig` | `BottomBarItems.onReselected` and `scrollToStartOnReselect` (since 3.1.0) |
| `SelectedTabPressConfig.onPressed` | `BottomBarItems.onReselected` (since 3.1.0) |
| `SelectedTabPressConfig.popAction` | Your `onReselected` callback. `popUntil((r) => r.isFirst)` matches `PopActionType.all`, and `pop()` matches `single`. |
| `SelectedTabPressConfig.scrollToTop` | `BottomBarItems.scrollToStartOnReselect` (since 3.1.0) |
| `PersistentTabView.avoidBottomPadding` | `BottomBarLayout.respectSafeArea` |
| `PersistentTabView.handleAndroidBackButtonPress` | The `PopScope` in the after file |
| `PersistentTabView.hideNavigationBar` | `BottomBarController.hide()` and `show()` |
| `PersistentTabView.hideOnScrollVelocity` | Hiding is on by default. `BottomBarScrollBehavior.deltaThreshold` sets how far to scroll before it flips. Set `hideOnScroll: false` to turn it off. |
| `PersistentTabView.screenTransitionAnimation`, `animatedTabBuilder` | No equivalent. Wrap the `IndexedStack` in your own transition. |
| `PersistentTabView.drawer`, `drawerEdgeDragWidth` | `Scaffold.drawer` and `Scaffold.drawerEdgeDragWidth` |
| `PersistentTabView.gestureNavigationEnabled` | No equivalent. Use a `PageView` in place of the `IndexedStack`. |
| `PersistentTabView.router` with `navigationShell` | `StatefulShellRoute` in `BottomBar.body`. See the [go_router recipe](../../EXAMPLES.md#go_router-statefulshellroute). |
| `PersistentTabConfig.screen` | The first route of that tab's `Navigator` |
| `PersistentTabConfig.item` | A `BottomBarItem` |
| `PersistentTabConfig.navigatorConfig` | The arguments of that tab's `Navigator`, such as `onGenerateRoute`, `initialRoute` and `observers` |
| `PersistentTabConfig.scrollController` | Not needed. `scrollToStartOnReselect` finds the visible list. |
| `PersistentTabConfig.noScreen` with `onPressed` | `BottomBarItems.centerAction` (since 3.1.0), or a `BottomBarItem` whose `onTap` runs the action |
| `ItemConfig.icon` | `BottomBarItem.icon`. When `inactiveIcon` is set, this icon moves to `BottomBarItem.selectedIcon`. |
| `ItemConfig.inactiveIcon` | `BottomBarItem.icon` |
| `ItemConfig.title` (a `String`) | `BottomBarItem.label` (a widget, such as `Text('Home')`) |
| `ItemConfig.activeForegroundColor` | `BottomBarItem.selectedColor` |
| `ItemConfig.inactiveForegroundColor` | `BottomBarItem.color` |
| `ItemConfig.activeColorSecondary` | `BottomBarIndicator.pill(color: ...)` or `.tint(color: ...)` (since 3.1.0) |
| `ItemConfig.inactiveBackgroundColor` | No equivalent |
| `ItemConfig.textStyle` | `BottomBarItemThemeData.labelStyle` (since 3.1.0) |
| `ItemConfig.iconSize` | `BottomBarItemThemeData.iconSize` (since 3.1.0) |
| `Style1BottomNavBar` to `Style16BottomNavBar`, `NeumorphicBottomNavBar` | No equivalent. Pick a `BottomBarIndicator` (since 3.1.0) and a `BottomBarItemThemeData`. |
| `NavBarDecoration` | `BottomBarThemeData.barDecoration`, or `BottomBarThemeData.surface` (since 3.1.0) |
| `pushScreen`, `pushWithNavBar` | `Navigator.of(context).push(...)` from inside a tab |
| `pushWithoutNavBar` | `Navigator.of(context, rootNavigator: true).push(...)` |

## Behaviour differences

- **Hide on scroll.** `persistent_bottom_nav_bar_v2` hides the bar only when
  `hideOnScrollVelocity` is above 0, which is not the default. This bar hides
  on scroll by default. While the bar is hidden, a scroll-to-top button shows.
  Set `showIcon: false` to remove it.
- **Safe area.** With `avoidBottomPadding: true`, the old bar sits above the
  system bottom inset. `BottomBar` wraps the bar in a `SafeArea` and floats it
  `layout.offset` above that.
- **Body padding.** With the default `NavBarOverlap.none`, the old tabs end at
  the top of the bar. Here the bar floats over the body. `BottomBarBodyPadding`
  around the `IndexedStack` keeps the last row clear.
- **Back button.** The old package pops the current tab, then goes to the
  previous tab in its history, then exits. The after file pops the current
  tab, then goes to Home, then exits. Keep a list of visited indexes if you
  want the history.
- **State per tab.** Both keep every tab and its pushed screens alive. The old
  package does it with `stateManagement`. The after file does it with an
  `IndexedStack` of `Navigator`s.
- **Reselect.** The old package pops all screens of the tab, or scrolls to top
  when a `scrollController` is set. The after file pops to the root, or
  scrolls the visible list to its start when the tab is already at its root.
- **Push without the bar.** Push on the root navigator to cover the bar, as
  `pushWithoutNavBar` does.

## Live demo

The [go_router shell demo](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/go-router-shell)
shows per-tab stacks, reselect and back with go_router.

[All migration guides](README.md)
