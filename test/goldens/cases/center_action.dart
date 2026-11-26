import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../golden_case.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

final centerActionFeature = GoldenFeature(
  'Centre action',
  readme: 'centre-action',
  demo: 'center-action',
  cases: [
    _centerCase(
      'center_action_inline',
      'Inline centre action between the tabs',
      BottomBarCenterActionStyle.inline,
      themed,
    ),
    _centerCase(
      'center_action_raised',
      'Raised centre action above the tabs',
      BottomBarCenterActionStyle.raised,
      themed,
    ),
    _centerCase(
      'center_action_notched',
      'Notched centre action in the bar',
      BottomBarCenterActionStyle.notched,
      themedRtl,
    ),
  ],
);

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

GoldenCase _centerCase(
  String id,
  String caption,
  BottomBarCenterActionStyle style,
  List<Shot> shots,
) {
  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    build: (shot) => goldenApp(
      shot,
      Scaffold(
        body: BottomBar(
          body: const SizedBox.shrink(),
          layout: const BottomBarLayout(width: 360),
          theme: style == BottomBarCenterActionStyle.notched
              ? _notchedBarTheme(shot.brightness)
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
  );
}
