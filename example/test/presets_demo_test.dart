import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openPresets(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/presets';
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('presets page switches presets, dark mode and scrolls', (
    tester,
  ) async {
    expect(demos.last.slug, 'presets');

    await _openPresets(tester);
    expect(find.text('BottomBarThemeData.glass()'), findsOneWidget);

    await tester.tap(find.text('M3'));
    await tester.pumpAndSettle();
    expect(find.text('BottomBarThemeData.material3()'), findsOneWidget);

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    final selectedColor = Theme.of(
      tester.element(find.byType(BottomBar)),
    ).colorScheme.onSecondaryContainer;
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.explore_rounded))).color,
      selectedColor,
    );

    await tester.tap(find.text('Pill'));
    await tester.pumpAndSettle();
    expect(find.text('BottomBarThemeData.pill()'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);

    await tester.tap(find.text('Minimal'));
    await tester.pumpAndSettle();
    expect(find.text('BottomBarThemeData.minimal()'), findsOneWidget);

    await tester.tap(find.byTooltip('Dark mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(BottomBar))).brightness,
      Brightness.dark,
    );

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
