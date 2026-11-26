@Tags(['golden'])
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

void main() {
  _centerGolden(
    'center_action_inline_light.png',
    BottomBarCenterActionStyle.inline,
    Brightness.light,
  );
  _centerGolden(
    'center_action_inline_dark.png',
    BottomBarCenterActionStyle.inline,
    Brightness.dark,
  );
  _centerGolden(
    'center_action_raised_light.png',
    BottomBarCenterActionStyle.raised,
    Brightness.light,
  );
  _centerGolden(
    'center_action_raised_dark.png',
    BottomBarCenterActionStyle.raised,
    Brightness.dark,
  );
  _centerGolden(
    'center_action_notched_light.png',
    BottomBarCenterActionStyle.notched,
    Brightness.light,
  );
  _centerGolden(
    'center_action_notched_dark.png',
    BottomBarCenterActionStyle.notched,
    Brightness.dark,
  );
  _centerGolden(
    'center_action_notched_rtl.png',
    BottomBarCenterActionStyle.notched,
    Brightness.light,
    direction: TextDirection.rtl,
  );
}

BottomBarThemeData? _notchedBarTheme(Brightness brightness) {
  return BottomBarThemeData(
    barDecoration: BoxDecoration(
      color: brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF2B2930),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
  );
}

void _centerGolden(
  String fileName,
  BottomBarCenterActionStyle style,
  Brightness brightness, {
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(fileName, (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: BottomBar(
              body: const SizedBox.shrink(),
              layout: const BottomBarLayout(width: 360),
              theme: style == BottomBarCenterActionStyle.notched
                  ? _notchedBarTheme(brightness)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BottomBarItems(
                  selectedIndex: 1,
                  indicator: const BottomBarIndicator.pill(),
                  centerAction: BottomBarCenterAction(
                    icon: const Icon(Icons.add),
                    tooltip: 'Create',
                    style: style,
                    onPressed: () {},
                  ),
                  children: [
                    for (final tab in _tabs)
                      BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(BottomBar), matchesGoldenFile(fileName));
  });
}
