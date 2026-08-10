# Floating Bottom Bar Next-Release Quality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair every vetted audit issue, add the approved body-clearance, adaptive-layout, and scroll-settling APIs, then publish a fully verified screenshot-backed pull request.

**Architecture:** Keep `BottomBar` as the composition root while extracting layout-driven size observation and reusable body padding. Make scroll behavior deterministic inside `ScrollNotificationDispatcher`, keep controller ownership explicit, and make visibility transitions control interaction as well as paint.

**Tech Stack:** Dart 3.5+, Flutter 3.22+, Motor 1.1, `flutter_test`, FVM, GitHub Actions.

---

### Task 1: Restore trustworthy verification and release hygiene

**Files:**
- Modify: `Makefile`
- Modify: `example/test/widget_test.dart`
- Modify: `example/pubspec.lock`
- Modify: `.pubignore`
- Create: `.github/workflows/ci.yml`
- Modify: `.fvmrc`

- [ ] Write/adjust checks so the example test demonstrates the current failure and route coverage requirement.
- [ ] Run `cd example && fvm flutter test` and record the expected obsolete-label failure.
- [ ] Update the smoke test to assert current labels and open every demo route.
- [ ] Change `format-check` to `$(DART) format --output=none --set-exit-if-changed .`.
- [ ] Pin the current Flutter SDK in `.fvmrc` and use it in CI.
- [ ] Exclude `screenshots/`, `.omx/`, and internal skill artifacts from publication.
- [ ] Refresh the example lockfile with `cd example && fvm flutter pub get`.
- [ ] Add CI jobs for format, analyze, package/example tests, and publish dry run.
- [ ] Verify the example test passes and publish dry-run contents omit screenshots.

### Task 2: Make scroll decisions deterministic and body-owned

**Files:**
- Modify: `lib/src/internal/scroll_notification_dispatcher.dart`
- Modify: `lib/src/config/bottom_bar_scroll_behavior.dart`
- Modify: `lib/src/bottom_bar.dart`
- Modify: `test/scroll_notification_dispatcher_test.dart`
- Modify: `test/floating_bar_test.dart`
- Modify: `test/bottom_bar_scroll_behavior_test.dart`

- [ ] Add failing tests for accumulated 1–3 px deltas, direction reversal, `showAtStart`, and `showOnScrollEnd`.
- [ ] Add a failing widget test proving a vertical scrollable in `BottomBar.child` must not affect visibility or active target.
- [ ] Implement per-scrollable accumulated directional state and the two opt-in settling flags.
- [ ] Move the notification listener so only `body` notifications reach the dispatcher.
- [ ] Run the focused dispatcher and widget tests until green.

### Task 3: Repair controller and nested-scroll ownership

**Files:**
- Modify: `lib/src/bottom_bar_controller.dart`
- Modify: `lib/src/bottom_bar.dart`
- Modify: `test/bottom_bar_controller_test.dart`
- Modify: `test/floating_bar_test.dart`

- [ ] Add a failing release-behavior unit/widget test for double attachment that proves the first binding remains authoritative.
- [ ] Add a failing test with an unrelated descendant list inside `NestedScrollView` and assert that list remains the boundary target.
- [ ] Enforce binding ownership at runtime and ignore visibility updates from non-owners.
- [ ] Restrict the `NestedScrollView` coordinator path to positions attached to its inner/outer controllers.
- [ ] Run focused controller and nested-scroll tests until green.

### Task 4: Replace polling measurement and add body clearance

**Files:**
- Create: `lib/src/internal/size_observer.dart`
- Create: `lib/src/widgets/bottom_bar_body_padding.dart`
- Modify: `lib/src/bottom_bar.dart`
- Modify: `lib/flutter_floating_bottom_bar.dart`
- Modify: `test/bottom_bar_scope_test.dart`
- Create: `test/bottom_bar_body_padding_test.dart`

