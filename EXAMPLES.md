# Recipes

A catalogue of patterns for `flutter_floating_bottom_bar` v2.0+. Each recipe in §1–6 has a runnable counterpart under `example/lib/demos/`. Run them with:

```bash
cd example && flutter run
```

Then pick the demo from the in-app picker.

---

## 1. Basic

The minimal `BottomBar` setup: provide a `child` (the floating widget) and a `body` (the scrollable content). Use `BottomBarLayout` to control width and corner radius. This is the starting point for every other recipe.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BasicDemoPage extends StatelessWidget {
  const BasicDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This is the floating widget',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
```

---

## 2. Tab bar with FAB notch

A 5-tab bar that changes colour with each page, with a floating action button notched into the bar. Demonstrates `BottomBarThemeData`, `BottomBarMotion`, `BottomBarScrollBehavior`, and a custom `icon` builder for the scroll-to-top affordance.

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../widgets/infinite_list_page.dart';

class TabBarDemoPage extends StatefulWidget {
  const TabBarDemoPage({super.key});

  @override
  State<TabBarDemoPage> createState() => _TabBarDemoPageState();
}

class _TabBarDemoPageState extends State<TabBarDemoPage>
    with SingleTickerProviderStateMixin {
  late int currentPage;
  late TabController tabController;
  final List<Color> colors = [
    Colors.yellow,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    currentPage = 0;
    tabController = TabController(length: 5, vsync: this);
    tabController.animation?.addListener(() {
      final value = tabController.animation!.value.round();
      if (value != currentPage && mounted) {
        setState(() => currentPage = value);
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselectedColor =
        colors[currentPage].computeLuminance() < 0.5 ? Colors.black : Colors.white;
    final unselectedColorReverse =
        colors[currentPage].computeLuminance() < 0.5 ? Colors.white : Colors.black;
    final barFillColor = colors[currentPage].computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text('Tab bar demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width * 0.8,
          offset: 10,
          borderRadius: BorderRadius.circular(500),
          alignment: Alignment.bottomCenter,
          fit: StackFit.expand,
          clip: Clip.none,
        ),
        motion: const BottomBarMotion(
          duration: Duration(milliseconds: 500),
          curve: Curves.decelerate,
          slideStart: Offset(0, 3),
        ),
        scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: true),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: colors[currentPage],
            borderRadius: BorderRadius.circular(500),
          ),
          iconDecoration: BoxDecoration(
            color: unselectedColor,
            borderRadius: BorderRadius.circular(500),
          ),
          iconWidth: 30,
          iconHeight: 30,
        ),
        icon: (width, height) => Center(
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: null,
            icon: Icon(
              Icons.arrow_upward_rounded,
              color: colors[currentPage],
              size: width,
            ),
          ),
        ),
        body: TabBarView(
          controller: tabController,
          dragStartBehavior: DragStartBehavior.down,
          physics: const BouncingScrollPhysics(),
          children: colors
              .map((c) => InfiniteListPage(
                    key: ValueKey('infinite_list_$c'),
                    color: c,
                  ))
              .toList(),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            TabBar(
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorPadding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
              controller: tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: barFillColor,
                  width: 4,
                ),
                insets: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              ),
              tabs: [
                _tab(Icons.home, 0, unselectedColor),
                _tab(Icons.search, 1, unselectedColor),
                _tab(Icons.add, 2, unselectedColorReverse),
                _tab(Icons.favorite, 3, unselectedColor),
                _tab(Icons.settings, 4, unselectedColor),
              ],
            ),
            Positioned(
              top: -20,
              child: FloatingActionButton(
                elevation: 0,
                onPressed: () {},
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(IconData icon, int idx, Color unselected) {
    return SizedBox(
      height: 55,
      width: 40,
      child: Center(
        child: Icon(
          icon,
          color: currentPage == idx ? colors[idx] : unselected,
        ),
      ),
    );
  }
}
```

The `InfiniteListPage` helper widget used above:

```dart
import 'package:flutter/material.dart';

class InfiniteListPage extends StatelessWidget {
  final Color color;
  const InfiniteListPage({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) =>
          ListTile(onTap: () {}, tileColor: color, title: Text("$index")),
    );
  }
}
```

---

## 3. Search bar

Turns the floating bar into a full-width search field. The bar slides in from below with a custom easing curve; the `body` is a live results list. Use this pattern whenever the primary action is search.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class SearchBarDemoPage extends StatelessWidget {
  const SearchBarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search bar demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(32),
          alignment: Alignment.bottomCenter,
        ),
        motion: const BottomBarMotion(
          duration: Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Result $i')),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search...',
                  ),
                ),
              ),
              Icon(Icons.tune),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 4. Nested scroll

