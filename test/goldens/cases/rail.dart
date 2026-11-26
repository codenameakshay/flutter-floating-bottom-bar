import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.explore_outlined, Icons.explore, 'Explore'),
  (Icons.bookmark_outline, Icons.bookmark, 'Saved'),
  (Icons.person_outline, Icons.person, 'Profile'),
];

const _backdropColors = <Color>[
  Colors.pink,
  Colors.orange,
  Colors.teal,
  Colors.indigo,
  Colors.purple,
];

Widget _rail(
  Shot shot,
  BottomBarThemeData Function() preset, {
  BottomBarLabelBehavior? labels,
}) {
  return goldenApp(
    shot,
    Scaffold(
      body: BottomBarAdaptive(
        theme: preset(),
        railLabelBehavior: labels,
        items: BottomBarItems(
          selectedIndex: 1,
          onSelected: (_) {},
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add),
            tooltip: 'Create',
            onPressed: () {},
          ),
          children: [
            for (var i = 0; i < _tabs.length; i++)
              BottomBarItem(
                icon: Icon(_tabs[i].$1),
                selectedIcon: Icon(_tabs[i].$2),
                label: Text(_tabs[i].$3),
                badge: switch (i) {
                  2 => const BottomBarBadge.count(3),
                  3 => const BottomBarBadge.dot(),
                  _ => null,
                },
              ),
          ],
        ),
        body: Row(
          children: [
            for (final c in _backdropColors)
              Expanded(
                child: ColoredBox(color: c, child: const SizedBox.expand()),
              ),
          ],
        ),
      ),
    ),
  );
}

final railFeature = GoldenFeature(
  'Adaptive rail',
  readme: 'adaptive-rail',
  demo: 'adaptive-rail',
  cases: [
    GoldenCase(
      'rail_glass_floating',
      caption: 'Glass adaptive rail on a colored backdrop',
      shots: themedRtl,
      size: const Size(720, 560),
      build: (shot) => _rail(shot, BottomBarThemeData.glass),
      target: () => find.byType(BottomBarAdaptive),
    ),
    GoldenCase(
      'rail_material3_attached',
      caption: 'Material 3 adaptive rail attached to the edge',
      shots: themedRtl,
      size: const Size(720, 560),
      build: (shot) => _rail(shot, BottomBarThemeData.material3),
      target: () => find.byType(BottomBarAdaptive),
    ),
    GoldenCase(
      'rail_labels_selected',
      caption: 'Material 3 rail with the label on the selected item only',
      shots: const [Shot.light],
      size: const Size(720, 560),
      build: (shot) => _rail(
        shot,
        BottomBarThemeData.material3,
        labels: BottomBarLabelBehavior.onlySelected,
      ),
      target: () => find.byType(BottomBarAdaptive),
    ),
    GoldenCase(
      'rail_labels_all',
      caption: 'Glass adaptive rail with a label on every item',
      shots: const [Shot.light],
      size: const Size(720, 560),
      build: (shot) => _rail(
        shot,
        BottomBarThemeData.glass,
        labels: BottomBarLabelBehavior.alwaysShow,
      ),
      target: () => find.byType(BottomBarAdaptive),
    ),
  ],
);
