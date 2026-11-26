import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> setWidth(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 800);
    await tester.pumpAndSettle();
  }

  Widget app({required int index, ValueChanged<int>? onSelected}) =>
      MaterialApp(
        home: Scaffold(
          body: BottomBarAdaptive(
            items: BottomBarItems(
              selectedIndex: index,
              onSelected: onSelected,
              indicator: const BottomBarIndicator.pill(),
              children: const [
                BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
                BottomBarItem(icon: Icon(Icons.person), label: Text('Me')),
              ],
            ),
            body: Column(
              children: [
                const TextField(key: Key('field')),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < 100; i++)
                        ListTile(title: Text('Row $i')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  testWidgets('keeps the body state and index across the breakpoint', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 400);
    var index = 1;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) =>
            app(index: index, onSelected: (i) => setState(() => index = i)),
      ),
    );
    expect(find.byType(BottomBar), findsOneWidget);
    await tester.enterText(find.byKey(const Key('field')), 'typed');
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first;
    final offset = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(offset, greaterThan(0));

    await setWidth(tester, 900);
    expect(find.byType(BottomBar), findsNothing);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);

    await setWidth(tester, 400);
    expect(find.byType(BottomBar), findsOneWidget);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, offset);
    expect(find.text('typed'), findsOneWidget);
    expect(index, 1);
    final items = tester.widget<BottomBarItems>(find.byType(BottomBarItems));
    expect(items.selectedIndex, 1);
  });

  BottomBarItems railItems({
    int index = 0,
    ValueChanged<int>? onSelected,
    bool scrollToStartOnReselect = false,
    BottomBarLabelBehavior? labelBehavior,
  }) => BottomBarItems(
    selectedIndex: index,
    onSelected: onSelected,
    scrollToStartOnReselect: scrollToStartOnReselect,
    labelBehavior: labelBehavior,
    indicator: const BottomBarIndicator.pill(),
    children: const [
      BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
      BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
      BottomBarItem(icon: Icon(Icons.person), label: Text('Me')),
    ],
  );

  Widget adaptive({
    BottomBarItems? items,
    Widget? body,
    BottomBarController? controller,
    double breakpoint = 600,
    BottomBarThemeData? theme,
    BottomBarRailStyle? railStyle,
    BottomBarLabelBehavior? railLabelBehavior,
    Widget? railLeading,
    Widget? railTrailing,
    TextDirection direction = TextDirection.ltr,
  }) => MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: BottomBarAdaptive(
          items: items ?? railItems(),
          body: body ?? const SizedBox.expand(),
          controller: controller,
          breakpoint: breakpoint,
          theme: theme,
          railStyle: railStyle,
          railLabelBehavior: railLabelBehavior,
          railLeading: railLeading,
          railTrailing: railTrailing,
        ),
      ),
    ),
  );

  Finder itemLabel(String label) => find.descendant(
    of: find.byType(BottomBarItems),
    matching: find.text(label),
  );

  testWidgets('below 600 the bar shows, at 600 the rail shows', (tester) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 599);
    await tester.pumpWidget(app(index: 0));
    await tester.pumpAndSettle();
    expect(find.byType(BottomBar), findsOneWidget);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).direction,
      Axis.horizontal,
    );

    await setWidth(tester, 600);
    expect(find.byType(BottomBar), findsNothing);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).direction,
      Axis.vertical,
    );
  });

  testWidgets('rail label behavior resolves override before row and theme', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 599);
    await tester.pumpWidget(adaptive(theme: BottomBarThemeData.minimal()));
    expect(find.byType(BottomBar), findsOneWidget);
    expect(itemLabel('Home'), findsWidgets);
    expect(itemLabel('Search'), findsNothing);

    await setWidth(tester, 600);
    expect(find.byType(BottomBar), findsNothing);
    expect(itemLabel('Home'), findsWidgets);
    expect(itemLabel('Search'), findsNothing);

    await tester.pumpWidget(
      adaptive(
        theme: BottomBarThemeData.minimal(),
        items: railItems(labelBehavior: BottomBarLabelBehavior.alwaysShow),
      ),
    );
    expect(itemLabel('Home'), findsWidgets);
    expect(itemLabel('Search'), findsWidgets);

    await tester.pumpWidget(
      adaptive(
        theme: BottomBarThemeData.minimal(),
        items: railItems(labelBehavior: BottomBarLabelBehavior.alwaysShow),
        railLabelBehavior: BottomBarLabelBehavior.alwaysHide,
      ),
    );
    expect(itemLabel('Home'), findsNothing);
    expect(itemLabel('Search'), findsNothing);

    await tester.pumpWidget(adaptive(theme: BottomBarThemeData.minimal()));
    expect(itemLabel('Home'), findsWidgets);
    expect(itemLabel('Search'), findsNothing);

    await tester.pumpWidget(adaptive());
    expect(itemLabel('Home'), findsWidgets);
    expect(itemLabel('Search'), findsWidgets);

    await tester.pumpWidget(
      adaptive(
        items: const BottomBarItems(children: []),
        theme: BottomBarThemeData.minimal(),
      ),
    );
    expect(itemLabel('Home'), findsNothing);
    expect(itemLabel('Search'), findsNothing);
  });

  testWidgets('a custom breakpoint of 800 keeps the bar at 700', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 700);
    await tester.pumpWidget(adaptive(breakpoint: 800));
    await tester.pumpAndSettle();
    expect(find.byType(BottomBar), findsOneWidget);

    await setWidth(tester, 800);
    expect(find.byType(BottomBar), findsNothing);
  });

  testWidgets(
    'hide state resets across the breakpoint and the controller re-attaches',
    (tester) async {
      addTearDown(tester.view.reset);
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await setWidth(tester, 400);
      await tester.pumpWidget(adaptive(controller: controller));
      await tester.pumpAndSettle();
      expect(controller.isAttached, isTrue);

      controller.hide();
      await tester.pumpAndSettle();
      expect(controller.isVisible, isFalse);

      await setWidth(tester, 900);
      expect(controller.isAttached, isFalse);

      await setWidth(tester, 400);
      expect(controller.isVisible, isTrue);
      expect(controller.isAttached, isTrue);
    },
  );

  testWidgets('tapping a rail item selects it and the selection persists', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final selected = <int>[];
    var index = 0;
    await setWidth(tester, 900);
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => adaptive(
          items: railItems(
            index: index,
            onSelected: (i) {
              selected.add(i);
              setState(() => index = i);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search').first);
    await tester.pumpAndSettle();
    expect(selected, [1]);
    expect(index, 1);

    await setWidth(tester, 400);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).selectedIndex,
      1,
    );
  });

  testWidgets(
    'insets: LTR rail clears the start inset and the body keeps the end inset',
    (tester) async {
      addTearDown(tester.view.reset);
      addTearDown(tester.view.resetPadding);
      tester.view.padding = const FakeViewPadding(
        left: 44,
        right: 30,
        top: 20,
        bottom: 20,
      );
      await setWidth(tester, 900);
      EdgeInsets? seen;
      await tester.pumpWidget(
        adaptive(
          body: Builder(
            builder: (context) {
              seen = MediaQuery.paddingOf(context);
              return SizedBox.expand(key: const Key('body'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(BottomBarItem).first).left,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getRect(find.byKey(const Key('body'))).left,
        greaterThan(44),
      );
      expect(seen!.left, 0);
      expect(seen!.right, 30);
    },
  );

  testWidgets(
    'insets: RTL rail clears the end inset and the body keeps the start inset',
    (tester) async {
      addTearDown(tester.view.reset);
      addTearDown(tester.view.resetPadding);
      tester.view.padding = const FakeViewPadding(
        left: 44,
        right: 30,
        top: 20,
        bottom: 20,
      );
      await setWidth(tester, 900);
      EdgeInsets? seen;
      await tester.pumpWidget(
        adaptive(
          direction: TextDirection.rtl,
          body: Builder(
            builder: (context) {
              seen = MediaQuery.paddingOf(context);
              return SizedBox.expand(key: const Key('body'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(BottomBarItem).first).right,
        lessThanOrEqualTo(900 - 30),
      );
      expect(seen!.right, 0);
      expect(seen!.left, 44);
    },
  );

  testWidgets(
    'material3 rail is attached: the first item hugs the start edge and the body starts at 80',
    (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await tester.pumpWidget(
        adaptive(
          theme: BottomBarThemeData.material3(),
          body: SizedBox.expand(key: const Key('body')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(BottomBarItem).first).left,
        lessThan(20),
      );
      expect(tester.getRect(find.byKey(const Key('body'))).left, 80);
    },
  );

  testWidgets('glass rail floats: the body starts at 80 plus 2 times 16', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await setWidth(tester, 900);
    await tester.pumpWidget(
      adaptive(
        theme: BottomBarThemeData.glass(),
        body: SizedBox.expand(key: const Key('body')),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const Key('body'))).left,
      closeTo(80 + 2 * 16, 0.01),
    );
  });

  testWidgets(
    'railStyle attached overrides a glass theme: the body starts at 80',
    (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await tester.pumpWidget(
        adaptive(
          theme: BottomBarThemeData.glass(),
          railStyle: BottomBarRailStyle.attached,
          body: SizedBox.expand(key: const Key('body')),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getRect(find.byKey(const Key('body'))).left, 80);
    },
  );

  testWidgets(
    'railLeading sits above the first item and railTrailing below the last',
    (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await tester.pumpWidget(
        adaptive(
          railLeading: const SizedBox(key: Key('lead'), width: 40, height: 40),
          railTrailing: const SizedBox(
            key: Key('trail'),
            width: 40,
            height: 40,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final first = tester.getRect(find.byType(BottomBarItem).first);
      final last = tester.getRect(find.byType(BottomBarItem).last);
      expect(
        tester.getRect(find.byKey(const Key('lead'))).bottom,
        lessThanOrEqualTo(first.top),
      );
      expect(
        tester.getRect(find.byKey(const Key('trail'))).top,
        greaterThanOrEqualTo(last.bottom),
      );
    },
  );

  testWidgets(
    'railLabelBehavior alwaysHide hides rail labels at 900 but not the bar labels at 400',
    (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await tester.pumpWidget(
        adaptive(railLabelBehavior: BottomBarLabelBehavior.alwaysHide),
      );
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);

      await setWidth(tester, 400);
      expect(find.text('Home'), findsWidgets);
    },
  );

  testWidgets(
    'reselecting in rail mode scrolls the body list back to its start',
    (tester) async {
      addTearDown(tester.view.reset);
      await setWidth(tester, 900);
      await tester.pumpWidget(
        adaptive(
          items: railItems(scrollToStartOnReselect: true),
          body: ListView.builder(
            itemCount: 100,
            itemBuilder: (context, i) => ListTile(title: Text('Row $i')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      final scrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );

      await tester.tap(find.text('Home').first);
      await tester.pumpAndSettle();
      expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
    },
  );

  testWidgets('BottomBarBodyPadding in rail mode reserves the bottom inset', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetPadding);
    tester.view.padding = const FakeViewPadding(bottom: 20);
    await setWidth(tester, 900);
    await tester.pumpWidget(
      adaptive(
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 100,
            itemBuilder: (context, i) => ListTile(title: Text('Row $i')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(BottomBarBodyPadding),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding.resolve(TextDirection.ltr).bottom, 20);
  });
}
