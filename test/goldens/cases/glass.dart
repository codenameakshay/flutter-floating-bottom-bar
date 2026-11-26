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

final glassFeature = GoldenFeature(
  'Glass surface',
  readme: 'glass-surface',
  demo: 'glass-surface',
  cases: [
    _glassCase('glass_default', 'Glass surface on the second tab'),
    _glassCase(
      'glass_notched',
      'Glass surface with a notched centre action',
      shots: themedRtl,
      notched: true,
    ),
    _glassCase(
      'glass_shadow',
      'Glass surface at half fill with a heavy shadow',
      shots: const [Shot.light],
      surface: const BottomBarSurface.glass(
        fillOpacity: 0.5,
        shadows: [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
    ),
    _glassCase(
      'glass_high_contrast',
      'Glass surface with high contrast on',
      highContrast: true,
    ),
    _glassCase(
      'glass_over_white',
      'Glass surface over a white backdrop',
      background: const ColoredBox(
        color: Colors.white,
        child: SizedBox.expand(),
      ),
    ),
    _glassCase(
      'glass_over_black',
      'Glass surface over a black backdrop',
      background: const ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(),
      ),
    ),
  ],
);

GoldenCase _glassCase(
  String id,
  String caption, {
  List<Shot> shots = themed,
  BottomBarSurface surface = const BottomBarSurface.glass(),
  bool notched = false,
  bool highContrast = false,
  Widget? background,
}) {
  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    size: const Size(400, 200),
    build: (shot) => MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: shot.brightness,
      ),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(highContrast: highContrast),
          child: Directionality(
            textDirection: shot.direction,
            child: BottomBar(
              body: background ?? const _Stripes(),
              layout: const BottomBarLayout(width: 360),
              theme: BottomBarThemeData(surface: surface),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BottomBarItems(
                  selectedIndex: 1,
                  indicator: const BottomBarIndicator.pill(),
                  centerAction: notched
                      ? BottomBarCenterAction(
                          icon: const Icon(Icons.add),
                          tooltip: 'Create',
                          style: BottomBarCenterActionStyle.notched,
                          onPressed: () {},
                        )
                      : null,
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
