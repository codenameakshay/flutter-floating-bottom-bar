import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

import '../golden_case.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.search, 'Search'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

const _stripes = [
  Color(0xFFE53935),
  Color(0xFFFFFFFF),
  Color(0xFF1E88E5),
  Color(0xFF000000),
  Color(0xFFFDD835),
  Color(0xFF43A047),
];

final groupsFeature = GoldenFeature(
  'Groups',
  readme: 'groups',
  demo: 'groups',
  cases: [
    GoldenCase(
      'group_glass',
      caption: 'Glass group with side buttons and a notched centre action',
      shots: themedRtl,
      size: const Size(520, 200),
      build: (shot) => _group(shot, const BottomBarSurface.glass()),
    ),
    GoldenCase(
      'group_solid',
      caption: 'Solid group with side buttons and a notched centre action',
      size: const Size(520, 200),
      build: (shot) => _group(shot, const BottomBarSurface.solid()),
    ),
  ],
);

Widget _group(Shot shot, BottomBarSurface surface) {
  return goldenApp(
    shot,
    BottomBar(
      body: const _Stripes(),
      layout: const BottomBarLayout(width: 500),
      theme: BottomBarThemeData(surface: surface),
      showIcon: false,
      leading: IconButton(
        tooltip: 'Profile',
        icon: const Icon(Icons.person),
        onPressed: () {},
      ),
      trailing: IconButton(
        tooltip: 'Search',
        icon: const Icon(Icons.search),
        onPressed: () {},
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: BottomBarItems(
          selectedIndex: 1,
          indicator: const BottomBarIndicator.pill(),
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add),
            tooltip: 'Create',
            style: BottomBarCenterActionStyle.notched,
            onPressed: () {},
          ),
          children: [
            for (final tab in _tabs)
              BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
          ],
        ),
      ),
    ),
  );
}

class _Stripes extends StatelessWidget {
  const _Stripes();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(-0.7, -0.4),
          tileMode: TileMode.repeated,
          colors: [
            for (final c in _stripes) ...[c, c],
          ],
          stops: [
            for (var i = 0; i < _stripes.length; i++) ...[
              i / _stripes.length,
              (i + 1) / _stripes.length,
            ],
          ],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
