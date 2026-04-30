# Common glitches and how to fix them

A debugging guide for the package's known footguns. Read this when the user says "the bar is glitchy", "doesn't hide", "jumps", or pastes broken-looking code.

## Bar doesn't hide on scroll

**Symptoms:** scrolling does nothing, bar stays visible.

**Likely causes (most → least common):**

1. **The scrollable isn't a descendant of `BottomBar.body`.** The bar listens to `ScrollNotification` from the subtree of `body`. If the user has the scrollable elsewhere (e.g. as a sibling in a `Column`), the bar can't see it.

   **Fix:** wrap the scrollable in `BottomBar.body`, or restructure so it's inside the subtree.

2. **The scrollable can't scroll** (content fits on screen). No scroll → no notifications.

   **Fix:** make sure the user has enough content to scroll. Or remove `hideOnScroll` if they never wanted it.

3. **`hideOnScroll: false`** on `BottomBarScrollBehavior`.

   **Fix:** remove it (or set `hideOnScroll: true`).

4. **`predicate` returns `false` for the relevant notification.**

   **Fix:** check `predicate` logic. Try removing it temporarily to confirm.

## Bar twitches / oscillates on slow scrolls

**Symptoms:** bar rapidly shows/hides on small scroll movements (e.g. a trackpad fine-scroll, or an over-eager `ScrollPhysics`).

**Cause:** `deltaThreshold` too low.

**Fix:** bump `BottomBarScrollBehavior.deltaThreshold` from default `8` to `16` or `24`:

```dart
const BottomBarScrollBehavior(deltaThreshold: 16)
```

## NestedScrollView: bar doesn't hide, or hides at the wrong time

**Symptoms:** with `NestedScrollView`, the bar reacts to outer header scroll instead of inner content scroll, or vice versa.

**Cause:** `NestedScrollView` emits notifications from both its outer header and its inner scrollables. The dispatcher sees both.

**Fix 1 — let the package handle it:** the default `BottomBarScrollBehavior` works fine for most `NestedScrollView` setups. Try without `predicate` first.

**Fix 2 — disambiguate with `predicate`:**

```dart
BottomBar(
  scrollBehavior: BottomBarScrollBehavior(
    predicate: (n) {
      // Only respond to the inner scrollable (depth > 0).
      return n.depth > 0;
    },
  ),
  body: NestedScrollView(...),
  child: ...,
);
```

Or filter to only the outer:
```dart
predicate: (n) => n.depth == 0,
```

`ScrollNotification.depth` is `0` for the outermost scrollable in the notification dispatch and increments inward.

## Content clipped behind the bar

**Symptoms:** last list item is hidden behind the bar; user has to scroll past it.

**Cause:** scrollable's content padding doesn't account for the bar's height.

**Fix 1 — static padding (simplest):** add bottom padding to the scrollable equal to roughly bar-height + offset (e.g. `96` for default sizing):

```dart
ListView.builder(
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
  ...
)
```

**Fix 2 — dynamic spacer using `BottomBarScope`:** picks up the actual rendered height.

```dart
ListView(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  children: [
    ...children,
    ValueListenableBuilder<double>(
      valueListenable: BottomBarScope.of(context).barHeight,
      builder: (context, height, _) => SizedBox(height: height + 24),
    ),
  ],
)
```

This is more accurate but slightly more code. Use it when the bar's height varies (e.g. dynamic content inside the bar's child).

## FAB is clipped at the top

**Symptoms:** a FAB positioned with `Positioned(top: -24)` to overhang the bar gets cut off.

**Cause:** `Stack` clips by default.

**Fix:** set `BottomBarLayout.clip: Clip.none`.

```dart
BottomBar(
  layout: BottomBarLayout(
    fit: StackFit.expand,
    clip: Clip.none, // critical
    ...
  ),
  ...
)
```

## Custom transition flickers / inverts / scales weirdly

**Symptoms:** with `BottomBarMotion(...).cupertino(...)` + `transitionBuilder`, the bar briefly inverts, flickers, or scales beyond `1`.

**Cause:** Cupertino springs overshoot. `anim.value` can briefly be `1.05` or `-0.02`. Unclamped values into `Opacity` (out of `0..1`), `Transform.scale` (negative scale flips the widget), or `SizedBox` (negative sizes throw) cause artifacts.

**Fix:** clamp inside the builder:

```dart
transitionBuilder: (context, anim, child) {
  final v = anim.value.clamp(0.0, 1.0);
  return Opacity(opacity: v, child: Transform.scale(scale: v, child: child));
}
```

This clamp is mentioned multiple times across the docs because it's the #1 source of custom-transition bugs.

## "Controller is already attached to a BottomBar"

**Symptoms:** debug-mode assertion when navigating between two pages that both use the same `BottomBarController`.

**Cause:** a `BottomBarController` cannot be attached to two `BottomBar`s simultaneously. The package asserts this in debug.

**Fix 1 — use one controller per `BottomBar`.** Don't share a global controller across pages.

