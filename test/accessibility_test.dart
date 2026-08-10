import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'BottomBar passes platform tap-target, label, and contrast guidelines',
      (tester) async {
    await tester.pumpWidget(_buildAccessibilityHarness());
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets(
      'hidden BottomBar back action passes platform tap-target, label, and contrast guidelines',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_buildAccessibilityHarness());
      await tester.pumpAndSettle();

      expect(_semanticsLabels(tester), isNot(contains('Scroll to top')));

      await tester.dragFrom(const Offset(100, 100), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Scroll to top'), findsOneWidget);

      final labels =
          _semanticsLabels(tester).where((label) => label == 'Scroll to top');
      expect(labels, hasLength(1));

      final actionData = tester
          .getSemantics(find.bySemanticsLabel('Scroll to top'))
          .getSemanticsData();
      expect(actionData.label, 'Scroll to top');
      expect(actionData.flagsCollection.isButton, isTrue);
      expect(actionData.hasAction(SemanticsAction.tap), isTrue);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });
}

Widget _buildAccessibilityHarness() {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: Scaffold(
      body: BottomBar(
        theme: const BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
        ),
        body: ListView.builder(
          itemCount: 24,
          itemBuilder: (context, index) => ListTile(
            title: Text('Inbox item ${index + 1}'),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
                selected: true,
                onTap: _noop,
                color: Colors.black,
                selectedColor: Colors.black,
              ),
              BottomBarItem(
                icon: Icon(Icons.search),
                label: Text('Search'),
                onTap: _noop,
                color: Colors.black,
                selectedColor: Colors.black,
              ),
              BottomBarItem(
                icon: Icon(Icons.person_outline),
                label: Text('Profile'),
                onTap: _noop,
                color: Colors.black,
                selectedColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _noop() {}

Iterable<String> _semanticsLabels(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty);
}
