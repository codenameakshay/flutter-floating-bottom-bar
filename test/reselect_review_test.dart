import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/demos/indicators_demo.dart';

void main() {
  testWidgets('account menu tolerates the demo being disposed', (tester) async {
    final visible = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, show, child) =>
              show ? const IndicatorsDemoPage() : const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(BottomBarItem).last);
    await tester.pumpAndSettle();
    expect(find.text('Work'), findsOneWidget);
    visible.value = false;
    await tester.pump();
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    visible.dispose();
  });

  testWidgets('long-press-only item is enabled for assistive technology', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBarItem(
            key: const ValueKey('item'),
            icon: const Icon(Icons.home),
            semanticLabel: 'Home',
            onLongPress: () => presses++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final node = tester.getSemantics(find.byKey(const ValueKey('item')));
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.longPress),
      isTrue,
    );
    expect(
      node.getSemanticsData().flagsCollection.isEnabled,
      ui.Tristate.isTrue,
    );
    node.owner!.performAction(node.id, SemanticsAction.longPress);
    await tester.pump();
    expect(presses, 1);
    semantics.dispose();
  });
}
