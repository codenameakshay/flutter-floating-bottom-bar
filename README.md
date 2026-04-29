<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

<h1 align="center">Floating Bottom Bar</h1>

<p align="center">A Flutter package that floats any widget above your content and reacts to scrolling. Use it as a tab bar, bottom navigation bar, search bar, or any custom child.</p><br>

<p align="center">
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter"
      alt="Platform" />
  </a>
  <a href="https://pub.dartlang.org/packages/flutter_floating_bottom_bar">
    <img src="https://img.shields.io/pub/v/flutter-floating-bottom-bar.svg"
      alt="Pub Package" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/codenameakshay/flutter-floating-bottom-bar?color=red"
      alt="License: MIT" />
  </a>
  <a href="https://www.paypal.me/codenameakshay">
    <img src="https://img.shields.io/badge/Donate-PayPal-00457C?logo=paypal"
      alt="Donate" />
  </a>
</p><br>

| ![A floating tab bar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/1.gif) | ![A floating search bar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/2.gif) | ![A basic example](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/3.gif) |
| -------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **A floating tab bar**                                                                                                     | **A floating search bar**                                                                                                     | **A basic example**                                                                                                     |

---

## Features

`flutter_floating_bottom_bar` v2.0.0 is a floating widget host that sits above your scrollable content and responds to scroll events automatically — no `ScrollController` wiring required.

- **Host anything**: pass a `TabBar`, search bar, custom `Row`, or `BottomBarItems` widget as the floating `child`.
- **Notification-based scroll detection**: the bar listens to `ScrollNotification` from any descendant scrollable in the body subtree — `NestedScrollView`, multi-`TabBarView`, `CustomScrollView`, and user-supplied controllers all work out of the box.
- **Material 3 themed defaults**: `barDecoration` defaults to `colorScheme.surfaceContainer`; `iconDecoration` defaults to `colorScheme.primary`. No more hardcoded `Colors.black`.
- **Optional helpers**: `BottomBarItem` and `BottomBarItems` make the common nav-item case (icon, label, badge, selection) easy without turning the package into a full navigation widget.
- **Custom transitions**: choose from built-in `BottomBarTransition` enum values (`slide`, `fade`, `scale`, `slideAndFade`) or supply your own `transitionBuilder`.
- **Config objects**: flat constructor parameters from v1 are grouped into `BottomBarLayout`, `BottomBarMotion`, and `BottomBarScrollBehavior` for better readability and app-wide theming via `BottomBarThemeData`.

---

