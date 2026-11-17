import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

String? _focusedControl() {
  String? result;
  FocusManager.instance.primaryFocus?.context?.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is CompactPillButton) {
      result = 'pill';
      return false;
    }
    if (widget is BottomBarItem) {
      result = (widget.label! as Text).data;
      return false;
    }
    if (widget.key case ValueKey<String>(:final value)) {
      if (['body', 'leading', 'accessory', 'trailing'].contains(value)) {
        result = value;
        return false;
      }
    }
    return true;
  });
  return result;
}

Future<List<String?>> _tabOrder(WidgetTester tester, int count) async {
  final result = <String?>[];
  for (var i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    result.add(_focusedControl());
  }
  return result;
}

List<String> _spokenControls(WidgetTester tester) => tester.semantics
    .simulatedAccessibilityTraversal()
    .expand((node) => [node.label, node.tooltip])
    .where(
      (label) =>
          ['accessory', 'leading', 'Home', 'Inbox', 'trailing'].contains(label),
    )
    .toList();

Future<double> _pumpToProgress(
  WidgetTester tester,
  double target, {
  bool expanding = false,
}) async {
  double progress() =>
      tester.widget<MinimizeHost>(find.byType(MinimizeHost)).progress.value;
  await tester.pump();
  for (
    var i = 0;
    i < 100 && (expanding ? progress() > target : progress() < target);
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(progress(), inExclusiveRange(0, 1));
  return progress();
}

Future<BottomBarController> _pumpBar(
  WidgetTester tester,
  TextDirection direction, {
  FocusNode? accessoryFocus,
  Widget? accessory,
  Widget? body,
}) async {
  tester.view
    ..physicalSize = const Size(500, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = BottomBarController();
  addTearDown(controller.dispose);
  Widget control(String name, IconData icon, {FocusNode? focusNode}) =>
      IconButton(
        key: ValueKey(name),
        tooltip: name,
        focusNode: focusNode,
        onPressed: () {},
        icon: Icon(icon),
      );
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: BottomBar(
          controller: controller,
          layout: const BottomBarLayout(width: 460),
          leading: control('leading', Icons.menu),
          trailing: control('trailing', Icons.search),
          accessory:
              accessory ??
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    control(
                      'accessory',
                      Icons.play_arrow,
                      focusNode: accessoryFocus,
                    ),
                  ],
                ),
              ),
          body: body ?? const SizedBox.expand(),
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('body is read and focused before the ordered bar pieces', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _pumpBar(
        tester,
        TextDirection.ltr,
        body: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: TextButton(
              key: const ValueKey('body'),
              onPressed: () {},
              child: const Text('Body'),
            ),
          ),
        ),
      );
      expect(await _tabOrder(tester, 6), [
        'body',
        'accessory',
        'leading',
        'Home',
        'Inbox',
        'trailing',
      ]);
      expect(
        tester.semantics
            .simulatedAccessibilityTraversal()
            .expand((node) => [node.label, node.tooltip])
            .where(
              (label) => [
                'Body',
                'accessory',
                'leading',
                'Home',
                'Inbox',
                'trailing',
              ].contains(label),
            ),
        ['Body', 'accessory', 'leading', 'Home', 'Inbox', 'trailing'],
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('bar without an accessory keeps inherited custom focus order', (
    tester,
  ) async {
    Widget control(String name, String order) => FocusTraversalOrder(
      order: LexicalFocusOrder(order),
      child: IconButton(
        key: ValueKey(name),
        onPressed: () {},
        icon: const Icon(Icons.circle),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: BottomBar(
            leading: control('leading', 'z'),
            trailing: control('trailing', 'a'),
            body: const SizedBox.expand(),
            child: control('accessory', 'm'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(await _tabOrder(tester, 3), ['trailing', 'accessory', 'leading']);
  });

  for (final side in ['leading', 'trailing']) {
    for (final initiallyPresent in [false, true]) {
      testWidgets(
        '$side state survives accessory ${initiallyPresent ? 'removal' : 'addition'}',
        (tester) async {
          final focusNode = FocusNode();
          addTearDown(focusNode.dispose);
          late StateSetter update;
          var present = initiallyPresent;
          await tester.pumpWidget(
            MaterialApp(
              home: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  final field = SizedBox(
                    width: 80,
                    child: TextField(
                      key: const Key('side-field'),
                      focusNode: focusNode,
                    ),
                  );
                  return BottomBar(
                    layout: const BottomBarLayout(width: 460),
                    leading: side == 'leading' ? field : null,
                    trailing: side == 'trailing' ? field : null,
                    accessory: present ? const SizedBox(height: 56) : null,
                    body: const SizedBox.expand(),
                    child: const SizedBox(height: 64),
                  );
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byKey(const Key('side-field')), 'draft');
          expect(focusNode.hasPrimaryFocus, isTrue);
          update(() => present = !present);
          await tester.pumpAndSettle();
          expect(focusNode.hasPrimaryFocus, isTrue);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            'draft',
          );
        },
      );
    }
  }

  testWidgets('accessory custom focus order stays local to its piece', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      TextDirection.ltr,
      accessory: FocusTraversalOrder(
        order: const LexicalFocusOrder('play'),
        child: IconButton(
          key: const ValueKey('accessory'),
          tooltip: 'accessory',
          onPressed: () {},
          icon: const Icon(Icons.play_arrow),
        ),
      ),
    );
    expect(await _tabOrder(tester, 5), [
      'accessory',
      'leading',
      'Home',
      'Inbox',
      'trailing',
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final direction in TextDirection.values) {
    testWidgets('expanded keyboard order follows the rows in $direction', (
      tester,
    ) async {
      await _pumpBar(tester, direction);
      expect(await _tabOrder(tester, 5), [
        'accessory',
        'leading',
        'Home',
        'Inbox',
        'trailing',
      ]);
    });

    testWidgets('minimized keyboard order follows the row in $direction', (
      tester,
    ) async {
      final controller = await _pumpBar(tester, direction);
      controller.minimize();
      await tester.pumpAndSettle();
      expect(await _tabOrder(tester, 4), [
        'leading',
        'pill',
        'accessory',
        'trailing',
      ]);
    });

    for (final progress in [0.25, 0.75]) {
      testWidgets(
        'minimizing keyboard uses minimized order near $progress in $direction',
        (tester) async {
          final controller = await _pumpBar(tester, direction);
          controller.minimize();
          final actualProgress = await _pumpToProgress(tester, progress);
          expect(await _tabOrder(tester, 4), [
            'leading',
            'pill',
            'accessory',
            'trailing',
          ], reason: 'minimize progress $actualProgress');
        },
      );

      testWidgets(
        'minimizing semantics use minimized order near $progress in $direction',
        (tester) async {
          final handle = tester.ensureSemantics();
          try {
            final controller = await _pumpBar(tester, direction);
            controller.minimize();
            final actualProgress = await _pumpToProgress(tester, progress);
            expect(_spokenControls(tester), [
              'leading',
              'Home',
              'accessory',
              'trailing',
            ], reason: 'minimize progress $actualProgress');
          } finally {
            handle.dispose();
          }
        },
      );

      testWidgets(
        'expanding keyboard uses expanded order near $progress in $direction',
        (tester) async {
          final controller = await _pumpBar(tester, direction);
          controller.minimize();
          await tester.pumpAndSettle();
          controller.expand();
          final actualProgress = await _pumpToProgress(
            tester,
            progress,
            expanding: true,
          );
          expect(await _tabOrder(tester, 5), [
            'accessory',
            'leading',
            'Home',
            'Inbox',
            'trailing',
          ], reason: 'expansion progress $actualProgress');
        },
      );

      testWidgets(
        'expanding semantics use expanded order near $progress in $direction',
        (tester) async {
          final handle = tester.ensureSemantics();
          try {
            final controller = await _pumpBar(tester, direction);
            controller.minimize();
            await tester.pumpAndSettle();
            controller.expand();
            final actualProgress = await _pumpToProgress(
              tester,
              progress,
              expanding: true,
            );
            expect(
              _spokenControls(tester),
              ['accessory', 'leading', 'Home', 'Inbox', 'trailing'],
              reason: 'expansion progress $actualProgress',
            );
          } finally {
            handle.dispose();
          }
        },
      );
    }

    testWidgets('accessory retains focus while minimizing in $direction', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final controller = await _pumpBar(
        tester,
        direction,
        accessoryFocus: focusNode,
      );
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasPrimaryFocus, isTrue);
      controller.minimize();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(focusNode.hasPrimaryFocus, isTrue);
      await tester.pumpAndSettle();
      expect(focusNode.hasPrimaryFocus, isTrue);
      controller.expand();
      await tester.pumpAndSettle();
      expect(focusNode.hasPrimaryFocus, isTrue);
    });

    testWidgets('hiding evicts and blocks accessory focus in $direction', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final controller = await _pumpBar(
        tester,
        direction,
        accessoryFocus: focusNode,
      );
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasPrimaryFocus, isTrue);
      controller.hide();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      await tester.pumpAndSettle();
      expect(await _tabOrder(tester, 5), isNot(contains('accessory')));
    });

    testWidgets('semantics follow both accessory placements in $direction', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = await _pumpBar(tester, direction);
      expect(_spokenControls(tester), [
        'accessory',
        'leading',
        'Home',
        'Inbox',
        'trailing',
      ]);
      controller.minimize();
      await tester.pumpAndSettle();
      expect(_spokenControls(tester), [
        'leading',
        'Home',
        'accessory',
        'trailing',
      ]);
      controller.hide();
      await tester.pumpAndSettle();
      expect(_spokenControls(tester), isEmpty);
      handle.dispose();
    });
  }
}
