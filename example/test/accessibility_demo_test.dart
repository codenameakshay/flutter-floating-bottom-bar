import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar_example/demos/accessibility_demo.dart';

void _setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _setTextScale(WidgetTester tester, double value) async {
  final slider = tester.widget<Slider>(find.byType(Slider));
  slider.onChanged!(value);
  await tester.pump();
}

Future<void> _toggle(WidgetTester tester, String label) async {
  await Scrollable.ensureVisible(
    tester.element(find.text(label)),
    alignment: 0.5,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

List<String> _semanticsLabels(WidgetTester tester) => [
  for (final node in tester.semantics.simulatedAccessibilityTraversal())
    if (node.label.isNotEmpty) node.label,
];

void main() {
  testWidgets('text scale 1x, 2x and 3x lay out without overflow', (
    tester,
  ) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: AccessibilityDemoPage()));
    await tester.pumpAndSettle();

    for (final value in [1.0, 2.0, 3.0]) {
      await _setTextScale(tester, value);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'scale $value');
    }
  });

  testWidgets('German strings give German bar labels and badge announcements', (
    tester,
  ) async {
    _setPhoneSurface(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: AccessibilityDemoPage()));
    await tester.pumpAndSettle();

    await _setTextScale(tester, 1);
    await tester.pumpAndSettle();
    await _toggle(tester, 'German strings');

    final labels = _semanticsLabels(tester);
    expect(
      labels,
      containsAll(['Posteingang, 3 neu, Tab 2 von 4', 'Verfassen']),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('right to left and high contrast render without exception', (
    tester,
  ) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: AccessibilityDemoPage()));
    await tester.pumpAndSettle();

    await _toggle(tester, 'Right to left');
    expect(tester.takeException(), isNull);

    await _toggle(tester, 'High contrast');
    expect(tester.takeException(), isNull);
  });
}
