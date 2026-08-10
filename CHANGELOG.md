## [Unreleased]

### Added

- `BottomBarLayout.maxWidth` and `BottomBarLayout.adaptive(maxWidth: ...)` for
  width-capped adaptive layouts.
- `BottomBarBodyPadding` as the built-in way to reserve the live floating-bar
  footprint inside `BottomBar.body`.
- `BottomBarScrollBehavior.showAtStart` and
  `BottomBarScrollBehavior.showOnScrollEnd` for settling-based visibility
  restoration.

### Changed

- `BottomBarScope.barHeight` now reflects the full rendered footprint reserved
  by the bar, including configured offset and bottom safe-area when enabled.
- `BottomBarItem` accessible naming is now deterministic:
  `semanticLabel` wins, otherwise `tooltip`, otherwise descendant semantics.
  Explicit names exclude descendant semantics to avoid duplicate announcements.
- Custom `BottomBarMotion.transitionBuilder` usage is documented as a
  paint-only contract that must preserve layout footprint.
- The hidden action is direction-aware by default: glyph, tooltip, and
  semantics flip with `scrollOpposite`, the touch target stays at least 48x48
  when active, and the default glyph color follows `ColorScheme.onPrimary`.
- Hidden bar actions are non-interactive and excluded from semantics when the
  bar is visible.
- Reduced-motion environments snap directly to the target shown/hidden state
  instead of animating.
- `BottomBarController` ownership is strict: double-attach fails in debug and
  release, and visibility updates are accepted only from the owning bar.
- `BottomBarController` boundary scrolling now documents and uses explicit
  start/end semantics independent of `scrollOpposite`.

### Fixed

- `BottomBarController.scrollToStart()` always targets
  `ScrollPosition.minScrollExtent`, and `scrollToEnd()` always targets
  `ScrollPosition.maxScrollExtent`.
- `NestedScrollView` boundary scrolling now targets the correct coordinated
  controller so start/end actions reset both header and body as expected.
- Large `iconOffset` values keep the hidden action tappable because hit testing
  now follows the translated visual position.

## 2.0.2

