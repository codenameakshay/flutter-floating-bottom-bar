import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

final indicatorsFeature = GoldenFeature(
  'Indicators',
  readme: 'indicators',
  demo: 'indicators',
  cases: [
    _indicatorCase(
      'indicator_pill',
      'Pill indicator on the second tab',
      const BottomBarIndicator.pill(),
      shots: const [Shot.light, Shot.dark, Shot.rtl, Shot.text2x],
    ),
    _indicatorCase(
      'indicator_tint',
      'Tint indicator on the second tab',
      const BottomBarIndicator.tint(),
    ),
    _indicatorCase(
      'indicator_underline',
      'Underline indicator on the second tab',
      const BottomBarIndicator.underline(),
    ),
    _indicatorCase(
      'indicator_dot',
      'Dot indicator on the second tab',
      const BottomBarIndicator.dot(),
    ),
    _indicatorCase(
      'indicator_container',
      'Container indicator on the second tab',
      const BottomBarIndicator.container(),
    ),
    _indicatorCase(
      'indicator_builder',
      'Tubelight indicator on the second tab',
      BottomBarIndicator.builder(
        (context, rect, _) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: rect.width,
            height: 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ),
      ),
    ),
    _indicatorCase('indicator_none', 'No indicator on the second tab', null),
  ],
);

GoldenCase _indicatorCase(
  String id,
  String caption,
  BottomBarIndicator? indicator, {
  List<Shot> shots = themed,
}) {
  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    build: (shot) => goldenApp(shot, _indicatorBar(indicator)),
  );
}

Widget _indicatorBar(BottomBarIndicator? indicator) {
  return Scaffold(
    body: BottomBar(
      body: const SizedBox.shrink(),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: BottomBarItems(
          selectedIndex: 1,
          indicator: indicator,
          children: [
            for (final tab in _tabs)
              BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
          ],
        ),
      ),
    ),
  );
}