**Fix 2 — if both pages need the same controller**, dispose / detach before navigating. The simplest pattern is one controller per `State`:

```dart
class _MyPageState extends State<MyPage> {
  final _barController = BottomBarController();

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }
  ...
}
```

## Bar height is `0` on first frame

**Symptoms:** `BottomBarScope.of(context).barHeight.value` is `0` initially.

**Cause:** the bar hasn't been laid out yet — the height is measured in a post-frame callback.

**Fix:** use `ValueListenableBuilder` so your widget rebuilds when the height updates:

```dart
ValueListenableBuilder<double>(
  valueListenable: BottomBarScope.of(context).barHeight,
  builder: (context, height, _) => SizedBox(height: height),
)
```

Don't read `.value` directly in `build` and expect a real number on first frame.

## "scrollToStart called before any scroll notification was observed"

**Symptoms:** `controller.scrollToStart()` (or `.scrollToEnd()`) prints a `FlutterError` and does nothing.

**Cause:** the dispatcher hasn't seen a single `ScrollNotification` yet — usually because the user hasn't scrolled at all. The bar can't scroll a scrollable it doesn't know about.

**Fix:** if you legitimately need to scroll programmatically before any user interaction, pass a `ScrollController` directly to the scrollable and call `.animateTo` on it yourself. Don't rely on `BottomBarController.scrollToStart` as the *only* way to scroll.

## v1 leftovers in v2 code

**Symptoms:** "The named parameter 'barColor' isn't defined", "The argument type '(BuildContext, ScrollController) => Widget' can't be assigned to 'Widget'", etc.

**Cause:** partial migration from v1.

**Fix:** see [migration-v1-to-v2.md](migration-v1-to-v2.md) for the full mapping. Common ones:

- `barColor: Colors.white` → `theme: BottomBarThemeData(barDecoration: BoxDecoration(color: Colors.white))`
- `body: (ctx, controller) => ListView(...)` → `body: ListView(...)`  (drop the builder; v2 listens to notifications)
- `start: 2, end: 0` → `slideStart: Offset(0, 2), slideEnd: Offset.zero`
- `scrollDeltaThreshold: 12` → `scrollBehavior: BottomBarScrollBehavior(deltaThreshold: 12)`

## `setState` inside `onVisibilityChanged` causing rebuild loops

**Symptoms:** infinite loop / "setState called during build".

**Cause:** the user is using `onVisibilityChanged` to mirror visibility into local state, then using that state to drive the bar's visibility. Feedback loop.

**Fix:** if you need to *react* to visibility changes (e.g. for analytics, coordinating other UI), `setState` is fine — but don't loop the value back into the bar. If you need imperative control over visibility, use `BottomBarController.show()` / `.hide()` directly; don't drive it through state + `onVisibilityChanged`.

```dart
// OK — analytics ping
onVisibilityChanged: (visible) {
  analytics.log(visible ? 'bar_shown' : 'bar_hidden');
}

// NOT OK — feedback loop
onVisibilityChanged: (visible) {
  setState(() => _hidden = !visible);
}
// ...if _hidden is then used elsewhere to call controller.hide(), you have a loop.
```

## Spring feels wrong after duration change

**Symptoms:** user sets a long `duration:` on a Cupertino motion expecting a slower bar — gets the same speed.

**Cause:** for Cupertino springs, `duration` is an *estimate*, not a hard timing. The actual settle time depends on the physics. Big `duration` doesn't slow the spring — it just changes the "estimated" frame budget for the motor.

**Fix:** if the user wants slower motion deterministically, switch to `BottomBarMotion.curved(duration: ..., curve: ...)`. If they want a "softer" spring, use `BottomBarCupertinoMotion.smooth` (less stiff).

## Two bars on screen, only one reacts

**Symptoms:** layouts with two `BottomBar`s — only one hides on scroll.

**Cause:** notifications bubble up. Both bars *do* see notifications from scrollables in their own subtrees, but if both subtrees share the same scrollable, the inner bar wins (because `NotificationListener` consumes notifications by default — though `BottomBar` itself returns `false` from its listener, so this *shouldn't* happen).

**Fix:** generally don't nest `BottomBar`s. If you genuinely need two, give each its own scrollable. If you need one bar to react to a parent's scroll, that bar must wrap the parent.

## Last item not tappable on iOS even with bottom padding

**Symptoms:** the very last list item or button is tappable in the visible area but not when scrolled near the bottom — it's behind the iOS home indicator.

**Cause:** the bar's `respectSafeArea: true` (default) means the bar floats above the safe-area inset, but the *scrollable* doesn't necessarily account for it.

**Fix:** add the safe-area inset to the scrollable's bottom padding, or wrap content in `SafeArea(top: false)`:

```dart
ListView(
  padding: EdgeInsets.fromLTRB(
    16,
    16,
    16,
    96 + MediaQuery.of(context).viewPadding.bottom,
  ),
  ...
)
```
