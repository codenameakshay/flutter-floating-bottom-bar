<h1 align="center">Floating Bottom Bar</h1>

<p align="center">A Flutter package for building floating bottom widgets (tab bars, action bars, custom containers) that react to scroll direction.</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_floating_bottom_bar">
    <img src="https://img.shields.io/pub/v/flutter_floating_bottom_bar.svg" alt="Pub Version" />
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform" />
  </a>
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/github/license/codenameakshay/flutter-floating-bottom-bar?color=red" alt="License" />
  </a>
</p>

| ![A floating tab bar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/1.gif) | ![A floating search bar](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/2.gif) | ![A basic example](https://raw.githubusercontent.com/codenameakshay/flutter-floating-bottom-bar/main/screenshots/3.gif) |
| --- | --- | --- |
| **A floating tab bar** | **A floating search bar** | **A basic example** |

| ![A floating tab bar with FAB](https://user-images.githubusercontent.com/60510869/183573165-28e6b896-6559-4d86-897a-3bc8b0adb927.png) |
| --- |
| **A floating tab bar with a FAB** |

## Features

- Floating bottom widget that shows/hides based on scroll direction.
- Optional back-to-top icon.
- Full customization of alignment, shape, animation, color, and decoration.
- Optional imperative control via `BottomBarController`.
- Optional visibility events via `onVisibilityChanged`.
- Backward-compatible defaults (existing UIs do not need changes).

## Installation

```yaml
dependencies:
  flutter_floating_bottom_bar: ^1.4.0
```

## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

BottomBar(
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'This is the floating widget',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white),
    ),
  ),
  body: (context, controller) => ListView.builder(
    controller: controller,
    itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
  ),
)
```

## Programmatic Control (New in `1.4.0`)

```dart
final bottomBarController = BottomBarController();

BottomBar(
  controller: bottomBarController,
  onVisibilityChanged: (isVisible) {
    debugPrint('Bottom bar visible: $isVisible');
  },
  scrollDeltaThreshold: 8,
  iconTooltip: 'Scroll to top',
  child: const SizedBox(height: 56, child: Center(child: Text('Bottom Bar'))),
  body: (context, scrollController) => ListView.builder(
    controller: scrollController,
    itemBuilder: (context, index) => ListTile(title: Text('Row $index')),
  ),
);

// Later:
bottomBarController.hide();
bottomBarController.show();
bottomBarController.toggle();
await bottomBarController.scrollToStart();
await bottomBarController.scrollToEnd();
```

## Key Properties

- `body` and `child` (required)
- `controller` (optional): imperative show/hide/scroll control
- `onVisibilityChanged` (optional): listen to visible/hidden changes
- `scrollDeltaThreshold` (optional): ignore tiny scroll deltas to reduce flicker
- `iconSemanticLabel` and `iconTooltip` (optional): accessibility hooks for icon action
- Existing properties remain available: `barColor`, `barDecoration`, `iconDecoration`, `duration`, `curve`, `width`, `offset`, `barAlignment`, `showIcon`, `reverse`, `scrollOpposite`, `hideOnScroll`, `respectSafeArea`, `fit`, and `clip`

## Compatibility

- Developed and tested with Flutter `3.41.4` (via FVM).
- Package constraints remain broad to support compatible Flutter 3.x projects.

## Example

See [example/example.md](example/example.md) and the repository demo app for full UI samples.

## Issues and Contributions

- Bugs/feature requests: <https://github.com/codenameakshay/flutter-floating-bottom-bar/issues>
- Contributions: see [CONTRIBUTING.md](https://github.com/codenameakshay/flutter-floating-bottom-bar/blob/main/CONTRIBUTING.md)
