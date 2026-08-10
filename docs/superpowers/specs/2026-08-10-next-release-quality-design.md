# Floating Bottom Bar Next-Release Quality Design

## Status

Approved for implementation on 2026-08-10. This design records the complete
scope accepted when the maintainer asked to fix every vetted audit issue and
ship the grounded next-release improvements without stopping for intermediate
approval.

## Goal

Make the package release-ready by repairing correctness, interaction,
accessibility, packaging, verification, and documentation defects; then add
small, opt-in APIs for body clearance, adaptive width, and scroll settling.

## Constraints

- Do not add dependencies.
- Do not add compatibility shims or migrations.
- Preserve existing behavior unless the audit proved it incorrect or
  misleading.
- Keep new capabilities opt-in and composable with arbitrary `BottomBar.body`
  and `BottomBar.child` widgets.
- Every behavior change starts with a regression test that fails for the
  expected reason.
- The release archive must exclude development screenshots while the GitHub PR
  still embeds real application screenshots from the branch.

## Approaches considered

### Recommended: focused repairs plus three modular helpers

Repair the existing dispatcher, controller, measurement, transition, and item
boundaries in place. Extract only the units that gain a clear responsibility:
size observation, back-to-boundary action presentation, and body clearance.
Add adaptive width as a named `BottomBarLayout.adaptive` constructor and add
settling flags to `BottomBarScrollBehavior`.

This has the smallest public and implementation surface that satisfies every
audit item while leaving `BottomBar` as a host rather than a navigation state
machine.

### Rejected: replace `BottomBar` with a new navigation component

A destination/index API would duplicate Flutter's existing navigation widgets,
exclude search/prompt/custom children, and contradict the package's host-anything
intent.

### Rejected: rewrite scroll handling around an owned `ScrollController`

This would undo the v2 notification-based design and would no longer support
arbitrary descendant controllers without wiring.

## Correctness design

### Notification ownership and accumulation

Only notifications from the `body` subtree may reach the dispatcher. The
dispatcher tracks an anchor offset plus accumulated directional distance per
scrollable. Sub-threshold samples accumulate; reversing direction resets the
anchor. A decision resets the accumulated distance so high-refresh devices and
slow drags behave consistently.

`showAtStart` forces the bar visible at `minScrollExtent` and
`showOnScrollEnd` forces it visible on `ScrollEndNotification`. Both default to
false.

### Scroll boundary selection

The most recently active `ScrollPosition` remains the default target. The
`NestedScrollView` special case is used only when that position belongs to its
coordinated inner or outer controller. Unrelated descendant lists remain the
target that the user actually operated.

### Controller ownership

A controller has one live binding. A second attachment reports a `FlutterError`
and refuses to replace the first binding in release; debug builds retain an
assertion. Visibility updates are accepted only from the owning binding.

### Transition interaction

The bar stops receiving pointer events as soon as its target state becomes
hidden and returns to semantics when showing. Fade and custom transitions
therefore cannot leave an invisible interaction layer over the body or the
back action.

### Layout and measurement

An explicit `BorderRadius.zero` wins over decoration defaults when a widget- or
theme-level layout object was supplied. When no layout override exists, the
decoration radius remains authoritative.

A size-observer render object reports the outer bar footprint, including layout
offset and safe-area padding, whenever layout changes. `BottomBarScope.barHeight`
is updated from this observer rather than unconditional post-frame polling.

## UX and accessibility design

- The back action keeps a fixed minimum 48-by-48 interaction area while its
  visual circle animates independently.
- Default foreground color is `colorScheme.onPrimary`.
- `scrollOpposite` changes the default arrow, tooltip, and semantic intent to
  the bottom/end direction.
- `BackToTopIconBuilder` receives the actual animated visual width and height.
- `BottomBarItem` has a minimum 48-by-48 hit target and explicit selected
  semantics.
- Badge placement uses directional `end`, not physical `right`.
- Hidden content is excluded from pointer interaction and accessibility focus.

Motor 1.1's bounded controller exposes `AnimationBehavior.normal`, but its
custom simulation path does not snap when disabled animations are enabled.
`BottomBar` therefore needs an explicit reduced-motion branch that cancels any
active Motor simulation and sets the target value when platform, semantics, or
`MediaQuery` animation disabling is in effect. This behavior receives a
regression test.

## New APIs

### `BottomBarBodyPadding`

An opt-in widget inside `BottomBar.body` that listens to
`BottomBarScope.barHeight` and adds that value to its bottom padding. It always
reserves the footprint to avoid content jumping as the bar animates. Callers
may supply additional `EdgeInsetsGeometry`.

### `BottomBarLayout.adaptive`

A const named constructor that uses `double.infinity` width with a configurable
`maxWidth` and the existing offset/safe-area behavior. The regular constructor
gains an optional `maxWidth`. The rendered bar is constrained to the smaller of
the host width and `maxWidth`.

### Scroll settling

`BottomBarScrollBehavior` gains `showAtStart` and `showOnScrollEnd`, both false
by default and included in `copyWith`, equality, hashing, documentation, and
tests.

## Performance and module boundaries

The size observer replaces repeated `GlobalKey` render-object lookups and
post-frame callbacks. The back action separates its static semantics/tooltip/
material shell from frame-dependent opacity and scale, avoiding repeated
reconstruction and layout of the entire action subtree.

`bottom_bar.dart` remains the composition root. Size observation and body
padding live in focused files; nested-scroll targeting may move to an internal
coordinator if extraction reduces the main state without creating indirection.

## Tooling, packaging, and documentation

- `format-check` uses `dart format --output=none --set-exit-if-changed`.
- The example smoke test opens every registered demo.
- The example lockfile is refreshed.
- GitHub Actions pins the repository's Flutter version and runs format,
  analysis, package tests, example tests, accessibility tests, and publish dry
  run.
- `.pubignore` excludes screenshots and other development-only files; publish
  validation records a materially smaller archive.
- README, examples, public Dartdoc, changelog, and contributing guidance are
  synchronized with the implementation.
- `motor` remains an intentional public contract.

## Verification

Required gates:

1. Every regression test is observed failing before its implementation.
2. `make check` exits zero without modifying tracked files.
3. Accessibility guideline tests pass for Android and iOS tap targets, labels,
   selected semantics, RTL, and large text.
4. `flutter pub publish --dry-run` exits zero and excludes `screenshots/`.
5. The example web app runs, browser console is clean, and screenshots are
   captured at mobile and desktop widths.
6. Visual verdict score is at least 90 against the existing demo references.
7. A final independent code review has no unresolved critical or important
   findings.
8. The PR description embeds the committed screenshots and reports exact
   verification evidence.
