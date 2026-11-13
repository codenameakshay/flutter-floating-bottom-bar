# Replacing existing bars

Recipes for converting common bottom-bar patterns to `flutter_floating_bottom_bar`. Each recipe shows the **before** (what the user typically has) and the **after** (what to ship).

**Full guides with a property-by-property mapping live in the repo at [`docs/migrate/`](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/README.md):** `BottomNavigationBar`, `NavigationBar`, `google_nav_bar`, `convex_bottom_bar`, `salomon_bottom_bar`, `persistent_bottom_nav_bar_v2` and `animated_bottom_navigation_bar`. Each guide's after code is a compiled file in `example/lib/migrate/`. Prefer those guides over the short notes below when the user is on one of those bars.

**Version check first.** `selectedIndex`/`onSelected`, indicators, badges, the item theme, the centre action and `BottomBarSurface` are since 3.1.0. Check the user's resolved version in `pubspec.lock`. On 3.0.1, drive selection with `selected:` + `onTap:` on each `BottomBarItem` instead.

The general transformation is:
1. Find the `Scaffold` and its `body` + `bottomNavigationBar` (or equivalent).
2. Move the scrollable from `body:` to `BottomBar.body`.
3. Move the bar widget into `BottomBar.child` (mapping its API to ours).
4. Remove `Scaffold.bottomNavigationBar`.
5. Wrap the body in `BottomBarBodyPadding` so the last item isn't hidden behind the bar.

## 1. `BottomNavigationBar` (Material 2)

### Before
```dart
Scaffold(
  body: ListView.builder(
    itemCount: 50,
    itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _index,
    onTap: (i) => setState(() => _index = i),
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  ),
);
```

### After
```dart
Scaffold(
  body: BottomBar(
    layout: const BottomBarLayout.adaptive(maxWidth: 420),
    body: BottomBarBodyPadding(
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: BottomBarItems(
        selectedIndex: _index, // since 3.1.0
        onSelected: (i) => setState(() => _index = i), // since 3.1.0
        children: const [
          BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
          BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
          BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
        ],
      ),
    ),
  ),
);
```

**Mapping notes** (full table: [bottom-navigation-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/bottom-navigation-bar.md)):
- `BottomNavigationBarItem.icon` → `BottomBarItem.icon`; `activeIcon` → `selectedIcon`. If the user only had a single icon, keep it that way — `selectedIcon` is optional.
- `BottomNavigationBarItem.label` (String) → `Text(label)` widget.
- `currentIndex` + `onTap` → `BottomBarItems.selectedIndex` + `onSelected` (since 3.1.0). On 3.0.1: `selected: _index == N` + `onTap: () => setState(() => _index = N)` on each item. **Keep the user's existing `_index` field** — don't rename to `_currentIndex` or vice versa.
- Color → if they had `selectedItemColor: Colors.purple`, set `BottomBarItem.selectedColor: Colors.purple` on each item, or `BottomBarItemThemeData.selectedColor` (since 3.1.0) app-wide.
- `BottomBarBodyPadding` reserves the bar's measured footprint (height + `layout.offset` + bottom safe area). Don't hand-tune a magic bottom padding.

## 2. `NavigationBar` (Material 3)

### Before
```dart
Scaffold(
  body: ListView.builder(...),
  bottomNavigationBar: NavigationBar(
    selectedIndex: _index,
    onDestinationSelected: (i) => setState(() => _index = i),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: 'Inbox',
      ),
    ],
  ),
);
```

### After

Same shape as the `BottomNavigationBar` recipe — `NavigationDestination` already gives you `icon` + `selectedIcon`, so the mapping is direct. Add `indicator: const BottomBarIndicator.pill()` (since 3.1.0) to `BottomBarItems` for the M3 indicator. Full table: [navigation-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/navigation-bar.md).

```dart
BottomBarItem(
  icon: const Icon(Icons.home_outlined),
  selectedIcon: const Icon(Icons.home),
  label: const Text('Home'),
),
```

**Material 3 hint:** the default `borderRadius` is already 28 — it matches the M3 expressive shape language. The default `BottomBarThemeData` already uses `colorScheme.surfaceContainer`, so M3 theming is automatic.

## 3. `BottomAppBar` (with FAB notch)

This is the trickiest case — the user typically has a `FloatingActionButton` registered on the `Scaffold` that sits in a notch cut out of the `BottomAppBar`.

### Before
```dart
Scaffold(
  body: ListView.builder(...),
  floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
  floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
  bottomNavigationBar: BottomAppBar(
    shape: const CircularNotchedRectangle(),
    notchMargin: 8,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        const SizedBox(width: 40), // notch space
        IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
      ],
    ),
  ),
);
```

### After

Use `BottomBarItems.centerAction` with `BottomBarCenterActionStyle.notched` (since 3.1.0). The bar's outline is cut around the action with a smooth circular notch, and the action hides with the bar. On 3.0.1 there is no notch: overhang a FAB with a `Stack` + `Positioned(top: -24)` in `BottomBar.child` and set `clip: Clip.none` on the layout.

```dart
Scaffold(
  body: BottomBar(
    layout: const BottomBarLayout.adaptive(maxWidth: 420),
    body: BottomBarBodyPadding(
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: BottomBarItems(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        labelBehavior: BottomBarLabelBehavior.alwaysHide,
        centerAction: BottomBarCenterAction(
          icon: const Icon(Icons.add),
          tooltip: 'Add',
          style: BottomBarCenterActionStyle.notched,
          onPressed: _add,
        ),
        children: const [
          BottomBarItem(icon: Icon(Icons.menu), label: Text('Menu')),
          BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
          BottomBarItem(icon: Icon(Icons.favorite_border), label: Text('Saved')),
          BottomBarItem(icon: Icon(Icons.person_outline), label: Text('Profile')),
        ],
      ),
    ),
  ),
);
```

