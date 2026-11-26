import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'fixtures/row_label_behavior_sentinel.dart';

const _items = [
  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
  BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
];

void main() {
  test('the package barrel keeps its row label helper hidden', () {
    // These unprefixed imports make a barrel export collide with the sentinel.
    expect(rowLabelBehavior, 'fixture sentinel');
  });

  test('labelBehavior stays non-nullable with the 3.1.0 default', () {
    final unset = const BottomBarItems(children: []);
    final explicitlyNull = const BottomBarItems(
      labelBehavior: null,
      children: [],
    );
    final set = const BottomBarItems(
      labelBehavior: BottomBarLabelBehavior.alwaysHide,
      children: [],
    );

    // This is the 3.1.0 consumer expression, which must not become nullable.
    final int legacyIndex = unset.labelBehavior.index;
    expect(legacyIndex, BottomBarLabelBehavior.alwaysShow.index);
    expect(explicitlyNull.labelBehavior, unset.labelBehavior);
    expect(set.labelBehavior, BottomBarLabelBehavior.alwaysHide);
  });

  Widget bar(BottomBarItems items) => MaterialApp(
    home: Scaffold(
      body: BottomBar(
        theme: BottomBarThemeData.minimal(),
        body: const SizedBox.expand(),
        child: items,
      ),
    ),
  );

  testWidgets('a row with no labelBehavior follows the theme', (tester) async {
    await tester.pumpWidget(
      bar(const BottomBarItems(selectedIndex: 0, children: _items)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('an explicit row labelBehavior beats the theme', (tester) async {
    await tester.pumpWidget(
      bar(
        const BottomBarItems(
          selectedIndex: 0,
          labelBehavior: BottomBarLabelBehavior.alwaysShow,
          children: _items,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });

  group('rail', () {
    Future<void> pumpRail(WidgetTester tester, BottomBarItems items) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 800);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarAdaptive(
              theme: BottomBarThemeData.minimal(),
              items: items,
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<BottomBarItems>(find.byType(BottomBarItems)).direction,
        Axis.vertical,
      );
    }

    testWidgets('a row with no labelBehavior follows the theme', (
      tester,
    ) async {
      await pumpRail(
        tester,
        const BottomBarItems(selectedIndex: 0, children: _items),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('an explicit row labelBehavior beats the theme', (
      tester,
    ) async {
      await pumpRail(
        tester,
        const BottomBarItems(
          selectedIndex: 0,
          labelBehavior: BottomBarLabelBehavior.alwaysShow,
          children: _items,
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });
  });
}
