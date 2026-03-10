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
