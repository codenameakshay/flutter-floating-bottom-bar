import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _tabs = <(IconData, String)>[
  (Icons.home_outlined, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox_outlined, 'Inbox'),
  (Icons.person_outline, 'Profile'),
];

Widget _app(Brightness brightness, Widget bar) => MaterialApp(
  theme: ThemeData(colorSchemeSeed: Colors.indigo, brightness: brightness),
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: bar),
  ),
);

Widget _presetBar() => SizedBox(
  height: 200,
  child: BottomBar(
    theme: BottomBarThemeData.material3(),
    showIcon: false,
    body: const SizedBox.expand(),
    child: BottomBarItems(
      selectedIndex: 1,
      children: [
        for (final (icon, label) in _tabs)
          BottomBarItem(icon: Icon(icon), label: Text(label)),
      ],
    ),
  ),
);

Widget _navigationBar() => NavigationBar(
  selectedIndex: 1,
  destinations: [
    for (final (icon, label) in _tabs)
      NavigationDestination(icon: Icon(icon), label: label),
  ],
);

Rect _iconRect(WidgetTester tester, IconData icon) =>
    tester.getRect(find.byIcon(icon));

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('material3 matches NavigationBar metrics, $brightness', (
      tester,
    ) async {
      await tester.pumpWidget(_app(brightness, _navigationBar()));
      await tester.pumpAndSettle();
      final navBar = tester.getRect(find.byType(NavigationBar));
      final navIcon = _iconRect(tester, Icons.search);
      final navLabel = tester.getRect(find.text('Search'));
      final navIndicator = tester.getRect(
        find.byType(NavigationIndicator).at(1),
      );
      final navStyle = tester.widget<RichText>(
        find.descendant(
          of: find.text('Search'),
          matching: find.byType(RichText),
        ),
      );
      final cs = Theme.of(
        tester.element(find.byType(NavigationBar)),
      ).colorScheme;
      final navIconColor = IconTheme.of(
        tester.element(find.byIcon(Icons.search)),
      ).color;

      expect(navBar.height, 80);
      expect(navStyle.text.style!.fontSize, 12);
      expect(navStyle.text.style!.fontWeight, FontWeight.w500);
      expect(navStyle.text.style!.letterSpacing, 0.5);
      await tester.pumpWidget(_app(brightness, _presetBar()));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(BottomBarItems));
      final icon = _iconRect(tester, Icons.search);
      final label = tester.getRect(find.text('Search'));

      expect(bar.height, navBar.height);
      expect(bar.height, 80);
      expect(tester.getSize(find.byType(BarSurface)).height, navBar.height);
      expect(icon.size, navIcon.size);
      expect(icon.top - bar.top, navIcon.top - navBar.top);
      expect(label.top - bar.top, navLabel.top - navBar.top);
      expect(label.height, navLabel.height);

      final itemStyle = tester
          .widget<RichText>(
            find.descendant(
              of: find.text('Search'),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(itemStyle.fontSize, navStyle.text.style!.fontSize);
      expect(itemStyle.fontWeight, navStyle.text.style!.fontWeight);
      expect(itemStyle.letterSpacing, navStyle.text.style!.letterSpacing);
      expect(itemStyle.color, cs.onSurface);
      expect(itemStyle.color, navStyle.text.style!.color);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.search))).color,
        cs.onSecondaryContainer,
      );
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.search))).color,
        navIconColor,
      );

      expect(navIndicator.size, const Size(64, 32));
      final trackOrigin = tester.getTopLeft(find.byType(IndicatorTrack));
      final expected = Rect.fromCenter(
        center:
            Offset(
              icon.center.dx,
              bar.top + (navIndicator.center.dy - navBar.top),
            ) -
            trackOrigin,
        width: navIndicator.width,
        height: navIndicator.height,
      );
      expect(
        tester.renderObject(find.byType(IndicatorTrack)),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(expected, const Radius.circular(16)),
          color: cs.secondaryContainer,
        ),
      );
    });
  }

  testWidgets('docked preset keeps an 80px item row above the safe inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
          ),
          child: Scaffold(
            body: BottomBar(
              theme: BottomBarThemeData.material3(),
              showIcon: false,
              body: const SizedBox.expand(),
              child: BottomBarItems(
                selectedIndex: 0,
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final row = tester.getRect(find.byType(BottomBarItems));
    final surface = tester.getRect(find.byType(BarSurface));
    expect(row.height, 80);
    expect(surface.height, 104);
    expect(surface.bottom, 844);
    expect(row.bottom, 820);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty preset row and grouped actions build without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Brightness.light,
        BottomBar(
          theme: BottomBarThemeData.glass(),
          leading: const Icon(Icons.menu),
          trailing: const Icon(Icons.more_vert),
          body: const SizedBox.expand(),
          child: const BottomBarItems(children: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomBarItems), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byType(BarSurface), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
