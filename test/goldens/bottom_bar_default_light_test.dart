import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('default Material 3 light theme', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: Scaffold(
        body: BottomBar(
          body: const SizedBox.shrink(),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('Bar')),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(BottomBar),
      matchesGoldenFile('bottom_bar_default_light.png'),
    );
  });
}
