import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show kPressTimeout;

import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

List<BottomBarItem> _items(int count) => [
  for (var i = 0; i < count; i++)
    BottomBarItem(
      key: ValueKey(i),
      icon: Icon(_tabs[i].$1),
      label: Text(_tabs[i].$2),
    ),
];

BottomBarCenterAction _action({
  required VoidCallback? onPressed,
  BottomBarCenterActionStyle style = BottomBarCenterActionStyle.inline,
  Color? backgroundColor,
  double? size,
}) {
  return BottomBarCenterAction(
    icon: const Icon(Icons.add),
    tooltip: 'Create',
    onPressed: onPressed,
    style: style,
    backgroundColor: backgroundColor,
    size: size,
  );
}

Widget _bar({
  List<BottomBarItem>? items,
  BottomBarCenterAction? action,
  int initialIndex = 0,
  bool dragToSelect = false,
  BottomBarIndicator? indicator,
  BottomBarThemeData? theme,
  ThemeData? appTheme,
  BottomBarController? controller,
  BottomBarLayout? layout,
  ValueChanged<int>? onSelected,
  ValueChanged<int>? onReselected,
  Widget? body,
  double? width = 360,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
}) {
  var index = initialIndex;
  return MaterialApp(
    key: UniqueKey(),
    theme: appTheme,
    builder: (context, child) => reduceMotion
        ? MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          )
        : child!,
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => BottomBar(
            controller: controller,
            theme: theme,
            layout: layout ?? const BottomBarLayout(width: 360),
            body: body ?? const SizedBox.shrink(),
            child: width == null
                ? BottomBarItems(
                    selectedIndex: index,
                    indicator: indicator ?? const BottomBarIndicator.pill(),
                    dragToSelect: dragToSelect,
                    centerAction: action,
                    onSelected: (i) {
                      setState(() => index = i);
                      onSelected?.call(i);
                    },
                    onReselected: onReselected,
                    children: items ?? _items(4),
                  )
                : SizedBox(
                    width: width,
                    child: BottomBarItems(
                      selectedIndex: index,
                      indicator: indicator ?? const BottomBarIndicator.pill(),
                      dragToSelect: dragToSelect,
                      centerAction: action,
                      onSelected: (i) {
                        setState(() => index = i);
                        onSelected?.call(i);
                      },
                      onReselected: onReselected,
                      children: items ?? _items(4),
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

List<Object?> _recordHaptics(WidgetTester tester) {
  final haptics = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return haptics;
}

Finder _actionInk() => find.descendant(
  of: find.byType(BottomBarCenterAction),
  matching: find.byType(InkWell),
);

Finder _barMaterial() => find
    .ancestor(of: find.byType(BottomBarItems), matching: find.byType(Material))
    .first;

Rect _actionRect(WidgetTester tester) => tester.getRect(_actionInk());

Rect _surfaceRect(WidgetTester tester) =>
    tester.getRect(find.byType(BarSurface));

Rect _barRect(WidgetTester tester) => tester.getRect(_barMaterial());

RenderBarSurface _surface(WidgetTester tester) =>
    tester.renderObject<RenderBarSurface>(find.byType(BarSurface));

Offset _raisedTapPoint(WidgetTester tester) {
  final rect = _actionRect(tester);
  return Offset(rect.center.dx, rect.top + 5);
}

void main() {
  for (final indicator in [null, const BottomBarIndicator.none()]) {
    for (final selectedIndex in [null, 0]) {
      testWidgets('raised action lifts with indicator $indicator and '
          'selectedIndex $selectedIndex', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BottomBar(
                body: const SizedBox.shrink(),
                child: BottomBarItems(
                  selectedIndex: selectedIndex,
                  indicator: indicator,
                  centerAction: BottomBarCenterAction(
                    icon: const Icon(Icons.add),
                    tooltip: 'Create',
                    style: BottomBarCenterActionStyle.raised,
                    onPressed: () => taps++,
                  ),
                  children: _items(4),
                ),
              ),
            ),
          ),
        );
        final barTop = tester.getRect(find.byType(BottomBarItems)).top;
        final surface = tester.getRect(find.byType(BarSurface));
        final action = tester.getRect(_actionInk());
        expect(barTop - surface.top, 28);
        expect(action.top, surface.top);
        expect(action.height, 56);
        await tester.pumpAndSettle();
        await tester.tapAt(Offset(action.center.dx, barTop - 5));
        expect(taps, 1);
      });
    }
  }

  testWidgets('selection, reselection and taps skip the centre action', (
    tester,
  ) async {
    final selected = <int>[];
    final reselected = <int>[];
    var pressed = 0;
    await tester.pumpWidget(
      _bar(
        action: _action(onPressed: () => pressed++),
        onSelected: selected.add,
        onReselected: reselected.add,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_actionInk());
    await tester.pumpAndSettle();
    expect(pressed, 1);
    expect(selected, isEmpty);

    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(reselected, isEmpty);

    selected.clear();
    pressed = 0;
    await tester.pumpWidget(
      _bar(
        initialIndex: 2,
        action: _action(onPressed: () => pressed++),
        onSelected: selected.add,
        onReselected: reselected.add,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.pumpAndSettle();
    expect(reselected, [2]);
    expect(selected, [2]);

    await tester.tap(_actionInk());
    await tester.pumpAndSettle();
    expect(pressed, 1);
    expect(reselected, [2]);
    expect(selected, [2]);
  });

  testWidgets('indicator and selection scopes skip the centre action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _bar(
        initialIndex: 2,
        indicator: const BottomBarIndicator.pill(),
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byType(BottomBarCenterAction),
        matching: find.byType(BottomBarItemSelectionScope),
      ),
      findsNothing,
    );
    final scopes = tester
        .widgetList<BottomBarItemSelectionScope>(
          find.byType(BottomBarItemSelectionScope),
        )
        .toList();
    expect([for (final scope in scopes) scope.index], [0, 1, 2, 3]);
    expect(scopes.singleWhere((scope) => scope.index == 2).selected, isTrue);
  });

  testWidgets('drag across the centre action selects the item past it', (
    tester,
  ) async {
    final selected = <int>[];
    var pressed = 0;
    await tester.pumpWidget(
      _bar(
        initialIndex: 1,
        dragToSelect: true,
        indicator: const BottomBarIndicator.pill(),
        action: _action(onPressed: () => pressed++),
        onSelected: selected.add,
      ),
    );
    await tester.pumpAndSettle();

    final from = tester.getCenter(find.byKey(const ValueKey(1)));
    final to = tester.getCenter(find.byKey(const ValueKey(2)));
    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    for (var step = 1; step <= 10; step++) {
      await gesture.moveTo(
        Offset.lerp(from + const Offset(30, 0), to, step / 10)!,
      );
      await tester.pump();
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(pressed, 0);

    selected.clear();
    await tester.pumpWidget(
      _bar(
        initialIndex: 1,
        dragToSelect: true,
        indicator: const BottomBarIndicator.pill(),
        action: _action(onPressed: () => pressed++),
        onSelected: selected.add,
      ),
    );
    await tester.pumpAndSettle();

    final searchCentre = tester.getCenter(find.byKey(const ValueKey(1)));
    final actionCentre = tester.getCenter(_actionInk());
    final second = await tester.startGesture(searchCentre);
    await second.moveBy(const Offset(30, 0));
    await tester.pumpAndSettle();
    for (var step = 1; step <= 10; step++) {
      await second.moveTo(
        Offset.lerp(
          searchCentre + const Offset(30, 0),
          actionCentre,
          step / 10,
        )!,
      );
      await tester.pump();
    }
    await second.up();
    await tester.pumpAndSettle();
    expect(selected, everyElement(isIn({1, 2})));
    expect(pressed, 0);
  });

  testWidgets('raised and notched actions take taps above the bar edge', (
    tester,
  ) async {
    for (final style in [
      BottomBarCenterActionStyle.raised,
      BottomBarCenterActionStyle.notched,
    ]) {
      var pressed = 0;
      await tester.pumpWidget(
        _bar(
          action: _action(style: style, onPressed: () => pressed++),
        ),
      );
      await tester.pumpAndSettle();

      final point = _raisedTapPoint(tester);
      expect(point.dy, lessThan(_surfaceRect(tester).top + 28));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(pressed, 1);
    }
  });

  testWidgets('hidden bar drops the raised action from taps and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    var pressed = 0;
    await tester.pumpWidget(
      _bar(
        controller: controller,
        action: _action(
          style: BottomBarCenterActionStyle.raised,
          onPressed: () => pressed++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final point = _raisedTapPoint(tester);

    controller.hide();
    await tester.pumpAndSettle();
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(pressed, 0);
    expect(semanticsLabels(tester), isNot(contains('Create')));

    controller.show();
    await tester.pumpAndSettle();
    expect(semanticsLabels(tester), contains('Create'));
    await tester.tapAt(_raisedTapPoint(tester));
    await tester.pumpAndSettle();
    expect(pressed, 1);
    semantics.dispose();
  });

  testWidgets('raised action is a labelled enabled button, not selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _bar(
        action: _action(
          style: BottomBarCenterActionStyle.raised,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.bySemanticsLabel('Create'));
    expect(
      node,
      matchesSemantics(
        label: 'Create',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(
      node.getSemanticsData().flagsCollection.isSelected,
      isNot(ui.Tristate.isTrue),
    );
    expect(_actionRect(tester).top, closeTo(_barRect(tester).top - 28, 0.5));
    semantics.dispose();
  });

  testWidgets('raise adds to barHeight and to BottomBarBodyPadding', (
    tester,
  ) async {
    late BuildContext bodyContext;
    final body = Builder(
      builder: (context) {
        bodyContext = context;
        return BottomBarBodyPadding(
          child: const SizedBox.expand(key: Key('content')),
        );
      },
    );

    await tester.pumpWidget(_bar(body: body));
    await tester.pumpAndSettle();
    final without = BottomBarScope.of(bodyContext).barHeight.value;

    await tester.pumpWidget(
      _bar(
        body: body,
        action: _action(
          style: BottomBarCenterActionStyle.raised,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    final withAction = BottomBarScope.of(bodyContext).barHeight.value;
    expect(withAction - without, closeTo(28.0, 0.001));

    final padding = tester.widget<Padding>(
      find
          .ancestor(
            of: find.byKey(const Key('content')),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding.resolve(TextDirection.ltr).bottom, withAction);

    await tester.pumpWidget(
      _bar(
        body: body,
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump();
    final inline = BottomBarScope.of(bodyContext).barHeight.value;
    expect(inline, greaterThanOrEqualTo(without));
    expect(_surfaceRect(tester).height, tester.getRect(_barMaterial()).height);
  });

  testWidgets('notch follows the action across a layout change', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _bar(
        width: null,
        items: _items(3),
        layout: const BottomBarLayout.adaptive(maxWidth: 600),
        action: _action(
          style: BottomBarCenterActionStyle.notched,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    void expectNotchFollowsAction() {
      final expected =
          _actionRect(tester).center.dx - _surfaceRect(tester).center.dx;
      expect(_surface(tester).outline.notch!.center.dx, closeTo(expected, 0.5));
    }

    expectNotchFollowsAction();

    tester.view.physicalSize = const Size(800, 400);
    await tester.pump();
    expectNotchFollowsAction();

    await tester.pumpWidget(
      _bar(
        width: null,
        items: _items(3),
        layout: const BottomBarLayout.adaptive(maxWidth: 600),
        action: _action(
          style: BottomBarCenterActionStyle.raised,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_surface(tester).outline.notch, isNull);

    await tester.pumpWidget(
      _bar(
        width: null,
        items: _items(3),
        layout: const BottomBarLayout.adaptive(maxWidth: 600),
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(_surface(tester).outline.notch, isNull);
  });

  testWidgets(
    'a row too narrow for its items scrolls and the action goes inline',
    (tester) async {
      await tester.pumpWidget(
        _bar(
          width: null,
          layout: const BottomBarLayout(width: 200),
          action: _action(
            style: BottomBarCenterActionStyle.notched,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(BottomBarItems),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(_surface(tester).outline.notch, isNull);
      expect(_surfaceRect(tester).height, _barRect(tester).height);
      expect(tester.getSize(_actionInk()), const Size(48, 48));
    },
  );

  testWidgets('notch mirrors in right-to-left layout', (tester) async {
    Widget bar(TextDirection direction) => _bar(
      width: null,
      direction: direction,
      items: _items(3),
      layout: const BottomBarLayout.adaptive(maxWidth: 600),
      action: _action(
        style: BottomBarCenterActionStyle.notched,
        onPressed: () {},
      ),
    );

    await tester.pumpWidget(bar(TextDirection.ltr));
    await tester.pumpAndSettle();
    final ltrNotch = _surface(tester).outline.notch!.center.dx;

    await tester.pumpWidget(bar(TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(_surface(tester).outline.notch!.center.dx, closeTo(-ltrNotch, 0.5));
    expect(
      _actionRect(tester).center.dx - _surfaceRect(tester).center.dx,
      closeTo(-ltrNotch, 0.5),
    );
  });

  testWidgets(
    'action colour follows action, then BottomBar theme, then extension',
    (tester) async {
      Color actionColor() => tester
          .widget<Material>(
            find
                .descendant(
                  of: find.byType(BottomBarCenterAction),
                  matching: find.byType(Material),
                )
                .first,
          )
          .color!;

      BottomBarThemeData themed(Color color) => BottomBarThemeData(
        items: BottomBarItemThemeData(
          centerAction: BottomBarCenterActionThemeData(backgroundColor: color),
        ),
      );

      await tester.pumpWidget(_bar(action: _action(onPressed: () {})));
      await tester.pumpAndSettle();
      expect(
        actionColor(),
        Theme.of(
          tester.element(find.byType(BottomBarCenterAction)),
        ).colorScheme.primary,
      );

      await tester.pumpWidget(
        _bar(
          appTheme: ThemeData(extensions: [themed(Colors.red)]),
          action: _action(onPressed: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(actionColor(), Colors.red);

      await tester.pumpWidget(
        _bar(
          appTheme: ThemeData(extensions: [themed(Colors.red)]),
          theme: themed(Colors.green),
          action: _action(onPressed: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(actionColor(), Colors.green);

      await tester.pumpWidget(
        _bar(
          appTheme: ThemeData(extensions: [themed(Colors.red)]),
          theme: themed(Colors.green),
          action: _action(onPressed: () {}, backgroundColor: Colors.blue),
        ),
      );
      await tester.pumpAndSettle();
      expect(actionColor(), Colors.blue);
    },
  );

  testWidgets('theme size and raise shape the centre action', (tester) async {
    await tester.pumpWidget(
      _bar(
        theme: const BottomBarThemeData(
          items: BottomBarItemThemeData(
            centerAction: BottomBarCenterActionThemeData(size: 64),
          ),
        ),
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(_actionInk()), const Size(64, 64));

    await tester.pumpWidget(
      _bar(
        theme: const BottomBarThemeData(
          items: BottomBarItemThemeData(
            centerAction: BottomBarCenterActionThemeData(raise: 10),
          ),
        ),
        action: _action(
          style: BottomBarCenterActionStyle.raised,
          onPressed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_actionRect(tester).top, closeTo(_barRect(tester).top - 10, 0.5));
  });

  testWidgets('pressed scale is applied at once under reduced motion', (
    tester,
  ) async {
    const theme = BottomBarThemeData(
      items: BottomBarItemThemeData(pressedScale: 0.8),
    );
    double scale() => tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(BottomBarCenterAction),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];

    await tester.pumpWidget(
      _bar(
        theme: theme,
        reduceMotion: true,
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();
    final reduced = await tester.startGesture(tester.getCenter(_actionInk()));
    await tester.pump(kPressTimeout + const Duration(milliseconds: 1));
    expect(scale(), closeTo(0.8, 0.001));
    await reduced.up();
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.001));

    await tester.pumpWidget(
      _bar(
        theme: theme,
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();
    final animated = await tester.startGesture(tester.getCenter(_actionInk()));
    await tester.pump(kPressTimeout + const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(scale(), allOf(greaterThan(0.8), lessThan(1.0)));
    await animated.up();
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, 0.001));
  });

  testWidgets('tapping the centre action fires its haptic', (tester) async {
    final haptics = _recordHaptics(tester);
    await tester.pumpWidget(
      _bar(
        theme: const BottomBarThemeData(
          items: BottomBarItemThemeData(haptics: BottomBarHaptics.lightImpact),
        ),
        action: _action(onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_actionInk());
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
  });

  test('a centre action needs a semantics label or a tooltip', () {
    expect(
      () => BottomBarCenterAction(icon: const Icon(Icons.add), onPressed: null),
      throwsAssertionError,
    );
  });
}
