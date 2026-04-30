---
name: flutter-floating-bottom-bar
description: Integrate, replace, or migrate to the `flutter_floating_bottom_bar` Flutter package — a floating widget host that sits above scrollable content and reacts to scroll events. Use this skill whenever the user mentions floating bottom bars, hide-on-scroll bars, replacing `BottomNavigationBar` / `NavigationBar` / `BottomAppBar`, swapping out third-party nav-bar packages (salomon, google_nav_bar, convex, persistent_bottom_nav_bar), migrating from `flutter_floating_bottom_bar` v1.x → v2.x, or fixing glitches with the package (jumpy springs, content clipped behind the bar, NestedScrollView not triggering hide, custom transition overshoot, FAB notch issues, double-attached controllers). Trigger even when the user does not say "flutter_floating_bottom_bar" by name — phrases like "I want a floating tab bar", "make my bottom bar hide on scroll", "iOS-style spring bottom navigation", or pasting a `BottomNavigationBar` and asking to "make it nicer" all qualify.
---

# flutter_floating_bottom_bar integration & migration

`flutter_floating_bottom_bar` (v2.x) is a Flutter package that floats any widget — `TabBar`, search bar, custom `Row`, `BottomBarItems` — above scrollable content and reacts to scroll notifications automatically. No `ScrollController` plumbing required.

You're being invoked because the user wants to **integrate it into their app**, **replace an existing bottom bar**, **migrate from v1.x → v2.0**, **dial in motion that feels great**, or **fix a glitch**. Your job is to do the work end-to-end: read what they have, plan the change, apply it, and verify it analyses cleanly. Don't ask the user to write the code themselves — that's what they invoked you for.

## Why this skill is opinionated

Flutter motion is a deep rabbit hole — `Curves`, `Tween`, `AnimationController`, springs, custom transitions. Most developers don't have time to A/B test 12 motion configurations to discover that Cupertino-style springs feel right because they redirect mid-flight when the user reverses scroll direction. So this skill:

1. **Picks a sensible default** based on signals it reads from the user's existing app (Material 3 vs 2, `useMaterial3`, existing animation curves, app theme).
2. **Surfaces the alternatives** so the user can redirect ("I went with `BottomBarMotion.cupertino(preset: snappy)` because your app uses Material 3 — switch to `bouncy` or `BottomBarMotion.curved(...)` if you'd prefer something more playful or deterministic").
3. **Refuses to guess** when the signals aren't there. If the user has no theme, no existing nav bar, and pastes a one-line "add a bottom bar" prompt, ask a single clarifying question rather than hallucinating their app's vibe.

This is the right tradeoff because (a) most users will accept a good default, (b) the ones who care will tell you, and (c) silently picking everything is worse than picking-and-disclosing.

## Workflow

Follow this sequence. Don't skip the discover step — applying a transformation without reading the user's existing code leads to broken imports, mismatched `_currentIndex` state, and Material 2/3 style drift.

### 1. Discover

Read what's actually in the user's project before touching anything.

