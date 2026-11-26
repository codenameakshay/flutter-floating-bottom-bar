import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden_case.dart';

const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
  (Icons.bookmark_outline, Icons.bookmark, 'Saved'),
  (Icons.person_outline, Icons.person, 'Profile'),
];

const _twoX = [
  Shot('light', textScale: 2),
  Shot('dark', brightness: Brightness.dark, textScale: 2),
];

const _threeX = [
  Shot('light', textScale: 3),
  Shot('dark', brightness: Brightness.dark, textScale: 3),
  Shot('rtl', direction: TextDirection.rtl, textScale: 3),
];

final largeTextFeature = GoldenFeature(
  'Large text',
  readme: 'accessibility',
  demo: 'accessibility',
  cases: [
    _largeTextCase(
      'large_text_2x',
      'Bar at 2x text scale in light and dark',
      _twoX,
    ),
    _largeTextCase(
      'large_text_3x',
      'Bar at 3x text scale in light, dark and right to left',
      _threeX,
    ),
  ],
);

GoldenCase _largeTextCase(String id, String caption, List<Shot> shots) {
  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    size: const Size(390, 360),
    run: (tester, shot) async {
      await tester.pumpWidget(
        goldenApp(
          shot,
          BottomBar(
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
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );
}
