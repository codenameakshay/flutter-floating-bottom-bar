# `flutter_floating_bottom_bar` v2.0.0 — Design

Date: 2026-04-29
Status: Approved (pending spec review)
Release strategy: Major v2.0.0 with breaking changes; no compat shim.

## 1. Goals

- Modernize architecture: split the single 480-line `bottom_bar.dart` into focused units, group the 29 flat constructor parameters into config objects, and add Material 3-aware theming via `ThemeExtension`.
- Eliminate the "controller attached to multiple ScrollPositions" bug class by replacing controller-based scroll detection with notification-based detection.
- Add ergonomics: optional `BottomBarItem` / `BottomBarItems` helpers for the common nav-item case (without turning the package into a full navigation widget).
- Flatten the repository so the package lives at root and the example app lives at `example/`, matching pub.dev convention.
- Ensure the existing example app's behavior is preserved 1:1 after migration.

Non-goals (parking lot for later releases):

- Keyboard-aware auto-hide.
- Idle-hide timer.
- Swipe-to-toggle gesture.
- Web/desktop-specific hover states beyond Flutter's default `InkWell`.
- A high-level fully-wired `FloatingNavigationBar` widget.

## 2. Repository layout (after flattening)

The package becomes the repo root; the example app moves into `example/`. The `packages/` directory is deleted.

```
flutter-floating-bottom-bar/
  lib/
    flutter_floating_bottom_bar.dart        # public exports
    src/
      bottom_bar.dart                       # BottomBar widget + state
      bottom_bar_controller.dart            # BottomBarController
      bottom_bar_scope.dart                 # InheritedWidget for descendants
      bottom_bar_theme.dart                 # BottomBarThemeData ThemeExtension
      config/
        bottom_bar_layout.dart
        bottom_bar_motion.dart
        bottom_bar_scroll_behavior.dart
      widgets/
        bottom_bar_item.dart
        bottom_bar_items.dart
      internal/
        scroll_notification_dispatcher.dart
        visibility_animator.dart
  test/
    bottom_bar_test.dart
    bottom_bar_controller_test.dart
    bottom_bar_theme_test.dart
    bottom_bar_items_test.dart
    bottom_bar_scope_test.dart
    bottom_bar_motion_test.dart
    goldens/
  example/
    lib/
      main.dart
      demos/
        tab_bar_demo.dart
        search_bar_demo.dart
        basic_demo.dart
        nested_scroll_demo.dart
        badges_demo.dart
        custom_transition_demo.dart
      widgets/
        infinite_list_page.dart
    test/
      widget_test.dart
    android/  ios/  macos/  linux/  windows/  web/
    pubspec.yaml
  pubspec.yaml                              # package pubspec, version 2.0.0
  README.md                                 # rewritten
  EXAMPLES.md                               # ported recipes (replaces example/example.md)
  CHANGELOG.md                              # ## 2.0.0 entry added
  LICENSE
  analysis_options.yaml
  screenshots/
  .fvm/  .fvmrc
  Makefile                                  # paths updated
  .metadata
```

### File moves

| From | To |
|---|---|
| `packages/flutter_floating_bottom_bar/lib/**` | `lib/**` |
| `packages/flutter_floating_bottom_bar/test/**` | `test/**` |
| `packages/flutter_floating_bottom_bar/pubspec.yaml` | `pubspec.yaml` (replaces root) |
| `packages/flutter_floating_bottom_bar/CHANGELOG.md` | `CHANGELOG.md` (replaces root) |
| `packages/flutter_floating_bottom_bar/README.md` | merged into root `README.md` |
| Root `lib/main.dart` and `lib/pages/` | `example/lib/main.dart` and `example/lib/widgets/` |
| Root `test/widget_test.dart` | `example/test/widget_test.dart` |
| Root `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` | `example/{android,ios,...}` |
| `packages/flutter_floating_bottom_bar/example/example.md` | replaced by root `EXAMPLES.md` (content ported to v2 API) |
| `packages/` | deleted |

### Pubspec changes

Root `pubspec.yaml` (the package):

```yaml
name: flutter_floating_bottom_bar
version: 2.0.0
description: A floating widget that can host a tab bar, navigation bar, search bar, or any custom child, and reacts to scrolling events.
homepage: https://hashstudios.in
repository: https://github.com/codenameakshay/flutter-floating-bottom-bar
environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

`example/pubspec.yaml`:

```yaml
name: flutter_floating_bottom_bar_example
publish_to: 'none'
dependencies:
  flutter:
    sdk: flutter
  flutter_floating_bottom_bar:
    path: ../
