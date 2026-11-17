import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('adaptive rail accessory remains exposed and focused at bottom', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var reservedHeight = 0.0;
    BottomBarAccessoryPlacement? placement;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: BottomBarAdaptive(
              items: BottomBarItems(
                selectedIndex: 0,
                onSelected: (_) {},
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                ],
              ),
              body: Builder(
                builder: (context) {
                  final height = BottomBarScope.of(context).barHeight;
                  return BottomBarBodyPadding(
                    child: ValueListenableBuilder<double>(
                      valueListenable: height,
                      builder: (context, value, child) {
                        reservedHeight = value;
                        return child!;
                      },
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
              accessory: Builder(
                builder: (context) {
                  placement = BottomBarAccessoryPlacement.of(context);
                  return Focus(
                    focusNode: focusNode,
                    child: IconButton(
                      key: const Key('accessory-control'),
                      tooltip: 'Play',
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accessory-control')), findsOneWidget);
    expect(placement, BottomBarAccessoryPlacement.expanded);
    expect(reservedHeight, greaterThan(0));
    expect(
      tester.getBottomLeft(find.byKey(const Key('accessory-control'))).dy,
      lessThan(700),
    );
    expect(
      tester.semantics.simulatedAccessibilityTraversal().expand(
        (node) => [node.label, node.tooltip],
      ),
      contains('Play'),
    );
    handle.dispose();

    focusNode.requestFocus();
    await tester.pump();
    tester.view.physicalSize = const Size(400, 700);
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus,
      focusNode,
      reason: 'moving the accessory between rail and bar keeps its focus',
    );
    expect(find.byKey(const Key('accessory-control')), findsOneWidget);
  });

  testWidgets('adaptive rail places accessory at the body bottom in RTL', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(900, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BottomBarAdaptive(
              items: BottomBarItems(
                selectedIndex: 0,
                onSelected: (_) {},
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                ],
              ),
              body: const SizedBox.expand(),
              accessory: const SizedBox(
                key: Key('accessory'),
                width: 120,
                height: 40,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final accessoryRect = tester.getRect(find.byKey(const Key('accessory')));
    final railItemsRect = tester.getRect(find.byType(BottomBarItems));
    expect(accessoryRect.center.dx, lessThan(railItemsRect.center.dx));
    expect(accessoryRect.bottom, lessThanOrEqualTo(700));
    expect(accessoryRect.bottom, greaterThan(600));
  });
}
