import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(double? pressedScale, {bool enabled = true}) => MaterialApp(
  themeAnimationDuration: Duration.zero,
  theme: ThemeData(
    extensions: [
      BottomBarThemeData(
        items: BottomBarItemThemeData(pressedScale: pressedScale),
      ),
    ],
  ),
  home: Scaffold(
    body: Center(
      child: BottomBarItem(
        icon: const Icon(Icons.home),
        onTap: enabled ? () {} : null,
      ),
    ),
  ),
);

double _scale(WidgetTester tester) => tester
    .widget<Transform>(
      find.ancestor(
        of: find.byIcon(Icons.home),
        matching: find.byType(Transform),
      ),
    )
    .transform
    .storage[0];

Widget _selectedApp(
  Widget icon,
  Widget selectedIcon,
  bool selected, {
  Motion? motion,
}) => MaterialApp(
  themeAnimationDuration: Duration.zero,
  theme: ThemeData(
    extensions: [
      BottomBarThemeData(
        items: BottomBarItemThemeData(
          color: Colors.black,
          selectedColor: Colors.white,
          motion: motion,
        ),
      ),
    ],
  ),
  home: Scaffold(
    body: Center(
      child: BottomBarItem(
        icon: icon,
        selectedIcon: selectedIcon,
        selected: selected,
      ),
    ),
  ),
);

double _progress(WidgetTester tester) =>
    IconTheme.of(tester.element(find.byIcon(Icons.home).first)).color!.r;

void main() {
  testWidgets('disposing a pressed item stops its controller', (tester) async {
    await tester.pumpWidget(_app(0.8));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(const SizedBox.shrink());
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reparenting a pressed item releases its press state', (
    tester,
  ) async {
    final key = GlobalKey();
    Widget app(bool moved) => MaterialApp(
      theme: ThemeData(
        extensions: const [
          BottomBarThemeData(items: BottomBarItemThemeData(pressedScale: 0.8)),
        ],
      ),
      home: Scaffold(
        body: Row(
          children: [
            for (final slot in [false, true])
              SizedBox(
                width: 100,
                child: slot == moved
                    ? BottomBarItem(
                        key: key,
                        icon: const Icon(Icons.home),
                        onTap: () {},
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(app(false));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(0.8, 0.001));
    await tester.pumpWidget(app(true));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
    expect(tester.binding.transientCallbackCount, 0);
  });

  for (final disable in [false, true]) {
    testWidgets(
      'press resets on ${disable ? 'disable' : 'pointer cancellation'}',
      (tester) async {
        await tester.pumpWidget(_app(0.8));
        final gesture = await tester.startGesture(
          tester.getCenter(find.byIcon(Icons.home)),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        expect(_scale(tester), closeTo(0.8, 0.001));
        if (disable) {
          await tester.pumpWidget(_app(0.8, enabled: false));
        } else {
          await gesture.cancel();
        }
        await tester.pumpAndSettle();
        expect(_scale(tester), 1);
        if (disable) await gesture.up();
      },
    );
  }

  testWidgets('pressedScale changes retarget an active press', (tester) async {
    await tester.pumpWidget(_app(0.8));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.home)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(0.8, 0.001));
    await tester.pumpWidget(_app(0.6));
    expect(_scale(tester), closeTo(0.8, 0.001));
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(0.6, 0.001));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
  });

  testWidgets('reused icon with a nested GlobalKey is not mounted twice', (
    tester,
  ) async {
    final key = GlobalKey();
    final icon = Padding(
      padding: const EdgeInsets.all(1),
      child: Icon(Icons.home, key: key),
    );
    await tester.pumpWidget(_selectedApp(icon, icon, false));
    await tester.pumpWidget(_selectedApp(icon, icon, true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('motion changes preserve selection progress mid-flight', (
    tester,
  ) async {
    Widget app(bool selected, Motion motion) => _selectedApp(
      const Icon(Icons.home),
      const Icon(Icons.home),
      selected,
      motion: motion,
    );
    const slow = CupertinoMotion.smooth(duration: Duration(seconds: 2));
    const fast = CupertinoMotion.snappy(duration: Duration(milliseconds: 200));
    await tester.pumpWidget(app(false, slow));
    await tester.pumpWidget(app(true, slow));
    await tester.pump(const Duration(milliseconds: 100));
    final before = _progress(tester);
    expect(before, inExclusiveRange(0, 1));
    await tester.pumpWidget(app(true, fast));
    expect(_progress(tester), closeTo(before, 1e-6));
    await tester.pumpAndSettle();
    expect(_progress(tester), 1);
  });

  testWidgets('platform reduced motion stops active item controllers', (
    tester,
  ) async {
    final dispatcher = tester.binding.platformDispatcher;
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: false,
    );
    Widget app(bool selected) =>
        _selectedApp(const Icon(Icons.home), const Icon(Icons.home), selected);
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_progress(tester), inExclusiveRange(0, 1));
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    await tester.pump();
    expect(_progress(tester), 1);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: false,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final sameWidget in [true, false]) {
    testWidgets('crossfade supports a shared GlobalKey ($sameWidget)', (
      tester,
    ) async {
      final key = GlobalKey();
      final icon = Icon(Icons.home_outlined, key: key);
      final selectedIcon = sameWidget ? icon : Icon(Icons.home, key: key);
      await tester.pumpWidget(_selectedApp(icon, selectedIcon, false));
      await tester.pumpWidget(_selectedApp(icon, selectedIcon, true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
    });
  }

  testWidgets(
    'removing pressedScale during a press does not retain the press',
    (tester) async {
      await tester.pumpWidget(_app(0.8));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.home)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(_scale(tester), closeTo(0.8, 0.001));

      await tester.pumpWidget(_app(null));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(0.8));
      await tester.pumpAndSettle();
      expect(_scale(tester), 1);
    },
  );
}