- [ ] Add failing tests for offset/safe-area-inclusive height and a child that changes height without rebuilding `BottomBar`.
- [ ] Add a failing public-API test showing `BottomBarBodyPadding` reserves the reported footprint plus caller padding.
- [ ] Implement a deduplicated layout-driven size observer and remove `GlobalKey`/post-frame polling.
- [ ] Implement and export `BottomBarBodyPadding`.
- [ ] Run scope/body-padding tests until green.

### Task 5: Fix adaptive layout and explicit square corners

**Files:**
- Modify: `lib/src/config/bottom_bar_layout.dart`
- Modify: `lib/src/bottom_bar.dart`
- Modify: `test/bottom_bar_layout_test.dart`
- Modify: `example/lib/demos/*.dart`

- [ ] Add failing tests for an explicit `BorderRadius.zero`, adaptive width on narrow screens, and max-width capping on wide screens.
- [ ] Add `maxWidth` and `BottomBarLayout.adaptive`, including copy/equality/hash behavior.
- [ ] Resolve radius based on whether a layout override exists, not whether its value is zero.
- [ ] Migrate responsive demos from manual `MediaQuery` arithmetic to the adaptive constructor.
- [ ] Run layout and example tests until green.

### Task 6: Make actions and items accessible, directional, and cheap to animate

**Files:**
- Modify: `lib/src/bottom_bar.dart`
- Modify: `lib/src/internal/visibility_animator.dart`
- Modify: `lib/src/widgets/bottom_bar_item.dart`
- Modify: `test/floating_bar_test.dart`
- Modify: `test/bottom_bar_items_test.dart`
- Modify: `test/bottom_bar_motion_test.dart`
- Create: `test/accessibility_test.dart`

- [ ] Add failing tests for hidden fade/custom hit testing, actual custom-icon dimensions, direction-aware end action, `onPrimary` foreground, 48 px targets, selected semantics, and RTL badge placement.
- [ ] Add failing Android/iOS tap-target, label, and contrast guideline tests.
- [ ] Wrap hidden bar content with pointer and semantics exclusion.
- [ ] Keep a fixed accessible action target while animating only its visual circle; hoist static subtrees where possible.
- [ ] Add selected semantics and directional badge layout to `BottomBarItem`.
- [ ] Add a reduced-motion regression test proving Motor/Flutter honors disabled animations without a package-specific branch.
- [ ] Run focused motion/item/accessibility tests until green.

### Task 7: Synchronize public documentation and release notes

**Files:**
- Modify: `README.md`
- Modify: `EXAMPLES.md`
- Modify: `CONTRIBUTING.md`
- Modify: `CHANGELOG.md`
- Modify: public Dartdoc under `lib/`

- [ ] Document the corrected interaction, measurement, scroll, adaptive-layout, and body-padding behavior.
- [ ] Remove stale patch-version prose and obsolete contributor guidance.
- [ ] Correct `scrollToStart`/`scrollToEnd` Dartdoc so controller boundaries remain absolute.
- [ ] Add an unreleased changelog section covering fixes, improvements, and new APIs.
- [ ] Run analyzer and documentation/example compile checks.

### Task 8: Integrate, profile, visually verify, and publish

**Files:**
- Create: `screenshots/next-release/*.png`
- Create/update: `.omx/state/next-release/ralph-progress.json`

- [ ] Run `make check` from a clean tracked diff and confirm it does not modify files.
- [ ] Run `fvm flutter pub publish --dry-run`, inspect the file list, and record archive size.
- [ ] Run the example as a web server and inspect console/runtime diagnostics in the T3 collaborative preview.
- [ ] Capture mobile and desktop screenshots of representative demos.
- [ ] Compare captures against existing references with `$visual-verdict`; persist JSON and iterate until score is at least 90.
- [ ] Run a final independent spec review and code-quality review; resolve every critical/important finding.
- [ ] Stage only intended files, commit with Lore trailers, push the branch, and open a ready-for-review PR.
- [ ] Embed stable raw screenshot URLs based on the pushed commit SHA in the PR description.