```

## 3. Public API

### 3.1 `BottomBar`

```dart
BottomBar({
  required Widget child,                    // floating widget contents
  required Widget body,                     // body widget; not a builder
  BottomBarController? controller,
  BottomBarLayout layout = const BottomBarLayout(),
  BottomBarMotion motion = const BottomBarMotion(),
  BottomBarScrollBehavior scrollBehavior = const BottomBarScrollBehavior(),
  BottomBarThemeData? theme,
  BackToTopIconBuilder? icon,
  bool showIcon = true,
  String? iconSemanticLabel,
  String? iconTooltip,
  ValueChanged<bool>? onVisibilityChanged,
  VoidCallback? onBottomBarShown,
  VoidCallback? onBottomBarHidden,
  Key? key,
})
```

`body` is a plain widget; `BottomBar` does not own or supply a `ScrollController`. Scroll-driven hide/show is observed through `ScrollNotification` from any descendant scrollable in the body's subtree.

### 3.2 Config objects

```dart
class BottomBarLayout {
  const BottomBarLayout({
    this.width = 300,
    this.offset = 10,
    this.borderRadius = BorderRadius.zero,
    this.alignment = Alignment.bottomCenter,
    this.fit = StackFit.loose,
    this.clip = Clip.hardEdge,
    this.respectSafeArea = true,
  });
  final double width;
  final double offset;
  final BorderRadius borderRadius;
  final Alignment alignment;
  final StackFit fit;
  final Clip clip;
  final bool respectSafeArea;
}

class BottomBarMotion {
  const BottomBarMotion({
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeOutCubic,
    this.transition = BottomBarTransition.slide,
    this.transitionBuilder,
    this.slideStart = const Offset(0, 2),
    this.slideEnd = Offset.zero,
  });
  final Duration duration;
  final Curve curve;
  final BottomBarTransition transition;
  final Widget Function(BuildContext, Animation<double>, Widget)? transitionBuilder;
  final Offset slideStart;
  final Offset slideEnd;
}

enum BottomBarTransition { slide, fade, scale, slideAndFade }

class BottomBarScrollBehavior {
  const BottomBarScrollBehavior({
    this.hideOnScroll = true,
    this.reverse = false,
    this.scrollOpposite = false,
    this.deltaThreshold = 8,
    this.predicate,
  });
  final bool hideOnScroll;
  final bool reverse;
  final bool scrollOpposite;
  final double deltaThreshold;
  final bool Function(ScrollNotification notification)? predicate;
}
```

### 3.3 `BottomBarThemeData`

```dart
class BottomBarThemeData extends ThemeExtension<BottomBarThemeData> {
  const BottomBarThemeData({
    this.barDecoration,
    this.iconDecoration,
    this.iconWidth,
    this.iconHeight,
    this.layout,
    this.motion,
    this.scrollBehavior,
  });
  final BoxDecoration? barDecoration;
  final BoxDecoration? iconDecoration;
  final double? iconWidth;
  final double? iconHeight;
  final BottomBarLayout? layout;
  final BottomBarMotion? motion;
  final BottomBarScrollBehavior? scrollBehavior;

  @override BottomBarThemeData copyWith({...});
  @override BottomBarThemeData lerp(ThemeExtension<BottomBarThemeData>? other, double t);
  BottomBarThemeData merge(BottomBarThemeData? other);  // other wins
}
```

Resolution order at build time, low → high precedence:

1. Built-in defaults.
2. `Theme.of(context).extension<BottomBarThemeData>()`.
3. The `theme` argument on `BottomBar`.
4. Per-widget config arguments (`layout`, `motion`, `scrollBehavior`).

Built-in defaults use Material 3 colors:

- `barDecoration`: `BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(28))`.
- `iconDecoration`: `BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle)`.
- `iconWidth`, `iconHeight`: `30`.

The hardcoded `Colors.black` default from v1 is gone.

### 3.4 `BottomBarController`

API surface preserved from v1.4.0:

```dart
class BottomBarController extends ChangeNotifier {
  bool get isVisible;
  bool get isAttached;
  void show();
  void hide();
  void toggle();
  Future<void> scrollToStart();
  Future<void> scrollToEnd();
}
```

`scrollToStart` and `scrollToEnd` operate on the most recently observed `ScrollPosition` (tracked from incoming `ScrollNotification`s). If no scrollable has been observed yet, the call is a no-op and emits a single debug-mode `FlutterError.reportError` warning.

A controller cannot be attached to two `BottomBar`s simultaneously; double-attach asserts in debug and emits a single `FlutterError.reportError` in release.

### 3.5 `BottomBarScope`

Replaces `BottomBarScrollControllerProvider`. Exposes height and visibility for descendant widgets; does not expose any `ScrollController`.

```dart
class BottomBarScope extends InheritedWidget {
  ValueListenable<double> get barHeight;
  ValueListenable<bool> get isVisible;
  static BottomBarScope of(BuildContext context);
  static BottomBarScope? maybeOf(BuildContext context);
}
```

`barHeight` starts at `0` and is updated after the first frame using a post-layout `RenderBox` measurement. Consumers are expected to wrap reads in `ValueListenableBuilder` and tolerate the first-frame transition.

### 3.6 `BottomBarItem` and `BottomBarItems`

```dart
class BottomBarItem extends StatelessWidget {
  const BottomBarItem({
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
    this.selected = false,
    this.onTap,
    this.tooltip,
    this.color,
    this.selectedColor,
  });
  final Widget icon;
  final Widget? selectedIcon;
  final Widget? label;
  final Widget? badge;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final Color? selectedColor;
}

