import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openSwitcher(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/switcher';
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();
}

Finder _tile(int index) => find
    .descendant(
      of: find.byType(GridView),
      matching: find.byType(GestureDetector),
    )
    .at(index);

void main() {
  testWidgets('switcher demo starts on the nav dock', (tester) async {
    await _openSwitcher(tester);

    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('long press selects a tile and shows the selection dock', (
    tester,
  ) async {
    await _openSwitcher(tester);

    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Library'), findsNothing);
  });

  testWidgets('tapping another tile in selection mode adds it', (tester) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();

    await tester.tap(_tile(1));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('compose opens the composer and close returns to selection', (
    tester,
  ) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Compose'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('cancel clears the selection and restores the nav dock', (
    tester,
  ) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
  });
}