**Drop `Scaffold.floatingActionButton` and `floatingActionButtonLocation`** — the action now lives in the bar. Otherwise you'll have two FABs. The action takes slot `children.length ~/ 2`, so use an even number of items to centre it. It is a button, not a tab: it does not count toward `selectedIndex`. If the old row used plain `IconButton`s with no selection, keep that row as-is instead of converting to tabs. Same pattern for `animated_bottom_navigation_bar`: [animated-bottom-navigation-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/animated-bottom-navigation-bar.md).

## 4. Hand-rolled custom bars

Anything pattern-matched as: `Container` with `decoration:` and a `Row` of icons inside `bottomNavigationBar:`.

### Before
```dart
Scaffold(
  body: ListView.builder(...),
  bottomNavigationBar: Container(
    height: 70,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(40),
      boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
    ),
    margin: const EdgeInsets.all(12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        Icon(Icons.home),
        Icon(Icons.search),
        Icon(Icons.person),
      ],
    ),
  ),
);
```

### After

For hand-rolled bars, **preserve the user's visual design exactly** — just move it into `BottomBar.child` and lift the decoration into `BottomBarThemeData.barDecoration`. The skill's job is to add scroll-reactivity + spring motion, not to redesign their bar.

```dart
Scaffold(
  body: BottomBar(
    layout: const BottomBarLayout.adaptive(
      maxWidth: 480,
      offset: 12,
      borderRadius: BorderRadius.all(Radius.circular(40)),
    ),
    theme: BottomBarThemeData(
      barDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
    ),
    body: BottomBarBodyPadding(
      child: ListView.builder(
        itemCount: 50,
        itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
      ),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home),
          Icon(Icons.search),
          Icon(Icons.person),
        ],
      ),
    ),
  ),
);
```

Don't strip their shadows, gradients, or borders. Don't change their selection logic. Don't replace their custom `Icon` widgets with `BottomBarItem` — that's a redesign, not a port.

## 5. Third-party packages

Each has a full guide with before/after code and a property table. Follow it:

| Package | Guide | Closest look |
| --- | --- | --- |
| `salomon_bottom_bar` | [salomon-bottom-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/salomon-bottom-bar.md) | `labelBehavior: BottomBarLabelBehavior.onlySelected` + `BottomBarIndicator.tint()`, per-item `selectedColor` |
| `google_nav_bar` | [google-nav-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/google-nav-bar.md) | Same as salomon. `GButton(icon: Icons.home)` takes `IconData`; ours takes `Icon(Icons.home)`. |
| `convex_bottom_bar` | [convex-bottom-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/convex-bottom-bar.md) | `TabStyle.fixed`/`fixedCircle` → `centerAction` with `raised`. The centre becomes a button, not a tab. |
| `persistent_bottom_nav_bar_v2` | [persistent-bottom-nav-bar-v2.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/persistent-bottom-nav-bar-v2.md) | `IndexedStack` of per-tab `Navigator`s + `PopScope` + `onReselected`. With go_router, use the `StatefulShellRoute` recipe in `EXAMPLES.md`. |
| `animated_bottom_navigation_bar` | [animated-bottom-navigation-bar.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/docs/migrate/animated-bottom-navigation-bar.md) | Docked FAB + `GapLocation.center` → `centerAction` with `notched` |

Flag what does not carry over: salomon/GNav put the label beside the icon (ours is under it), convex's bump and `react`/`flip` styles, animated_bottom_navigation_bar's tap bubble and `GapLocation.end`.

**Always remove the old package's `import` and `pubspec.yaml` entry** when replacing it (`flutter pub remove <package>`). Don't leave dead deps.

## TabBar (with `TabBarView`) as the floating child

This isn't replacing a *bottom* bar so much as making a *tab* bar float — but it's a common request.

```dart
DefaultTabController(
  length: tabs.length,
  child: Scaffold(
    body: BottomBar(
      layout: BottomBarLayout(
        width: MediaQuery.of(context).size.width * 0.8,
        borderRadius: BorderRadius.circular(500),
        fit: StackFit.expand,
        clip: Clip.none,
      ),
      motion: const BottomBarMotion.cupertino(
        preset: BottomBarCupertinoMotion.snappy,
        slideStart: Offset(0, 3), // slides further to feel fully offscreen
      ),
      theme: BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(500),
        ),
      ),
      body: TabBarView(children: pages),
      child: TabBar(tabs: tabs),
    ),
  ),
);
```

`TabBarView` provides its own scrollables; the bar reacts to whichever tab is currently scrolling. No `predicate` typically needed.

## After any replacement

1. **Add the import** at the top of the file:
   ```dart
   import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
   ```
2. **Update `pubspec.yaml`** — `flutter pub add flutter_floating_bottom_bar` (3.x needs Flutter `>=3.44.0` and imports Material from `package:material_ui/material_ui.dart`).
3. **Remove old imports** for any third-party bar package being replaced. Also remove its line from `pubspec.yaml`.
4. **Run `flutter analyze`** in the user's project root. Fix any issues (stale state fields, unused imports).
5. **Tell the user** what changed in one sentence and call out anything visually different (label under the icon instead of beside it, a lost tap animation, a centre tab that became a button, etc.).
