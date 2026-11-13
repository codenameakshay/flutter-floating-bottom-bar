import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  late GoldenFileComparator previous;
  setUpAll(() {
    previous = goldenFileComparator;
    goldenFileComparator = _TolerantComparator(
      (previous as LocalFileComparator).basedir.resolve(
        'scroll_edge_surface_test.dart',
      ),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _edgeGolden('scroll_edge_standard_light.png');
  _edgeGolden('scroll_edge_standard_dark.png', brightness: Brightness.dark);
  _edgeGolden('scroll_edge_clear_light.png', scrolledToEnd: true);
  _edgeGolden(
    'scroll_edge_clear_dark.png',
    brightness: Brightness.dark,
    scrolledToEnd: true,
  );
  _edgeGolden(
    'scroll_edge_mid_light.png',
    scrolledToEnd: true,
    midFlight: const Duration(milliseconds: 100),
  );
  _edgeGolden(
    'scroll_edge_mid_dark.png',
    brightness: Brightness.dark,
    scrolledToEnd: true,
    midFlight: const Duration(milliseconds: 100),
  );
  _edgeGolden(
    'scroll_edge_notched_clear_light.png',
    notched: true,
    scrolledToEnd: true,
  );
}

void _edgeGolden(
  String fileName, {
  Brightness brightness = Brightness.light,
  bool notched = false,
  bool scrolledToEnd = false,
  Duration? midFlight,
}) {
  testWidgets(fileName, (tester) async {
    tester.view
      ..physicalSize = const Size(400, 200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
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
      ),
    );
    await tester.pumpAndSettle();

    if (scrolledToEnd) {
      final position = tester.state<ScrollableState>(find.byType(Scrollable));
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

    await expectLater(find.byType(BottomBar), matchesGoldenFile(fileName));
  });
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

/// Accepts antialiasing drift between machines: the GitHub macOS runner draws
/// the blurred notch edge about 10 pixels differently from a local Mac. A
/// misplaced notch or a lost blur changes thousands of pixels.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const _maxDiff = 0.0005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _maxDiff) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
