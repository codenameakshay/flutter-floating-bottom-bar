import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

List<BottomBarItem> _items(int count) {
  const tabs = <(IconData, String)>[
    (Icons.home, 'Home'),
    (Icons.search, 'Search'),
    (Icons.inbox, 'Inbox'),
    (Icons.person, 'Profile'),
  ];
  return [
    for (var i = 0; i < count; i++)
      BottomBarItem(
        key: ValueKey(i),
        icon: Icon(tabs[i].$1),
        label: Text(tabs[i].$2),
      ),
  ];
}

Future<void> pumpBar(
  WidgetTester tester, {
  BottomBarThemeData? theme,
  ThemeData? appTheme,
  bool highContrast = false,
  Widget? child,
  BottomBarController? controller,
  BottomBarMotion? motion,
  BottomBarLayout? layout,
  bool withLayout = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: appTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: child!,
      ),
      home: Scaffold(
        body: BottomBar(
          body: ListView.builder(
            itemCount: 50,
            itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
          ),
          layout: withLayout
              ? layout ?? const BottomBarLayout(width: 360)
              : null,
          theme: theme,
          controller: controller,
          motion: motion,
          child: child ?? BottomBarItems(children: _items(4)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<BackdropFilterLayer> _backdrops(WidgetTester tester) =>
    tester.layers.whereType<BackdropFilterLayer>().toList();

BackdropFilterLayer _onlyBackdrop(WidgetTester tester) {
  final layers = _backdrops(tester);
  expect(layers, hasLength(1));
  return layers.single;
}

Offset _layerOrigin(Layer layer) {
  var origin = Offset.zero;
  for (Layer? node = layer.parent; node != null; node = node.parent) {
    if (node is OffsetLayer) origin += node.offset;
  }
  return origin;
}

BarSurface _barSurfaceWidget(WidgetTester tester) =>
    tester.widget<BarSurface>(find.byType(BarSurface));

void _expectSameRect(Rect actual, Rect expected) {
  expect(actual.left, closeTo(expected.left, 0.01));
  expect(actual.top, closeTo(expected.top, 0.01));
  expect(actual.right, closeTo(expected.right, 0.01));
  expect(actual.bottom, closeTo(expected.bottom, 0.01));
}

void main() {
  testWidgets('a bar with no surface reads no backdrop', (tester) async {
    await pumpBar(tester);

    expect(_backdrops(tester), isEmpty);
  });

  testWidgets('a glass surface reads the backdrop inside a clip', (
    tester,
  ) async {
    await pumpBar(
      tester,
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
    );

    final backdrop = _onlyBackdrop(tester);
    expect(backdrop.parent, isA<ClipPathLayer>());
  });

  testWidgets('glass with zero blur reads no backdrop', (tester) async {
    await pumpBar(
      tester,
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass(blur: 0)),
    );

    expect(_backdrops(tester), isEmpty);
  });

  testWidgets('a solid surface reads no backdrop', (tester) async {
    await pumpBar(
      tester,
      theme: const BottomBarThemeData(surface: BottomBarSurface.solid()),
    );

    expect(_backdrops(tester), isEmpty);
  });

  for (final transition in BottomBarTransition.values) {
    testWidgets('a hidden glass bar reads no backdrop with $transition', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await pumpBar(
        tester,
        controller: controller,
        motion: BottomBarMotion(transition: transition),
        theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
      );
      expect(_backdrops(tester), hasLength(1));

      controller.hide();
      await tester.pumpAndSettle();
      expect(_backdrops(tester), isEmpty);

      controller.show();
      await tester.pumpAndSettle();
      expect(_backdrops(tester), hasLength(1));
    });
  }

  testWidgets('the glass clip is the bar outline with its notch cut', (
    tester,
  ) async {
    await pumpBar(
      tester,
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
      child: BottomBarItems(
        centerAction: BottomBarCenterAction(
          icon: const Icon(Icons.add),
          tooltip: 'Create',
          style: BottomBarCenterActionStyle.notched,
          onPressed: () {},
        ),
        children: _items(4),
      ),
    );

    final render = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    expect(render.outline.notch, isNotNull);
    final child = render.child!;
    final barRect = (child.parentData! as BoxParentData).offset & child.size;
    final origin = render.localToGlobal(Offset.zero);
    final expected = render.outline.getOuterPath(barRect).shift(origin);

    final clip = _onlyBackdrop(tester).parent! as ClipPathLayer;
    final actual = clip.clipPath!.shift(_layerOrigin(clip));

    _expectSameRect(actual.getBounds(), expected.getBounds());
    final sampled = expected.getBounds().inflate(2);
    for (var x = sampled.left; x <= sampled.right; x += 4) {
      for (var y = sampled.top; y <= sampled.bottom; y += 4) {
        final point = Offset(x, y);
        expect(
          actual.contains(point),
          expected.contains(point),
          reason: 'clip and outline disagree at $point',
        );
      }
    }

    final globalRect = barRect.shift(origin);
    expect(
      actual.contains(globalRect.centerLeft + const Offset(20, 0)),
      isTrue,
    );
    expect(actual.contains(globalRect.topCenter + const Offset(0, 2)), isFalse);
  });

  testWidgets('high contrast paints no blur and uses the default fill', (
    tester,
  ) async {
    await pumpBar(
      tester,
      highContrast: true,
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
    );

    expect(_backdrops(tester), isEmpty);
    final surface = _barSurfaceWidget(tester).surface!;
    final scheme = Theme.of(
      tester.element(find.byType(BarSurface)),
    ).colorScheme;
    expect(surface.blur, 0);
    expect(surface.tint, scheme.surfaceContainer);
    expect(surface.shadows, BottomBarSurface.glass().shadows);
  });

  testWidgets('high contrast fills with fallbackColor', (tester) async {
    await pumpBar(
      tester,
      highContrast: true,
      theme: const BottomBarThemeData(
        surface: BottomBarSurface.glass(fallbackColor: Colors.red),
      ),
    );

    final surface = _barSurfaceWidget(tester).surface!;
    expect(surface.blur, 0);
    expect(surface.tint, Colors.red);
  });

  testWidgets('surface replaces the barDecoration fill and shadows but keeps '
      'its radius', (tester) async {
    await pumpBar(
      tester,
      withLayout: false,
      theme: BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
        ),
        surface: const BottomBarSurface.solid(color: Colors.blue),
      ),
    );

    final bar = _barSurfaceWidget(tester);
    expect(bar.decoration!.color, isNull);
    expect(bar.decoration!.boxShadow, isNull);
    expect(bar.decoration!.borderRadius, BorderRadius.circular(10));
    expect(bar.surface!.tint, Colors.blue);
  });

  testWidgets('an explicit layout radius overrides the barDecoration radius', (
    tester,
  ) async {
    await pumpBar(
      tester,
      layout: BottomBarLayout(
        width: 360,
        borderRadius: BorderRadius.circular(4),
      ),
      theme: BottomBarThemeData(
        barDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        surface: const BottomBarSurface.solid(color: Colors.blue),
      ),
    );

    expect(
      _barSurfaceWidget(tester).decoration!.borderRadius,
      BorderRadius.circular(4),
    );
  });

  test('lerp blends a solid surface into glass', () {
    const a = BottomBarSurface.solid(color: Color(0xFF000000));
    const b = BottomBarSurface.glass(tint: Color(0xFF000000));

    expect(BottomBarSurface.lerp(a, b, 0), a);
    expect(BottomBarSurface.lerp(a, b, 1), b);
    final middle = BottomBarSurface.lerp(a, b, 0.5)!;
    expect(middle.blur, 8);
    expect(middle.fillOpacity, 0.9);
    expect(middle.saturation, 1.3);
  });

  test('lerp against a null surface steps at halfway', () {
    const b = BottomBarSurface.glass(tint: Color(0xFF000000));

    expect(BottomBarSurface.lerp(null, b, 0.4), isNull);
    expect(BottomBarSurface.lerp(null, b, 0.6), b);
  });

  test('copyWith replaces only the given fields', () {
    final base = BottomBarSurface.glass(blur: 10);
    final changed = base.copyWith(blur: 3);

    expect(changed.blur, 3);
    expect(changed.saturation, base.saturation);
    expect(changed.tint, base.tint);
    expect(changed.fillOpacity, base.fillOpacity);
    expect(changed.copyWith(blur: 10), base);
  });

  test('equal surfaces are equal and differ when a field differs', () {
    final a = BottomBarSurface.glass(blur: 10);
    final b = BottomBarSurface.glass(blur: 10);
    final c = BottomBarSurface.glass(blur: 11);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == c, isFalse);
  });

  test('theme merge and copyWith replace the surface', () {
    final x = BottomBarSurface.glass(blur: 10);
    final y = BottomBarSurface.glass(blur: 20);
    final themed = BottomBarThemeData(surface: x);

    expect(themed.merge(BottomBarThemeData(surface: y)).surface, y);
    expect(themed.merge(const BottomBarThemeData()).surface, x);
    expect(themed.copyWith(surface: y).surface, y);
  });

  test('theme lerp interpolates the surface', () {
    const a = BottomBarThemeData(surface: BottomBarSurface.glass(blur: 10));
    const b = BottomBarThemeData(surface: BottomBarSurface.glass(blur: 20));

    expect(a.lerp(b, 0.5).surface!.blur, 15);
  });

  testWidgets('a surface from ThemeData extensions sets the blur', (
    tester,
  ) async {
    const extension = BottomBarThemeData(
      surface: BottomBarSurface.glass(blur: 5),
    );
    await pumpBar(tester, appTheme: ThemeData(extensions: const [extension]));

    expect(_barSurfaceWidget(tester).surface!.blur, 5);
  });

  testWidgets('a BottomBar theme surface overrides the ThemeData extension', (
    tester,
  ) async {
    const extension = BottomBarThemeData(
      surface: BottomBarSurface.glass(blur: 5),
    );
    await pumpBar(
      tester,
      appTheme: ThemeData(extensions: const [extension]),
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass(blur: 9)),
    );

    expect(_barSurfaceWidget(tester).surface!.blur, 9);
  });

  for (final transition in [
    BottomBarTransition.fade,
    BottomBarTransition.slideAndFade,
  ]) {
    testWidgets('a fading glass bar keeps its blur out of opacity layers '
        'with $transition', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await pumpBar(
        tester,
        controller: controller,
        motion: BottomBarMotion.curved(
          duration: const Duration(milliseconds: 400),
          transition: transition,
        ),
        theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
      );

      controller.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final backdrop = _onlyBackdrop(tester);
      for (Layer? node = backdrop.parent; node != null; node = node.parent) {
        if (node is OpacityLayer) {
          expect(node.alpha, anyOf(isNull, 255), reason: 'fades the backdrop');
        }
      }
      final blur = backdrop.filter.toString();
      expect(
        blur,
        isNot(contains('16.0')),
        reason: 'blur scales with the fade',
      );
      expect(
        tester.layers.whereType<OpacityLayer>().map((l) => l.alpha),
        contains(inExclusiveRange(0, 255)),
        reason: 'the items fade',
      );

      await tester.pumpAndSettle();
      expect(_backdrops(tester), isEmpty);
    });
  }
}
