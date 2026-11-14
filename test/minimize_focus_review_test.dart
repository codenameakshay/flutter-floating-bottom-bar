import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'controller minimizing excludes full content focus and expanding restores it',
    (tester) async {
      final controller = BottomBarController();
      final full = FocusNode();
      final compact = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(full.dispose);
      addTearDown(compact.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBar(
            controller: controller,
            body: const SizedBox.expand(),
            compactChild: SizedBox(
              width: 100,
              height: 48,
              child: TextField(focusNode: compact),
            ),
            child: SizedBox(height: 64, child: TextField(focusNode: full)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      full.requestFocus();
      await tester.pump();
      expect(full.hasFocus, isTrue);
      controller.minimize();
      await tester.pumpAndSettle();
      expect(full.hasFocus, isFalse);
      full.requestFocus();
      await tester.pump();
      expect(full.hasFocus, isFalse);
      compact.requestFocus();
      await tester.pump();
      expect(compact.hasFocus, isTrue);
      controller.expand();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(compact.hasFocus, isFalse);
      compact.requestFocus();
      await tester.pump();
      expect(compact.hasFocus, isFalse);
      await tester.pumpAndSettle();
      full.requestFocus();
      await tester.pump();
      expect(full.hasFocus, isTrue);
      controller.minimize();
      await tester.pumpAndSettle();
      compact.requestFocus();
      await tester.pump();
      expect(compact.hasFocus, isTrue);
      controller.hide();
      await tester.pumpAndSettle();
      expect(compact.hasFocus, isFalse);
      compact.requestFocus();
      await tester.pump();
      expect(compact.hasFocus, isFalse);
      controller.show();
      await tester.pumpAndSettle();
      full.requestFocus();
      await tester.pump();
      expect(full.hasFocus, isTrue);
    },
  );

  for (final keepVisible in [true, false]) {
    testWidgets('scroll minimize respects keepVisibleOnFocus=$keepVisible', (
      tester,
    ) async {
      final controller = BottomBarController();
      final full = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(full.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBar(
            controller: controller,
            scrollBehavior: BottomBarScrollBehavior(
              minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
              keepVisibleOnFocus: keepVisible,
            ),
            body: ListView(children: const [SizedBox(height: 4000)]),
            compactChild: const SizedBox.square(dimension: 48),
            child: SizedBox(height: 64, child: TextField(focusNode: full)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      full.requestFocus();
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(
        controller.visibility.value,
        keepVisible ? BottomBarVisibility.shown : BottomBarVisibility.minimized,
      );
      expect(full.hasFocus, keepVisible);
    });
  }

  testWidgets('selected icon changes during the minimize morph', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    late StateSetter update;
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return BottomBar(
              controller: controller,
              body: const SizedBox.expand(),
              child: BottomBarItems(
                selectedIndex: selected,
                onSelected: (_) {},
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    update(() => selected = 1);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(DefaultCompactPill),
        matching: find.byIcon(Icons.search),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(DefaultCompactPill),
        matching: find.byIcon(Icons.home),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    controller.expand();
    await tester.pumpAndSettle();
    expect(find.byType(CompactPillButton), findsNothing);
  });
}
