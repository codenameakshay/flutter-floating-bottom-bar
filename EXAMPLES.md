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

While the `TextField` is focused, the default `keepVisibleOnFocus: true` keeps
the bar visible as the body scrolls.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class FocusAwareBottomBarExample extends StatelessWidget {
  const FocusAwareBottomBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 40,
            itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(hintText: 'Search'),
          ),
        ),
      ),
    );
  }
}
```

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
