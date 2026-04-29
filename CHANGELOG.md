## 2.0.0

Major release. Breaking changes — see the migration table in README.md and EXAMPLES.md.

Breaking:
- `BottomBar.body` is now `Widget` instead of `Widget Function(BuildContext, ScrollController)`. The bar listens to `ScrollNotification` from any descendant scrollable; you no longer wire a controller through the builder.
- The `barColor`, `width`, `offset`, `borderRadius`, `barAlignment`, `fit`, `clip`, `respectSafeArea` parameters have moved into `BottomBarLayout`.
- The `duration`, `curve`, `start`, `end` parameters have moved into `BottomBarMotion`. `start`/`end` (doubles) are now `slideStart`/`slideEnd` (`Offset`s).
- The `hideOnScroll`, `reverse`, `scrollOpposite`, `scrollDeltaThreshold` parameters have moved into `BottomBarScrollBehavior`. `scrollDeltaThreshold` is now `deltaThreshold`.
- The `iconWidth`, `iconHeight`, `iconDecoration`, `barDecoration` parameters move to `BottomBarThemeData` (per-instance overrides remain via the `theme:` argument).
- `BottomBarScrollControllerProvider` is replaced by `BottomBarScope`. The `scrollController` field is gone; new fields are `barHeight` and `isVisible`.
- The hardcoded `Colors.black` default is replaced with Material 3 `colorScheme.surfaceContainer` for the bar and `colorScheme.primary` for the icon.

New:
- `BottomBarThemeData` `ThemeExtension` for app-wide defaults.
- `BottomBarTransition` enum (`slide`, `fade`, `scale`, `slideAndFade`) plus `BottomBarMotion.transitionBuilder` escape hatch.
- `BottomBarItem` and `BottomBarItems` helpers for the common nav-item case.
- `BottomBarScope.barHeight` exposes the live rendered bar height to descendants for content-padding purposes.
- `BottomBarScope.isVisible` exposes live visibility without owning a controller.
- Notification-based scroll detection works with `NestedScrollView`, `CustomScrollView`, multiple `TabBarView` children, and any user-supplied `ScrollController` with no wiring.
- `BottomBarScrollBehavior.predicate` for filtering unwanted notifications.
- `BottomBarController` now asserts on double-attach in debug.

Repository:
- Package source moved from `packages/flutter_floating_bottom_bar/` to repo root. The example app moved to `example/`. The `packages/` directory is removed.

## 1.4.0

- Upgrade project/tooling for Flutter `3.41.4` development via FVM.
- Update SDK constraints and refresh dependencies.
- Add `BottomBarController` for programmatic `show`, `hide`, `toggle`, `scrollToStart`, and `scrollToEnd`.
- Add `onVisibilityChanged` callback for visibility state transitions.
- Add `scrollDeltaThreshold` to reduce flicker from minor scroll movement.
- Add `iconSemanticLabel` and `iconTooltip` for better accessibility.
- Improve internal scroll/visibility handling and test coverage.

## 1.3.0

- Added `respectSafeArea` property to control whether the BottomBar should respect the SafeArea
- Removed deprecated `alignment` property (use `barAlignment` instead)
- Fixed ScrollController issues with multiple attachments
- Improved scroll listener management for better performance

## 1.2.1+1

- Fix code formatting

## 1.2.1

- Update to Flutter v3.22.1
- Fix divider error in example
- Update dependencies

## 1.2.0

- Add `offset`, `barAlignment`, `barDecoration`, `iconDecoration` properties.
- Remove `bottom` property.
- Deperecated `alignment` property, use `barAlignment` instead. `alignment` will be removed in a future release.
- Update all code examples, and fix errors.

## 1.1.0

- Add clip property to support clip behavior.
- Add an example for bar with a FAB.

## 1.0.1

- Support for Flutter 3.10.5
- Update dependencies

## 1.0.0+1

- Add documentation

## 1.0.0

- Initial release with basic functionality
