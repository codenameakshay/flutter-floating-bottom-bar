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
      (previous as LocalFileComparator).basedir.resolve(
        'glass_surface_test.dart',
      ),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _glassGolden('glass_default_light.png');
  _glassGolden('glass_default_dark.png', brightness: Brightness.dark);
  _glassGolden('glass_notched_light.png', notched: true);
  _glassGolden(
    'glass_notched_dark.png',
    notched: true,
    brightness: Brightness.dark,
  );
  _glassGolden(
    'glass_shadow_light.png',
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
  );
  _glassGolden('glass_high_contrast_light.png', highContrast: true);
  _glassGolden(
    'glass_high_contrast_dark.png',
    highContrast: true,
    brightness: Brightness.dark,
  );
  _glassGolden(
    'glass_over_white_light.png',
    background: const ColoredBox(color: Colors.white, child: SizedBox.expand()),
  );
  _glassGolden(
    'glass_over_black_light.png',
    background: const ColoredBox(color: Colors.black, child: SizedBox.expand()),
  );
  _glassGolden(
    'glass_over_white_dark.png',
    background: const ColoredBox(color: Colors.white, child: SizedBox.expand()),
    brightness: Brightness.dark,
  );
  _glassGolden(
    'glass_over_black_dark.png',
    background: const ColoredBox(color: Colors.black, child: SizedBox.expand()),
    brightness: Brightness.dark,
  );
  _glassGolden(
    'glass_notched_rtl.png',
    notched: true,
    direction: TextDirection.rtl,
  );
}

void _glassGolden(
  String fileName, {
  BottomBarSurface surface = const BottomBarSurface.glass(),
  Brightness brightness = Brightness.light,
  bool notched = false,
  bool highContrast = false,
  TextDirection direction = TextDirection.ltr,
  Widget? background,
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
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(highContrast: highContrast),
            child: Directionality(
              textDirection: direction,
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
