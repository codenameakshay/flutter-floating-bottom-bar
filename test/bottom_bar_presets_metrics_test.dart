import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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

      await tester.pumpWidget(_app(brightness, _presetBar()));
      await tester.pumpAndSettle();
      final bar = tester.getRect(find.byType(BottomBarItems));
      final icon = _iconRect(tester, Icons.search);
      final label = tester.getRect(find.text('Search'));

      expect(bar.height, navBar.height);
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

      final indicator = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              (w.decoration as ShapeDecoration).shape is StadiumBorder,
        ),
      );
      expect(indicator.size, navIndicator.size);
      expect(indicator.size, const Size(64, 32));
      expect(
        indicator.center.dy - bar.top,
        navIndicator.center.dy - navBar.top,
      );
      expect(indicator.center.dx, icon.center.dx);
      final fill = tester.widget<DecoratedBox>(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              (w.decoration as ShapeDecoration).shape is StadiumBorder,
        ),
      );
      expect((fill.decoration as ShapeDecoration).color, cs.secondaryContainer);
    });
  }
}
