import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _row({Key? key, required VoidCallback? onPressed}) => BottomBarItems(
  key: key,
  centerAction: BottomBarCenterAction(
    icon: const Icon(Icons.add),
    semanticLabel: 'Create',
    style: BottomBarCenterActionStyle.raised,
    onPressed: onPressed,
  ),
  children: const [SizedBox(height: 48), SizedBox(height: 48)],
);

Widget _app(Widget child, {BottomBarThemeData? theme}) => MaterialApp(
  home: Scaffold(
    body: BottomBar(
      theme: theme,
      layout: const BottomBarLayout(width: 360),
      body: const SizedBox.shrink(),
      child: child,
    ),
  ),
);

Finder _ink({bool skipOffstage = true}) => find.descendant(
  of: find.byType(BottomBarCenterAction, skipOffstage: skipOffstage),
  matching: find.byType(InkWell, skipOffstage: skipOffstage),
  skipOffstage: skipOffstage,
);

void main() {
  testWidgets('large action with a small raise reserves its lower extent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        BottomBarItems(
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add),
            semanticLabel: 'Create',
            style: BottomBarCenterActionStyle.raised,
            size: 96,
            onPressed: () {},
          ),
          children: const [SizedBox(height: 48), SizedBox(height: 48)],
        ),
        theme: const BottomBarThemeData(
          items: BottomBarItemThemeData(
            centerAction: BottomBarCenterActionThemeData(raise: 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.getRect(_ink());
    final surface = tester.getRect(find.byType(BarSurface));
    expect(surface.height, 96);
    expect(surface.contains(button.bottomCenter - const Offset(0, 1)), isTrue);
  });

  for (final size in [56.0, 120.0]) {
    testWidgets(
      'raised action with empty tabs fits the footprint at size $size',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          _app(
            BottomBarItems(
              centerAction: BottomBarCenterAction(
                icon: const Icon(Icons.add),
                semanticLabel: 'Create',
                style: BottomBarCenterActionStyle.raised,
                size: size,
                onPressed: () => taps++,
              ),
              children: const [],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = tester.getRect(_ink());
        final surface = tester.getRect(find.byType(BarSurface));
        expect(
          surface.contains(button.bottomCenter - const Offset(0, 1)),
          isTrue,
        );
        await tester.tapAt(button.bottomCenter - const Offset(0, 5));
        expect(taps, 1);
      },
    );
  }

  testWidgets('disabled raised action never calls a callback', (tester) async {
    await tester.pumpWidget(_app(_row(onPressed: null)));
    await tester.pumpAndSettle();
    final button = tester.getRect(_ink());
    await tester.tapAt(Offset(button.center.dx, button.top + 5));
    expect(tester.takeException(), isNull);
    expect(tester.widget<InkWell>(_ink()).onTap, isNull);
  });

  testWidgets('action runtime styles and removal update footprint and notch', (
    tester,
  ) async {
    BottomBarCenterActionStyle? style = BottomBarCenterActionStyle.inline;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return BottomBarItems(
              centerAction: style == null
                  ? null
                  : BottomBarCenterAction(
                      icon: const Icon(Icons.add),
                      semanticLabel: 'Create',
                      style: style!,
                      onPressed: () {},
                    ),
              children: const [SizedBox(height: 48), SizedBox(height: 48)],
            );
          },
        ),
      ),
    );
    for (final next in [
      BottomBarCenterActionStyle.raised,
      BottomBarCenterActionStyle.notched,
      BottomBarCenterActionStyle.inline,
      null,
      BottomBarCenterActionStyle.notched,
    ]) {
      update(() => style = next);
      await tester.pumpAndSettle();
      final surface = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      final lifted = next != null && next != BottomBarCenterActionStyle.inline;
      expect(surface.size.height, lifted ? 76 : 48);
      expect(
        surface.outline.notch != null,
        next == BottomBarCenterActionStyle.notched,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'raised action delivers transformed pointer events to ancestors',
    (tester) async {
      Offset? localPosition;
      const listenerKey = ValueKey('listener');
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Listener(
              key: listenerKey,
              onPointerDown: (event) => localPosition = event.localPosition,
              child: _row(onPressed: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.getRect(_ink());
      final point = Offset(button.center.dx, button.top + 5);
      await tester.tapAt(point);
      expect(localPosition, point - tester.getTopLeft(find.byKey(listenerKey)));
    },
  );

  for (final wrapper in <String, Widget Function(Widget)>{
    'IgnorePointer': (child) => IgnorePointer(child: child),
    'AbsorbPointer': (child) => AbsorbPointer(child: child),
    'Offstage': (child) => Offstage(child: child),
    'ClipRect': (child) => ClipRect(child: child),
  }.entries) {
    testWidgets('raised action respects ${wrapper.key}', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(wrapper.value(_row(onPressed: () => taps++))),
      );
      await tester.pumpAndSettle();
      final button = tester.getRect(_ink(skipOffstage: false));
      await tester.tapAt(Offset(button.center.dx, button.top + 5));
      expect(taps, 0);
    });
  }

  testWidgets('remaining row becomes raised after first row is removed', (
    tester,
  ) async {
    var first = true;
    late StateSetter update;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (first) _row(key: const ValueKey('first'), onPressed: () {}),
                _row(key: const ValueKey('second'), onPressed: () {}),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    update(() => first = false);
    await tester.pumpAndSettle();
    final action = tester.getRect(_ink());
    final surface = tester.getRect(find.byType(BarSurface));
    expect(action.top, surface.top);
    expect(surface.height, 76);
  });
}
