# Motion recipes

Dialing in motion that feels right is the package's most opinion-laden surface. This file is a decision tree + a small catalogue of presets for common app feels.

## How to think about motion choice

Three questions, in order:

1. **Does the user want the bar to feel responsive to their gesture?** If yes → spring (`BottomBarMotion.cupertino` or `BottomBarMotion.motor` with a spring). Springs redirect mid-flight when the user reverses scroll direction; curves restart from the new direction with a hard discontinuity.
2. **Do they need *deterministic* timing** (e.g. for goldens, screen recordings, or CI tests where consistent durations matter)? If yes → `BottomBarMotion.curved(...)`.
3. **Do they want a specific motor preset that none of the four cupertino presets cover?** If yes → `BottomBarMotion.motor(Motion.snappySpring())` or similar.

For 95% of apps, the answer is "1, give me the spring." Default to it.

## The default

```dart
const BottomBarMotion() // == cupertino + snappy + slide
```

This is what `BottomBar()` uses if you don't pass `motion:`. It's the right starting point. Recommend it before you recommend anything else.

## Cupertino presets — when to use which

```dart
const BottomBarMotion.cupertino(preset: BottomBarCupertinoMotion.snappy)
```

| Preset | Feel | Use when |
|---|---|---|
| `smooth` | Critically damped, no bounce. Soft, gentle. | App's design language is calm/professional (banking, productivity). |
| `snappy` | Default. Mild bounce, fast settle. Apple-system feel. | Default. Use unless you have a reason not to. |
| `bouncy` | Visible overshoot + oscillation. Playful. | Consumer/social apps, kids' apps, anything that wants personality. Pair with `extraBounce: 0.04` for *more* bounce. |
| `interactive` | Tuned for gesture-driven interactions. Quick to start, slow to settle. | Bars that respond directly to drag (rare for this package). |

If the user says **"playful"**, **"fun"**, **"social app"**, **"more personality"** → `bouncy`. If they say **"calm"**, **"professional"**, **"banking"**, **"corporate"** → `smooth`. Otherwise → `snappy`.

`extraBounce` knob: ranges roughly `0.0`–`0.1`. Even `0.04` is noticeable; `0.1` is loud. Default `0` is fine.

## Curved (deterministic)

```dart
BottomBarMotion.curved(
  duration: const Duration(milliseconds: 280),
  curve: Curves.easeOutCubic,
)
```

Use when:
- Writing widget tests / goldens that need exact timing.
- Matching an existing app-wide animation curve (if their `MaterialApp.theme` uses `easeInOut` everywhere, matching it keeps things coherent).
- The user explicitly asks for a curve.

Curve cheat sheet:

| Curve | Feel |
|---|---|
| `Curves.easeOutCubic` | Default. Decelerates smoothly. Good general-purpose. |
| `Curves.easeOutBack` | Slight overshoot. The closest thing to "spring" without using a spring. |
| `Curves.fastOutSlowIn` | Material standard easing. Use for M2-styled apps. |
| `Curves.easeInOutCubicEmphasized` | M3 emphasized easing. Use for M3 apps that want curved motion. |
| `Curves.linear` | Generally avoid. Robotic. |

Duration cheat sheet (rough):

| Range | Feel |
|---|---|
| 150–220ms | Snappy, almost instant. |
| 240–320ms | **Default range.** What most apps want. |
| 350–500ms | Slower, more visible. Use only when motion is part of the experience. |
| 500ms+ | Probably too slow for hide/show. |

## Raw Motor

```dart
BottomBarMotion.motor(Motion.snappySpring())
```

Reach for this only when the user wants a Motor motion the four Cupertino presets don't cover. Examples:

```dart
BottomBarMotion.motor(Motion.smoothSpring())
BottomBarMotion.motor(Motion.materialSpring())
BottomBarMotion.motor(Motion.snappySpring())
```

The Motor types (`Motion`, `CupertinoMotion`, `CurvedMotion`, `LinearMotion`, `SpringMotion`, `MaterialSpringMotion`) are re-exported by `flutter_floating_bottom_bar`. **No separate `motor` import needed.**

