# API reference (v2.0.0)

Compact, normative reference for `flutter_floating_bottom_bar`. If a field isn't here, it isn't part of the public API.

## Table of contents

- [`BottomBar`](#bottombar) — the root widget
- [`BottomBarLayout`](#bottombarlayout) — size/shape/position
- [`BottomBarMotion`](#bottombarmotion) — show/hide animation
- [`BottomBarTransition`](#bottombartransition) — built-in transition presets
- [`BottomBarScrollBehavior`](#bottombarscrollbehavior) — scroll-detection knobs
- [`BottomBarThemeData`](#bottombarthemedata) — `ThemeExtension` for app-wide styling
- [`BottomBarController`](#bottombarcontroller) — imperative `show`/`hide`/`scrollToStart`
- [`BottomBarScope`](#bottombarscope) — `InheritedWidget` exposing `barHeight` + `isVisible`
- [`BottomBarItem` / `BottomBarItems`](#bottombaritem--bottombaritems) — nav-item helpers

## `BottomBar`

```dart
const BottomBar({
  required Widget child,
  required Widget body,
  BottomBarController? controller,
  BottomBarLayout? layout,
  BottomBarMotion? motion,
  BottomBarScrollBehavior? scrollBehavior,
  BottomBarThemeData? theme,
  BackToTopIconBuilder? icon,
  bool showIcon = true,
  String? iconSemanticLabel,
  String? iconTooltip,
  ValueChanged<bool>? onVisibilityChanged,
  VoidCallback? onBottomBarShown,
  VoidCallback? onBottomBarHidden,
  Key? key,
});
```

| Field | Type | Default | Notes |
|---|---|---|---|
| `child` | `Widget` | required | The floating widget itself (your tab bar / search bar / row). |
| `body` | `Widget` | required | The scrollable beneath. Any descendant scrollable drives hide/show. **No `ScrollController` needed.** |
| `controller` | `BottomBarController?` | `null` | Imperative `show()` / `hide()` / `scrollToStart()`. |
| `layout` | `BottomBarLayout?` | `BottomBarLayout()` | See below. |
| `motion` | `BottomBarMotion?` | `BottomBarMotion()` (Cupertino snappy + slide) | See below. |
| `scrollBehavior` | `BottomBarScrollBehavior?` | `BottomBarScrollBehavior()` | See below. |
| `theme` | `BottomBarThemeData?` | `null` | Per-instance overrides. **Higher precedence than `Theme.of(context).extension`.** |
| `icon` | `BackToTopIconBuilder?` | built-in arrow-up | `Widget Function(double width, double height)`. |
| `showIcon` | `bool` | `true` | Show the back-to-top icon when bar is hidden. |
| `iconSemanticLabel` | `String?` | `null` | A11y label. |
| `iconTooltip` | `String?` | `null` | Defaults to `'Scroll to top'`. |
| `onVisibilityChanged` | `ValueChanged<bool>?` | `null` | `true` = now visible. |
| `onBottomBarShown` | `VoidCallback?` | `null` | Convenience. |
| `onBottomBarHidden` | `VoidCallback?` | `null` | Convenience. |

**Resolution order (low → high):** built-in M3 defaults → `Theme.of(context).extension<BottomBarThemeData>()` → `theme:` arg → per-widget `layout`/`motion`/`scrollBehavior`.

## `BottomBarLayout`

```dart
const BottomBarLayout({
  double width = 300,
  double offset = 10,
  BorderRadius borderRadius = BorderRadius.zero,
  Alignment alignment = Alignment.bottomCenter,
  StackFit fit = StackFit.loose,
  Clip clip = Clip.hardEdge,
  bool respectSafeArea = true,
});
```

| Field | Default | Notes |
|---|---|---|
| `width` | `300` | Logical pixels. For full-width-with-margin, use `MediaQuery.of(context).size.width - 32`. |
| `offset` | `10` | Padding from screen bottom and sides. Increase to `24` for breathing room. |
| `borderRadius` | `BorderRadius.zero` | Use `BorderRadius.circular(28)` for M3, `999` for pill. |
| `alignment` | `Alignment.bottomCenter` | The `Stack` alignment. |
| `fit` | `StackFit.loose` | Pass `StackFit.expand` when the bar's child uses `Stack` + `Positioned` (e.g. FAB notch). |
| `clip` | `Clip.hardEdge` | **Set `Clip.none` when overlapping a FAB out of bounds.** |
| `respectSafeArea` | `true` | Avoids iOS home indicator. |

## `BottomBarMotion`

Four constructors. All accept `transition`, `transitionBuilder`, `slideStart`, `slideEnd`.

```dart
// Default — Cupertino snappy spring + slide.
const BottomBarMotion();

// Cupertino preset spring.
const BottomBarMotion.cupertino({
  BottomBarCupertinoMotion preset = BottomBarCupertinoMotion.snappy,
  Duration duration = const Duration(milliseconds: 500),
  double extraBounce = 0,
  bool snapToEnd = true,
  BottomBarTransition transition = BottomBarTransition.slide,
  Widget Function(BuildContext, Animation<double>, Widget)? transitionBuilder,
  Offset slideStart = const Offset(0, 2),
  Offset slideEnd = Offset.zero,
});

// Deterministic curve.
const BottomBarMotion.curved({
  Duration duration = const Duration(milliseconds: 240),
  Curve curve = Curves.easeOutCubic,
  ...
});

// Raw Motor motion.
const BottomBarMotion.motor(Motion motorMotion, { ... });
```

`BottomBarCupertinoMotion` enum values: `smooth`, `snappy`, `bouncy`, `interactive`.

`BottomBarMotionMode` is internal — derived from which constructor you used (`cupertino`, `curved`, `motor`).

**`extraBounce`** — additional bounce on top of the preset (e.g. `0.04` makes `bouncy` bouncier).
**`snapToEnd`** — when the spring settles, snap exactly to the target value (avoids tiny perpetual oscillation).
**`slideStart` / `slideEnd`** — `Offset`s in `SlideTransition` units (multiples of child size). Default `(0, 2)` → `(0, 0)` slides up from below.
**`transitionBuilder`** — when non-null, **overrides `transition`**. Receives the `Animation<double>` (0 hidden → 1 shown). **Spring progress can overshoot**, so clamp opacity/size: `final v = anim.value.clamp(0.0, 1.0);`.

## `BottomBarTransition`

Enum values:

| Value | Effect |
|---|---|
| `slide` | `SlideTransition` from `slideStart` to `slideEnd`. |
| `fade` | `FadeTransition`. |
| `scale` | `ScaleTransition`. |
| `slideAndFade` | `SlideTransition` composed with `FadeTransition`. |

## `BottomBarScrollBehavior`

```dart
const BottomBarScrollBehavior({
  bool hideOnScroll = true,
  bool reverse = false,
  bool scrollOpposite = false,
  double deltaThreshold = 8,
  bool Function(ScrollNotification)? predicate,
});
```

| Field | Default | Notes |
|---|---|---|
| `hideOnScroll` | `true` | When `false`, scroll never hides the bar (imperative `controller.hide()` still works). |
| `reverse` | `false` | When `true`, bar hides on **upward** scroll instead of downward. |
| `scrollOpposite` | `false` | When `true`, the back-to-top icon scrolls to **end** instead of start. |
| `deltaThreshold` | `8` | Min scroll delta in px to flip visibility. Bump to `16+` if the bar feels twitchy. |
| `predicate` | `null` | Filter for `ScrollNotification`s. Return `false` to ignore. **Use this for `NestedScrollView`** to disambiguate inner vs outer scroll. |

## `BottomBarThemeData`

```dart
class BottomBarThemeData extends ThemeExtension<BottomBarThemeData> {
  const BottomBarThemeData({
    BoxDecoration? barDecoration,
    BoxDecoration? iconDecoration,
    double? iconWidth,
    double? iconHeight,
    BottomBarLayout? layout,
    BottomBarMotion? motion,
    BottomBarScrollBehavior? scrollBehavior,
  });
  // copyWith(...), lerp(other, t), merge(other) — other wins on conflict.
}
```

**Built-in M3 defaults** (when no theme is provided):
- `barDecoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28))`
- `iconDecoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)`
- `iconWidth: 30`, `iconHeight: 30`

Install app-wide:
```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    extensions: const [BottomBarThemeData(...)],
  ),
);
```

## `BottomBarController`

Extends `ChangeNotifier`.

| Member | Description |
|---|---|
| `bool isVisible` | Current visibility. |
| `bool isAttached` | Whether attached to a live `BottomBar`. |
| `void show()` | Show. Fires `onBottomBarShown`. |
| `void hide()` | Hide. Fires `onBottomBarHidden`. Bypasses `hideOnScroll: false`. |
| `void toggle()` | Toggle. |
| `Future<void> scrollToStart()` | Scrolls last-active scrollable to start. No-op if none observed. |
| `Future<void> scrollToEnd()` | Scrolls to end. |

**Cannot be attached to two `BottomBar`s simultaneously.** Double-attach asserts in debug. If you need two bars, use two controllers.

## `BottomBarScope`

`InheritedWidget` automatically installed inside `BottomBar`. Exposes:

| Member | Type | Notes |
|---|---|---|
| `barHeight` | `ValueListenable<double>` | Rendered height in logical px. `0` before first frame; updates post-layout. |
| `isVisible` | `ValueListenable<bool>` | Current visibility. |
| `BottomBarScope.of(context)` | `BottomBarScope` | Throws if absent. |
| `BottomBarScope.maybeOf(context)` | `BottomBarScope?` | Returns `null` if absent. |

Common use — bottom padding so content isn't clipped:
```dart
ValueListenableBuilder<double>(
  valueListenable: BottomBarScope.of(context).barHeight,
  builder: (context, height, _) => SizedBox(height: height + 24),
)
```

## `BottomBarItem` / `BottomBarItems`

Optional helpers for the nav-item case. Skip them if you have a `TabBar`, search field, or anything more custom — pass the raw widget as `child` instead.

```dart
const BottomBarItem({
  required Widget icon,
  Widget? selectedIcon,
  Widget? label,
  Widget? badge,
  bool selected = false,
  VoidCallback? onTap,
  String? tooltip,
  Color? color,
  Color? selectedColor,
});

const BottomBarItems({
  required List<Widget> children,
  MainAxisAlignment spacing = MainAxisAlignment.spaceAround,
});
```

`BottomBarItem` does **not** maintain its own state. Pass `selected: index == _currentIndex` and update in `onTap`.

## Re-exports from `package:motor/motor.dart`

The library re-exports these so you don't need a separate motor import for `BottomBarMotion.motor(...)`:

```dart
Motion, CupertinoMotion, CurvedMotion, LinearMotion, SpringMotion, MaterialSpringMotion
```

## SDK requirements

```yaml
environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.22.0"
```

Bump SDK constraints in the user's `pubspec.yaml` if their existing constraints are tighter.
