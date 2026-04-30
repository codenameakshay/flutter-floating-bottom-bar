import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarItem', () {
    testWidgets('renders icon, swaps to selectedIcon when selected',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BottomBarItem(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: const Text('Home'),
            selected: true,
          ),
        ),
      ));
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('renders badge when supplied', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BottomBarItem(
            icon: const Icon(Icons.inbox),
            badge: Container(
              key: const Key('badge'),
              width: 8,
              height: 8,
              color: const Color(0xFFFF0000),
            ),
          ),
        ),
      ));
      expect(find.byKey(const Key('badge')), findsOneWidget);
    });

    testWidgets('onTap fires on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BottomBarItem(
            icon: const Icon(Icons.add),
            onTap: () => taps++,
          ),
        ),
      ));
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    });
  });

  testWidgets('BottomBarItems renders children in a Row', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBarItems(
          children: [
            BottomBarItem(icon: const Icon(Icons.home)),
            BottomBarItem(icon: const Icon(Icons.search)),
          ],
        ),
      ),
    ));
    expect(find.byType(Row), findsOneWidget);
    expect(find.byType(BottomBarItem), findsNWidgets(2));
  });
}
