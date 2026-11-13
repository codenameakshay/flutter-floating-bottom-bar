import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  BottomBarController? controller,
  BottomBarMotion motion = const BottomBarMotion.curved(),
  bool highContrast = false,
  bool settle = true,
  Widget body = const SizedBox.expand(),
  Widget child = const SizedBox(height: 56),
  BottomBarLayout? layout,
  TextDirection textDirection = TextDirection.ltr,
  BottomBarSurface surface = const BottomBarSurface.glass(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: child!,
      ),
      home: Directionality(
        textDirection: textDirection,
        child: BottomBar(
          controller: controller,
          showIcon: false,
          motion: motion,
          theme: BottomBarThemeData(surface: surface),
          layout: layout,
          scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
          body: body,
          child: child,
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

BackdropFilterLayer _backdrop(WidgetTester tester) =>
    tester.layers.whereType<BackdropFilterLayer>().single;

void main() {
  testWidgets('high contrast makes a translucent fallback opaque', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      highContrast: true,
      surface: const BottomBarSurface.glass(fallbackColor: Color(0x40887766)),
    );
    final surface = tester.widget<BarSurface>(find.byType(BarSurface)).surface!;
    expect(surface.tint, const Color(0xFF887766));
    expect(surface.fillOpacity, 1);
    expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
  });

  for (final transition in [
    BottomBarTransition.slide,
    BottomBarTransition.scale,
  ]) {
    testWidgets(
      '$transition retains surface pictures between animation ticks',
      (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await _pumpBar(
          tester,
          controller: controller,
          motion: BottomBarMotion.curved(
            duration: const Duration(milliseconds: 400),
            curve: Curves.linear,
            transition: transition,
          ),
        );
        controller.hide();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final picture = _backdrop(tester).firstChild;
        expect(picture, isA<PictureLayer>());
        await tester.pump(const Duration(milliseconds: 100));
        expect(_backdrop(tester).firstChild, same(picture));
        await tester.pumpAndSettle();
        expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
        controller.show();
        await tester.pumpAndSettle();
        expect(tester.layers.whereType<BackdropFilterLayer>(), hasLength(1));
      },
    );
  }
  testWidgets(
    'a custom translation retains the surface and removes hidden blur',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pumpBar(
        tester,
        controller: controller,
        motion: BottomBarMotion.curved(
          duration: const Duration(milliseconds: 400),
          curve: Curves.linear,
          transitionBuilder: (_, animation, child) => Transform.translate(
            offset: Offset(0, 60 * (1 - animation.value)),
            child: child,
          ),
        ),
      );
      controller.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final picture = _backdrop(tester).firstChild;
      await tester.pump(const Duration(milliseconds: 100));
      expect(_backdrop(tester).firstChild, same(picture));
      await tester.pumpAndSettle();
      expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
    },
  );

  testWidgets('body scrolling retains the surface picture', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _pumpBar(
      tester,
      body: ListView.builder(
        controller: scroll,
        itemCount: 100,
        itemBuilder: (_, i) => SizedBox(height: 50, child: Text('$i')),
      ),
    );
    final picture = _backdrop(tester).firstChild;
    for (final offset in [50.0, 100.0, 150.0]) {
      scroll.jumpTo(offset);
      await tester.pump();
      expect(_backdrop(tester).firstChild, same(picture));
    }
  });

  testWidgets(
    'RTL notch clip follows maxWidth and rotation in the same frame',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(500, 800);
      addTearDown(tester.view.reset);
      final child = BottomBarItems(
        centerAction: BottomBarCenterAction(
          icon: const Icon(Icons.add),
          tooltip: 'Create',
          style: BottomBarCenterActionStyle.notched,
          onPressed: () {},
        ),
        children: const [
          BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
          BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
        ],
      );
      Future<void> resize(double maxWidth) => _pumpBar(
        tester,
        settle: false,
        textDirection: TextDirection.rtl,
        child: child,
        layout: BottomBarLayout(
          width: double.infinity,
          maxWidth: maxWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(24),
          ),
        ),
      );
      void expectCurrentClip(double width) {
        final render = tester.renderObject<RenderBarSurface>(
          find.byType(BarSurface),
        );
        final box = render.child!;
        final rect = (box.parentData! as BoxParentData).offset & box.size;
        expect(rect.width, width);
        final expected = render.outline.getOuterPath(
          rect,
          textDirection: TextDirection.rtl,
        );
        final actual = (_backdrop(tester).parent! as ClipPathLayer).clipPath!;
        final actualOrigin = actual.getBounds().topLeft;
        final expectedOrigin = expected.getBounds().topLeft;
        expect(actual.getBounds().size, expected.getBounds().size);
        for (var x = 0.0; x < rect.width; x += 3) {
          for (var y = 0.0; y < rect.height; y += 3) {
            final point = Offset(x, y);
            expect(
              actual.contains(actualOrigin + point),
              expected.contains(expectedOrigin + point),
            );
          }
        }
        expect(expected.contains(rect.topCenter + const Offset(0, 2)), isFalse);
      }

      await resize(380);
      expectCurrentClip(380);
      await resize(280);
      expectCurrentClip(280);
      tester.view.physicalSize = const Size(800, 500);
      await tester.pump();
      expectCurrentClip(280);
      await resize(620);
      expectCurrentClip(620);
    },
  );
  for (final transition in [
    BottomBarTransition.fade,
    BottomBarTransition.slideAndFade,
  ]) {
    testWidgets(
      '$transition approaches both fade endpoints without a blur pop',
      (tester) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await _pumpBar(
          tester,
          controller: controller,
          surface: const BottomBarSurface.glass(saturation: 1),
          motion: BottomBarMotion.curved(
            duration: const Duration(milliseconds: 400),
            curve: Curves.linear,
            transition: transition,
          ),
        );
        void expectFade(double opacity) {
          final backdrop = _backdrop(tester);
          final sigmas = RegExp(
            r'ImageFilter.blur\(([^,]+), ([^,]+),',
          ).firstMatch(backdrop.filter.toString())!;
          for (final group in [1, 2]) {
            expect(
              double.parse(sigmas.group(group)!),
              closeTo(16 * opacity, 1e-9),
            );
          }
          final alpha = tester.layers
              .whereType<OpacityLayer>()
              .where((layer) => layer.alpha != 255)
              .single
              .alpha!;
          expect(alpha, closeTo(255 * opacity, 1));
          for (
            Layer? layer = backdrop.parent;
            layer != null;
            layer = layer.parent
          ) {
            if (layer is OpacityLayer) expect(layer.alpha, 255);
          }
        }

        controller.hide();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expectFade(399 / 400);
        await tester.pump(const Duration(milliseconds: 398));
        expectFade(1 / 400);
        await tester.pumpAndSettle();
        expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
        controller.show();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expectFade(1 / 400);
        await tester.pump(const Duration(milliseconds: 398));
        expectFade(399 / 400);
        await tester.pumpAndSettle();
      },
    );
  }
}
