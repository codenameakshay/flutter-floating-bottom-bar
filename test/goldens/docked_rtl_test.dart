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

void main() {
  late GoldenFileComparator previous;
  setUpAll(() {
    previous = goldenFileComparator;
    goldenFileComparator = _TolerantComparator(
      (previous as LocalFileComparator).basedir.resolve('docked_rtl_test.dart'),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _barGolden(
    'docked_solid_light.png',
    layout: const BottomBarLayout.docked(),
    surface: const BottomBarSurface.solid(),
    insets: const EdgeInsets.only(bottom: 24),
  );
  _barGolden(
    'docked_solid_dark.png',
    layout: const BottomBarLayout.docked(),
    surface: const BottomBarSurface.solid(),
    insets: const EdgeInsets.only(bottom: 24),
    brightness: Brightness.dark,
  );
  _barGolden(
    'docked_glass_light.png',
    layout: const BottomBarLayout.docked(),
    surface: const BottomBarSurface.glass(),
    insets: const EdgeInsets.only(bottom: 24),
  );
  _barGolden(
    'docked_glass_dark.png',
    layout: const BottomBarLayout.docked(),
    surface: const BottomBarSurface.glass(),
    insets: const EdgeInsets.only(bottom: 24),
    brightness: Brightness.dark,
  );
  _barGolden(
    'rtl_start_aligned.png',
    layout: const BottomBarLayout(
      width: 220,
      directionalAlignment: AlignmentDirectional.bottomStart,
    ),
    surface: const BottomBarSurface.glass(),
    direction: TextDirection.rtl,
  );
  _barGolden(
    'landscape_side_insets.png',
    size: const Size(800, 240),
    layout: const BottomBarLayout(width: double.infinity),
    surface: const BottomBarSurface.solid(),
    insets: const EdgeInsets.only(left: 47, right: 47, bottom: 21),
  );
}

void _barGolden(
  String fileName, {
  Size size = const Size(400, 240),
  EdgeInsets insets = EdgeInsets.zero,
  required BottomBarLayout layout,
  BottomBarSurface surface = const BottomBarSurface.glass(),
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(fileName, (tester) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size, padding: insets, viewPadding: insets),
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: brightness,
          ),
          home: Directionality(
            textDirection: direction,
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
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(BottomBar), matchesGoldenFile(fileName));
  });
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
