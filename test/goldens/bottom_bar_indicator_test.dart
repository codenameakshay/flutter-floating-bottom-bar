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

void main() {
  late GoldenFileComparator previous;
  setUpAll(() {
    previous = goldenFileComparator;
    goldenFileComparator = _TolerantComparator(
      (previous as LocalFileComparator).basedir.resolve(
        'bottom_bar_indicator_test.dart',
      ),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _indicatorGolden(
    'indicator_pill_light.png',
    const BottomBarIndicator.pill(),
    Brightness.light,
  );
  _indicatorGolden(
    'indicator_pill_dark.png',
    const BottomBarIndicator.pill(),
    Brightness.dark,
  );
  _indicatorGolden(
    'indicator_tint_light.png',
    const BottomBarIndicator.tint(),
    Brightness.light,
  );
  _indicatorGolden(
    'indicator_tint_dark.png',
    const BottomBarIndicator.tint(),
    Brightness.dark,
  );
  _indicatorGolden(
    'indicator_underline_light.png',
    const BottomBarIndicator.underline(),
    Brightness.light,
  );
  _indicatorGolden(
    'indicator_underline_dark.png',
    const BottomBarIndicator.underline(),
    Brightness.dark,
  );
  _indicatorGolden(
    'indicator_dot_light.png',
    const BottomBarIndicator.dot(),
    Brightness.light,
  );
  _indicatorGolden(
    'indicator_dot_dark.png',
    const BottomBarIndicator.dot(),
    Brightness.dark,
  );
  _indicatorGolden(
    'indicator_pill_rtl.png',
    const BottomBarIndicator.pill(),
    Brightness.light,
    direction: TextDirection.rtl,
  );
}

void _indicatorGolden(
  String fileName,
  BottomBarIndicator indicator,
  Brightness brightness, {
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(fileName, (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
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
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(BottomBar), matchesGoldenFile(fileName));
  });
}

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
