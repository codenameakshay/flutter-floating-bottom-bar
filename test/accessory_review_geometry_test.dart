import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_group.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('expanded height stays reserved for placement-specific content', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            layout: const BottomBarLayout(width: 360),
            accessory: Builder(
              builder: (context) => SizedBox(
                key: const ValueKey('placement-height'),
                height:
                    BottomBarAccessoryPlacement.of(context) ==
                        BottomBarAccessoryPlacement.expanded
                    ? 56
                    : 24,
              ),
            ),
            body: const SizedBox.expand(),
            child: BottomBarItems(
              selectedIndex: 0,
              onSelected: (_) {},
              children: const [
                BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              ],
            ),
          ),
        ),
      ),
    );

    final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
    final initialHeight = group.size.height;
    expect(initialHeight, 114);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(group.size.height, initialHeight);
  });

  testWidgets('dry layout matches a constrained accessory footprint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            height: 100,
            child: BarGroup(
              pillIndex: 0,
              spacing: 8,
              hasAccessory: true,
              children: [
                SizedBox(key: Key('pill'), height: 50),
                SizedBox(key: Key('accessory'), height: 56),
              ],
            ),
          ),
        ),
      ),
    );
    final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
    expect(group.size, const Size(300, 100));
    expect(group.getDryLayout(group.constraints), group.size);
  });

  testWidgets('accessory first mounted on an already minimized bar', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    Widget bar(Widget? accessory) => MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          layout: const BottomBarLayout(width: 360),
          accessory: accessory,
          body: const SizedBox.expand(),
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
            ],
          ),
        ),
      ),
    );

    await tester.pumpWidget(bar(null));
    controller.minimize();
    await tester.pumpAndSettle();
    await tester.pumpWidget(bar(const SizedBox(height: 56)));
    final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
    expect(group.size.height, 114);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dry layout retains expanded accessory height while inline', (
    tester,
  ) async {
    for (final progress in [0.0, 1.0, 0.0]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              child: BarGroup(
                pillIndex: 0,
                spacing: 8,
                hasAccessory: true,
                minimize: AlwaysStoppedAnimation(progress),
                children: [
                  BarSurface(
                    key: const ValueKey('direct-pill'),
                    child: MinimizeHost(
                      progress: AlwaysStoppedAnimation(progress),
                      minimized: progress == 1,
                      full: const SizedBox(height: 64),
                      compact: const SizedBox.square(dimension: 48),
                    ),
                  ),
                  SizedBox(height: progress == 0 ? 56 : 24),
                ],
              ),
            ),
          ),
        ),
      );
      final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
      expect(group.size.height, 128);
      expect(group.getDryLayout(group.constraints).height, 128);
      expect(group.getMinIntrinsicHeight(group.size.width), 128);
      expect(group.getMaxIntrinsicHeight(group.size.width), 128);
    }
  });
}
