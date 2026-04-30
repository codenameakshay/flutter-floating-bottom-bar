# Migrating from v1.x → v2.0

v2.0 is a major release. **No compatibility shim ships with v2** — every v1 call site needs an explicit migration. This file is the precise mapping.

## Detecting v1 usage

If the user's code has any of these, they're on v1.x:

- `body: (context, controller) => Widget` — v1 used a builder; v2 takes a plain widget.
- `barColor:`, `iconWidth:`, `iconHeight:`, `iconDecoration:`, `barDecoration:` as **direct parameters** to `BottomBar`.
- Direct `width:`, `offset:`, `borderRadius:`, `barAlignment:`, `fit:`, `clip:`, `respectSafeArea:` parameters on `BottomBar`.
- Direct `duration:`, `curve:`, `start:`, `end:` (doubles) parameters on `BottomBar`.
- Direct `hideOnScroll:`, `reverse:`, `scrollOpposite:`, `scrollDeltaThreshold:` parameters on `BottomBar`.
- `BottomBarScrollControllerProvider` (renamed in v2).

If you see any of these, follow this guide.

## The mapping table

| v1.x | v2.0 | Migration |
|---|---|---|
| `body: (context, controller) => Widget` | `body: Widget` | **Drop the builder.** The bar listens to `ScrollNotification` automatically. If your scrollable needs its own `ScrollController`, instantiate one and pass it directly to that scrollable. |
| `barColor:` | removed | Use `BottomBarThemeData.barDecoration` (via `theme:` arg or `Theme.extensions`). |
| `width:`, `offset:`, `borderRadius:`, `barAlignment:`, `fit:`, `clip:`, `respectSafeArea:` | `BottomBarLayout(...)` | Wrap into `layout: BottomBarLayout(...)`. **Note:** `barAlignment` → `alignment`. |
| `duration:`, `curve:`, `start:`, `end:` | `BottomBarMotion(...)` | Wrap into `motion: BottomBarMotion(...)`. **`start`/`end` (doubles) → `slideStart`/`slideEnd` (`Offset`s)** — see below. |
| `hideOnScroll:`, `reverse:`, `scrollOpposite:`, `scrollDeltaThreshold:` | `BottomBarScrollBehavior(...)` | Wrap into `scrollBehavior: BottomBarScrollBehavior(...)`. **Note:** `scrollDeltaThreshold` → `deltaThreshold`. |
| `iconWidth:`, `iconHeight:`, `iconDecoration:`, `barDecoration:` | `BottomBarThemeData` | Move to `theme:` or `Theme.extensions`. Per-instance `theme:` overrides theme-extension values. |
| `BottomBarScrollControllerProvider` | `BottomBarScope` | Renamed. **The `scrollController` field is gone.** New fields: `barHeight` (`ValueListenable<double>`), `isVisible` (`ValueListenable<bool>`). |

## Concrete examples

### Before — v1.x

```dart
BottomBar(
  body: (context, controller) => ListView.builder(
    controller: controller,
    itemCount: 200,
    itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
  ),
  barColor: Colors.white,
  width: 280,
  borderRadius: BorderRadius.circular(28),
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeOutCubic,
  start: 2,
  end: 0,
  hideOnScroll: true,
  scrollOpposite: false,
  scrollDeltaThreshold: 12,
  iconWidth: 32,
  iconHeight: 32,
  iconDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Floating widget'),
  ),
);
```

### After — v2.0

```dart
BottomBar(
  layout: BottomBarLayout(
    width: 280,
    borderRadius: BorderRadius.circular(28),
  ),
  motion: BottomBarMotion.curved(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
    slideStart: const Offset(0, 2),
    slideEnd: Offset.zero,
  ),
  scrollBehavior: const BottomBarScrollBehavior(
    hideOnScroll: true,
    deltaThreshold: 12,
  ),
  theme: BottomBarThemeData(
    barDecoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    iconDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
    iconWidth: 32,
    iconHeight: 32,
  ),
  body: ListView.builder(
    itemCount: 200,
    itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
  ),
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Floating widget'),
  ),
);
```

### Notes on this migration

- **`body:` builder → plain widget.** The user's `controller` arg from v1 was used to wire scroll events; v2 doesn't need it. If they were *using* that controller for something else (e.g. their own `scrollToTop` button), keep that controller — but instantiate it directly and pass it to the scrollable, not to `BottomBar`.
- **`start: 2, end: 0` → `slideStart: Offset(0, 2), slideEnd: Offset.zero`.** v1 was 1-axis; v2 is 2-axis. The vertical component goes in `dy` (the second `Offset` argument). Most v1 users only animated vertically, so `dx` should be `0`.
- **`barColor: Colors.white` becomes `BottomBarThemeData.barDecoration.color`.** Don't drop `borderRadius` from the decoration — keep both `layout.borderRadius` and `theme.barDecoration.borderRadius` matching. (The package will use `layout.borderRadius` if non-zero, otherwise fall back to the decoration's; consistency avoids surprises.)
- **`duration` + `curve` keeps you on `BottomBarMotion.curved`.** The default `BottomBarMotion()` (no args) uses Cupertino spring motion. Recommend the user **try the default** — it usually feels better than fixed-duration curves and redirects mid-flight on scroll reversal.

## Migrating `BottomBarScrollControllerProvider`

### Before — v1.x

```dart
final scrollController = BottomBarScrollControllerProvider.of(context).scrollController;
return ListView.builder(
  controller: scrollController,
  itemCount: 100,
  itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
);
```

### After — v2.0

The whole pattern goes away. v2 doesn't expose a `ScrollController` because it doesn't need one — it listens to notifications. Just use a regular `ListView`:

```dart
return ListView.builder(
  itemCount: 100,
  itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
);
```

If the user genuinely needs a controller (e.g. for their own `jumpTo`), instantiate one in their state and pass it to the `ListView` directly. **It does not need to be passed to `BottomBar`.**

If they used `BottomBarScrollControllerProvider` for the bar's measured height or visibility (rare in v1, common pattern post-migration), use `BottomBarScope.of(context)`:

```dart
final scope = BottomBarScope.of(context);
ValueListenableBuilder<double>(
  valueListenable: scope.barHeight,
  builder: (context, height, _) => SizedBox(height: height),
);
```

## After migration

Run `flutter analyze` and fix:
- Stale parameter errors ("The named parameter 'barColor' isn't defined").
- Type errors on `start:` / `end:` (was `double`, now `Offset`).
- Imports — should still be `package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart`. No path changes.

Run the user's tests if they have any. Visual diff is best done on-device — the v2 default motion is springy where v1 was curved, so the bar will feel different even when no other code changed.
