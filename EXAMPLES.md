# Examples

Run the demo app:

```bash
cd example
flutter run
```

The examples now focus on motion. `BottomBarMotion()` defaults to Motor-backed Cupertino spring motion, so quick scroll direction changes redirect naturally instead of restarting a fixed curve.

## Polished Demos

- **Issues dock** (`example/lib/demos/tab_bar_demo.dart`): reference-inspired issue list with a floating icon dock and search puck. Scroll quickly up/down to see the Cupertino spring redirect mid-flight.
- **AI prompt dock** (`example/lib/demos/search_bar_demo.dart`): large prompt composer with pill actions, a speak button, and interactive Cupertino motion.
- **Minimal API** (`example/lib/demos/basic_demo.dart`): compact example showing the default spring behavior with the smallest useful `BottomBar` setup.

## Supporting Recipes

- **Nested scroll**: `NestedScrollView` support with smooth spring show/hide.
- **Badged nav**: `BottomBarItems` and `BottomBarItem` with bouncy Cupertino motion.
- **Custom transition**: deterministic `BottomBarMotion.curved(...)` plus a custom fade/scale builder. Clamp opacity and size in custom builders because spring progress can overshoot.

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
