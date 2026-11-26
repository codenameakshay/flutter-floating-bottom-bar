@Tags(['golden'])
library;

import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
  (Icons.bookmark_outline, Icons.bookmark, 'Saved'),
  (Icons.person_outline, Icons.person, 'Profile'),
];

void main() {
  for (final scale in [2.0, 3.0]) {
    for (final brightness in Brightness.values) {
      _largeTextGolden(
        'large_text_${scale.toInt()}x_${brightness.name}.png',
        scale: scale,
        brightness: brightness,
      );
    }
  }
  _largeTextGolden(
    'large_text_3x_rtl.png',
    scale: 3,
    brightness: Brightness.light,
    direction: TextDirection.rtl,
  );
}

void _largeTextGolden(
  String file, {
  required double scale,
  required Brightness brightness,
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(file, (tester) async {
    tester.view.physicalSize = const Size(390, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Directionality(
          textDirection: direction,
          child: BottomBar(
            theme: BottomBarThemeData.glass(),
            showIcon: false,
            body: const ColoredBox(
              color: Colors.teal,
              child: SizedBox.expand(),
            ),
            accessory: const ListTile(
              leading: Icon(Icons.music_note),
              title: Text('Now playing'),
            ),
            child: BottomBarItems(
              selectedIndex: 1,
              onSelected: (_) {},
              centerAction: BottomBarCenterAction(
                icon: const Icon(Icons.add),
                tooltip: 'Compose',
                style: BottomBarCenterActionStyle.notched,
                onPressed: () {},
              ),
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  BottomBarItem(
                    icon: Icon(_tabs[i].$1),
                    selectedIcon: Icon(_tabs[i].$2),
                    label: Text(_tabs[i].$3),
                    badge: switch (i) {
                      1 => const BottomBarBadge.count(120),
                      2 => const BottomBarBadge.dot(),
                      _ => null,
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectLater(find.byType(BottomBar), matchesGoldenFile(file));
  });
}
