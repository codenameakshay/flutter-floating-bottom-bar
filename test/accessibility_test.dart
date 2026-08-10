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
        body: ListView(
          children: const [
            ListTile(title: Text('Inbox item 1')),
            ListTile(title: Text('Inbox item 2')),
            ListTile(title: Text('Inbox item 3')),
          ],
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
