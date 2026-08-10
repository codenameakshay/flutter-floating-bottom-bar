# Floating Bottom Bar

A Flutter package that floats any widget above your content and reacts to
scrolling. Use it as a tab bar, bottom navigation bar, search bar, command
surface, or any custom child.

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
</p>

| ![Issues dock](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/1-issues-dock.gif) | ![AI prompt dock](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/2-ai-prompt-dock.gif) | ![Basic TabBar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/3-basic-tab-bar.gif) |
| ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| **Issues dock**                                                                                                                 | **AI prompt dock**                                                                                                                    | **Basic TabBar**                                                                                                                    |
| ![Minimal API](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/4-minimal-api.gif) | ![Nested scroll](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/5-nested-scroll.gif) | ![Badged nav](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/6-badged-nav.gif) |
| **Minimal API**                                                                                                                 | **Nested scroll**                                                                                                                     | **Badged nav**                                                                                                                      |
| ![Custom transition](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/0c1275b/screenshots/7-custom-transition.gif) |                                                                                                                                       |                                                                                                                                     |
| **Custom transition**                                                                                                           |                                                                                                                                       |                                                                                                                                     |

## Why this package

- Host any widget as the floating bar: `TabBar`, `BottomBarItems`, a search
  composer, or a custom `Row`.
- Scroll detection is notification-based. Most setups need no
  `ScrollController` plumbing.
- `BottomBarLayout.adaptive(maxWidth: ...)` fills the host width while keeping
  a hard cap for tablets, desktop, and wide layouts.
- `BottomBarBodyPadding` reserves the bar's full measured footprint, including
  configured offset and bottom safe-area, so body content stays clear even
  while the bar is hidden.
- `BottomBarMotion()` defaults to Motor-backed Cupertino spring motion with
  velocity-preserving redirects when scroll direction changes mid-animation.
- Custom transitions are supported, but they must stay paint-only and preserve
  the child's layout footprint.
- The hidden action is accessibility-safe by default: it is non-interactive and
  excluded from semantics while the bar is visible, keeps at least a 48x48 hit
  target when active, uses direction-aware icon/tooltip text, and defaults its
  glyph color to `ColorScheme.onPrimary`.
- Reduced-motion environments snap directly to the final shown/hidden state.
- `BottomBarController` supports imperative show/hide plus
  `scrollToStart()`/`scrollToEnd()`, including correct `NestedScrollView`
  boundary targeting.
- `Motion` from the `motor` package is re-exported intentionally for
  `BottomBarMotion.motor(...)`.

## Install

Requires Dart `>=3.5.0` and Flutter `>=3.22.0`.

```bash
flutter pub add flutter_floating_bottom_bar
```

```dart
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
```

## Claude Code skill

