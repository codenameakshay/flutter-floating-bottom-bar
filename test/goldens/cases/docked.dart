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

const _barSize = Size(400, 240);
const _landscapeSize = Size(800, 240);

final dockedFeature = GoldenFeature(
  'Docked',
  readme: 'docked',
  demo: 'docked',
  cases: [
    GoldenCase(
      'docked_solid',
      caption: 'Solid docked bar with a bottom inset',
      size: _barSize,
      build: (shot) => _barTree(
        shot,
        size: _barSize,
        layout: const BottomBarLayout.docked(),
        surface: const BottomBarSurface.solid(),
        insets: const EdgeInsets.only(bottom: 24),
      ),
    ),
    GoldenCase(
      'docked_glass',
      caption: 'Glass docked bar with a bottom inset',
      size: _barSize,
      build: (shot) => _barTree(
        shot,
        size: _barSize,
        layout: const BottomBarLayout.docked(),
        surface: const BottomBarSurface.glass(),
        insets: const EdgeInsets.only(bottom: 24),
      ),
    ),
  ],
);

final rtlFeature = GoldenFeature(
  'RTL',
  readme: 'rtl',
  demo: null,
  cases: [
    GoldenCase(
      'rtl_start_aligned',
      caption: 'Narrow glass bar aligned to the start edge in RTL',
      shots: const [Shot('', direction: TextDirection.rtl)],
      size: _barSize,
      build: (shot) => _barTree(
        shot,
        size: _barSize,
        layout: const BottomBarLayout(
          width: 220,
          directionalAlignment: AlignmentDirectional.bottomStart,
        ),
        surface: const BottomBarSurface.glass(),
      ),
    ),
  ],
);

final edgeToEdgeFeature = GoldenFeature(
  'Edge-to-edge and safe area',
  readme: 'edge-to-edge-and-safe-area',
  demo: null,
  cases: [
    GoldenCase(
      'landscape_side_insets',
      caption: 'Full-width solid bar inset from the landscape side edges',
      shots: const [Shot('')],
      size: _landscapeSize,
      build: (shot) => _barTree(
        shot,
        size: _landscapeSize,
        layout: const BottomBarLayout(width: double.infinity),
        surface: const BottomBarSurface.solid(),
        insets: const EdgeInsets.only(left: 47, right: 47, bottom: 21),
      ),
    ),
  ],
);

Widget _barTree(
  Shot shot, {
  required Size size,
  EdgeInsets insets = EdgeInsets.zero,
  required BottomBarLayout layout,
  required BottomBarSurface surface,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, padding: insets, viewPadding: insets),
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: shot.brightness,
      ),
      home: Directionality(
        textDirection: shot.direction,
        child: BottomBar(
          body: const _Stripes(),
          layout: layout,
          theme: BottomBarThemeData(surface: surface),
          showIcon: false,
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            children: [
              for (final tab in _tabs)
                BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
            ],
          ),
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
