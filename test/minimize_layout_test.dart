import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';

const _labels = ['Home', 'Search', 'Inbox', 'Profile'];

Widget _items({
  int selected = 0,
  Widget? badge,
  ValueChanged<int>? onSelected,
  Key? key,
}) => BottomBarItems(
  key: key,
  selectedIndex: selected,
  onSelected: onSelected ?? (_) {},
  children: [
    for (var i = 0; i < _labels.length; i++)
      BottomBarItem(
        icon: const Icon(Icons.circle_outlined),
        selectedIcon: const Icon(Icons.circle),
        label: Text(_labels[i]),
        badge: i == selected ? badge : null,
      ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  BottomBarController? controller,
  BottomBarMinimizeBehavior minimize = BottomBarMinimizeBehavior.onScrollDown,
  Widget? child,
  Widget? compactChild,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            scrollBehavior: BottomBarScrollBehavior(minimizeBehavior: minimize),
            compactChild: compactChild,
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) =>
                  SizedBox(height: 60, child: Text('Row $i')),
            ),
            child: child ?? _items(),
          ),
        ),
      ),
    ),
  );
}

RenderBarSurface _surface(WidgetTester tester) =>
    tester.renderObject<RenderBarSurface>(find.byType(BarSurface));

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView), Offset(0, dy));
  await tester.pumpAndSettle();
}

Widget _morphHarness(
  double t, {
  TextDirection direction = TextDirection.ltr,
  Widget? full,
}) => Directionality(
  textDirection: direction,
  child: Align(
    alignment: Alignment.topLeft,
    child: BarSurface(
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(32),
      ),
      minimize: AlwaysStoppedAnimation(t),
      child: MinimizeHost(
        progress: AlwaysStoppedAnimation(t),
        minimized: t >= 0.5,
        full: full ?? const SizedBox(width: 300, height: 64),
        compact: const SizedBox.square(dimension: 48),
      ),
    ),
  ),
);

Widget _notchedFull() => const SizedBox(
  width: 300,
  height: 64,
  child: Center(
    child: CenterActionSlot(
      width: 56,
      lifted: true,
      notched: true,
      raise: 16,
      notchMargin: 4,
      child: SizedBox.square(dimension: 56),
    ),
  ),
);