class BottomBarItems extends StatelessWidget {
  const BottomBarItems({
    required this.children,
    this.spacing = MainAxisAlignment.spaceAround,
  });
  final List<Widget> children;
  final MainAxisAlignment spacing;
}
```

`BottomBarItem` renders `Tooltip > InkWell > Column(icon|selectedIcon, label?)` with an optional `Badge` overlay. There is no internal selection state machine; consumers pass `selected: i == currentIndex` and handle `onTap`. `BottomBarItems` is a thin row layout helper.

### 3.7 Public exports

`flutter_floating_bottom_bar.dart` exports: `BottomBar`, `BottomBarController`, `BottomBarScope`, `BottomBarThemeData`, `BottomBarLayout`, `BottomBarMotion`, `BottomBarScrollBehavior`, `BottomBarTransition`, `BottomBarItem`, `BottomBarItems`, `BackToTopIconBuilder`. Files under `src/internal/` are not exported.

## 4. Behavior

### 4.1 Scroll detection

`_BottomBarState` wraps its `Stack` in a single `NotificationListener<ScrollNotification>`. The listener is the only source of truth for scroll-driven visibility changes. Algorithm per notification:

1. If `widget.scrollBehavior.predicate != null` and returns `false`, ignore.
2. Identify the originating scrollable by combining `notification.depth` (depth of the originating `Scrollable` relative to this `NotificationListener`) and `notification.metrics.axis`. Track per-scrollable last offset in a `Map<int, double>` of bounded size (max 16; LRU eviction). Stale entries are evicted on `ScrollEndNotification` for the same key.
3. Compute `delta = currentOffset - lastOffset`. Update last offset.
4. If `|delta| < scrollBehavior.deltaThreshold`, ignore.
5. `shouldHide = scrollBehavior.reverse ? delta < 0 : delta > 0`. Call `_setVisible(!shouldHide)`.
6. Remember this scrollable's `ScrollPosition` as the active one for `BottomBarController.scrollToStart`/`scrollToEnd`.

This handles `NestedScrollView`, multiple `TabBarView` children, `CustomScrollView`, and user-supplied controllers without any wiring on the consumer's part.

### 4.2 Visibility animation

A `_VisibilityAnimator` widget in `internal/visibility_animator.dart` owns the `AnimationController`. The transition is resolved at build time:

- If `motion.transitionBuilder != null`, it is used.
- Otherwise, the `motion.transition` enum dispatches:
  - `slide`: `SlideTransition` from `motion.slideStart` to `motion.slideEnd`.
  - `fade`: `FadeTransition`.
  - `scale`: `ScaleTransition`.
  - `slideAndFade`: composed `SlideTransition` + `FadeTransition`.

`_setVisible(bool)` calls `controller.forward()` or `controller.reverse()`. Callbacks (`onVisibilityChanged`, `onBottomBarShown`, `onBottomBarHidden`, `BottomBarController._updateVisibility`) fire on the target state at the moment of state change, not on animation completion. This matches v1.x firing semantics.

### 4.3 Bar height measurement

The bar widget is wrapped in a `_HeightProbe` that uses a post-frame `RenderBox.size.height` read and writes to a `ValueNotifier<double>` exposed through `BottomBarScope.barHeight`. Updates trigger on subsequent layouts (e.g., orientation change). The notifier starts at `0` for the first frame.

### 4.4 Edge cases

- No scrollable in the body subtree: bar stays visible permanently; `scrollToStart`/`scrollToEnd` is a no-op.
- Body rebuilds without changing scrollable identity: tracking map keys remain stable.
- Bar removed from tree mid-animation: `dispose()` stops the controller; no late `setState`.
- Hot reload changes `motion.duration`: `didUpdateWidget` updates the animation controller's duration in place.
- `scrollBehavior.hideOnScroll == false` combined with `controller.hide()`: the bar still hides. Imperative controller calls override scroll-suppression, matching v1.x's `fromController` flag semantics.
- Controller attached to two `BottomBar`s: asserts in debug, reports a `FlutterError` in release, and the second attach wins.

## 5. Migration from v1.4.0

| v1.x | v2.0 | Migration |
|---|---|---|
| `body: (context, controller) => Widget` | `body: Widget` | Drop the builder; use any `ScrollController` you want internally. The bar listens to notifications. |
| `barColor` | removed | Use `BottomBarThemeData.barDecoration`, or set a `BoxDecoration` via `theme:`. |
| `width`, `offset`, `borderRadius`, `barAlignment`, `fit`, `clip`, `respectSafeArea` | `BottomBarLayout` | Wrap into `layout: BottomBarLayout(...)`. `barAlignment` → `alignment`. |
| `duration`, `curve`, `start`, `end` | `BottomBarMotion` | Wrap into `motion: BottomBarMotion(...)`. `start`/`end` (doubles) → `slideStart`/`slideEnd` (`Offset`s). |
| `hideOnScroll`, `reverse`, `scrollOpposite`, `scrollDeltaThreshold` | `BottomBarScrollBehavior` | Wrap into `scrollBehavior: BottomBarScrollBehavior(...)`. `scrollDeltaThreshold` → `deltaThreshold`. |
| `iconWidth`, `iconHeight`, `iconDecoration`, `barDecoration` | `BottomBarThemeData` | Move to theme. Per-instance overrides remain via the `theme:` argument. |
| `BottomBarScrollControllerProvider` | `BottomBarScope` | Renamed. The `scrollController` field is gone; pass your own controller into your scrollable directly. New fields: `barHeight`, `isVisible`. |

No compat shim ships with v2.

## 6. Examples and documentation

### 6.1 Example app

Located at `example/`. The current behavior of the v1 example app (5 colored pages, `TabBar` with FAB notch, infinite list per page, color-driven theming) is reproduced 1:1 in `tab_bar_demo.dart`, ported to the v2 API. Visual parity is verified manually against the v1 screenshots before merge.

Demos:

- `basic_demo.dart`: minimal `BottomBar(child:, body:)` usage.
- `tab_bar_demo.dart`: 1:1 port of the existing v1 demo.
- `search_bar_demo.dart`: floating search bar variant.
- `nested_scroll_demo.dart`: `NestedScrollView` + bar, demonstrating the new notification-based behavior.
- `badges_demo.dart`: `BottomBarItems` row with `BottomBarItem`s carrying badges and selection state.
- `custom_transition_demo.dart`: `BottomBarTransition.fade` plus a custom `transitionBuilder` example.

`example/lib/main.dart` is a `MaterialApp` whose `home` is a scaffold with a `Drawer` for picking the demo.

### 6.2 README

Rewritten. Sections, in order:

1. Banner and badges (preserved from v1).
2. Feature overview.
3. Install.
4. 5-line basic usage.
5. Migration from v1 (the table from §5).
6. Recipes — three or four short inline snippets (basic, tab bar, search bar, badges) with a prominent link to `EXAMPLES.md`.
7. API reference table (config objects, theme, controller, scope, items).
8. Contributing.

### 6.3 `EXAMPLES.md`

Replaces the old `packages/flutter_floating_bottom_bar/example/example.md` (528 lines). Same recipe coverage, all snippets ported to the v2 API. Each recipe corresponds 1:1 to a runnable demo in `example/lib/demos/` so users can either read or run.

### 6.4 `CHANGELOG.md`

Adds a `## 2.0.0` entry summarizing every breaking change from §5 plus the new features (`BottomBarScope`, `BottomBarThemeData`, `BottomBarItem`/`BottomBarItems`, transitions, notification-based scroll detection).

