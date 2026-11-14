import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  late GoldenFileComparator previous;
  setUpAll(() {
    previous = goldenFileComparator;
    goldenFileComparator = _TolerantComparator(
      (previous as LocalFileComparator).basedir.resolve('presets_test.dart'),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _presetGolden('preset_glass_light.png', () => BottomBarThemeData.glass());
  _presetGolden(
    'preset_glass_dark.png',
    () => BottomBarThemeData.glass(),
    brightness: Brightness.dark,
  );
  _presetGolden(
    'preset_material3_light.png',
    () => BottomBarThemeData.material3(),
  );
  _presetGolden(
    'preset_material3_dark.png',
    () => BottomBarThemeData.material3(),
    brightness: Brightness.dark,
  );
  _presetGolden('preset_pill_light.png', () => BottomBarThemeData.pill());
  _presetGolden(
    'preset_pill_dark.png',
    () => BottomBarThemeData.pill(),
    brightness: Brightness.dark,
  );
  _presetGolden(
    'preset_minimal_light.png',
    () => BottomBarThemeData.minimal(),
    labelBehavior: BottomBarLabelBehavior.onlySelected,
  );
  _presetGolden(
    'preset_minimal_dark.png',
    () => BottomBarThemeData.minimal(),
    brightness: Brightness.dark,
    labelBehavior: BottomBarLabelBehavior.onlySelected,
  );
  _presetGolden(
    'preset_pill_rtl.png',
    () => BottomBarThemeData.pill(),
    direction: TextDirection.rtl,
  );
  _presetGolden(
    'preset_glass_notched_badges_light.png',
    () => BottomBarThemeData.glass(),
    notched: true,
    badged: true,
  );

  testWidgets('preset_material3_vs_navigation_bar_light.png', (tester) async {
    tester.view.physicalSize = const Size(390, 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
        ),
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
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
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preset_material3_vs_navigation_bar_light.png'),
    );
  });
}

void _presetGolden(
  String file,
  BottomBarThemeData Function() preset, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool notched = false,
  bool badged = false,
  BottomBarLabelBehavior labelBehavior = BottomBarLabelBehavior.alwaysShow,
}) {
  testWidgets(file, (tester) async {
    tester.view.physicalSize = Size(390, notched ? 260 : 220);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: Directionality(
          textDirection: direction,
          child: BottomBar(
            theme: preset(),
            showIcon: false,
            body: _backdrop(),
            child: BottomBarItems(
              selectedIndex: 1,
              onSelected: (_) {},
              labelBehavior: labelBehavior,
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
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(BottomBar), matchesGoldenFile(file));
  });
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

/// Accepts antialiasing drift between machines: the GitHub macOS runner
/// rasterises these icon glyphs and curves a few pixels differently from a
/// local Mac. A misplaced indicator changes thousands of pixels, far above
/// this limit.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const _maxDiff = 0.0001;

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
