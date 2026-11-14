import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final style in [
    BottomBarCenterActionStyle.raised,
    BottomBarCenterActionStyle.notched,
  ]) {
    testWidgets('minimized $style action does not intercept body taps', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      var actionTaps = 0;
      var bodyTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              layout: const BottomBarLayout(width: 320, offset: 0),
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => bodyTaps++,
                child: const SizedBox.expand(),
              ),
              child: BottomBarItems(
                selectedIndex: 0,
                onSelected: (_) {},
                centerAction: BottomBarCenterAction(
                  style: style,
                  semanticLabel: "Create",
                  icon: const Icon(Icons.add),
                  onPressed: () => actionTaps++,
                ),
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.descendant(
        of: find.byType(BottomBarCenterAction),
        matching: find.byType(InkWell),
      );
      final point = tester.getCenter(action);
      controller.minimize();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(actionTaps, 0);
      expect(bodyTaps, 1);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(actionTaps, 0);
      expect(bodyTaps, 2);
      expect(controller.visibility.value, BottomBarVisibility.minimized);
      controller.expand();
      await tester.pumpAndSettle();
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(actionTaps, 1);
    });
  }

  testWidgets('the rounded pill corners do not intercept body taps', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    var bodyTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => bodyTaps++,
            child: const SizedBox.expand(),
          ),
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    final surface = tester.renderObject<RenderBarSurface>(
      find.byType(BarSurface),
    );
    final corner = surface.outlineRect.topLeft + const Offset(1, 1);
    await tester.tapAt(surface.localToGlobal(corner));
    await tester.pumpAndSettle();
    expect(bodyTaps, 1);
    expect(controller.visibility.value, BottomBarVisibility.minimized);
  });
}