## 7. Testing

### 7.1 Widget tests (`test/`)

Existing tests from v1 are ported to the v2 API. New coverage added:

- Renders with all default config objects.
- `BottomBarThemeData`: defaults pull from a `Theme.extension`; widget-level `theme:` overrides extension.
- Notification path: drag inside a nested `ListView` hides the bar; opposite drag shows.
- Notification path: drag inside one of two `TabBarView` children does not false-hide on tab switch.
- `predicate` filters out unwanted notifications.
- `BottomBarController`: attach/detach across rebuilds; double-attach asserts in debug.
- `BottomBarMotion.transition: fade` plays a `FadeTransition`; non-null `transitionBuilder` overrides the enum.
- `BottomBarScope.barHeight` reports the rendered height after the first frame.
- `BottomBarItem`: selection swaps `icon` ↔ `selectedIcon` and applies `selectedColor`.
- `BottomBarItem`: badge renders when supplied.
- `scrollDeltaThreshold` (now `BottomBarScrollBehavior.deltaThreshold`) suppresses tiny movements (ported from v1).
- Custom tooltip is attached to the icon action (ported from v1).

### 7.2 Golden tests (`test/goldens/`)

- Default Material 3 light and dark themes.
- Each `BottomBarTransition` enum value at 50% animation progress.

