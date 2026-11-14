import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('extension labels apply outside and inside BottomBar', (
    tester,
  ) async {
    const extension = BottomBarThemeData(
      items: BottomBarItemThemeData(
        labelBehavior: BottomBarLabelBehavior.onlySelected,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [extension]),
        home: Scaffold(
          body: Column(
            children: [
              BottomBarItems(
                selectedIndex: 0,
                children: const [
                  BottomBarItem(
                    icon: Icon(Icons.home),
                    label: Text('Outside A'),
                  ),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Outside B'),
                  ),
                ],
              ),
              Expanded(
                child: BottomBar(
                  body: const SizedBox.expand(),
                  child: BottomBarItems(
                    selectedIndex: 1,
                    children: const [
                      BottomBarItem(
                        icon: Icon(Icons.home),
                        label: Text('Inside A'),
                      ),
                      BottomBarItem(
                        icon: Icon(Icons.search),
                        label: Text('Inside B'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Outside A'), findsOneWidget);
    expect(find.text('Outside B'), findsNothing);
    expect(find.text('Inside A'), findsNothing);
    expect(find.text('Inside B'), findsOneWidget);
  });

  test(
    'minimal preset merges over material3 with its indicator and labels',
    () {
      final merged = BottomBarThemeData.material3().merge(
        BottomBarThemeData.minimal(),
      );

      expect(merged.items!.labelBehavior, BottomBarLabelBehavior.onlySelected);
      expect(
        merged.items!.indicator,
        BottomBarThemeData.minimal().items!.indicator,
      );
      expect(merged.layout, BottomBarThemeData.minimal().layout);
    },
  );

  testWidgets('switching presets keeps the controlled selection', (
    tester,
  ) async {
    Future<void> pump(BottomBarThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              theme: theme,
              body: const SizedBox.expand(),
              child: BottomBarItems(
                selectedIndex: 1,
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('First')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Second'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(BottomBarThemeData.material3());
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);

    await pump(BottomBarThemeData.minimal());
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
  });
}
