# Examples

Runnable demos live under `example/lib/demos/`. This file keeps the docs-side
snippets short, current, and directly compilable.

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

## Demo index

- `example/lib/demos/basic_demo.dart`
- `example/lib/demos/basic_tab_bar_demo.dart`
- `example/lib/demos/tab_bar_demo.dart`
- `example/lib/demos/search_bar_demo.dart`
- `example/lib/demos/nested_scroll_demo.dart`
- `example/lib/demos/badges_demo.dart`
- `example/lib/demos/custom_transition_demo.dart`

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
