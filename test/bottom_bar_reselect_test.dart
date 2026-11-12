import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

BottomBarItem _item(
  int index, {
  Widget? label,
  String? tooltip,
  String? semanticLabel,
  VoidCallback? onLongPress,
}) {
  return BottomBarItem(
    key: ValueKey(index),
    icon: Icon(_tabs[index].$1),
    label: label ?? Text(_tabs[index].$2),
    tooltip: tooltip,
    semanticLabel: semanticLabel,
    onLongPress: onLongPress,
  );
}

List<Widget> _items(int count) => [for (var i = 0; i < count; i++) _item(i)];

ListView _list({Key? key, ScrollController? controller}) {
  return ListView.builder(
    key: key,
    controller: controller,
    itemCount: 100,
    itemBuilder: (context, i) => ListTile(title: Text('Row $i')),
  );
}

BottomBarThemeData _hapticTheme(BottomBarHaptics haptics) {
  return BottomBarThemeData(items: BottomBarItemThemeData(haptics: haptics));
}

List<Object?> _recordHaptics(WidgetTester tester) {
  final haptics = <Object?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return haptics;
}

Widget _bar({
  required Widget Function(int index) body,
  BottomBarController? controller,
  BottomBarThemeData? theme,
  int initialIndex = 0,
  List<Widget>? items,
  double width = 400,
  bool scrollToStartOnReselect = false,
  bool dragToSelect = false,
  BottomBarIndicator? indicator,
  ValueChanged<int>? onSelected,
  ValueChanged<int>? onReselected,
  ValueChanged<int>? onLongPressed,
}) {
  var index = initialIndex;
  return MaterialApp(
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => BottomBar(
          controller: controller,
          theme: theme,
          scrollBehavior: const BottomBarScrollBehavior(deltaThreshold: 10000),
          body: body(index),
          child: SizedBox(
            width: width,
            child: BottomBarItems(
              selectedIndex: index,
              indicator: indicator,
              dragToSelect: dragToSelect,
              scrollToStartOnReselect: scrollToStartOnReselect,
              onSelected: (i) {
                setState(() => index = i);
                onSelected?.call(i);
              },
              onReselected: onReselected,
              onLongPressed: onLongPressed,
              children: items ?? _items(3),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('reselect', () {
    testWidgets(
      'onReselected fires only when the selected item is tapped again',
      (tester) async {
        final selected = <int>[];
        final reselected = <int>[];
        await tester.pumpWidget(
          _bar(
            body: (_) => const SizedBox(),
            onSelected: selected.add,
            onReselected: reselected.add,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey(1)));
        await tester.pumpAndSettle();
        expect(reselected, isEmpty);
        expect(selected, [1]);

        await tester.tap(find.byKey(const ValueKey(1)));
        await tester.pumpAndSettle();
        expect(reselected, [1]);
        expect(selected, [1, 1]);
      },
    );

    testWidgets(
      'reselect without scrollToStartOnReselect leaves the list offset',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _bar(body: (_) => _list(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        final offset = controller.offset;
        expect(offset, greaterThan(0));

        await tester.tap(find.byKey(const ValueKey(0)));
        await tester.pumpAndSettle();
        expect(controller.offset, offset);
      },
    );

    testWidgets('scrollToStartOnReselect scrolls only the visible list', (
      tester,
    ) async {
      final listA = ScrollController();
      final listB = ScrollController();
      addTearDown(listA.dispose);
      addTearDown(listB.dispose);
      await tester.pumpWidget(
        _bar(
          items: _items(2),
          scrollToStartOnReselect: true,
          body: (index) => IndexedStack(
            index: index,
            children: [
              _list(key: const ValueKey('list-a'), controller: listA),
              _list(key: const ValueKey('list-b'), controller: listB),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('list-a')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('list-b')),
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey(0)));
      await tester.pumpAndSettle();

      expect(listA.offset, greaterThan(0));
      final offsetB = listB.offset;
      expect(offsetB, greaterThan(0));

      await tester.tap(find.byKey(const ValueKey(0)));
      await tester.pumpAndSettle();
      expect(listA.offset, 0);
      expect(listB.offset, offsetB);
    });

    testWidgets(
      'reselect shows a hidden bar and scrolls the list to its start',
      (tester) async {
        final controller = BottomBarController();
        final list = ScrollController();
        addTearDown(list.dispose);
        await tester.pumpWidget(
          _bar(
            controller: controller,
            scrollToStartOnReselect: true,
            body: (_) => _list(controller: list),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(list.offset, greaterThan(0));

        controller.hide();
        await tester.pumpAndSettle();
        expect(controller.isVisible, isFalse);

        tester
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(const ValueKey(0)),
                matching: find.byType(InkWell),
              ),
            )
            .onTap!();
        await tester.pumpAndSettle();
        expect(controller.isVisible, isTrue);
        expect(list.offset, 0);
      },
    );

    testWidgets(
      'reselect returns a NestedScrollView header and inner list to the top',
      (tester) async {
        final nestedKey = GlobalKey<NestedScrollViewState>();
        await tester.pumpWidget(
          _bar(
            scrollToStartOnReselect: true,
            body: (_) => NestedScrollView(
              key: nestedKey,
              headerSliverBuilder: (_, _) => const [
                SliverAppBar(
                  pinned: false,
                  expandedHeight: 200,
                  title: Text('Header'),
                ),
              ],
              body: _list(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final headerTop = tester.getTopLeft(find.text('Header')).dy;

        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();
        final nested = nestedKey.currentState!;
        expect(find.text('Header'), findsNothing);
        expect(nested.innerController.position.pixels, greaterThan(0));

        await tester.tap(find.byKey(const ValueKey(0)));
        await tester.pumpAndSettle();
        expect(nested.innerController.position.pixels, 0);
        expect(nested.outerController.position.pixels, 0);
        expect(
          tester.getTopLeft(find.text('Header')).dy,
          closeTo(headerTop, 0.01),
        );
      },
    );

    testWidgets(
      'scrollToStartOnReselect outside a BottomBar does nothing and does not throw',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final reselected = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  BottomBarItems(
                    selectedIndex: 0,
                    scrollToStartOnReselect: true,
                    onReselected: reselected.add,
                    children: _items(3),
                  ),
                  Expanded(child: _list(controller: controller)),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        final offset = controller.offset;
        expect(offset, greaterThan(0));

        await tester.tap(find.byKey(const ValueKey(0)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(reselected, [0]);
        expect(controller.offset, offset);
      },
    );

    testWidgets(
      'the scroll starts before onReselected, which runs before onSelected',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        final log = <String>[];
        var scrollingInReselect = false;
        await tester.pumpWidget(
          _bar(
            scrollToStartOnReselect: true,
            body: (_) => _list(controller: controller),
            onReselected: (i) {
              log.add('reselected $i');
              scrollingInReselect =
                  controller.position.isScrollingNotifier.value;
            },
            onSelected: (i) => log.add('selected $i'),
          ),
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey(0)));
        await tester.pumpAndSettle();

        expect(scrollingInReselect, isTrue);
        expect(log, ['reselected 0', 'selected 0']);
      },
    );
  });

  group('haptics', () {
    testWidgets('default haptics stay silent on select and reselect', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(_bar(body: (_) => const SizedBox()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();

      expect(haptics, isEmpty);
    });

    testWidgets('selectionClick fires on every tap, including reselect', (
      tester,
    ) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(
        _bar(
          theme: _hapticTheme(BottomBarHaptics.selectionClick),
          body: (_) => const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();
      expect(haptics, ['HapticFeedbackType.selectionClick']);

      await tester.tap(find.byKey(const ValueKey(1)));
      await tester.pumpAndSettle();
      expect(haptics, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });

    testWidgets('lightImpact fires on tap', (tester) async {
      final haptics = _recordHaptics(tester);
      await tester.pumpWidget(
        _bar(
          theme: _hapticTheme(BottomBarHaptics.lightImpact),
          body: (_) => const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey(2)));
      await tester.pumpAndSettle();
      expect(haptics, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets(
      'dragToSelect clicks on each item crossed and fires the release haptic',
      (tester) async {
        final haptics = _recordHaptics(tester);
        final selected = <int>[];
        await tester.pumpWidget(
          _bar(
            theme: _hapticTheme(BottomBarHaptics.lightImpact),
            items: _items(4),
            indicator: const BottomBarIndicator.pill(),
            dragToSelect: true,
            body: (_) => const SizedBox(),
            onSelected: selected.add,
          ),
        );
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey(0))),
        );
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey(1))));
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey(2))));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(haptics, [
          'HapticFeedbackType.selectionClick',
          'HapticFeedbackType.selectionClick',
          'HapticFeedbackType.lightImpact',
        ]);
        expect(selected, [2]);
      },
    );
  });

  group('long press', () {
    testWidgets('item onLongPress runs before the row onLongPressed', (
      tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(
        _bar(
          body: (_) => const SizedBox(),
          onLongPressed: (i) => log.add('row $i'),
          items: [
            _item(0),
            _item(1),
            _item(2, onLongPress: () => log.add('item')),
            _item(3),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byKey(const ValueKey(2)));
      await tester.pumpAndSettle();
      expect(log, ['item', 'row 2']);
    });

    testWidgets(
      'tooltip stays hidden on long-press when the item has a long-press handler',
      (tester) async {
        await tester.pumpWidget(
          _bar(
            body: (_) => const SizedBox(),
            items: [
              _item(0),
              _item(1),
              _item(2, tooltip: 'Profile tip', onLongPress: () {}),
              _item(3),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byKey(const ValueKey(2)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Profile tip'), findsNothing);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'tooltip shows on long-press when the item has no long-press handler',
      (tester) async {
        await tester.pumpWidget(
          _bar(
            body: (_) => const SizedBox(),
            items: [
              _item(0),
              _item(1),
              _item(2, tooltip: 'Profile tip'),
              _item(3),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byKey(const ValueKey(2)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Profile tip'), findsOneWidget);

        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets(
      'semantics expose a long-press action only with a long-press handler',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          _bar(
            body: (_) => const SizedBox(),
            items: [
              _item(0),
              _item(1),
              _item(
                2,
                label: const Text('Profile'),
                semanticLabel: 'Profile',
                onLongPress: () {},
              ),
              _item(3, label: const Text('Profile'), semanticLabel: 'Profile'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.byKey(const ValueKey(2))),
          isSemantics(
            label: 'Profile',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
            hasLongPressAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.byKey(const ValueKey(3))),
          isSemantics(
            label: 'Profile',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
        handle.dispose();
      },
    );
  });
}
