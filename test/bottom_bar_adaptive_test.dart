import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    await tester.pumpAndSettle();
  }

  Widget app({required int index, ValueChanged<int>? onSelected}) =>
      MaterialApp(
        home: Scaffold(
          body: BottomBarAdaptive(
            items: BottomBarItems(
              selectedIndex: index,
              onSelected: onSelected,
              indicator: const BottomBarIndicator.pill(),
              children: const [
                BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
                BottomBarItem(icon: Icon(Icons.person), label: Text('Me')),
              ],
            ),
            body: Column(
              children: [
                const TextField(key: Key('field')),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < 100; i++)
                        ListTile(title: Text('Row $i')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('keeps the body state and index across the breakpoint', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 400);
    var index = 1;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) =>
            app(index: index, onSelected: (i) => setState(() => index = i)),
      ),
    );
    expect(find.byType(BottomBar), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field')), 'typed');
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    await setWidth(tester, 900);
    expect(find.byType(BottomBar), findsNothing);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);

    await setWidth(tester, 400);
    expect(find.byType(BottomBar), findsOneWidget);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(find.text('typed'), findsOneWidget);
    expect(index, 1);
    final items = tester.widget<BottomBarItems>(find.byType(BottomBarItems));
    expect(items.selectedIndex, 1);
  });
}