bool focusIn(Type type, {Key? key}) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  var found = false;
  ctx.visitAncestorElements((e) {
    if ((key != null && e.widget.key == key) ||
        (key == null && e.widget.runtimeType == type)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

void main() {
  testWidgets('scrolling down minimizes and scrolling up expands', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller);
    expect(controller.visibility.value, BottomBarVisibility.shown);

    await _scroll(tester, -300);
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(controller.isVisible, isTrue);
    expect(_surface(tester).morph, 1);

    await _scroll(tester, 200);
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(_surface(tester).morph, 0);
  });

  testWidgets('the outline morphs from the bar to the pill', (tester) async {
    await tester.pumpWidget(_morphHarness(0));
    var surface = _surface(tester);
    expect(surface.outlineRect, const Rect.fromLTWH(0, 0, 300, 64));
    expect(
      surface.outline.borderRadius.resolve(TextDirection.ltr),
      BorderRadius.circular(32),
    );

    await tester.pumpWidget(_morphHarness(0.5));
    surface = _surface(tester);
    expect(surface.outlineRect, const Rect.fromLTRB(4, 4, 178, 60));
    expect(
      surface.outline.borderRadius.resolve(TextDirection.ltr),
      BorderRadius.circular(28),
    );

    await tester.pumpWidget(_morphHarness(1));
    surface = _surface(tester);
    expect(surface.outlineRect, const Rect.fromLTWH(8, 8, 48, 48));
    expect(
      surface.outline.borderRadius.resolve(TextDirection.ltr),
      BorderRadius.circular(24),
    );
  });

  testWidgets('the morphed outline mirrors in RTL', (tester) async {
    await tester.pumpWidget(_morphHarness(1, direction: TextDirection.rtl));
    expect(_surface(tester).outlineRect, const Rect.fromLTWH(244, 8, 48, 48));
  });

  testWidgets('the notch shrinks with the outline and stays on the action', (
    tester,
  ) async {
    await tester.pumpWidget(_morphHarness(0, full: _notchedFull()));
    var surface = _surface(tester);
    final bar = surface.outlineRect;
    expect(surface.outline.notch, isNotNull);
    expect(surface.outline.notch!.width, 64);
    final notchCentreBefore = surface.outline.notch!.center + bar.center;

    await tester.pumpWidget(_morphHarness(0.5, full: _notchedFull()));
    surface = _surface(tester);
    final halfPill = tester
        .renderObject<RenderMinimizeHost>(find.byType(MinimizeHost))
        .compactRectIn(surface)!;
    expect(
      surface.outlineRect.left,
      moreOrLessEquals(Rect.lerp(bar, halfPill, 0.5)!.left),
    );
    expect(
      surface.outlineRect.top,
      moreOrLessEquals(Rect.lerp(bar, halfPill, 0.5)!.top),
    );
    expect(
      surface.outlineRect.right,
      moreOrLessEquals(Rect.lerp(bar, halfPill, 0.5)!.right),
    );
    expect(
      surface.outlineRect.bottom,
      moreOrLessEquals(Rect.lerp(bar, halfPill, 0.5)!.bottom),
    );
    expect(surface.outline.notch!.width, closeTo(64 * fullOpacity(0.5), 0.01));
    final notchCentreHalf =
        surface.outline.notch!.center + surface.outlineRect.center;
    expect(notchCentreHalf.dx, closeTo(notchCentreBefore.dx, 0.01));
    expect(notchCentreHalf.dy, closeTo(notchCentreBefore.dy, 0.01));

    await tester.pumpWidget(_morphHarness(1, full: _notchedFull()));
    surface = _surface(tester);
    final pill = tester
        .renderObject<RenderMinimizeHost>(find.byType(MinimizeHost))
        .compactRectIn(surface)!;
    expect(surface.outline.notch, isNull);
    expect(surface.outlineRect.left, moreOrLessEquals(pill.left));
    expect(surface.outlineRect.top, moreOrLessEquals(pill.top));
    expect(surface.outlineRect.right, moreOrLessEquals(pill.right));
    expect(surface.outlineRect.bottom, moreOrLessEquals(pill.bottom));
  });

  testWidgets('a docked bar minimizes to a pill inside its leading end', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(bottom: 34)),
          child: child!,
        ),
        home: BottomBar(
          controller: controller,
          layout: const BottomBarLayout.docked(),
          scrollBehavior: BottomBarScrollBehavior(
            minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
          ),
          body: const SizedBox.expand(),
          child: _items(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = _surface(tester).outlineRect;

    controller.minimize();
    await tester.pumpAndSettle();

    final pill = _surface(tester).outlineRect;
    expect(pill.size, const Size(48, 48));
    expect(pill.bottom, lessThanOrEqualTo(bar.bottom - 34));
    expect(
      pill.left,
      moreOrLessEquals(bar.left + ((bar.height - 34) - 48) / 2),
    );
  });

  testWidgets('a minimized RTL bar puts its pill at the trailing edge', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, controller: controller, direction: TextDirection.rtl);
    final bar = _surface(tester).outlineRect;

    controller.minimize();
    await tester.pumpAndSettle();

    final pill = _surface(tester).outlineRect;
    expect(pill.right, moreOrLessEquals(bar.right - (bar.height - 48) / 2));
    expect(pill.left, greaterThan(bar.center.dx));
  });

  testWidgets(
    'taps on the bar outside the pill reach the body while minimized',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      var bodyTaps = 0;
      final selected = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: BottomBar(
                controller: controller,
                body: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => bodyTaps++,
                  child: const SizedBox.expand(),
                ),
                child: _items(onSelected: selected.add),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final bar = _surface(tester).outlineRect;
      controller.minimize();
      await tester.pumpAndSettle();

      final surface = _surface(tester);
      final barRight = surface.localToGlobal(
        bar.centerRight - const Offset(30, 0),
      );
      await tester.tapAt(barRight);
      await tester.pumpAndSettle();
      expect(bodyTaps, 1);
      expect(selected, isEmpty);

      await tester.tapAt(surface.localToGlobal(surface.outlineRect.center));
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.shown);
      expect(selected, isEmpty);
    },
  );

  testWidgets('the pill is the only semantics of a minimized bar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: BottomBar(
              controller: controller,
              body: const SizedBox.expand(),
              child: _items(badge: const BottomBarBadge.count(3)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();

    final pillNode = tester.getSemantics(find.byType(CompactPillButton));
    expect(
      pillNode,
      isSemantics(isButton: true, hasTapAction: true, hint: 'Expand'),
    );
    expect(pillNode.label, contains('Home'));
    expect(
      semanticsLabels(tester).where((label) => label.contains('Search')),
      isEmpty,
    );

    controller.expand();
    await tester.pumpAndSettle();
    expect(
      semanticsLabels(tester).where((label) => label.contains('Search')),
      isNotEmpty,
    );
    handle.dispose();
  });

  testWidgets('focus leaves the hidden items and Tab reaches the pill', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    const itemsKey = Key('items');
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: BottomBar(
              controller: controller,
              body: const SizedBox.expand(),
              child: _items(key: itemsKey),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var reached = false;
    for (var i = 0; i < 8 && !reached; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      reached = focusIn(Null, key: itemsKey);
    }
    expect(reached, isTrue);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(focusIn(Null, key: itemsKey), isFalse);

    var reachedPill = false;
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusIn(Null, key: itemsKey), isFalse);
      if (focusIn(CompactPillButton)) reachedPill = true;
    }
    expect(reachedPill, isTrue);
  });

  testWidgets('a custom compactChild becomes the pill', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(
      tester,
      controller: controller,
      child: const SizedBox(height: 64, child: Text('custom')),
      compactChild: const SizedBox(
        width: 160,
        height: 40,
        child: Text('Now playing'),
      ),
    );
    await tester.pumpAndSettle();

    controller.minimize();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(_surface(tester).outlineRect.size, const Size(160, 40));
    expect(find.text('Now playing'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CompactPillButton)),
      isSemantics(hint: 'Expand', isButton: true),
    );

    await tester.tapAt(
      _surface(tester).localToGlobal(_surface(tester).outlineRect.center),
    );
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    handle.dispose();
  });

  testWidgets('a bar without a pill hides on minimize', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: BottomBar(
              controller: controller,
              body: const SizedBox.expand(),
              child: BottomBarItems(
                onSelected: (_) {},
                children: [
                  for (final label in _labels)
                    BottomBarItem(
                      icon: const Icon(Icons.circle_outlined),
                      label: Text(label),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.hidden);
  });

  testWidgets(
    'a selected plain child without a BottomBarItem hides on minimize',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: BottomBar(
                controller: controller,
                body: const SizedBox.expand(),
                child: BottomBarItems(
                  selectedIndex: 0,
                  onSelected: (_) {},
                  children: const [
                    SizedBox(width: 48, height: 48),
                    SizedBox(width: 48, height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.minimize();
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.hidden);
    },
  );

  testWidgets('body padding and visible height follow the minimize state', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    late BottomBarScope scope;
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          body: BottomBarBodyPadding(
            child: Builder(
              builder: (context) {
                scope = BottomBarScope.of(context);
                return ListView(
                  key: const Key('list'),
                  children: const [SizedBox(height: 60, child: Text('Row'))],
                );
              },
            ),
          ),
          child: _items(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    EdgeInsetsGeometry bodyPadding() => tester
        .widget<Padding>(
          find
              .descendant(
                of: find.byType(BottomBarBodyPadding),
                matching: find.byType(Padding),
              )
              .first,
        )
        .padding;

    final shownPadding = bodyPadding();
    final full = scope.barHeight.value;
    expect(scope.visibleHeight.value, full);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(bodyPadding(), shownPadding);
    expect(scope.visibility.value, BottomBarVisibility.minimized);
    expect(scope.visibleHeight.value, greaterThan(0));
    expect(scope.visibleHeight.value, lessThan(full));

    controller.expand();
    await tester.pumpAndSettle();
    expect(bodyPadding(), shownPadding);
    expect(scope.visibleHeight.value, full);

    controller.hide();
    await tester.pumpAndSettle();
    expect(scope.visibleHeight.value, 0);

    controller.show();
    await tester.pumpAndSettle();
    expect(scope.visibleHeight.value, scope.barHeight.value);
  });
}
