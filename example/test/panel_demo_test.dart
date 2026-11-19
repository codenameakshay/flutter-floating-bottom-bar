import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar_example/demos/panel_demo.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openPanelDemo(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: PanelDemoPage()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'create action fans out four actions and a pick shows a snackbar',
    (tester) async {
      await _openPanelDemo(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Link'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();
      expect(find.text('Created Note'), findsOneWidget);
      expect(find.text('Photo'), findsNothing);
    },
  );

  testWidgets('more panel filters the list and Escape closes it', (
    tester,
  ) async {
    await _openPanelDemo(tester);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'his');
    await tester.pump();
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Search'), findsNothing);
  });

  test('accessibility demo is the last registered demo', () {
    expect(demos.last.slug, 'accessibility');
  });
}