If you use [Claude Code](https://claude.ai/code), this repo ships a skill for
integration, migration, and debugging help around this package.

Install:

```bash
/install-skill https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/.claude/skills/flutter-floating-bottom-bar.skill
```

## Basic usage

```dart
BottomBar(
  layout: const BottomBarLayout.adaptive(maxWidth: 420),
  body: BottomBarBodyPadding(
    padding: const EdgeInsets.only(top: 24),
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 50,
      itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
    ),
  ),
  child: const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.home_rounded),
        Text('Floating bar'),
        Icon(Icons.search_rounded),
      ],
    ),
  ),
)
```

`BottomBar` needs two required arguments:

- `body`: the subtree that emits `ScrollNotification`s.
- `child`: the floating widget shown above that body.

The bar is stacked above the body, so use `BottomBarBodyPadding` when your body
should reserve enough bottom space to stay clear of the bar.

## Common recipes

### Adaptive width + stable body padding

Use `BottomBarLayout.adaptive(maxWidth: ...)` to span narrow screens while
stopping at a defined maximum on wide screens. Pair it with
`BottomBarBodyPadding` when the body should reserve the full footprint.

```dart
BottomBar(
  layout: const BottomBarLayout.adaptive(maxWidth: 440),
  body: const BottomBarBodyPadding(
    child: CustomScrollView(
      slivers: [
        SliverAppBar(title: Text('Inbox')),
        SliverList.list(
          children: [
            ListTile(title: Text('Message 1')),
            ListTile(title: Text('Message 2')),
          ],
        ),
      ],
    ),
  ),
  child: const SizedBox(
    height: 56,
    child: Center(child: Text('Compose')),
  ),
)
```

`BottomBarScope.barHeight` and `BottomBarBodyPadding` use the bar's measured
layout footprint, not its animated transform. The reported value includes the
bar height plus configured `layout.offset` and bottom safe-area when
`respectSafeArea` is enabled.

### Nested scroll views

`BottomBarController.scrollToStart()` always targets the minimum extent and
`scrollToEnd()` always targets the maximum extent. In a `NestedScrollView`, the
controller automatically chooses the correct coordinated boundary controller:

- `scrollToStart()` drives the outer controller so pinned/expanded header
  slivers return to their true top state.
- `scrollToEnd()` drives the inner controller so the body scrolls to the end
  and the header collapses naturally.

If your body emits unrelated notifications, use
`BottomBarScrollBehavior.predicate` to filter them.

```dart
BottomBar(
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
    child: Center(child: Text('Scroll-aware')),
  ),
)
```

### Custom transitions

Custom transition builders must preserve the child's layout footprint. Use
paint-only wrappers such as `Opacity`, `Transform.translate`, or
`Transform.scale`.

Do not use layout-changing widgets such as `SizeTransition` or `Align` with a
`heightFactor`; those break the stable footprint contract used by
`BottomBarScope.barHeight` and `BottomBarBodyPadding`.

```dart
BottomBar(
  motion: BottomBarMotion(
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
    itemCount: 100,
    itemBuilder: (_, index) => ListTile(title: Text('Row $index')),
  ),
  child: const SizedBox(
    height: 56,
    child: Center(child: Text('Paint-only transition')),
  ),
)
```

Spring progress can overshoot. Clamp `animation.value` before using it for
opacity or scale.

### `BottomBarItems` and `BottomBarItem`

`BottomBarItems` is a row helper. `BottomBarItem` is an opinionated item widget
with built-in accessibility and RTL-aware badge placement.

- The badge uses `PositionedDirectional`, so it follows the top-end corner in
  both LTR and RTL layouts.
- The item exposes button semantics, selection state, and enabled state.
- The tappable surface keeps at least a 48x48 target.
- Accessible naming is deterministic: `semanticLabel` wins, otherwise
  `tooltip`, otherwise descendant semantics.
- When `semanticLabel` or `tooltip` provides the explicit accessible name,
  descendant semantics are excluded to avoid duplicate announcements.

## Migration from v1.x

| v1.x | v2.x | Migration |
| --- | --- | --- |
| `body: (context, controller) => Widget` | `body: Widget` | Drop the builder. The bar listens to `ScrollNotification`s from descendant scrollables. |
| `barColor` | removed | Use `BottomBarThemeData.barDecoration` or `theme:`. |
| `width`, `offset`, `borderRadius`, `barAlignment`, `fit`, `clip`, `respectSafeArea` | `BottomBarLayout` | Move these into `layout: BottomBarLayout(...)`. `barAlignment` became `alignment`. |
| `duration`, `curve`, `start`, `end` | `BottomBarMotion` | `BottomBarMotion()` now defaults to Cupertino spring motion. `start`/`end` became `slideStart`/`slideEnd`. |
| `hideOnScroll`, `reverse`, `scrollOpposite`, `scrollDeltaThreshold` | `BottomBarScrollBehavior` | Move these into `scrollBehavior: BottomBarScrollBehavior(...)`. `scrollDeltaThreshold` became `deltaThreshold`. |
| `iconWidth`, `iconHeight`, `iconDecoration`, `barDecoration` | `BottomBarThemeData` | Move these to the theme or the `theme:` override. |
| `BottomBarScrollControllerProvider` | `BottomBarScope` | The old controller provider was replaced by `BottomBarScope`, which exposes `barHeight` and `isVisible`. |

No backward-compatibility shim ships with v2.

## API quick reference

### `BottomBar`

| Parameter | Type | Default | Notes |
| --- | --- | --- | --- |
| `child` | `Widget` | required | Floating content shown above the body. |
| `body` | `Widget` | required | Descendant scrollables here drive hide/show via notifications. |
| `controller` | `BottomBarController?` | `null` | Imperative show/hide/scroll API. |
| `layout` | `BottomBarLayout?` | `null` | Falls back to theme layout, then `const BottomBarLayout()`. |
| `motion` | `BottomBarMotion?` | `null` | Falls back to theme motion, then `const BottomBarMotion()`. |
| `scrollBehavior` | `BottomBarScrollBehavior?` | `null` | Falls back to theme scroll behavior, then `const BottomBarScrollBehavior()`. |
| `theme` | `BottomBarThemeData?` | `null` | Per-instance theme overrides. |
| `icon` | `BackToTopIconBuilder?` | `null` | Custom hidden action visual. |
| `showIcon` | `bool` | `true` | Enables or removes the built-in hidden action. |
| `iconSemanticLabel` | `String?` | `null` | Defaults to the direction-aware tooltip text. |
| `iconTooltip` | `String?` | `null` | Defaults to `Scroll to top` or `Scroll to bottom`. |

The hidden action is only interactive while the bar is hidden. While the bar is
visible it is ignored for hit testing and removed from the semantics tree.

### `BottomBarLayout`

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `width` | `double` | `300` | Requested bar width before viewport/max-width clamping. |
| `maxWidth` | `double?` | `null` | Optional explicit width cap after host constraints. |
| `offset` | `double` | `10` | Outer padding applied around the bar or hidden action. |
| `borderRadius` | `BorderRadius` | `BorderRadius.zero` | Used by the default rectangular bar decoration. |
| `iconOffset` | `Offset` | `Offset.zero` | Extra translation applied only to the hidden action. |
| `alignment` | `Alignment` | `Alignment.bottomCenter` | Shared alignment for the bar and hidden action. |
| `fit` | `StackFit` | `StackFit.loose` | Host stack fit. |
| `clip` | `Clip` | `Clip.hardEdge` | Host stack clip behavior. |
| `respectSafeArea` | `bool` | `true` | Wraps the bar and hidden action in `SafeArea`. |

Use `BottomBarLayout.adaptive(maxWidth: ...)` to fill available width up to a
hard cap.

### `BottomBarMotion`

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `mode` | `BottomBarMotionMode` | `cupertino` | `BottomBarMotion()` defaults to Cupertino spring mode. |
| `duration` | `Duration` | `500ms` in default Cupertino mode | Used for curved motion and scroll-to-boundary animation timing. |
| `curve` | `Curve` | `Curves.easeOutCubic` | Used by curved motion and controller boundary scrolling. |
| `cupertinoPreset` | `BottomBarCupertinoMotion` | `snappy` | Default Cupertino preset. |
| `transition` | `BottomBarTransition` | `slide` | Built-in transition when `transitionBuilder` is null. |
| `transitionBuilder` | `Widget Function(BuildContext, Animation<double>, Widget)?` | `null` | Overrides the enum. Must preserve layout footprint and stay paint-only. |
| `slideStart` | `Offset` | `Offset(0, 2)` | Hidden offset for `slide` and `slideAndFade`. |
| `slideEnd` | `Offset` | `Offset.zero` | Visible offset for `slide` and `slideAndFade`. |

Reduced-motion environments snap to the target shown/hidden state instead of
animating.

### `BottomBarScrollBehavior`

| Field | Type | Default | Notes |
| --- | --- | --- | --- |
| `hideOnScroll` | `bool` | `true` | Disables scroll-driven hiding when false. |
| `reverse` | `bool` | `false` | Inverts the scroll direction that hides vs shows the bar. |
| `scrollOpposite` | `bool` | `false` | Changes only the built-in hidden action direction, tooltip, and glyph. It does not change `scrollToStart()` or `scrollToEnd()`. |
| `deltaThreshold` | `double` | `8` | Minimum absolute delta required before visibility can flip. |
| `showAtStart` | `bool` | `false` | Forces the bar visible when a scrollable reaches its minimum extent. |
| `showOnScrollEnd` | `bool` | `false` | Forces the bar visible when scrolling settles. |
| `predicate` | `bool Function(ScrollNotification)?` | `null` | Skip notifications entirely when it returns false. |

### `BottomBarController`

| Member | Notes |
| --- | --- |
| `isVisible` | Tracks the currently attached bar's visibility. |
| `isAttached` | Whether the controller is attached to a live bar. |
| `show()` / `hide()` / `toggle()` | Imperative visibility controls. |
| `scrollToStart()` | Always scrolls the last active scrollable to its minimum extent. |
| `scrollToEnd()` | Always scrolls the last active scrollable to its maximum extent. |

A controller can own only one live bar at a time. Double-attach fails in both
debug and release, and visibility updates are accepted only from the owning bar
binding.

### `BottomBarScope`

`BottomBarScope` exposes two listenables inside `BottomBar.body`:

- `barHeight`: the live measured bar footprint, including offset and bottom
  safe-area when enabled.
- `isVisible`: the current shown/hidden target state.

Use `BottomBarBodyPadding` when you want the common "reserve the bottom
footprint for me" behavior without wiring your own `ValueListenableBuilder`.

## Examples and demos

- API recipes: [EXAMPLES.md](./EXAMPLES.md)
- Runnable demo app: `example/`
- Demo entry point: `example/lib/main.dart`

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for setup, quality checks, and release
dry-run steps.

## Bugs or requests

Open an issue at
<https://github.com/codenameakshay/flutter-floating-bottom-bar/issues>.
