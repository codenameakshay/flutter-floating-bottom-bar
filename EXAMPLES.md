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
import 'package:material_ui/material_ui.dart';
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
import 'package:material_ui/material_ui.dart';
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
import 'package:material_ui/material_ui.dart';
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
import 'package:material_ui/material_ui.dart';
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

## Recipe demos

These five runnable pages show the patterns that need a little more context
than a short API snippet. Each link points to the source used by the example
app.

### Contextual issue actions

[Issues dock source](example/lib/demos/issues_dock_demo.dart) keeps selection,
filters, and the dock actions in the same app state. Selecting an issue changes
the dock from filters to contextual archive and clear actions.

### Local composer

[Composer source](example/lib/demos/ai_prompt_dock_demo.dart) is a local draft
and transcript example. It keeps the current draft in the composer and stores
submitted text as local transcript entries; it has no AI response engine.

### Reading controls

[Reading controls source](example/lib/demos/reader_demo.dart) hides the built-in
action with `showIcon: false` and calls `controller.show` from an explicit
reading-controls button. This keeps the reveal action specific to the reader
instead of presenting a generic scroll affordance.

### Scroll under

[Scroll under source](example/lib/demos/scroll_under_demo.dart) reads
`BottomBarScope.of(context).barHeight` and feeds that measured value into the
native `SliverPadding`. The measured footprint stays reserved while the bar is
hidden, so the final row can scroll clear of the floating dock.

### Adaptive navigation

[Adaptive navigation source](example/lib/demos/adaptive_navigation_demo.dart)
uses a wrapping destination layout at standard text sizes and switches to
labeled rows for large text while preserving the inherited
`MediaQuery.textScaler`. The selected destination is app state, and its content
changes with the selected item.

## Demo index

- `example/lib/demos/basic_demo.dart`
- `example/lib/demos/basic_tab_bar_demo.dart`
- `example/lib/demos/issues_dock_demo.dart`
- `example/lib/demos/ai_prompt_dock_demo.dart`
- `example/lib/demos/reader_demo.dart`
- `example/lib/demos/scroll_under_demo.dart`
- `example/lib/demos/adaptive_navigation_demo.dart`
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
| Legacy prompt visual | `2-ai-prompt-dock` |
| Basic TabBar | `3-basic-tab-bar` |
| Minimal API | `4-minimal-api` |
| Nested scroll | `5-nested-scroll` |
| Badged nav | `6-badged-nav` |
| Custom transition | `7-custom-transition` |
