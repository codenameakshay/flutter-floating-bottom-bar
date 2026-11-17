import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _buttonKey = ValueKey('accessory-button');
const _counterKey = ValueKey('accessory-counter');
const _accessoryKey = ValueKey('accessory-body');
const _centerIconKey = ValueKey('center-icon');
const _step = Duration(milliseconds: 8);

BottomBarItems _items({BottomBarCenterAction? centerAction}) => BottomBarItems(
  selectedIndex: 0,
  onSelected: (_) {},
  centerAction: centerAction,
  children: const [
    BottomBarItem(icon: Icon(Icons.circle_outlined), label: Text('Home')),
    BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
    BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
  ],
);

Widget _accessory({
  List<BottomBarAccessoryPlacement>? seen,
  VoidCallback? onPressed,
}) => SizedBox(
  key: _accessoryKey,
  height: 56,
  child: Builder(
    builder: (context) {
      seen?.add(BottomBarAccessoryPlacement.of(context));
      return Center(
        child: IconButton(
          key: _buttonKey,
          onPressed: onPressed ?? () {},
          icon: const Icon(Icons.play_arrow),
        ),
      );
    },
  ),
);

Widget _trailing() =>
    IconButton(onPressed: () {}, icon: const Icon(Icons.search));

Widget _leading() =>
    IconButton(onPressed: () {}, icon: const Icon(Icons.person));

Future<void> _pump(
  WidgetTester tester, {
  required BottomBarController controller,
  Widget? accessory,
  Widget? leading,
  Widget? trailing,
  BottomBarItems? items,
  BottomBarLayout layout = const BottomBarLayout(width: 360),
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  EdgeInsets padding = EdgeInsets.zero,
  Widget? body,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: reduceMotion, padding: padding),
        child: child!,
      ),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            layout: layout,
            accessory: accessory,
            leading: leading,
            trailing: trailing,
            body: body ?? const SizedBox.expand(),
            child: items ?? _items(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderBarSurface _pillSurface(WidgetTester tester) =>
    tester.renderObject<RenderBarSurface>(find.byKey(const ValueKey('pill')));

Rect _pillOutline(WidgetTester tester) {
  final surface = _pillSurface(tester);
  return MatrixUtils.transformRect(
    surface.getTransformTo(null),
    surface.outlineRect,
  );
}

Rect _piece(WidgetTester tester, String slot) =>
    tester.getRect(find.byKey(ValueKey(slot)));

void _expectRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.5));
  expect(actual.top, closeTo(expected.top, 0.5));
  expect(actual.right, closeTo(expected.right, 0.5));
  expect(actual.bottom, closeTo(expected.bottom, 0.5));
}