## Installing

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_floating_bottom_bar: ^2.0.0
```

Or use the Flutter CLI:

```bash
flutter pub add flutter_floating_bottom_bar
```

Then import:

```dart
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
```

---

## Basic usage

```dart
BottomBar(
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
    child: Text('This is the floating widget'),
  ),
)
```

`BottomBar` requires exactly two arguments: `child` (the floating widget) and `body` (the scrollable content beneath it). No `ScrollController` needs to be passed; the bar observes `ScrollNotification` automatically.

---

## Migrating from v1.x

v2.0.0 is a major release with breaking changes. Here's how to migrate from v1.x:

| v1.x | v2.0 | Migration |
|---|---|---|
| `body: (context, controller) => Widget` | `body: Widget` | Drop the builder; the bar listens to scroll notifications. Pass your own `ScrollController` into your scrollable directly if you need one. |
| `barColor` | removed | Use `BottomBarThemeData.barDecoration` or the `theme:` argument. |
| `width`, `offset`, `borderRadius`, `barAlignment`, `fit`, `clip`, `respectSafeArea` | `BottomBarLayout` | Wrap into `layout: BottomBarLayout(...)`. `barAlignment` → `alignment`. |
| `duration`, `curve`, `start`, `end` | `BottomBarMotion` | Wrap into `motion: BottomBarMotion(...)`. `start`/`end` (doubles) → `slideStart`/`slideEnd` (`Offset`s). |
| `hideOnScroll`, `reverse`, `scrollOpposite`, `scrollDeltaThreshold` | `BottomBarScrollBehavior` | Wrap into `scrollBehavior: BottomBarScrollBehavior(...)`. `scrollDeltaThreshold` → `deltaThreshold`. |
| `iconWidth`, `iconHeight`, `iconDecoration`, `barDecoration` | `BottomBarThemeData` | Move to theme. Per-instance overrides remain via the `theme:` argument. |
| `BottomBarScrollControllerProvider` | `BottomBarScope` | Renamed. The `scrollController` field is gone. New fields: `barHeight`, `isVisible`. |

No compatibility shim ships with v2.

---

## Recipes

### Basic floating bar

The minimal setup — see the [Basic usage](#basic-usage) section above.
The full runnable demo is at `example/lib/demos/basic_demo.dart`.

### Tab bar with FAB notch

Wrap a `TabBar` (with an optional overlapping `FloatingActionButton`) as the floating `child`. Pass the `TabBarView` as `body`.

```dart
BottomBar(
  layout: BottomBarLayout(
    width: MediaQuery.of(context).size.width * 0.8,
    borderRadius: BorderRadius.circular(500),
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
      color: Colors.blue,
      borderRadius: BorderRadius.circular(500),
    ),
  ),
  body: TabBarView(controller: tabController, children: pages),
  child: Stack(
    alignment: Alignment.center,
    clipBehavior: Clip.none,
    children: [
      TabBar(controller: tabController, tabs: tabs),
      Positioned(
        top: -20,
        child: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      ),
    ],
  ),
)
```

See `example/lib/demos/tab_bar_demo.dart` for the full color-driven demo.

### Badges with `BottomBarItems`

Use `BottomBarItems` + `BottomBarItem` for a ready-made icon/label/badge row without writing layout code:

```dart
BottomBar(
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
          badge: Badge(label: const Text('3')),
          selected: _index == 1,
          onTap: () => setState(() => _index = 1),
        ),
      ],
    ),
  ),
)
```

See `example/lib/demos/badges_demo.dart` for the full runnable version.

For the full recipe catalogue, see [EXAMPLES.md](./EXAMPLES.md). Each recipe has a runnable counterpart in `example/lib/demos/`.

---

## API Reference

### `BottomBar`

The root widget. Requires `child` and `body`.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | **required** | The floating widget shown above `body`. |
| `body` | `Widget` | **required** | The content beneath the bar. Any descendant scrollable drives hide/show via notifications. |
| `controller` | `BottomBarController?` | `null` | Optional imperative controller for `show()`, `hide()`, `toggle()`, scroll actions. |
| `layout` | `BottomBarLayout` | `BottomBarLayout()` | Size, radius, alignment, and stack configuration. |
| `motion` | `BottomBarMotion` | `BottomBarMotion()` | Animation duration, curve, transition type, and slide offsets. |
| `scrollBehavior` | `BottomBarScrollBehavior` | `BottomBarScrollBehavior()` | Scroll-detection thresholds and direction flags. |
| `theme` | `BottomBarThemeData?` | `null` | Per-instance decoration overrides. Higher precedence than `Theme.of(context).extension`. |
| `icon` | `BackToTopIconBuilder?` | `null` | Builder for the back-to-top icon shown when the bar is hidden. |
| `showIcon` | `bool` | `true` | Whether to show the back-to-top icon. |
| `iconSemanticLabel` | `String?` | `null` | Semantic label for the back-to-top icon. |
| `iconTooltip` | `String?` | `null` | Tooltip for the back-to-top icon. |
| `onVisibilityChanged` | `ValueChanged<bool>?` | `null` | Called whenever bar visibility changes. `true` = now visible. |
| `onBottomBarShown` | `VoidCallback?` | `null` | Called when the bar becomes visible. |
| `onBottomBarHidden` | `VoidCallback?` | `null` | Called when the bar becomes hidden. |

---

### `BottomBarLayout`

Controls the bar's size, shape, position, and stack behavior.

| Field | Type | Default | Description |
|---|---|---|---|
| `width` | `double` | `300` | Width of the floating bar in logical pixels. |
| `offset` | `double` | `10` | Padding from the bottom and sides of the screen. |
| `borderRadius` | `BorderRadius` | `BorderRadius.zero` | Corner radius of the bar. |
| `alignment` | `Alignment` | `Alignment.bottomCenter` | Alignment of the bar within the stack. |
| `fit` | `StackFit` | `StackFit.loose` | `fit` passed to the underlying `Stack`. |
| `clip` | `Clip` | `Clip.hardEdge` | `clipBehavior` of the underlying `Stack`. Set to `Clip.none` for a FAB notch. |
| `respectSafeArea` | `bool` | `true` | Whether the bar respects system safe-area insets (e.g. iOS home indicator). |

---

### `BottomBarMotion`

Controls how the bar animates in and out.

| Field | Type | Default | Description |
|---|---|---|---|
| `duration` | `Duration` | `Duration(milliseconds: 240)` | Animation duration. |
| `curve` | `Curve` | `Curves.easeOutCubic` | Animation curve. |
| `transition` | `BottomBarTransition` | `BottomBarTransition.slide` | Built-in transition type. |
| `transitionBuilder` | `Widget Function(BuildContext, Animation<double>, Widget)?` | `null` | Custom transition. When non-null, overrides `transition`. |
| `slideStart` | `Offset` | `Offset(0, 2)` | Starting offset for `slide` / `slideAndFade` transitions. |
| `slideEnd` | `Offset` | `Offset.zero` | Ending offset for `slide` / `slideAndFade` transitions. |

**`BottomBarTransition` enum values:**

| Value | Effect |
|---|---|
| `slide` | `SlideTransition` from `slideStart` to `slideEnd`. |
| `fade` | `FadeTransition`. |
| `scale` | `ScaleTransition`. |
| `slideAndFade` | `SlideTransition` composed with `FadeTransition`. |

---

### `BottomBarScrollBehavior`

Controls how the bar reacts to scroll events.

| Field | Type | Default | Description |
|---|---|---|---|
| `hideOnScroll` | `bool` | `true` | When `false`, scroll events never hide the bar (imperative `controller.hide()` still works). |
| `reverse` | `bool` | `false` | When `true`, the bar hides on upward scroll and shows on downward scroll (inverted). |
| `scrollOpposite` | `bool` | `false` | When `true`, the back-to-top icon scrolls to the end instead of the start. |
| `deltaThreshold` | `double` | `8` | Minimum scroll delta (in pixels) required to trigger a visibility change. |
| `predicate` | `bool Function(ScrollNotification)?` | `null` | Custom filter; return `false` to ignore a notification entirely. Useful for `NestedScrollView` disambiguation. |

---

### `BottomBarThemeData`

A `ThemeExtension<BottomBarThemeData>` for app-wide styling. Install via `Theme(data: theme.copyWith(extensions: [myTheme]), ...)` or pass directly as `BottomBar(theme: ...)`.

**Resolution order (low → high precedence):**
1. Built-in Material 3 defaults.
2. `Theme.of(context).extension<BottomBarThemeData>()`.
3. The `theme` argument on `BottomBar`.
4. Per-widget config arguments (`layout`, `motion`, `scrollBehavior`).

| Field | Type | Default | Description |
|---|---|---|---|
| `barDecoration` | `BoxDecoration?` | `BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28))` | Decoration applied to the floating bar container. |
| `iconDecoration` | `BoxDecoration?` | `BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)` | Decoration for the back-to-top icon container. |
| `iconWidth` | `double?` | `30` | Width of the back-to-top icon. |
| `iconHeight` | `double?` | `30` | Height of the back-to-top icon. |
| `layout` | `BottomBarLayout?` | `null` | Theme-level layout defaults. |
| `motion` | `BottomBarMotion?` | `null` | Theme-level motion defaults. |
| `scrollBehavior` | `BottomBarScrollBehavior?` | `null` | Theme-level scroll behavior defaults. |

Methods: `copyWith(...)`, `lerp(other, t)`, `merge(other)` (other wins on conflict).

---

### `BottomBarController`

Extends `ChangeNotifier`. Provides imperative control over bar visibility and scroll position.

| Member | Description |
|---|---|
| `bool isVisible` | Current visibility state. |
| `bool isAttached` | Whether the controller is attached to a live `BottomBar`. |
| `void show()` | Show the bar. Fires `onBottomBarShown`. |
| `void hide()` | Hide the bar. Fires `onBottomBarHidden`. |
| `void toggle()` | Toggle visibility. |
| `Future<void> scrollToStart()` | Scroll the most recently active scrollable to the start. No-op if no scrollable has been observed. |
| `Future<void> scrollToEnd()` | Scroll the most recently active scrollable to the end. No-op if no scrollable has been observed. |

A controller cannot be attached to two `BottomBar` instances simultaneously; double-attach asserts in debug mode.

---

### `BottomBarScope`

An `InheritedWidget` that exposes the bar's measured height and current visibility to descendants anywhere in the subtree. Replaces `BottomBarScrollControllerProvider` from v1.

| Member | Description |
|---|---|
| `ValueListenable<double> barHeight` | Rendered height of the floating bar in logical pixels. Starts at `0` before the first frame; update post-layout. |
| `ValueListenable<bool> isVisible` | Current visibility as a listenable. |
| `static BottomBarScope of(BuildContext context)` | Returns the nearest `BottomBarScope`; throws if none found. |
| `static BottomBarScope? maybeOf(BuildContext context)` | Returns the nearest `BottomBarScope`, or `null` if none found. |

Usage pattern:

```dart
ValueListenableBuilder<double>(
  valueListenable: BottomBarScope.of(context).barHeight,
  builder: (context, height, _) {
    return SizedBox(height: height); // spacer to avoid content clipping
  },
)
```

---

### `BottomBarItem`

A ready-made navigation item widget: icon, optional selected icon, optional label, optional badge, tap handler.

| Field | Type | Default | Description |
|---|---|---|---|
| `icon` | `Widget` | **required** | Icon shown when unselected. |
| `selectedIcon` | `Widget?` | `null` | Icon shown when `selected` is `true`. Falls back to `icon` if not provided. |
| `label` | `Widget?` | `null` | Label below the icon. |
| `badge` | `Widget?` | `null` | Badge overlay (e.g. notification count). |
| `selected` | `bool` | `false` | Whether this item is currently selected. |
| `onTap` | `VoidCallback?` | `null` | Called when the item is tapped. |
| `tooltip` | `String?` | `null` | Tooltip on long-press. |
| `color` | `Color?` | `null` | Icon/label color when unselected. |
| `selectedColor` | `Color?` | `null` | Icon/label color when selected. |

`BottomBarItem` does not maintain its own selection state; pass `selected: index == currentIndex` and update state in `onTap`.

---

### `BottomBarItems`

A thin row layout helper that arranges `BottomBarItem`s (or any widgets) horizontally.

| Field | Type | Default | Description |
|---|---|---|---|
| `children` | `List<Widget>` | **required** | Items to lay out in the row. |
| `spacing` | `MainAxisAlignment` | `MainAxisAlignment.spaceAround` | Main-axis alignment applied to the row. |

---

## Bugs or Requests

If you encounter any problems feel free to open an [issue](https://github.com/codenameakshay/flutter-floating-bottom-bar/issues/new?template=bug_report.md). If you feel the library is missing a feature, please raise a [ticket](https://github.com/codenameakshay/flutter-floating-bottom-bar/issues/new?template=feature_request.md) on GitHub and I'll look into it. Pull requests are also welcome.

See [Contributing.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/master/CONTRIBUTING.md).
