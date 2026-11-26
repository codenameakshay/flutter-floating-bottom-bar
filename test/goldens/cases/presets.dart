import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

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

final presetsFeature = GoldenFeature(
  'Presets',
  readme: 'presets',
  demo: 'presets',
  cases: [
    _presetCase(
      'preset_glass',
      'Glass preset in light and dark',
      () => BottomBarThemeData.glass(),
    ),
    _presetCase(
      'preset_material3',
      'Material 3 preset in light and dark',
      () => BottomBarThemeData.material3(),
    ),
    _presetCase(
      'preset_pill',
      'Pill preset in light, dark and right to left',
      () => BottomBarThemeData.pill(),
      shots: themedRtl,
    ),
    _presetCase(
      'preset_minimal',
      'Minimal preset in light and dark',
      () => BottomBarThemeData.minimal(),
    ),
    _presetCase(
      'preset_glass_notched_badges',
      'Glass preset with a notched centre action and badges',
      () => BottomBarThemeData.glass(),
      shots: const [Shot.light],
      notched: true,
      badged: true,
    ),
    GoldenCase(
      'preset_material3_vs_navigation_bar',
      caption: 'Material 3 preset beside the Material navigation bar',
      shots: const [Shot.light],
      size: const Size(390, 220),
      build: (shot) => goldenApp(
        shot,
        Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NavigationBar(
                selectedIndex: 1,
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: Icon(tab.$1),
                      selectedIcon: Icon(tab.$2),
                      label: tab.$3,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 80,
                child: BottomBar(
                  theme: BottomBarThemeData.material3(),
                  showIcon: false,
                  body: const SizedBox.shrink(),
                  child: BottomBarItems(
                    selectedIndex: 1,
                    onSelected: (_) {},
                    children: _items(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      target: () => find.byType(Scaffold),
    ),
  ],
);

GoldenCase _presetCase(
  String id,
  String caption,
  BottomBarThemeData Function() preset, {
  List<Shot> shots = themed,
  bool notched = false,
  bool badged = false,
}) {
  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    size: Size(390, notched ? 260 : 220),
    build: (shot) => goldenApp(
      shot,
      BottomBar(
        theme: preset(),
        showIcon: false,
        body: _backdrop(),
        child: BottomBarItems(
          selectedIndex: 1,
          onSelected: (_) {},
          centerAction: notched
              ? BottomBarCenterAction(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create',
                  style: BottomBarCenterActionStyle.notched,
                  onPressed: () {},
                )
              : null,
          children: _items(badged: badged),
        ),
      ),
    ),
  );
}

Widget _backdrop() => SizedBox.expand(
  child: Row(
    children: [
      for (final c in _backdropColors)
        Expanded(
          child: ColoredBox(color: c, child: const SizedBox.expand()),
        ),
    ],
  ),
);

List<Widget> _items({bool badged = false}) => [
  for (var i = 0; i < _tabs.length; i++)
    BottomBarItem(
      icon: Icon(_tabs[i].$1),
      selectedIcon: Icon(_tabs[i].$2),
      label: Text(_tabs[i].$3),
      badge: badged ? _badgeAt(i) : null,
    ),
];

BottomBarBadge? _badgeAt(int index) => switch (index) {
  1 => const BottomBarBadge.count(3),
  3 => const BottomBarBadge.dot(),
  _ => null,
};