void main() {
  group('expanded geometry', () {
    testWidgets('LTR with a trailing piece', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        trailing: _trailing(),
      );
      _expectRect(
        _piece(tester, 'accessory'),
        const Rect.fromLTRB(20, 676, 322, 732),
      );
      _expectRect(
        _piece(tester, 'pill'),
        const Rect.fromLTRB(20, 740, 322, 790),
      );
      _expectRect(
        _piece(tester, 'trailing'),
        const Rect.fromLTRB(330, 740, 380, 790),
      );
    });

    testWidgets('without leading or trailing spans the full bar width', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller, accessory: _accessory());
      final accessory = _piece(tester, 'accessory');
      final pill = _piece(tester, 'pill');
      expect(accessory.left, 20);
      expect(accessory.right, 380);
      expect(accessory.bottom, pill.top - 8);
      expect(accessory.bottom, 732);
    });

    testWidgets('with leading and trailing matches the pill, not the leading', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        leading: _leading(),
        trailing: _trailing(),
      );
      final accessory = _piece(tester, 'accessory');
      final pill = _piece(tester, 'pill');
      final leading = _piece(tester, 'leading');
      expect(leading.left, 20);
      expect(pill.left, 78);
      expect(pill.right, 322);
      expect(accessory.left, pill.left);
      expect(accessory.right, pill.right);
      expect(accessory.left, isNot(leading.left));
    });
  });

  group('minimized geometry', () {
    testWidgets('LTR with a trailing piece sits beside the compact pill', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        trailing: _trailing(),
      );
      controller.minimize();
      await tester.pumpAndSettle();
      _expectRect(
        _piece(tester, 'accessory'),
        const Rect.fromLTRB(77, 741, 322, 789),
      );
    });

    testWidgets('RTL mirrors the minimized accessory', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        direction: TextDirection.rtl,
        accessory: _accessory(),
        trailing: _trailing(),
      );
      controller.minimize();
      await tester.pumpAndSettle();
      _expectRect(
        _piece(tester, 'accessory'),
        const Rect.fromLTRB(78, 741, 323, 789),
      );
    });

    testWidgets('with leading and trailing it fits between pill and trailing', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        leading: _leading(),
        trailing: _trailing(),
      );
      controller.minimize();
      await tester.pumpAndSettle();
      final accessory = _piece(tester, 'accessory');
      final trailing = _piece(tester, 'trailing');
      expect(accessory.left, _pillOutline(tester).right + 8);
      expect(accessory.right, trailing.left - 8);
    });

    testWidgets('with no trailing piece it runs to the end of the bar', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller, accessory: _accessory());
      controller.minimize();
      await tester.pumpAndSettle();
      final accessory = _piece(tester, 'accessory');
      expect(accessory.right, 380);
      expect(accessory.left, _pillOutline(tester).right + 8);
    });
  });

  group('morph', () {
    testWidgets(
      'accessory is inline at morph 0.5 and expanded one frame earlier',
      (tester) async {
        final seen = <BottomBarAccessoryPlacement>[];
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await _pump(
          tester,
          controller: controller,
          accessory: _accessory(seen: seen),
          trailing: _trailing(),
        );
        controller.minimize();
        await tester.pump();
        var frames = 0;
        for (var i = 0; i < 300 && _pillSurface(tester).morph < 0.5; i++) {
          await tester.pump(_step);
          frames++;
        }
        expect(_pillSurface(tester).morph, greaterThanOrEqualTo(0.5));
        final top = _piece(tester, 'accessory').top;
        expect(top, greaterThan(676));
        expect(top, lessThan(741));
        expect(seen.last, BottomBarAccessoryPlacement.inline);

        await tester.pumpWidget(const SizedBox());
        final earlierSeen = <BottomBarAccessoryPlacement>[];
        final earlier = BottomBarController();
        addTearDown(earlier.dispose);
        await _pump(
          tester,
          controller: earlier,
          accessory: _accessory(seen: earlierSeen),
          trailing: _trailing(),
        );
        earlier.minimize();
        await tester.pump();
        for (var i = 0; i < frames - 1; i++) {
          await tester.pump(_step);
        }
        expect(_pillSurface(tester).morph, lessThan(0.5));
        expect(earlierSeen.last, BottomBarAccessoryPlacement.expanded);
      },
    );

    testWidgets('interrupting the morph expands without ever going inline', (
      tester,
    ) async {
      final seen = <BottomBarAccessoryPlacement>[];
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(seen: seen),
        trailing: _trailing(),
      );
      controller.minimize();
      await tester.pump();
      for (var i = 0; i < 300 && _pillSurface(tester).morph < 0.25; i++) {
        await tester.pump(_step);
      }
      final morph = _pillSurface(tester).morph;
      expect(morph, greaterThanOrEqualTo(0.1));
      expect(morph, lessThanOrEqualTo(0.4));

      controller.expand();
      await tester.pumpAndSettle();
      expect(seen, isNot(contains(BottomBarAccessoryPlacement.inline)));
      _expectRect(
        _piece(tester, 'accessory'),
        const Rect.fromLTRB(20, 676, 322, 732),
      );
    });

    testWidgets('reduced motion snaps to the minimized rect in one pump', (
      tester,
    ) async {
      final seen = <BottomBarAccessoryPlacement>[];
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(seen: seen),
        trailing: _trailing(),
        reduceMotion: true,
      );
      controller.minimize();
      await tester.pump();
      _expectRect(
        _piece(tester, 'accessory'),
        const Rect.fromLTRB(77, 741, 322, 789),
      );
      expect(seen.last, BottomBarAccessoryPlacement.inline);
    });
  });

  group('centre action', () {
    testWidgets('raised centre action sits above the accessory gap', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        items: _items(
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add, key: _centerIconKey),
            semanticLabel: 'Create',
            style: BottomBarCenterActionStyle.raised,
            onPressed: () {},
          ),
        ),
      );
      final action = tester.getRect(
        find
            .descendant(
              of: find.byType(BottomBarCenterAction),
              matching: find.byType(Material),
            )
            .first,
      );
      final accessory = _piece(tester, 'accessory');
      expect(accessory.bottom, action.top - 8);
      expect(accessory.overlaps(action), isFalse);
    });
  });

  group('docked', () {
    testWidgets('insets the accessory by group spacing from each edge', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        layout: const BottomBarLayout.docked(),
      );
      final accessory = _piece(tester, 'accessory');
      final pill = _piece(tester, 'pill');
      expect(accessory.left, 8);
      expect(accessory.right, 392);
      expect(accessory.bottom, pill.top - 8);
    });

    testWidgets('adds the side safe-area insets', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        layout: const BottomBarLayout.docked(),
        padding: const EdgeInsets.only(left: 30, right: 20),
      );
      final accessory = _piece(tester, 'accessory');
      expect(accessory.left, 38);
      expect(accessory.right, 372);
    });
  });

  group('bar height and body padding', () {
    testWidgets('barHeight counts the accessory and its spacing', (
      tester,
    ) async {
      double? barHeight;
      Widget body() => Builder(
        builder: (context) {
          final scope = BottomBarScope.of(context);
          return ValueListenableBuilder<double>(
            valueListenable: scope.barHeight,
            builder: (context, value, child) {
              barHeight = value;
              return const SizedBox.expand();
            },
          );
        },
      );

      final without = BottomBarController();
      addTearDown(without.dispose);
      await _pump(tester, controller: without, body: body());
      final barHeightWithout = barHeight!;
      expect(barHeightWithout, 70);

      await tester.pumpWidget(const SizedBox());
      final withAccessory = BottomBarController();
      addTearDown(withAccessory.dispose);
      await _pump(
        tester,
        controller: withAccessory,
        accessory: _accessory(),
        body: body(),
      );
      expect(barHeight, barHeightWithout + 56 + 8);
      expect(barHeight, 134);
    });

    testWidgets('BottomBarBodyPadding reserves the full height', (
      tester,
    ) async {
      final key = GlobalKey();
      double? barHeight;
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(),
        body: Builder(
          builder: (context) {
            final scope = BottomBarScope.of(context);
            return Column(
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: scope.barHeight,
                  builder: (context, value, child) {
                    barHeight = value;
                    return const SizedBox.shrink();
                  },
                ),
                Expanded(
                  child: BottomBarBodyPadding(child: SizedBox.expand(key: key)),
                ),
              ],
            );
          },
        ),
      );
      expect(barHeight, 134);
      expect(tester.getSize(find.byKey(key)).height, 666);

      controller.minimize();
      await tester.pumpAndSettle();
      expect(barHeight, 134);
      expect(tester.getSize(find.byKey(key)).height, 666);
    });

    testWidgets(
      'visibleHeight while minimized matches the bar without accessory',
      (tester) async {
        double? visible;
        Widget body() => Builder(
          builder: (context) {
            final scope = BottomBarScope.of(context);
            return ValueListenableBuilder<double>(
              valueListenable: scope.visibleHeight,
              builder: (context, value, child) {
                visible = value;
                return const SizedBox.expand();
              },
            );
          },
        );

        final without = BottomBarController();
        addTearDown(without.dispose);
        await _pump(
          tester,
          controller: without,
          trailing: _trailing(),
          body: body(),
        );
        without.minimize();
        await tester.pumpAndSettle();
        final visibleWithout = visible!;
        expect(visibleWithout, 70);

        await tester.pumpWidget(const SizedBox());
        final withAccessory = BottomBarController();
        addTearDown(withAccessory.dispose);
        await _pump(
          tester,
          controller: withAccessory,
          accessory: _accessory(),
          trailing: _trailing(),
          body: body(),
        );
        withAccessory.minimize();
        await tester.pumpAndSettle();
        expect(visible, visibleWithout);
        expect(visible, 70);
      },
    );
  });

  group('hide and show', () {
    testWidgets('hidden accessory takes no taps and comes back on show', (
      tester,
    ) async {
      var taps = 0;
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller: controller,
        accessory: _accessory(onPressed: () => taps++),
        trailing: _trailing(),
      );

      controller.hide();
      await tester.pumpAndSettle();
      expect(find.byKey(_buttonKey).hitTestable(), findsNothing);
      await tester.tapAt(tester.getCenter(find.byKey(_buttonKey)));
      await tester.pumpAndSettle();
      expect(taps, 0);

      controller.show();
      await tester.pumpAndSettle();
      _expectRect(
        _piece(tester, 'accessory'),
        const Rect.fromLTRB(20, 676, 322, 732),
      );
      await tester.tap(find.byKey(_buttonKey));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('no accessory', () {
    testWidgets('a bar without pieces has one surface at its usual rect', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(tester, controller: controller);
      expect(find.byType(BarSurface), findsOneWidget);
      _expectRect(
        _piece(tester, 'pill'),
        const Rect.fromLTRB(20, 740, 380, 790),
      );
    });
  });

  group('rail mode', () {
    testWidgets('accessory floats in the body pane, expanded, with padding', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final paneKey = GlobalKey();
      final padKey = GlobalKey();
      final seen = <BottomBarAccessoryPlacement>[];
      double? barHeight;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarAdaptive(
              items: _items(),
              accessory: _accessory(seen: seen),
              body: Builder(
                builder: (context) {
                  final scope = BottomBarScope.of(context);
                  return ValueListenableBuilder<double>(
                    valueListenable: scope.barHeight,
                    builder: (context, value, child) {
                      barHeight = value;
                      return Stack(
                        key: paneKey,
                        fit: StackFit.expand,
                        children: [
                          BottomBarBodyPadding(
                            child: SizedBox.expand(key: padKey),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pane = tester.getRect(find.byKey(paneKey));
      final accessory = tester.getRect(find.byKey(_accessoryKey));
      const offset = 10.0;
      expect(const BottomBarLayout().offset, offset);
      expect(seen.last, BottomBarAccessoryPlacement.expanded);
      expect(accessory.bottom, 600 - offset);
      expect(accessory.left, pane.left + offset);
      expect(accessory.right, pane.right - offset);
      expect(barHeight, 76);
      expect(tester.getSize(find.byKey(padKey)).height, 524);
    });

    testWidgets('accessory state survives crossing the breakpoint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final seen = <BottomBarAccessoryPlacement>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarAdaptive(
              items: _items(),
              accessory: _Counter(seen: seen),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_counterKey));
      await tester.pumpAndSettle();
      expect(find.text('count 1'), findsOneWidget);

      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      expect(find.text('count 1'), findsOneWidget);
      expect(seen.last, BottomBarAccessoryPlacement.expanded);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter({required this.seen});

  final List<BottomBarAccessoryPlacement> seen;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    widget.seen.add(BottomBarAccessoryPlacement.of(context));
    return SizedBox(
      height: 56,
      child: Center(
        child: TextButton(
          key: _counterKey,
          onPressed: () {
            setState(() {
              _count++;
            });
          },
          child: Text('count $_count'),
        ),
      ),
    );
  }
}
