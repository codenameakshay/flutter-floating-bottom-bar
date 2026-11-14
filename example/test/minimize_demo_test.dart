import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openMinimize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/minimize';
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('minimize page minimizes on scroll down', (tester) async {
    expect(demos.map((d) => d.slug), contains('minimize'));

    await _openMinimize(tester);
    expect(find.text('State: shown'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('State: minimized'), findsOneWidget);
  });

  testWidgets('now playing pill expands back to shown when tapped', (
    tester,
  ) async {
    await _openMinimize(tester);

    await tester.tap(find.text('Now playing pill'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Midnight City'), findsOneWidget);

    await tester.tap(find.text('Midnight City'));
    await tester.pumpAndSettle();
    expect(find.text('State: shown'), findsOneWidget);
  });

  testWidgets('never mode hides the bar on scroll', (tester) async {
    await _openMinimize(tester);

    await tester.tap(find.text('Never'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('State: hidden'), findsOneWidget);
  });
}
