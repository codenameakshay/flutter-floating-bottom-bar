import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';

const _labels = ['Home', 'Search', 'Inbox', 'Profile'];

Widget _items({int selected = 0, Key? key}) => BottomBarItems(
  key: key,
  selectedIndex: selected,
  onSelected: (_) {},
  children: [
    for (var i = 0; i < _labels.length; i++)
      BottomBarItem(
        icon: const Icon(Icons.circle_outlined),
        selectedIcon: const Icon(Icons.circle),
        label: Text(_labels[i]),
      ),
  ],
);

bool focusIn(Type type, {Key? key}) {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  var found = false;
  ctx.visitAncestorElements((e) {
    if ((key != null && e.widget.key == key) ||
        (key == null && e.widget.runtimeType == type)) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

String? _focusedItemLabel() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  final item = ctx?.findAncestorWidgetOfExactType<BottomBarItem>();
  final label = item?.label;
  return label is Text ? label.data : null;
}

Future<void> _pumpBar(
  WidgetTester tester, {
  required BottomBarController controller,
  Widget? child,
  Widget? body,
  BottomBarScrollBehavior? scrollBehavior,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: BottomBar(
            controller: controller,
            scrollBehavior: scrollBehavior ?? const BottomBarScrollBehavior(),
            body: body ?? const SizedBox.expand(),
            child: child ?? _items(selected: 2),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a custom compactChild is the pill and one semantics node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: BottomBar(
              controller: controller,
              body: const SizedBox.expand(),
              compactChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note),
                  const Text('Midnight City'),
                  IconButton(
                    onPressed: () {},
                    tooltip: 'Pause',
                    icon: const Icon(Icons.pause),
                  ),
                ],
              ),
              child: _items(selected: 2),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();

    final pillNode = tester.getSemantics(find.byType(CompactPillButton));
    expect(
      pillNode,
      isSemantics(
        label: 'Midnight City',
        hint: 'Expand',
        isButton: true,
        hasTapAction: true,
      ),
    );
    final data = pillNode.getSemanticsData();
    for (final action in SemanticsAction.values) {
      expect(
        data.hasAction(action),
        action == SemanticsAction.tap,
        reason: action.name,
      );
    }
    expect(
      semanticsLabels(tester).where((label) => label.contains('Midnight City')),
      hasLength(1),
    );
    handle.dispose();
  });

  testWidgets('the default pill keeps the selected item label', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.byType(CompactPillButton)).label, 'Inbox');
    handle.dispose();
  });

  testWidgets('the pill reports a collapsed expanded state', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.byType(CompactPillButton)),
      isSemantics(hasExpandedState: true, isExpanded: false),
    );
    handle.dispose();
  });

  testWidgets('a semantics tap on the pill expands the bar', (tester) async {
    final handle = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);

    tester.semantics.tap(find.semantics.byLabel('Inbox'));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    handle.dispose();
  });

  testWidgets(
    'minimizing with focus inside the items moves focus to the pill',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      const itemsKey = Key('items');
      await _pumpBar(
        tester,
        controller: controller,
        child: _items(selected: 2, key: itemsKey),
      );

      var reached = false;
      for (var i = 0; i < 8 && !reached; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        reached = focusIn(Null, key: itemsKey);
      }
      expect(reached, isTrue);

      controller.minimize();
      await tester.pumpAndSettle();
      expect(focusIn(CompactPillButton), isTrue);
    },
  );

  testWidgets('minimizing does not pull focus from a body text field', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final field = FocusNode(debugLabel: 'body field');
    addTearDown(field.dispose);
    await _pumpBar(
      tester,
      controller: controller,
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 200, child: TextField(focusNode: field)),
      ),
    );

    field.requestFocus();
    await tester.pump();
    expect(field.hasPrimaryFocus, isTrue);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(focusIn(CompactPillButton), isFalse);
  });

  testWidgets('minimizing with no focus leaves focus off the pill', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(focusIn(CompactPillButton), isFalse);
  });

  for (final (name, key) in [
    ('Enter', LogicalKeyboardKey.enter),
    ('Space', LogicalKeyboardKey.space),
  ]) {
    testWidgets('$name on the focused pill expands to the selected item', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      const itemsKey = Key('items');
      await _pumpBar(
        tester,
        controller: controller,
        child: _items(selected: 2, key: itemsKey),
      );

      var reached = false;
      for (var i = 0; i < 8 && !reached; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        reached = focusIn(Null, key: itemsKey);
      }
      expect(reached, isTrue);

      controller.minimize();
      await tester.pumpAndSettle();
      expect(focusIn(CompactPillButton), isTrue);

      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.shown);
      expect(_focusedItemLabel(), 'Inbox');
    });
  }

  testWidgets('a tap on the pill expands and focuses the selected item', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(tester, controller: controller);

    controller.minimize();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CompactPillButton));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(_focusedItemLabel(), 'Inbox');
  });

  testWidgets('expanding by controller moves focus off the unmounted pill', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    const itemsKey = Key('items');
    await _pumpBar(
      tester,
      controller: controller,
      child: _items(selected: 2, key: itemsKey),
    );

    var reached = false;
    for (var i = 0; i < 8 && !reached; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      reached = focusIn(Null, key: itemsKey);
    }
    expect(reached, isTrue);

    controller.minimize();
    await tester.pumpAndSettle();
    expect(focusIn(CompactPillButton), isTrue);

    controller.expand();
    await tester.pumpAndSettle();
    expect(find.byType(CompactPillButton), findsNothing);
    expect(_focusedItemLabel(), 'Inbox');
  });

  testWidgets('Tab never lands on the offstage items while minimized', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    const itemsKey = Key('items');
    await _pumpBar(
      tester,
      controller: controller,
      child: _items(selected: 2, key: itemsKey),
    );

    controller.minimize();
    await tester.pumpAndSettle();

    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusIn(Null, key: itemsKey), isFalse);
    }
  });

  testWidgets('scroll and tap minimize and expand without any announcement', (
    tester,
  ) async {
    final messages = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        messages.add(message);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );

    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(
      tester,
      controller: controller,
      scrollBehavior: const BottomBarScrollBehavior(
        minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
      ),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Row $i')),
      ),
    );

    final seen = <BottomBarVisibility>[];
    void record() => seen.add(controller.visibility.value);
    controller.visibility.addListener(record);
    addTearDown(() => controller.visibility.removeListener(record));

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(seen, contains(BottomBarVisibility.minimized));

    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);

    controller.minimize();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CompactPillButton));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);

    expect(
      messages.whereType<Map>().where((m) => m['type'] == 'announce'),
      isEmpty,
    );
  });
}