Wraps a `NestedScrollView` (collapsing `SliverAppBar` + inner list) inside `BottomBar`. The bar tracks the inner scroll controller automatically. Use this whenever you need a collapsing header alongside the floating bar.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class NestedScrollDemoPage extends StatelessWidget {
  const NestedScrollDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => const [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(title: Text('Nested scroll')),
            ),
          ],
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Bar over a NestedScrollView'),
        ),
      ),
    );
  }
}
```

---

## 5. Badges and items

Uses the `BottomBarItems` + `BottomBarItem` helpers to build a standard 3-tab nav bar with icon/label pairs and a notification badge on the inbox tab. Swap the `badge` property to drive live unread counts from your state management layer.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BadgesDemoPage extends StatefulWidget {
  const BadgesDemoPage({super.key});

  @override
  State<BadgesDemoPage> createState() => _BadgesDemoPageState();
}

class _BadgesDemoPageState extends State<BadgesDemoPage> {
  int _index = 0;

  Widget _badge(String count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(28),
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: const Text('Home'),
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              BottomBarItem(
                icon: const Icon(Icons.inbox_outlined),
                selectedIcon: const Icon(Icons.inbox),
                label: const Text('Inbox'),
                badge: _badge('3'),
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              BottomBarItem(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: const Text('Profile'),
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Custom transition

Replaces the default slide animation with a combined fade + scale via `BottomBarMotion.transitionBuilder`. Any `AnimationController`-driven widget can be plugged in here — scale, rotation, blur, etc.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class CustomTransitionDemoPage extends StatelessWidget {
  const CustomTransitionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom transition demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        motion: BottomBarMotion(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          transitionBuilder: (ctx, anim, child) {
            return Opacity(
              opacity: anim.value,
              child: Transform.scale(
                scale: 0.6 + 0.4 * anim.value,
                child: child,
              ),
            );
          },
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Custom fade + scale transition'),
        ),
      ),
    );
  }
}
```

---

## 7. Theming with `BottomBarThemeData`

Set app-wide bar defaults by adding `BottomBarThemeData` to `ThemeData.extensions`. Any `BottomBar` widget that does not supply its own `theme:` parameter will inherit these values automatically.

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: Colors.indigo,
    useMaterial3: true,
    extensions: const [
      BottomBarThemeData(
        iconWidth: 36,
        iconHeight: 36,
      ),
    ],
  ),
  home: ...,
);
```

Override per-widget by passing a local `theme:` to `BottomBar`:

```dart
BottomBar(
  theme: BottomBarThemeData(
    barDecoration: BoxDecoration(
      color: Colors.deepPurple,
      borderRadius: BorderRadius.circular(24),
    ),
  ),
  body: ...,
  child: ...,
)
```

---

## 8. Imperative show/hide via `BottomBarController`

Create a `BottomBarController` and pass it to `BottomBar`. Call `hide()`, `show()`, or `scrollToStart()` from anywhere in your widget tree — useful for hiding the bar during full-screen media playback or chat input focus.

```dart
final controller = BottomBarController();

// In build:
BottomBar(
  controller: controller,
  body: ...,
  child: ...,
)

// Elsewhere (e.g. a button handler or focus listener):
controller.hide();
controller.show();
await controller.scrollToStart();
```

Remember to dispose the controller when the owning widget is removed:

```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

---

## 9. Reading bar height in body via `BottomBarScope`

`BottomBarScope.of(ctx).barHeight` is a `ValueListenable<double>` that reflects the rendered height of the floating bar. Use it to add bottom padding to your scrollable content so the last item is never obscured.

```dart
BottomBar(
  body: Builder(
    builder: (ctx) {
      final h = BottomBarScope.of(ctx).barHeight;
      return ValueListenableBuilder<double>(
        valueListenable: h,
        builder: (_, height, __) => ListView(
          padding: EdgeInsets.only(bottom: height + 16),
          children: [...],
        ),
      );
    },
  ),
  child: ...,
)
```

`Builder` is required here because `BottomBarScope` is inserted below the `BottomBar` widget itself; `ctx` must be a descendant context.

---

For an API reference, see the project [README](./README.md).
