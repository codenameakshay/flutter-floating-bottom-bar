import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  final motions = <String, BottomBarMotion>{
    for (final transition in BottomBarTransition.values)
      transition.name: BottomBarMotion(transition: transition),
    'custom': BottomBarMotion(
      transitionBuilder: (context, animation, child) => child,
    ),
  };
  for (final motion in motions.entries) {
    testWidgets('${motion.key} excludes all hidden group interactions', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      final nodes = List.generate(3, (_) => FocusNode());
      addTearDown(() {
        controller.dispose();
        for (final node in nodes) {
          node.dispose();
        }
      });
      var presses = 0;
      final labels = ['Leading', 'Pill', 'Trailing'];
      Widget button(int index) => IconButton(
        key: ValueKey(labels[index]),
        tooltip: labels[index],
        focusNode: nodes[index],
        onPressed: () => presses++,
        icon: const Icon(Icons.add),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBar(
            controller: controller,
            motion: motion.value,
            showIcon: false,
            leading: button(0),
            trailing: button(2),
            body: const SizedBox.expand(),
            child: SizedBox(height: 50, child: button(1)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final positions = [
        for (final label in labels)
          tester.getCenter(find.byKey(ValueKey(label))),
      ];
      nodes.first.requestFocus();
      await tester.pump();
      expect(nodes.first.hasFocus, isTrue);
      controller.hide();
      await tester.pump();
      expect(nodes.first.hasFocus, isFalse);
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].requestFocus();
        await tester.pump();
        expect(nodes[i].hasFocus, isFalse);
        await tester.tapAt(positions[i]);
      }
      await tester.pumpAndSettle();
      expect(presses, 0);
      final texts = tester.semantics.simulatedAccessibilityTraversal().expand(
        (node) => [node.label, node.tooltip],
      );
      for (final label in labels) {
        expect(texts, isNot(contains(label)));
      }
      controller.show();
      await tester.pumpAndSettle();
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].requestFocus();
        await tester.pump();
        expect(nodes[i].hasFocus, isTrue);
        await tester.tapAt(positions[i]);
      }
      expect(presses, 3);
      semantics.dispose();
    });
  }

  for (final leading in [true, false]) {
    testWidgets(
      'focused ${leading ? 'leading' : 'trailing'} prevents scroll hiding',
      (tester) async {
        final controller = BottomBarController();
        final focus = FocusNode();
        addTearDown(() {
          controller.dispose();
          focus.dispose();
        });
        final button = IconButton(
          focusNode: focus,
          onPressed: () {},
          icon: const Icon(Icons.add),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: BottomBar(
              controller: controller,
              leading: leading ? button : null,
              trailing: leading ? null : button,
              body: ListView(children: const [SizedBox(height: 3000)]),
              child: const SizedBox(height: 50),
            ),
          ),
        );
        await tester.pumpAndSettle();
        focus.requestFocus();
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(controller.isVisible, isTrue);
        focus.unfocus();
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(controller.isVisible, isFalse);
      },
    );
  }

  testWidgets(
    'keyboard and safe area move the whole group without changing its footprint',
    (tester) async {
      late BuildContext bodyContext;
      Future<void> pumpInset(double inset) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 30),
                viewInsets: EdgeInsets.only(bottom: inset),
              ),
              child: child!,
            ),
            home: BottomBar(
              layout: const BottomBarLayout(width: 500),
              leading: const SizedBox(width: 50),
              trailing: const SizedBox(width: 50),
              body: Builder(
                builder: (context) {
                  bodyContext = context;
                  return const SizedBox.expand();
                },
              ),
              child: const SizedBox(height: 50),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpInset(0);
      final slots = ['leading', 'pill', 'trailing'];
      final rects = [
        for (final slot in slots) tester.getRect(find.byKey(ValueKey(slot))),
      ];
      final height = BottomBarScope.of(bodyContext).barHeight.value;
      for (final rect in rects) {
        expect(rect.bottom, 560);
      }
      await pumpInset(200);
      expect(BottomBarScope.of(bodyContext).barHeight.value, height);
      for (var i = 0; i < slots.length; i++) {
        expect(
          tester.getRect(find.byKey(ValueKey(slots[i]))),
          rects[i].shift(const Offset(0, -200)),
        );
      }
    },
  );

  for (final direction in TextDirection.values) {
    testWidgets('raised group reading order in $direction', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: BottomBar(
              layout: const BottomBarLayout(width: 500),
              leading: IconButton(
                tooltip: 'Leading',
                onPressed: () {},
                icon: const Icon(Icons.person),
              ),
              trailing: IconButton(
                tooltip: 'Trailing',
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
              body: const SizedBox.expand(),
              child: BottomBarItems(
                selectedIndex: 0,
                onSelected: (_) {},
                centerAction: BottomBarCenterAction(
                  icon: const Icon(Icons.add),
                  semanticLabel: 'Create',
                  style: BottomBarCenterActionStyle.raised,
                  onPressed: () {},
                ),
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
      final slots = <Key?>[];
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        slots.add(
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<BarSurface>()
              ?.key,
        );
      }
      expect(slots, const [
        ValueKey('leading'),
        ValueKey('pill'),
        ValueKey('pill'),
        ValueKey('pill'),
        ValueKey('trailing'),
      ]);
      final texts = tester.semantics
          .simulatedAccessibilityTraversal()
          .expand((node) => [node.label, node.tooltip])
          .where((text) => text.isNotEmpty)
          .toList();
      expect(texts.indexOf('Leading'), lessThan(texts.indexOf('Home')));
      expect(texts.indexOf('Home'), lessThan(texts.indexOf('Create')));
      expect(texts.indexOf('Create'), lessThan(texts.indexOf('Inbox')));
      expect(texts.indexOf('Inbox'), lessThan(texts.indexOf('Trailing')));
      semantics.dispose();
    });
  }
}
