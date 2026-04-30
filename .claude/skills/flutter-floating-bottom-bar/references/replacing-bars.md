# Replacing existing bars

Recipes for converting common bottom-bar patterns to `flutter_floating_bottom_bar`. Each recipe shows the **before** (what the user typically has) and the **after** (what to ship).

The general transformation is:
1. Find the `Scaffold` and its `body` + `bottomNavigationBar` (or equivalent).
2. Move the scrollable from `body:` to `BottomBar.body`.
3. Move the bar widget into `BottomBar.child` (mapping its API to ours).
4. Remove `Scaffold.bottomNavigationBar`.
5. Bottom-pad the scrollable's content so the last item isn't hidden behind the bar.

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
    layout: BottomBarLayout(
      width: MediaQuery.of(context).size.width - 32,
      borderRadius: BorderRadius.circular(28),
    ),
    body: ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: 50,
      itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
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
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: const Text('Search'),
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
```

**Mapping notes:**
- `BottomNavigationBarItem.icon` → `BottomBarItem.icon`. If the user only had a single icon (no separate selected/unselected), keep it that way — `selectedIcon` is optional.
- `BottomNavigationBarItem.label` (String) → `Text(label)` widget.
- `currentIndex` + `onTap` → repeated `selected: _index == N` + `onTap: () => setState(() => _index = N)`. **Keep the user's existing `_index` field** — don't rename to `_currentIndex` or vice versa.
- Color → if they had `selectedItemColor: Colors.purple`, set `BottomBarItem.selectedColor: Colors.purple` on each item (or set it via `BottomBarThemeData` if it's app-wide).
- Bottom padding 96 ≈ 64 (bar) + 32 (offset). Conservative; tune to taste. For exact: see [common-glitches.md](common-glitches.md#content-clipped-behind-bar).

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

Same shape as the `BottomNavigationBar` recipe — the only meaningful difference is that `NavigationDestination` already gives you `icon` + `selectedIcon`, so the mapping is direct:

```dart
BottomBarItem(
  icon: const Icon(Icons.home_outlined),
  selectedIcon: const Icon(Icons.home),
  label: const Text('Home'),
  selected: _index == 0,
  onTap: () => setState(() => _index = 0),
),
```

**Material 3 hint:** keep `borderRadius: BorderRadius.circular(28)` — it matches the M3 expressive shape language. The default `BottomBarThemeData` already uses `colorScheme.surfaceContainer`, so M3 theming is automatic.

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

The package supports a FAB that overhangs the bar via `Stack` + `Positioned(top: -N)`. Set `clip: Clip.none` on the layout so the FAB isn't clipped.

```dart
Scaffold(
  body: BottomBar(
    layout: BottomBarLayout(
      width: MediaQuery.of(context).size.width - 32,
      borderRadius: BorderRadius.circular(28),
      fit: StackFit.expand,
      clip: Clip.none, // critical — without this, the overhanging FAB is clipped
    ),
    body: ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: 50,
      itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
    ),
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
              IconButton(icon: const Icon(Icons.search), onPressed: () {}),
              const SizedBox(width: 56), // space under the overhanging FAB
              IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
              IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
            ],
          ),
        ),
        Positioned(
          top: -24,
          child: FloatingActionButton(
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    ),
  ),
);
```

**Drop `Scaffold.floatingActionButton` and `floatingActionButtonLocation`** — the FAB now lives inside the bar's `child`. Otherwise you'll have two FABs.

**The visual notch is lost** going from `CircularNotchedRectangle` to a `Stack` overlap. If the user explicitly wants a notch, that's a bigger design conversation — flag it. The default look (FAB sitting on top of the rounded bar) tends to look better with the floating presentation anyway.

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
    layout: BottomBarLayout(
      width: MediaQuery.of(context).size.width - 24,
      offset: 12,
      borderRadius: BorderRadius.circular(40),
    ),
    theme: BottomBarThemeData(
      barDecoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
    ),
    body: ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      itemCount: 50,
      itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
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

Common ones the user might be migrating from:

### `salomon_bottom_bar`
```dart
SalomonBottomBar(
  currentIndex: _index,
  onTap: (i) => setState(() => _index = i),
  items: [
    SalomonBottomBarItem(icon: Icon(Icons.home), title: Text('Home'), selectedColor: Colors.purple),
    ...
  ],
);
```

Map `SalomonBottomBarItem` to `BottomBarItem`:
- `icon` → `icon`
- `title` (Widget) → `label`
- `selectedColor` → `BottomBarItem.selectedColor`

The salomon "expanding pill" effect is part of its design — the floating package doesn't replicate it. If the user wants it back, that's a separate ask. Flag it as a behavior change.

### `google_nav_bar`
```dart
GNav(
  selectedIndex: _index,
  onTabChange: (i) => setState(() => _index = i),
  tabs: const [
    GButton(icon: Icons.home, text: 'Home'),
    ...
  ],
);
```

Map `GButton` → `BottomBarItem`. `IconData` (`Icons.home`) → `Icon(Icons.home)`. Like salomon, the GNav active-pill animation is bespoke — doesn't carry over.

### `convex_bottom_bar` / `persistent_bottom_nav_bar`
These have wildly different APIs. Convert to the canonical `BottomBarItems` shape from the [smallest useful integration](../SKILL.md#quick-reference-the-smallest-useful-integration) at the bottom of `SKILL.md`. Drop the third-party `import` and the corresponding `pubspec.yaml` entry.

**Always remove the old package's `import` and `pubspec.yaml` entry** when replacing it. Don't leave dead deps.

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
2. **Update `pubspec.yaml`** — `flutter pub add flutter_floating_bottom_bar` (use `^2.0.0`).
3. **Remove old imports** for any third-party bar package being replaced. Also remove its line from `pubspec.yaml`.
4. **Run `flutter analyze`** in the user's project root. Fix any issues (stale state fields, unused imports).
5. **Tell the user** what changed in one sentence and call out anything visually different (lost notch, lost expanding-pill animation, etc.).