### 7.3 Targets

- ~20 widget + golden tests total, all passing.
- `flutter analyze` clean (no warnings, no infos).
- `flutter pub publish --dry-run` reports no errors and no warnings beyond expected ones.

## 8. Implementation phasing

1. **Repo flatten.** `git mv` files, replace root `pubspec.yaml`/`CHANGELOG.md`/`README.md` with package versions, move platform folders to `example/`, regenerate `.metadata`, update `Makefile` and `.gitignore`. After this phase: `flutter pub get` works at root; example builds and runs on the unchanged v1 API.
2. **Internal split, no API change.** Extract files into `lib/src/` per §2 layout; public API identical to v1.4.0. After this phase: all 5 existing tests still pass.
3. **API redesign.** Introduce config objects, `BottomBarThemeData`, rewrite the constructor, port existing tests. After this phase: package compiles, ported tests pass; example app is broken (expected).
4. **Notification-based scroll.** Replace controller-based detection with `_ScrollNotificationDispatcher` per §4.1. Add nested-scroll and multi-scrollable tests.
5. **Scope, theme resolution, transitions, items.** `BottomBarScope` with `barHeight` and `isVisible`, `BottomBarThemeData` resolution per §3.3, `BottomBarTransition` enum and `transitionBuilder` per §4.2, `BottomBarItem`/`BottomBarItems` per §3.6. Each lands with its own tests.
6. **Example app rebuild.** Port `tab_bar_demo` first (visual parity check vs v1 screenshots), then add `basic`, `search_bar`, `nested_scroll`, `badges`, `custom_transition`. Run each demo manually plus `flutter test` in `example/`.
7. **Docs.** Rewrite root `README.md`, write `EXAMPLES.md` (porting all v1 recipes), write `CHANGELOG.md ## 2.0.0`. Regenerate screenshots if the tab-bar demo's visuals shifted.
8. **Goldens and final pass.** Add golden tests, run full `flutter test` and `flutter analyze`, sanity-check pub.dev metadata via `flutter pub publish --dry-run`.

## 9. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Notification-based detection misbehaves with `NestedScrollView`'s inner/outer split. | Phase 4 includes a dedicated `nested_scroll_demo.dart`; `BottomBarScrollBehavior.predicate` is the documented escape hatch. |
| Bar height measurement causes a layout-then-rebuild jump on the first frame. | Initial `ValueNotifier<double>` value is `0`; consumers wrap reads in `ValueListenableBuilder` and tolerate the first-frame transition. Documented. |
| `BottomBarController.scrollToStart`/`scrollToEnd` has no scrollable to act on. | No-op, with a debug-mode `FlutterError.reportError` warning. Documented. |
| Theme resolution merge order surprises users. | Codified in one place (`bottom_bar_theme.dart`) with unit tests; documented in API docs and README. |
| Visual parity break in the ported tab-bar demo. | Phase 6 starts with a side-by-side comparison against v1 screenshots before any other demos are ported. |
| Pub.dev sees the flattening as a "moved package". | Pub.dev tracks by package name plus version; the path move is invisible to consumers. The first v2 publish is a clean upload. |

## 10. Definition of done

- Repo flattened: package at root, example at `example/`, `packages/` removed.
- All v2 source files present in `lib/src/` per §2 layout.
- `pubspec.yaml` version is `2.0.0`; exports complete.
- All ~20 widget plus golden tests pass.
- `flutter analyze` clean (no warnings, no infos beyond Dart's defaults).
- Example app builds and all six demos run; `tab_bar_demo` visually matches v1's screenshots.
- `README.md`, `EXAMPLES.md`, and `CHANGELOG.md ## 2.0.0` written.
- `flutter pub publish --dry-run` reports no errors and no warnings beyond expected ones.
