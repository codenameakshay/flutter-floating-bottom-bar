import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.search, Icons.search, 'Search'),
  (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
  (Icons.person_outline, Icons.person, 'Profile'),
];

final itemThemeFeature = GoldenFeature(
  'Item theme',
  readme: 'item-theme',
  demo: 'item-theme',
  cases: [
    _itemThemeCase(
      'item_theme_quiet',
      'Quiet item theme with tint indicator and always-shown labels',
      quietItemTheme,
      BottomBarLabelBehavior.alwaysShow,
    ),
    _itemThemeCase(
      'item_theme_bold',
      'Bold item theme with stretching pill indicator',
      boldItemTheme,
      BottomBarLabelBehavior.onlySelected,
      shots: themedRtl,
    ),
    _itemThemeCase(
      'item_theme_icon_only',
      'Icon-only item theme with dot indicator',
      iconOnlyItemTheme,
      BottomBarLabelBehavior.alwaysHide,
    ),
  ],
);

BottomBarItemThemeData quietItemTheme(ColorScheme cs) => BottomBarItemThemeData(
  color: cs.onSurfaceVariant,
  selectedColor: cs.onSecondaryContainer,
  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
  iconLabelGap: 4,
  indicator: BottomBarIndicator.tint(
    color: cs.secondaryContainer,
    foregroundColor: cs.onSecondaryContainer,
  ),
);

BottomBarItemThemeData boldItemTheme(ColorScheme cs) => BottomBarItemThemeData(
  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  selectedLabelStyle: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),
  iconSize: 22,
  selectedIconSize: 24,
  pressedScale: 0.9,
  indicator: BottomBarIndicator.pill(color: cs.tertiary, stretch: true),
);

BottomBarItemThemeData iconOnlyItemTheme(ColorScheme cs) =>
    BottomBarItemThemeData(
      color: cs.outline,
      selectedColor: cs.primary,
      iconSize: 26,
      selectedIconSize: 30,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      indicator: const BottomBarIndicator.dot(),
    );

GoldenCase _itemThemeCase(
  String id,
  String caption,
  BottomBarItemThemeData Function(ColorScheme cs) itemTheme,
  BottomBarLabelBehavior labelBehavior, {
  List<Shot> shots = themed,
}) {
  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    build: (shot) => goldenApp(
      shot,
      Scaffold(
        body: Builder(
          builder: (context) => BottomBar(
            theme: BottomBarThemeData(
              items: itemTheme(Theme.of(context).colorScheme),
            ),
            body: const SizedBox.shrink(),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: BottomBarItems(
                selectedIndex: 1,
                labelBehavior: labelBehavior,
                children: [
                  for (final tab in _tabs)
                    BottomBarItem(
                      icon: Icon(tab.$1),
                      selectedIcon: Icon(tab.$2),
                      label: Text(tab.$3),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
