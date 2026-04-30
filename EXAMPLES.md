# Examples

Run the demo app:

```bash
cd example
flutter run
```

The examples now focus on motion. `BottomBarMotion()` defaults to Motor-backed Cupertino spring motion, so quick scroll direction changes redirect naturally instead of restarting a fixed curve.

## Polished Demos

### Issues dock — `example/lib/demos/tab_bar_demo.dart`

Reference-inspired issue list with a floating icon dock and search puck. Scroll quickly up/down to see the Cupertino spring redirect mid-flight.

![Issues dock](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/1-issues-dock.gif)

### AI prompt dock — `example/lib/demos/search_bar_demo.dart`

Large prompt composer with pill actions, a speak button, and interactive Cupertino motion.

![AI prompt dock](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/2-ai-prompt-dock.gif)

### Basic TabBar — `example/lib/demos/basic_tab_bar_demo.dart`

Direct five-tab bottom bar with a floating center action, colored pages, hide-on-scroll, and the default Cupertino-style spring.

![Basic TabBar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/3-basic-tab-bar.gif)

### Minimal API — `example/lib/demos/basic_demo.dart`

Compact example showing the default spring behavior with the smallest useful `BottomBar` setup.

![Minimal API](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/4-minimal-api.gif)

## Supporting Recipes

### Nested scroll — `example/lib/demos/nested_scroll_demo.dart`

`NestedScrollView` support with smooth spring show/hide.

![Nested scroll](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/5-nested-scroll.gif)

### Badged nav — `example/lib/demos/badges_demo.dart`

`BottomBarItems` and `BottomBarItem` with bouncy Cupertino motion.

![Badged nav](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/6-badged-nav.gif)

### Custom transition — `example/lib/demos/custom_transition_demo.dart`

Deterministic `BottomBarMotion.curved(...)` plus a custom fade/scale builder. Clamp opacity and size in custom builders because spring progress can overshoot.

![Custom transition](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/7-custom-transition.gif)

## Motion Snippets

```dart
// Default Cupertino spring.
const BottomBarMotion()
```

```dart
// A more expressive spring.
const BottomBarMotion.cupertino(
  preset: BottomBarCupertinoMotion.bouncy,
  extraBounce: 0.04,
)
```

```dart
// Traditional fixed-time motion for deterministic tests/goldens.
const BottomBarMotion.curved(
  duration: Duration(milliseconds: 280),
  curve: Curves.easeOutCubic,
)
```

```dart
// Raw Motor motion.
const BottomBarMotion.motor(
  Motion.snappySpring(),
)
```

---

## Recording your own gifs

The repo ships a small recording helper for the iOS Simulator at [tool/record_gif.sh](tool/record_gif.sh).

1. Boot the iOS Simulator and run the demo app:
   ```bash
   make run-ios
   ```
2. Pick a demo from the list and navigate to it.
3. In a second terminal, start recording with the slug for that demo:
   ```bash
   make record NAME=1-issues-dock
   ```
4. Interact with the simulator (scroll, tap, etc.). Press `Ctrl+C` in the recording terminal to stop and finalize.
5. The gif is written to `screenshots/<NAME>.gif`.

Use these slugs so they line up with the README grid:

| # | Demo               | Slug                    |
|---|--------------------|-------------------------|
| 1 | Issues dock        | `1-issues-dock`         |
| 2 | AI prompt dock     | `2-ai-prompt-dock`      |
| 3 | Basic TabBar       | `3-basic-tab-bar`       |
| 4 | Minimal API        | `4-minimal-api`         |
| 5 | Nested scroll      | `5-nested-scroll`       |
| 6 | Badged nav         | `6-badged-nav`          |
| 7 | Custom transition  | `7-custom-transition`   |

Tunables (env vars): `GIF_FPS` (default `24`), `GIF_WIDTH` (default `360`).
