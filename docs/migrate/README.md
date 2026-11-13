# Migration guides

Each guide moves one bottom bar to `flutter_floating_bottom_bar`. It shows the
code before and after, maps every property, and lists what behaves
differently.

| From | Guide | Live demo |
| --- | --- | --- |
| Flutter `BottomNavigationBar` | [bottom-navigation-bar.md](bottom-navigation-bar.md) | [item-theme](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/item-theme) |
| Flutter `NavigationBar` (Material 3) | [navigation-bar.md](navigation-bar.md) | [indicators](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/indicators) |
| `google_nav_bar` | [google-nav-bar.md](google-nav-bar.md) | [indicators](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/indicators) |
| `convex_bottom_bar` | [convex-bottom-bar.md](convex-bottom-bar.md) | [center-action](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/center-action) |
| `salomon_bottom_bar` | [salomon-bottom-bar.md](salomon-bottom-bar.md) | [item-theme](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/item-theme) |
| `persistent_bottom_nav_bar_v2` | [persistent-bottom-nav-bar-v2.md](persistent-bottom-nav-bar-v2.md) | [go-router-shell](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/go-router-shell) |
| `animated_bottom_navigation_bar` | [animated-bottom-navigation-bar.md](animated-bottom-navigation-bar.md) | [center-action](https://codenameakshay.github.io/flutter-floating-bottom-bar/#/center-action) |

## Before you start

- Add the package with `flutter pub add flutter_floating_bottom_bar`.
- Since 3.0.0 the package uses `package:material_ui/material_ui.dart` for
  Material. The after snippets import it in place of
  `package:flutter/material.dart`. See the
  [3.0.0 notes](../../CHANGELOG.md#300).
- Every after snippet is a file in
  [`example/lib/migrate`](../../example/lib/migrate) that compiles and runs in
  the example app's tests.
- APIs marked "since 3.1.0" are on `main` and not yet on pub.dev. The latest
  published version is 3.0.1.

## The common steps

1. Put a `BottomBar` in `Scaffold.body`. Remove `bottomNavigationBar`.
2. Put your pages in `BottomBar.body`, wrapped in `BottomBarBodyPadding`.
3. Put a `BottomBarItems` row of `BottomBarItem`s in `BottomBar.child`.
4. Remove the old package with `flutter pub remove <package>`.

The bar hides when the body scrolls down and shows when it scrolls up. Set
`scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false)` to keep
it on screen.

For a bar this list does not cover, such as `BottomAppBar` or a hand-rolled
`Container`, see the
[replacing bars notes](../../.claude/skills/flutter-floating-bottom-bar/references/replacing-bars.md).
