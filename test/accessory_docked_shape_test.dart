import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a docked accessory rounds into a capsule beside the pill', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          layout: const BottomBarLayout.docked(),
          accessory: const SizedBox(height: 56),
          body: const SizedBox.expand(),
          child: const BottomBarItems(
            selectedIndex: 0,
            children: [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    RenderBarSurface accessory() =>
        tester.renderObject<RenderBarSurface>(find.byType(BarSurface).last);
    expect(
      accessory().outline.borderRadius,
      BorderRadius.zero,
      reason: 'expanded, the accessory keeps the docked bar radius',
    );

    controller.minimize();
    await tester.pumpAndSettle();
    final height = accessory().size.height;
    expect(height, greaterThan(0));
    expect(
      accessory().outline.borderRadius,
      BorderRadius.circular(height / 2),
      reason: 'inline, it is a capsule like the pill beside it',
    );
  });
}
