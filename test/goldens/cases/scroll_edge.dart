import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

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

const _clear = BottomBarSurface(fillOpacity: 0);
const _linear = BottomBarMotion.curved(
  duration: Duration(milliseconds: 200),
  curve: Curves.linear,
);

final scrollEdgeFeature = GoldenFeature(
  'Scroll edge surface',
  readme: 'scroll-edge-surface',
  demo: 'glass-surface',
  cases: [
    _edgeCase(
      'scroll_edge_standard',
      'Standard scroll edge surface before scrolling',
    ),
    _edgeCase(
      'scroll_edge_clear',
      'Clear scroll edge surface after scrolling to the end',
      scrolledToEnd: true,
    ),
    _edgeCase(
      'scroll_edge_mid',
      'Clear scroll edge surface 100 ms into the fade',
      scrolledToEnd: true,
      midFlight: const Duration(milliseconds: 100),
    ),
    _edgeCase(
      'scroll_edge_notched_clear',
      'Clear scroll edge surface with a notched centre action',
      shots: const [Shot.light],
      notched: true,
      scrolledToEnd: true,
    ),
  ],
);

GoldenCase _edgeCase(
  String id,
  String caption, {
  List<Shot> shots = themed,
  bool notched = false,
  bool scrolledToEnd = false,
  Duration? midFlight,
}) {
  Widget tree(Shot shot) => MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.indigo,
      brightness: shot.brightness,
    ),
    home: BottomBar(
      body: const _StripedList(),
      layout: const BottomBarLayout(width: 360),
      motion: _linear,
      scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: false),
      theme: const BottomBarThemeData(
        surface: BottomBarSurface.glass(),
        scrollEdgeSurface: _clear,
      ),
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
  );

  return GoldenCase(
    id,
    caption: caption,
    shots: shots,
    size: const Size(400, 200),
    build: scrolledToEnd ? null : tree,
    run: scrolledToEnd
        ? (tester, shot) async {
            await tester.pumpWidget(tree(shot));
            await tester.pumpAndSettle();

            final position = tester.state<ScrollableState>(
              find.byType(Scrollable),
            );
            position.position.jumpTo(position.position.maxScrollExtent);
            await tester.pump();
            // The first ticker frame only sets the animation's start time.
            await tester.pump();
            if (midFlight == null) {
              await tester.pumpAndSettle();
            } else {
              await tester.pump(midFlight);
            }
          }
        : null,
  );
}

class _StripedList extends StatelessWidget {
  const _StripedList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 60,
      itemBuilder: (_, i) =>
          Container(height: 40, color: _stripes[i % _stripes.length]),
    );
  }
}