- **`pubspec.yaml`** — confirm `flutter_floating_bottom_bar` is (or isn't) listed; note any existing version. Also check Dart/Flutter SDK constraints — the package needs Dart `>=3.5.0` and Flutter `>=3.22.0`.
- **The file containing the bar they want to replace** — this is the load-bearing input. Identify the source pattern:
  - `BottomNavigationBar` (Material 2)
  - `NavigationBar` (Material 3)
  - `BottomAppBar` (often with FAB notch via `Scaffold.floatingActionButton` + `notchedShape`)
  - Hand-rolled `Container` + `Row` of icons / `GestureDetector`s
  - Third-party packages — `salomon_bottom_bar`, `google_nav_bar`, `convex_bottom_bar`, `persistent_bottom_nav_bar`, etc.
  - `flutter_floating_bottom_bar` v1.x (look for `body: (context, controller) => ...`, `barColor:`, flat `width`/`offset`/`borderRadius` params, `BottomBarScrollControllerProvider`, etc.)
- **The page that hosts the bar** — find the scrollable (`ListView`, `CustomScrollView`, `NestedScrollView`, `TabBarView`, `PageView`+inner scrollables). The new `BottomBar` will wrap this scrollable as its `body`.
- **Theme signals** — `MaterialApp.theme`, `useMaterial3`, custom `ThemeData`. These drive your motion + theme choice.

If the user pasted a snippet rather than pointing at a file, work from the snippet — but mention what you'd want to see (their `pubspec.yaml`, the surrounding scaffold) if it would change the answer.

### 2. Plan

State the plan in one short paragraph before editing. The plan should name:
- **Which file(s)** you're touching.
- **Source pattern** (e.g. "`BottomNavigationBar` with 4 items").
- **Motion default you're picking and why** (e.g. "Cupertino `snappy` spring + `slide` transition because the app uses Material 3 and your existing curves are `Curves.easeOutCubic`").
- **Layout default** (typical: `width: MediaQuery.of(context).size.width - 32` for full-width-with-margin, `borderRadius: 28` for Material 3 feel, `borderRadius: 999` for pill).
- **Anything you're deliberately not doing** (e.g. "I'm not adding a controller because you're not currently calling `.show()`/`.hide()` programmatically — pass one in if you need imperative control").

Keep it short. Don't write a design document; the user wants the change applied.

### 3. Implement

Apply the transformation. Stick to these principles:

- **Match the user's existing style.** If they're on Material 3, use Material 3 colors and the `28` radius idiom. If their nav items use `Icons.home_outlined` for unselected and `Icons.home` for selected, mirror that into `BottomBarItem.icon` / `selectedIcon`.
- **Preserve their state management.** If they had `int _currentIndex` and `setState`, keep that. If they had Riverpod / Bloc / Provider, route the selection through the same channel — don't accidentally rewrite their state layer.
- **Use the helper widgets when it fits.** `BottomBarItem` + `BottomBarItems` cover the icon + label + badge + tap pattern well. Don't reach for them when the user has a `TabBar`, search field, or anything more custom — pass the raw widget as `child` instead.
- **Wrap, don't move.** The new `BottomBar` wraps the user's scrollable as its `body`. Don't push the scrollable into a new file or restructure the widget tree more than necessary.
- **Add the import.** `import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';` at the top of the file. Update `pubspec.yaml` (`flutter pub add flutter_floating_bottom_bar` or a `^2.0.0` line) if the package isn't already a dependency.
- **For migrations**, follow the v1→v2 mapping in [references/migration-v1-to-v2.md](references/migration-v1-to-v2.md) precisely. Don't half-migrate (mixing v1 `barColor` with v2 `BottomBarThemeData`).

### 4. Verify

After editing, **run `flutter analyze`** in the user's project root. Report any errors and fix them. Common post-edit issues:
- Stale imports (`import 'package:salomon_bottom_bar/...'` left behind after replacement).
- Stale state fields (`_selectedIndex` referenced but no longer set).
- Layout overflow if the user's content padding doesn't account for the bar's height (see [references/common-glitches.md](references/common-glitches.md), "content clipped behind bar").

Don't claim the work is done until `flutter analyze` exits cleanly. If the user's environment doesn't have Flutter on PATH or the project doesn't analyze for unrelated reasons, say so explicitly rather than silently skipping.

## Decision tree — which reference to consult

Reference files live alongside this `SKILL.md` under `references/`. Read them only when the scenario calls for them; otherwise the body above plus the API reference is enough.

| Scenario | Reference |
|---|---|
| Need full API surface (every parameter on `BottomBar`, `BottomBarLayout`, `BottomBarMotion`, etc.) | [references/api-reference.md](references/api-reference.md) |
| Replacing any existing bar (Material `BottomNavigationBar`/`NavigationBar`/`BottomAppBar`, hand-rolled, third-party) | [references/replacing-bars.md](references/replacing-bars.md) |
| Migrating from v1.x to v2.0 | [references/migration-v1-to-v2.md](references/migration-v1-to-v2.md) |
| Picking motion (Cupertino preset, curved, raw Motor) and transition (slide/fade/scale/slideAndFade/custom) | [references/motion-recipes.md](references/motion-recipes.md) |
| Debugging glitches (NestedScrollView, content clipping, FAB notch, custom transition overshoot, controller errors) | [references/common-glitches.md](references/common-glitches.md) |

## Defaults this skill prefers

When the user hasn't expressed a preference, lean toward these defaults — they're chosen because they look good in the broadest range of apps and avoid the package's known footguns.

| Decision | Default | Why |
|---|---|---|
| Motion mode | `BottomBarMotion.cupertino(preset: BottomBarCupertinoMotion.snappy)` | Spring redirects mid-flight when the user reverses scroll direction; `snappy` is the most app-like preset (less bouncy than `bouncy`, less floaty than `smooth`). |
| Transition | `BottomBarTransition.slide` (default) | Matches user expectation of a bar moving offscreen. `fade` and `scale` are good for FAB-like elements; `slideAndFade` for showy transitions. |
| Layout width | `MediaQuery.of(context).size.width - 32` | Full-width with 16px margin each side. Use `300` only when the bar is intentionally narrow. |
| Border radius | `BorderRadius.circular(28)` for Material 3, `999` for pill, `0` only when explicitly square | Matches Material 3 expressive shape; pill works great when the bar is short. |
| `hideOnScroll` | `true` (the default) | The whole point of the package. Disable only when the user is using `BottomBar` purely as a floating container without scroll reactivity. |
| `respectSafeArea` | `true` (the default) | Avoids the iOS home indicator. Don't disable unless the user has their own `SafeArea` wrapping. |

When you choose a non-default value, **say why in your plan**. Example: "I went with `borderRadius: 999` (pill) because your existing tab pills use that radius."

## Output format

Lead with a one-line summary of what changed. Then either:

- **A diff/edit** if you're modifying their code in-place. Use the `Edit` tool, not full-file rewrites.
- **A complete file** if they pasted a self-contained snippet and asked for a return.

After the code, add a short **"Notes"** block calling out:
- Anything non-obvious you did (e.g. "I added `predicate:` to filter out the SliverAppBar's own scroll notifications").
- Suggested follow-ups they didn't ask for but should know about (e.g. "Consider calling `BottomBarScope.of(context).barHeight` to size your bottom padding so the last list item isn't clipped").

Don't pad with explanations they didn't ask for. The user wants the change to land.

## Things that look like they're worth doing but aren't

- **Don't** wrap `BottomBar` in another `BottomBar`. Just use one.
- **Don't** pass a `ScrollController` to `BottomBar` itself — v2 doesn't accept one. The bar listens to `ScrollNotification` from any descendant scrollable.
- **Don't** keep v1 `barColor` alongside v2 `theme:` / `BottomBarThemeData`. v1 fields are gone in v2 with no shim.
- **Don't** call `setState` inside `onVisibilityChanged` to drive the bar's visibility — that creates a feedback loop. Use a `BottomBarController` if you need imperative control.
- **Don't** reach for `BottomBarMotion.motor(...)` unless the user explicitly wants a Motor motion the four built-in modes don't cover. Cupertino + curved cover ~95% of cases.
- **Don't** invent parameters that don't exist. The API reference is the source of truth — if a field isn't there, it isn't a thing.

## Quick reference: the smallest useful integration

```dart
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(28),
        ),
        // Default motion is already Cupertino snappy — this is here just to
        // show the knob exists. Remove for the real default.
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: const Text('Home'),
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              BottomBarItem(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search),
                label: const Text('Search'),
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              BottomBarItem(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: const Text('Profile'),
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

That's the canonical shape. Most replacements / migrations end up looking like a variation of this.