## Transitions

The transition is *what* animates (slide, fade, scale, both). The motion is *how* it animates (spring vs curve, fast vs slow).

```dart
BottomBarMotion(transition: BottomBarTransition.slide)        // default
BottomBarMotion(transition: BottomBarTransition.fade)
BottomBarMotion(transition: BottomBarTransition.scale)
BottomBarMotion(transition: BottomBarTransition.slideAndFade)
```

| Transition | When |
|---|---|
| `slide` | Default. Bar slides offscreen and back. Matches user mental model of a bar. |
| `fade` | Bar fades without moving. Use for FAB-like elements that shouldn't translate. |
| `scale` | Bar scales from 0 to 1. Playful. Pair with `bouncy` Cupertino for max effect. |
| `slideAndFade` | Combined. Use for showy hero transitions. |

### `slideStart` / `slideEnd`

Offsets in `SlideTransition` units (multiples of child size).

| Use case | `slideStart` | `slideEnd` |
|---|---|---|
| Standard slide-down (default) | `Offset(0, 2)` | `Offset.zero` |
| Slide further (feels more "fully gone") | `Offset(0, 3)` | `Offset.zero` |
| Slide-up from bottom | `Offset(0, -2)` | `Offset.zero` |
| Slide-from-left | `Offset(-2, 0)` | `Offset.zero` |
| Slide-from-right | `Offset(2, 0)` | `Offset.zero` |

Most layouts only need vertical slide. Don't change `slideStart`/`slideEnd` unless there's a reason.

## Custom transitions (`transitionBuilder`)

When the four enum values aren't enough, supply `transitionBuilder`. **It overrides `transition`.**

```dart
BottomBarMotion.curved(
  duration: const Duration(milliseconds: 320),
  curve: Curves.easeOutBack,
  transitionBuilder: (context, anim, child) {
    final v = anim.value.clamp(0.0, 1.0); // critical: spring progress can overshoot
    return Opacity(
      opacity: v,
      child: Transform.scale(
        scale: 0.6 + 0.4 * v,
        child: child,
      ),
    );
  },
)
```

**The `clamp(0.0, 1.0)` is not optional.** Springs can overshoot — `anim.value` may briefly be `1.05` or `-0.02`. `Opacity` at `1.05` works fine, but a `Transform.scale(scale: -0.02 * ...)` flips your widget. Always clamp values that go into `Opacity`, `scale`, or anything else that breaks at extreme values.

## Recipes by app feel

### "iOS-native"
```dart
const BottomBarMotion.cupertino(preset: BottomBarCupertinoMotion.snappy)
```

### "Material 3 expressive"
```dart
BottomBarMotion.curved(
  duration: const Duration(milliseconds: 320),
  curve: Curves.easeInOutCubicEmphasized,
)
```

### "Playful / social app"
```dart
const BottomBarMotion.cupertino(
  preset: BottomBarCupertinoMotion.bouncy,
  extraBounce: 0.04,
  transition: BottomBarTransition.slideAndFade,
  slideStart: Offset(0, 3),
)
```

### "Calm / banking / professional"
```dart
const BottomBarMotion.cupertino(
  preset: BottomBarCupertinoMotion.smooth,
  duration: Duration(milliseconds: 380),
)
```

### "Deterministic for tests"
```dart
const BottomBarMotion.curved(
  duration: Duration(milliseconds: 240),
  curve: Curves.easeOutCubic,
)
```

### "Subtle, almost not there"
```dart
const BottomBarMotion(transition: BottomBarTransition.fade)
```

## When the user asks for "great motion" without specifying

This is the most common case. Pick `snappy` Cupertino + `slide` (the default), and tell them in your plan: "I went with the default `BottomBarMotion()` — Cupertino snappy spring + slide. If you want something more playful, say so and I'll switch to `bouncy`. If you want deterministic timing for tests, I can switch to `BottomBarMotion.curved(...)`."

This gives them a great default and a clear off-ramp without making them choose upfront.
