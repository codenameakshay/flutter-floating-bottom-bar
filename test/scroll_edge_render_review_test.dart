import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _surface(Animation<double> edge) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: RepaintBoundary(
      child: BarSurface(
        edge: edge,
        surface: const BottomBarSurface.glass(blur: 16, saturation: 1),
        edgeSurface: const BottomBarSurface.glass(blur: 4, saturation: 1),
        child: const SizedBox(width: 100, height: 40),
      ),
    ),
  ),
);

class _TrackedAnimation extends AlwaysStoppedAnimation<double> {
  _TrackedAnimation() : super(0);

  int listeners = 0;

  @override
  void addListener(VoidCallback listener) => listeners++;

  @override
  void removeListener(VoidCallback listener) => listeners--;
}

void main() {
  testWidgets(
    'edge endpoints preserve the notch and raised action hit target',
    (tester) async {
      final edge = AnimationController(vsync: tester);
      addTearDown(edge.dispose);
      final actionKey = GlobalKey();
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BarSurface(
              edge: edge,
              surface: const BottomBarSurface.glass(),
              edgeSurface: const BottomBarSurface(fillOpacity: 0),
              child: SizedBox(
                width: 200,
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CenterActionSlot(
                      width: 40,
                      lifted: true,
                      notched: true,
                      raise: 20,
                      notchMargin: 4,
                      child: GestureDetector(
                        key: actionKey,
                        behavior: HitTestBehavior.opaque,
                        onTap: () => taps++,
                        child: const SizedBox(width: 40, height: 40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      final child = render.child!;
      final rect = (child.parentData! as BoxParentData).offset & child.size;
      final initial = render.outline.getOuterPath(rect);
      expect(initial.contains(rect.topCenter + const Offset(0, 2)), isFalse);
      final actionRect = tester.getRect(find.byKey(actionKey));
      expect(actionRect.top, lessThan(render.localToGlobal(rect.topLeft).dy));
      for (final endpoint in [0.0, 1.0]) {
        edge.value = endpoint;
        await tester.pump();
        final path = render.outline.getOuterPath(rect);
        for (var x = 0.0; x < rect.width; x += 3) {
          for (var y = 0.0; y < rect.height; y += 3) {
            final point = rect.topLeft + Offset(x, y);
            expect(path.contains(point), initial.contains(point));
          }
        }
        expect(tester.getRect(find.byKey(actionKey)), actionRect);
        await tester.tapAt(actionRect.topCenter + const Offset(0, 5));
        expect(taps, endpoint == 0 ? 1 : 2);
        expect(
          tester.layers.whereType<BackdropFilterLayer>(),
          endpoint == 0 ? hasLength(1) : isEmpty,
        );
      }
    },
  );

  testWidgets(
    'edge listeners balance across swaps, reattachment and disposal',
    (tester) async {
      final first = _TrackedAnimation();
      final second = _TrackedAnimation();
      await tester.pumpWidget(_surface(first));
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      expect(first.listeners, 1);
      render.edge = second;
      expect(first.listeners, 0);
      expect(second.listeners, 1);
      final owner = render.owner!;
      final root = owner.rootNode!;
      root.detach();
      expect(second.listeners, 0);
      root.attach(owner);
      expect(second.listeners, 1);
      await tester.pumpWidget(const SizedBox());
      expect(first.listeners, 0);
      expect(second.listeners, 0);
    },
  );

  testWidgets(
    'zero blended blur releases retained backdrop handles immediately',
    (tester) async {
      final edge = AnimationController(vsync: tester);
      addTearDown(edge.dispose);
      await tester.pumpWidget(_surface(edge));
      final render = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      render.edgeSurface = const BottomBarSurface(fillOpacity: 0);
      final layers = tester.layers
          .where(
            (layer) => layer is ClipPathLayer || layer is BackdropFilterLayer,
          )
          .toList();
      expect(layers, hasLength(2));
      edge.value = 1;
      for (final layer in layers) {
        expect(layer.debugHandleCount, 1);
      }
      await tester.pump();
      expect(tester.layers.whereType<BackdropFilterLayer>(), isEmpty);
    },
  );
  testWidgets('reattach repaints an edge blend changed while detached', (
    tester,
  ) async {
    final edge = AnimationController(vsync: tester);
    addTearDown(edge.dispose);
    await tester.pumpWidget(_surface(edge));
    final backdrop = tester.layers.whereType<BackdropFilterLayer>().single;
    expect(backdrop.filter.toString(), contains('16.0'));
    final render = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    final owner = render.owner!;
    final root = owner.rootNode!;
    root.detach();
    edge.value = 1;
    root.attach(owner);
    await tester.pump();
    expect(
      tester.layers.whereType<BackdropFilterLayer>().single.filter.toString(),
      contains('4.0'),
    );
  });
}
