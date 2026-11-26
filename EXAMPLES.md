# Examples

Runnable demos live under `example/lib/demos/`. This file keeps the docs-side
snippets short, current, and directly compilable.

Moving from another bottom bar? See the
[migration guides](./docs/migrate/README.md).

Run the demo app:

```bash
cd example
fvm flutter run
```

## Recipes

Copy-paste answers for the commonest apps. Each one is a full page in `example/lib/recipes/`, and the [recipes page](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipes) opens all seven.

| Recipe | Use this when | Playground |
| --- | --- | --- |
| [Composer](#composer) | A chat or prompt input should sit above the keyboard. | [recipe-composer](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-composer) |
| [Selection dock](#selection-dock) | A long-press selects rows and the navigation turns into "N selected" actions. | [recipe-selection-dock](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-selection-dock) |
| [Reader controls](#reader-controls) | A reading screen should bring its controls back on a tap without moving the page. | [recipe-reader-controls](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-reader-controls) |
| [Scroll under](#scroll-under) | A `CustomScrollView` should scroll under a glass bar while its last row still clears the bar. | [recipe-scroll-under](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-scroll-under) |
| [Long labels](#long-labels) | Five tabs with long labels must stay usable on small phones, at large text sizes and in right-to-left layouts. | [recipe-long-labels](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-long-labels) |
| [Mini player](#mini-player) | A now-playing row above the tabs should shrink with the bar. | [recipe-mini-player](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-mini-player) |
| [Split bar](#split-bar) | You want the iOS 26 split tab bar: a pill, a profile button before it and a search circle after it, in glass. | [recipe-split-bar](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-split-bar) |

### Composer

Use this when a chat or prompt input should sit above the keyboard.

Source: [composer.dart](example/lib/recipes/composer.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-composer)

<!-- example/lib/recipes/composer.dart -->
```dart
void _send() {
  final message = _text.text.trim();
  if (message.isEmpty) return;
  setState(() => _messages.insert(0, message));
  _text.clear();
}
```

<!-- example/lib/recipes/composer.dart -->
```dart
child: TextField(
  controller: _text,
  minLines: 1,
  maxLines: 5,
  decoration: const InputDecoration.collapsed(
    hintText: 'Ask anything',
  ),
),
```

- The `Scaffold` shrinks its body for the keyboard, so the bar rides on top of it. `BottomBarLayout.avoidKeyboard`, on by default, covers a body the `Scaffold` does not resize.
- `hideOnScroll: false` keeps the composer on screen. Scrolling the list never takes focus from the field.
- Send trims the text, adds the message and clears the field. Focus stays in the field, so the keyboard stays up.
- `maxLines: 5` grows the bar up to five lines, then the field scrolls. `BottomBarBodyPadding` follows the taller bar.

### Selection dock

Use this when a long-press selects rows and the navigation turns into "N selected" actions.

Source: [selection_dock.dart](example/lib/recipes/selection_dock.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-selection-dock)

<!-- example/lib/recipes/selection_dock.dart -->
```dart
child: BottomBarSwitcher(
  child: _selected.isEmpty
      ? BottomBarItems(
          key: const ValueKey('nav'),
          selectedIndex: _tab,
          onSelected: (i) => setState(() => _tab = i),
          indicator: const BottomBarIndicator.pill(),
          children: const [
            BottomBarItem(
              icon: Icon(Icons.inbox),
              label: Text('Inbox'),
            ),
            BottomBarItem(
              icon: Icon(Icons.star),
              label: Text('Starred'),
            ),
            BottomBarItem(icon: Icon(Icons.send), label: Text('Sent')),
          ],
        )
      : Row(
          key: const ValueKey('selection'),
          children: [
            IconButton(
              tooltip: 'Clear selection',
              onPressed: () => setState(_selected.clear),
              icon: const Icon(Icons.close),
            ),
            Expanded(child: Text('${_selected.length} selected')),
            IconButton(
              tooltip: 'Delete',
              onPressed: () => setState(() {
                _rows.removeWhere(_selected.contains);
                _selected.clear();
              }),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
),
```

- `BottomBarSwitcher` morphs the bar when its child's key changes, here from `nav` to `selection` and back.
- The tab index lives in the page state, so clearing the selection returns to the same tab. The list keeps its scroll position because it lives in the body, not in the switcher.
- While rows are selected, a tap toggles a row. Delete removes the selected rows and brings the navigation back.

### Reader controls

Use this when a reading screen should bring its controls back on a tap without moving the page.

Source: [reader_controls.dart](example/lib/recipes/reader_controls.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-reader-controls)

<!-- example/lib/recipes/reader_controls.dart -->
```dart
controller: _bar,
showIcon: false,
body: Semantics(
  container: true,
  label: 'Article. Tap to show reading controls',
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _bar.show,
```

- `showIcon: false` removes the back-to-top action, which would scroll the article.
- `BottomBarController.show()` only animates the bar, so the scroll offset stays where it was.
- `HitTestBehavior.opaque` catches taps between paragraphs too. Drags still scroll and hide the bar.
- The `Semantics` label gives screen reader users the same tap to bring the controls back.

### Scroll under

Use this when a `CustomScrollView` should scroll under a glass bar while its last row still clears the bar.

Source: [scroll_under.dart](example/lib/recipes/scroll_under.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-scroll-under)

<!-- example/lib/recipes/scroll_under.dart -->
```dart
body: Builder(
  builder: (context) => ValueListenableBuilder<double>(
    valueListenable: BottomBarScope.of(context).barHeight,
    builder: (context, barHeight, _) => CustomScrollView(
      slivers: [
        const SliverAppBar.medium(title: Text('Scroll under')),
        SliverPadding(
          padding: EdgeInsets.only(bottom: barHeight),
          sliver: SliverList.builder(
```

- `BottomBarBodyPadding` would shrink the viewport, so nothing would scroll under the bar. Read `BottomBarScope.barHeight` and pad the last sliver instead.
- `barHeight` is the measured footprint: the bar, its offset and the bottom safe area. It keeps its value while the bar is hidden, so content does not jump.
- When the dock grows, `BottomBarSwitcher` springs the height and `barHeight` follows every frame, so the padding grows with it.

### Long labels

Use this when five tabs with long labels must stay usable on small phones, at large text sizes and in right-to-left layouts.

Source: [long_labels.dart](example/lib/recipes/long_labels.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-long-labels)

<!-- example/lib/recipes/long_labels.dart -->
```dart
child: BottomBarItems(
  selectedIndex: _index,
  onSelected: (i) => setState(() => _index = i),
  indicator: const BottomBarIndicator.pill(),
  children: [
    for (final (icon, label) in _tabs)
      BottomBarItem(icon: Icon(icon), label: Text(label)),
  ],
),
```

- No extra code. Each item keeps a 48 x 48 target, and a label that does not fit its slot ends in an ellipsis.
- Labels follow the text size up to 1.3x, like `NavigationBar`. Above 1.3x, a long-press shows the full label in a tooltip, and screen readers read the full label.
- The row mirrors in right to left. The page's app bar toggles 2x text and right to left so you can try both.

### Mini player

Use this when a now-playing row above the tabs should shrink with the bar.

Source: [mini_player.dart](example/lib/recipes/mini_player.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-mini-player)

<!-- example/lib/recipes/mini_player.dart -->
```dart
theme: BottomBarThemeData.glass(),
scrollBehavior: const BottomBarScrollBehavior(
  minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
),
accessory: NowPlaying(
  playing: _playing,
  onToggle: () => setState(() => _playing = !_playing),
),
```

<!-- example/lib/recipes/mini_player.dart -->
```dart
final expanded =
    BottomBarAccessoryPlacement.of(context) ==
    BottomBarAccessoryPlacement.expanded;
```

- `minimizeBehavior: onScrollDown` shrinks the bar into a pill on scroll down, and the accessory moves inline beside it.
- `BottomBarAccessoryPlacement.of(context)` picks the layout: title, artist and Next when expanded, title and Play when inline.
- The play state lives in the page, so it survives the move. Tapping the inline player runs its buttons and never expands the bar.

### Split bar

Use this when you want the iOS 26 split tab bar: a pill, a profile button before it and a search circle after it, in glass.

Source: [split_bar.dart](example/lib/recipes/split_bar.dart) · [Try it](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/recipe-split-bar)

<!-- example/lib/recipes/split_bar.dart -->
```dart
theme: BottomBarThemeData.glass(),
layout: const BottomBarLayout.adaptive(
  maxWidth: 480,
  borderRadius: BorderRadius.all(Radius.circular(999)),
),
leading: IconButton(
  tooltip: 'Profile',
  onPressed: () {},
  icon: const CircleAvatar(radius: 16, child: Text('JD')),
),
trailing: IconButton(
  tooltip: 'Search',
  onPressed: () {},
  icon: const Icon(Icons.search),
),
```

- `leading` and `trailing` are separate pieces with the bar's glass. A 999 radius makes the pill and the circles.
- The gaps between the pieces pass taps through to the content below.
- The grid pads itself with `BottomBarScope.barHeight`, so the photos scroll under the glass.

## Minimal bar

Related runnable demo: `example/lib/demos/basic_demo.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class MinimalBottomBarExample extends StatelessWidget {
  const MinimalBottomBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(maxWidth: 420),
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 40,
            itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
          ),
        ),
        child: const SizedBox(
          height: 56,
          child: Center(child: Text('Floating widget')),
        ),
      ),
    );
  }
}
```

## Focus-aware search bar

Moved to the [Composer](#composer) recipe. While a field in the bar has focus, the default `keepVisibleOnFocus: true` keeps the bar visible as the body scrolls.

To opt out, pass
`scrollBehavior: const BottomBarScrollBehavior(keepVisibleOnFocus: false)`.

## `BottomBarItems` navigation row

Related runnable demo: `example/lib/demos/badges_demo.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BottomBarItemsExample extends StatefulWidget {
  const BottomBarItemsExample({super.key});

  @override
  State<BottomBarItemsExample> createState() => _BottomBarItemsExampleState();
}

class _BottomBarItemsExampleState extends State<BottomBarItemsExample> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 30,
            itemBuilder: (_, row) => ListTile(title: Text('Row $row')),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: const Text('Home'),
                semanticLabel: 'Home tab',
                selected: index == 0,
                onTap: () => setState(() => index = 0),
              ),
              BottomBarItem(
                icon: const Icon(Icons.inbox_outlined),
                selectedIcon: const Icon(Icons.inbox_rounded),
                label: const Text('Inbox'),
                badge: const Badge(label: Text('3')),
                tooltip: 'Inbox tab',
                selected: index == 1,
                onTap: () => setState(() => index = 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Here the first item uses `semanticLabel` as its explicit accessible name, while
the second falls back to `tooltip`. If neither is provided, the item's
descendant semantics remain visible.

## Nested scroll + controller

Related runnable demo: `example/lib/demos/nested_scroll_demo.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class NestedScrollExample extends StatefulWidget {
  const NestedScrollExample({super.key});

  @override
  State<NestedScrollExample> createState() => _NestedScrollExampleState();
}

class _NestedScrollExampleState extends State<NestedScrollExample> {
  final controller = BottomBarController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: controller.scrollToStart,
        child: const Icon(Icons.vertical_align_top_rounded),
      ),
      body: BottomBar(
        controller: controller,
        scrollBehavior: BottomBarScrollBehavior(
          predicate: (notification) => notification.depth == 0,
          showAtStart: true,
          showOnScrollEnd: true,
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => const [
            SliverAppBar(
              pinned: true,
              expandedHeight: 180,
              flexibleSpace: FlexibleSpaceBar(title: Text('Nested scroll')),
            ),
          ],
          body: ListView.builder(
            itemCount: 100,
            itemBuilder: (_, index) => ListTile(title: Text('Row $index')),
          ),
        ),
        child: const SizedBox(
          height: 56,
          child: Center(child: Text('Controller-aware bar')),
        ),
      ),
    );
  }
}
```

## Paint-only custom transition

Related runnable demo: `example/lib/demos/custom_transition_demo.dart`.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class CustomTransitionExample extends StatelessWidget {
  const CustomTransitionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        motion: BottomBarMotion.motor(
          Motion.snappySpring(),
          transitionBuilder: (context, animation, child) {
            final value = animation.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.92 + (0.08 * value),
                child: child,
              ),
            );
          },
        ),
        body: ListView.builder(
          itemCount: 60,
          itemBuilder: (_, index) => ListTile(title: Text('Row $index')),
        ),
        child: const SizedBox(
          height: 56,
          child: Center(child: Text('Paint-only transition')),
        ),
      ),
    );
  }
}
```

`Motion` is re-exported by this package on purpose, so
`BottomBarMotion.motor(Motion.snappySpring())` does not require an extra import
from `motor`.

## go_router (StatefulShellRoute)

Related runnable demo: `example/lib/demos/go_router_shell_demo.dart`
([live](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/go-router-shell)).

`StatefulShellRoute.indexedStack` gives each tab its own `Navigator` and
keeps visited tabs alive in an `IndexedStack`. Put the `navigationShell` in
`BottomBar.body` and drive `BottomBarItems` from `currentIndex`. The bar
follows the active branch and shows itself on a branch change; see
[Tabs and pages](./README.md#tabs-and-pages) for the rule and the
`visibilityOnTabChange` option. Add
`go_router` to your app's `pubspec.yaml`. This package does not depend on it.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';

const branchRoots = ['/home', '/search', '/inbox', '/profile'];

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ScaffoldWithBottomBar(
        location: state.uri.path,
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomePage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      DetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (_, _) => const InboxPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      DetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithBottomBar extends StatefulWidget {
  const ScaffoldWithBottomBar({
    required this.location,
    required this.navigationShell,
    super.key,
  });

  final String location;
  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithBottomBar> createState() => _ScaffoldWithBottomBarState();
}

class _ScaffoldWithBottomBarState extends State<ScaffoldWithBottomBar> {
  final _bar = BottomBarController();

  @override
  void didUpdateWidget(ScaffoldWithBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex) {
      _bar.show();
    }
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final atRoot = widget.location == branchRoots[shell.currentIndex];
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: BottomBar(
          controller: _bar,
          layout: const BottomBarLayout.adaptive(maxWidth: 420, offset: 16),
          body: shell,
          child: BottomBarItems(
            selectedIndex: shell.currentIndex,
            indicator: const BottomBarIndicator.pill(),
            scrollToStartOnReselect: atRoot,
            onReselected: (i) {
              if (!atRoot) shell.goBranch(i, initialLocation: true);
            },
            onSelected: (i) {
              if (i != shell.currentIndex) shell.goBranch(i);
            },
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(
                icon: Icon(Icons.inbox),
                label: Text('Inbox'),
                badge: BottomBarBadge.count(3),
              ),
              BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
        ),
      ),
    );
  }
}
```

Each tab page is a normal `Scaffold`. Wrap its list in `BottomBarBodyPadding`
so the last rows clear the bar. Give the app the router with
`MaterialApp.router(routerConfig: router)`.

**Reselect rule.** A tap on the selected tab does one of two things:

- If the tab is deeper than its root, `goBranch(i, initialLocation: true)`
  pops it back to the root.
- If the tab is at its root, `scrollToStartOnReselect` scrolls the visible
  list to the top.

`onSelected` also fires on a reselect, after `onReselected`, so it ignores the
current index. The recipe uses `scrollToStartOnReselect: atRoot`. It shows
the bar and scrolls the branch's visible list, even before that list has
scrolled. At depth the flag is off, so the reselect does not scroll the page
that is about to close.

**Back rule.** Android system back goes in this order:

1. go_router pops the current tab's own stack first.
2. At the root of a tab other than Home, the shell's `PopScope` blocks the pop
   and goes to Home.
3. At the root of Home, `canPop` is true, so the app pops as usual.

Step 2 runs after the pop is refused, so Android predictive back shows no
preview of Home.

**Scroll and bar state.** Each tab keeps its own scroll position, because
the `IndexedStack` keeps visited tabs alive. The bar's scroll target skips tabs
that are offstage, so the hidden action and `scrollToStartOnReselect` scroll
only the visible tab. `didUpdateWidget` shows the bar when the branch index
changes, so a tab tap, the back rule and `context.go` all bring the bar back.

**Inside another app.** The demo app has its own `MaterialApp` routes, so the
demo mounts go_router as a nested `Router`. It passes a
`RouteInformationProvider` that reads go_router's location but does not send
it to the platform, so the browser URL stays the app's. It also sets
`overridePlatformDefaultLocation: true`, so go_router does not start at the
app's deep link. Back reaches the app's `Navigator` first, so the demo's page
forwards it to `routerDelegate.popRoute()` until Home is at its root. Away
from Home's root that page refuses the iOS edge swipe, so the demo puts a
Close button on each tab root. You do not need any of this when go_router is
your app's router.

## go_router shell with an adaptive rail

`BottomBarAdaptive` takes the shell's `navigationShell` as its `body`. The
shell keeps each branch's stack, and the rail keeps the shell's state when the
window crosses the breakpoint.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => Scaffold(
        body: BottomBarAdaptive(
          theme: BottomBarThemeData.glass(),
          items: BottomBarItems(
            selectedIndex: navigationShell.currentIndex,
            onSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home),
                label: const Text('Home'),
              ),
              BottomBarItem(
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
              BottomBarItem(
                icon: const Icon(Icons.inbox),
                label: const Text('Inbox'),
              ),
              BottomBarItem(
                icon: const Icon(Icons.person),
                label: const Text('Profile'),
              ),
            ],
          ),
          body: navigationShell,
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/inbox', builder: (_, _) => const InboxPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
          ],
        ),
      ],
    ),
  ],
);
```

## Contextual dock with BottomBarSwitcher

Moved to the [Selection dock](#selection-dock) recipe, which adds long-press selection and keeps the tab when the selection clears.

## Demo index

- `example/lib/demos/basic_demo.dart`
- `example/lib/demos/basic_tab_bar_demo.dart`
- `example/lib/demos/issues_dock_demo.dart`
- `example/lib/demos/ai_prompt_dock_demo.dart`
- `example/lib/demos/nested_scroll_demo.dart`
- `example/lib/demos/badges_demo.dart`
- `example/lib/demos/custom_transition_demo.dart`
- `example/lib/demos/go_router_shell_demo.dart`
- `example/lib/demos/tabs_demo.dart`
- `example/lib/demos/adaptive_rail_demo.dart`
- `example/lib/demos/switcher_demo.dart`
- `example/lib/recipes/` (the seven recipes)

The adaptive rail demo is live at `#/adaptive-rail`.

## Recording gifs

The repo includes `tool/record_gif.sh` for simulator recordings:

```bash
make run-ios
make record NAME=1-issues-dock
```

Use these slugs so screenshots and docs stay aligned:

| Demo | Slug |
| --- | --- |
| Issues dock | `1-issues-dock` |
| AI prompt dock | `2-ai-prompt-dock` |
| Basic TabBar | `3-basic-tab-bar` |
| Minimal API | `4-minimal-api` |
| Nested scroll | `5-nested-scroll` |
| Badged nav | `6-badged-nav` |
| Custom transition | `7-custom-transition` |
