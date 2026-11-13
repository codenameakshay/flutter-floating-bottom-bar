import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/visibility_animator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final transition in [
    BottomBarTransition.slide,
    BottomBarTransition.slideAndFade,
  ]) {
    testWidgets('$transition mirrors both endpoints when direction changes', (
      tester,
    ) async {
      var progress = 0.0;
      Future<Rect> pump(TextDirection direction) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: direction,
            child: Center(
              child: VisibilityAnimator(
                animation: AlwaysStoppedAnimation(progress),
                isVisible: true,
                motion: BottomBarMotion.curved(
                  transition: transition,
                  slideStart: const Offset(-2, 0),
                  slideEnd: const Offset(0.25, 0),
                  directionalSlide: true,
                ),
                child: const SizedBox(
                  key: Key('moving'),
                  width: 100,
                  height: 50,
                ),
              ),
            ),
          ),
        );
        return tester.getRect(find.byKey(const Key('moving')));
      }

      final ltrHidden = await pump(TextDirection.ltr);
      final rtlHidden = await pump(TextDirection.rtl);
      expect(rtlHidden.left - ltrHidden.left, 400);
      progress = 1;
      final rtlShown = await pump(TextDirection.rtl);
      final ltrShown = await pump(TextDirection.ltr);
      expect(ltrShown.left - rtlShown.left, 50);
    });
  }

  for (final style in [
    BottomBarCenterActionStyle.raised,
    BottomBarCenterActionStyle.notched,
  ]) {
    for (final highContrast in [false, true]) {
      testWidgets(
        'docked $style keeps geometry with glass, contrast=$highContrast',
        (tester) async {
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          double height = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(400, 800),
                  padding: const EdgeInsets.only(bottom: 24),
                  highContrast: highContrast,
                ),
                child: BottomBar(
                  layout: const BottomBarLayout.docked(),
                  theme: const BottomBarThemeData(
                    surface: BottomBarSurface.glass(),
                    scrollEdgeSurface: BottomBarSurface.glass(blur: 12),
                  ),
                  body: Builder(
                    builder: (context) {
                      height = BottomBarScope.of(context).barHeight.value;
                      return ValueListenableBuilder<double>(
                        valueListenable: BottomBarScope.of(context).barHeight,
                        builder: (_, value, _) {
                          height = value;
                          return const SizedBox.expand();
                        },
                      );
                    },
                  ),
                  child: BottomBarItems(
                    selectedIndex: 0,
                    onSelected: (_) {},
                    centerAction: BottomBarCenterAction(
                      icon: const Icon(Icons.add),
                      tooltip: 'Create',
                      style: style,
                      onPressed: () {},
                    ),
                    children: const [
                      BottomBarItem(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      BottomBarItem(
                        icon: Icon(Icons.search),
                        label: Text('Search'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final finder = find.byType(BarSurface);
          final render = tester.renderObject<RenderBarSurface>(finder);
          final row = tester.getRect(find.byType(BottomBarItems));
          final surface = tester.getRect(finder);
          final action = tester.getRect(
            find.descendant(
              of: find.byType(BottomBarCenterAction),
              matching: find.byType(InkWell),
            ),
          );
          expect(surface.bottom, 800);
          expect(row.bottom, 776);
          expect(action.top, lessThan(row.top));
          expect(render.layoutRaise, greaterThan(0));
          expect(height, render.size.height);
          final notched = style == BottomBarCenterActionStyle.notched;
          expect(render.outline.notch != null, notched);
          final path = render.outline.getOuterPath(
            Rect.fromLTWH(
              0,
              0,
              render.size.width,
              render.size.height - render.layoutRaise,
            ),
          );
          expect(path.contains(Offset(render.size.width / 2, 1)), !notched);
          final widget = tester.widget<BarSurface>(finder);
          expect(widget.surface!.blur, highContrast ? 0 : 16);
          expect(widget.edgeSurface!.blur, highContrast ? 0 : 12);
          expect(
            tester.layers.whereType<BackdropFilterLayer>().isNotEmpty,
            !highContrast,
          );
        },
      );
    }
  }

  testWidgets(
    'directional radius reaches the outline and ink on direction flip',
    (tester) async {
      for (final direction in [TextDirection.ltr, TextDirection.rtl]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: BottomBar(
                layout: const BottomBarLayout(
                  width: 200,
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                  directionalBorderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(24),
                  ),
                ),
                body: const SizedBox.expand(),
                child: const SizedBox(height: 56),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final surface = find.byType(BarSurface);
        final render = tester.renderObject<RenderBarSurface>(surface);
        final path = render.outline.getOuterPath(
          const Rect.fromLTWH(0, 0, 200, 56),
          textDirection: direction,
        );
        expect(
          path.contains(const Offset(1, 1)),
          direction == TextDirection.rtl,
        );
        expect(
          path.contains(const Offset(199, 1)),
          direction == TextDirection.ltr,
        );
        final material = find
            .descendant(of: surface, matching: find.byType(Material))
            .first;
        final radius = tester.widget<Material>(material).borderRadius!;
        expect(
          radius.resolve(Directionality.of(tester.element(material))),
          direction == TextDirection.ltr
              ? const BorderRadius.only(topLeft: Radius.circular(24))
              : const BorderRadius.only(topRight: Radius.circular(24)),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
