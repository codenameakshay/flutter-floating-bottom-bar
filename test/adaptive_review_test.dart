import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:material_ui/material_ui.dart';

BottomBarItems _items() => const BottomBarItems(
  selectedIndex: 1,
  children: [
    BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
    BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
  ],
);

void main() {
  testWidgets(
    'preserves nested navigator, text, focus and scroll in both directions',
    (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBarAdaptive(
            items: _items(),
            body: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute<void>(builder: (_) => const Text('root')),
            ),
          ),
        ),
      );
      final navigator = tester.state<NavigatorState>(
        find.descendant(
          of: find.byType(BottomBarAdaptive),
          matching: find.byType(Navigator),
        ),
      );
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => Material(
            child: Column(
              children: [
                TextField(focusNode: focus),
                Expanded(
                  child: ListView.builder(
                    itemExtent: 50,
                    itemCount: 100,
                    itemBuilder: (_, i) => Text('row $i'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'kept');
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      scroll.position.jumpTo(300);
      await tester.pumpAndSettle();

      for (final width in [900.0, 400.0, 900.0, 400.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.state<NavigatorState>(
            find.descendant(
              of: find.byType(BottomBarAdaptive),
              matching: find.byType(Navigator),
            ),
          ),
          same(navigator),
        );
        expect(navigator.canPop(), isTrue);
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(editable),
        );
        expect(find.text('kept'), findsOneWidget);
        expect(focus.hasFocus, isTrue);
        expect(scroll.position.pixels, 300);
        expect(
          tester
              .widget<BottomBarItems>(find.byType(BottomBarItems))
              .selectedIndex,
          1,
        );
      }
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('root'), findsOneWidget);
    },
  );
  testWidgets(
    'reselect after switching to rail finds an unchanged list viewport',
    (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: BottomBarAdaptive(
            items: BottomBarItems(
              selectedIndex: 0,
              scrollToStartOnReselect: true,
              children: const [
                BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              ],
            ),
            body: ListView.builder(
              itemExtent: 50,
              itemCount: 100,
              itemBuilder: (_, i) => Text('row $i'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      scroll.position.jumpTo(300);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(900, 800);
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, 300);
      await tester.tap(find.text('Home').first);
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, 0);
    },
  );

  for (final direction in TextDirection.values) {
    for (final style in BottomBarRailStyle.values) {
      for (final safe in [true, false]) {
        testWidgets(
          '$direction $style safe=$safe preserves rail and body insets',
          (tester) async {
            addTearDown(tester.view.reset);
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = const Size(900, 800);
            const padding = EdgeInsets.fromLTRB(44, 20, 30, 24);
            late EdgeInsets bodyPadding;
            late double bottomInset;
            await tester.pumpWidget(
              MaterialApp(
                home: Directionality(
                  textDirection: direction,
                  child: MediaQuery(
                    data: const MediaQueryData(padding: padding),
                    child: BottomBarAdaptive(
                      layout: BottomBarLayout(
                        offset: 10,
                        respectSafeArea: safe,
                      ),
                      railStyle: style,
                      items: _items(),
                      body: Builder(
                        builder: (context) {
                          bodyPadding = MediaQuery.paddingOf(context);
                          bottomInset = BottomBarScope.of(context).bottomInset;
                          return const SizedBox.expand(key: Key('body'));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final ltr = direction == TextDirection.ltr;
            final inset = ltr ? 44.0 : 30.0;
            final floating = style == BottomBarRailStyle.floating;
            final surface = tester.getRect(find.byType(BarSurface));
            final body = tester.getRect(find.byKey(const Key('body')));
            final surfaceStart = ltr ? surface.left : 900 - surface.right;
            final bodyStart = ltr ? body.left : 900 - body.right;
            expect(surfaceStart, floating ? (safe ? inset : 0) + 10 : 0);
            expect(surface.width, 80 + (!floating && safe ? inset : 0));
            expect(bodyStart, 80 + (safe ? inset : 0) + (floating ? 20 : 0));
            expect(
              bodyPadding,
              ltr ? padding.copyWith(left: 0) : padding.copyWith(right: 0),
            );
            expect(bottomInset, safe ? 24 : 0);
            final first = tester.getRect(find.byType(BottomBarItem).first);
            expect(first.top, greaterThanOrEqualTo(safe ? 20 : 0));
          },
        );
      }
    }
  }
  testWidgets('high contrast rail replaces glass with an opaque fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: BottomBarAdaptive(
            breakpoint: 0,
            theme: const BottomBarThemeData(
              surface: BottomBarSurface.glass(fallbackColor: Color(0x80FF0000)),
            ),
            items: _items(),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = tester.widget<BarSurface>(find.byType(BarSurface)).surface!;
    expect(surface.blur, 0);
    expect(surface.fillOpacity, 1);
    expect(surface.tint, const Color(0xFFFF0000));
  });
  testWidgets('empty items tolerate both adaptive modes', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(
      const MaterialApp(
        home: BottomBarAdaptive(
          items: BottomBarItems(children: []),
          body: Text('body'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('body'), findsOneWidget);
  });
}