- Fix: `BottomBarController.scrollToStart()` (and the back-to-top icon) did not
  fully reset a `NestedScrollView` — the collapsed
  `SliverAppBar`/`FlexibleSpaceBar` stayed collapsed and the list landed below
  its true top. A `NestedScrollView` scrolls on two coordinated positions (an
  outer header and an inner body), but the bar only animated the
  most-recently-active one. The controller now detects an enclosing
  `NestedScrollView` and drives its shared scroll coordinator with a single
  call — animating the outer controller to the top (which pulls the inner body
  up with it) for `scrollToStart`, and the inner controller to the bottom
  (which collapses the header) for `scrollToEnd`.
  ([#21](https://github.com/codenameakshay/flutter-floating-bottom-bar/issues/21))

## 2.0.1

- Fix: the back-to-top icon became unclickable when a large `iconOffset` was
  set. The icon was painted at the offset position but its `SafeArea` ancestor
  still hit-tested against the original (untranslated) rect, so a large offset
  moved the visible icon outside its tappable area. The offset now wraps the
  icon's `SafeArea` so hit-testing follows the painted position.
  ([#19](https://github.com/codenameakshay/flutter-floating-bottom-bar/issues/19))

## 2.0.0

Major release. Breaking changes — see the migration table in `README.md`.

Breaking:

- Dart SDK minimum is now `>=3.5.0` because the package uses Motor-backed
  motion.
- `BottomBar.body` is now `Widget` instead of
  `Widget Function(BuildContext, ScrollController)`. The bar listens to
  `ScrollNotification` from any descendant scrollable; you no longer wire a
  controller through the builder.
- The `barColor`, `width`, `offset`, `borderRadius`, `barAlignment`, `fit`,
  `clip`, and `respectSafeArea` parameters moved into `BottomBarLayout`.
- The `duration`, `curve`, `start`, and `end` parameters moved into
  `BottomBarMotion`. `BottomBarMotion()` now defaults to Cupertino spring
  motion; existing `BottomBarMotion(duration: ..., curve: ...)` calls remain
  curve-based. `start`/`end` (doubles) are now `slideStart`/`slideEnd`
  (`Offset`s).
- The `hideOnScroll`, `reverse`, `scrollOpposite`, and
  `scrollDeltaThreshold` parameters moved into `BottomBarScrollBehavior`.
  `scrollDeltaThreshold` is now `deltaThreshold`.
- The `iconWidth`, `iconHeight`, `iconDecoration`, and `barDecoration`
  parameters moved to `BottomBarThemeData` (per-instance overrides remain via
  the `theme:` argument).
- `BottomBarScrollControllerProvider` is replaced by `BottomBarScope`. The
  `scrollController` field is gone; new fields are `barHeight` and `isVisible`.
- The hardcoded `Colors.black` default is replaced with Material 3
  `colorScheme.surfaceContainer` for the bar and `colorScheme.primary` for the
  icon.

New:

- Motor-backed Cupertino motion is the default show/hide engine, with
  velocity-preserving redirection when scroll direction changes mid-animation.
- `BottomBarMotion.cupertino(...)`, `BottomBarMotion.curved(...)`, and
  `BottomBarMotion.motor(...)` constructors.
- `BottomBarThemeData` `ThemeExtension` for app-wide defaults.
- `BottomBarTransition` enum (`slide`, `fade`, `scale`, `slideAndFade`) plus
  `BottomBarMotion.transitionBuilder`.
- `BottomBarItem` and `BottomBarItems` helpers for the common nav-item case.
- `BottomBarScope.barHeight` exposes the live rendered bar height to
  descendants for content-padding purposes.
- `BottomBarScope.isVisible` exposes live visibility without owning a
  controller.
- Notification-based scroll detection works with `NestedScrollView`,
  `CustomScrollView`, multiple `TabBarView` children, and any user-supplied
  `ScrollController` with no wiring.
- `BottomBarScrollBehavior.predicate` for filtering unwanted notifications.
- `BottomBarController` now asserts on double-attach in debug.

Repository:

- Package source moved from `packages/flutter_floating_bottom_bar/` to repo
  root. The example app moved to `example/`. The `packages/` directory is
  removed.

## 1.4.0

- Upgrade project/tooling for Flutter `3.41.4` development via FVM.
- Update SDK constraints and refresh dependencies.
- Add `BottomBarController` for programmatic `show`, `hide`, `toggle`,
  `scrollToStart`, and `scrollToEnd`.
- Add `onVisibilityChanged` callback for visibility state transitions.
- Add `scrollDeltaThreshold` to reduce flicker from minor scroll movement.
- Add `iconSemanticLabel` and `iconTooltip` for better accessibility.
- Improve internal scroll/visibility handling and test coverage.

## 1.3.0

- Added `respectSafeArea` property to control whether the `BottomBar` should
  respect the safe area.
- Removed deprecated `alignment` property (use `barAlignment` instead).
- Fixed `ScrollController` issues with multiple attachments.
- Improved scroll listener management for better performance.

## 1.2.1+1

- Fix code formatting.

## 1.2.1

- Update to Flutter `3.22.1`.
- Fix divider error in example.
- Update dependencies.

## 1.2.0

- Add `offset`, `barAlignment`, `barDecoration`, and `iconDecoration`
  properties.
- Remove `bottom` property.
- Deprecate `alignment` in favor of `barAlignment`.
- Update all code examples and fix errors.

## 1.1.0

- Add `clip` property to support clip behavior.
- Add an example for a bar with a FAB.

## 1.0.1

- Support Flutter `3.10.5`.
- Update dependencies.

## 1.0.0+1

- Add documentation.

## 1.0.0

- Initial release with basic functionality.
