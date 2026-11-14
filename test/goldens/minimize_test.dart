import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
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
      (previous as LocalFileComparator).basedir.resolve('minimize_test.dart'),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _minimizeGolden('minimize_glass_light.png');
  _minimizeGolden('minimize_glass_dark.png', brightness: Brightness.dark);
  _minimizeGolden('minimize_solid_light.png', glass: false);
  _minimizeGolden(
    'minimize_solid_dark.png',
    glass: false,
    brightness: Brightness.dark,
  );
  _minimizeGolden('minimize_glass_rtl.png', direction: TextDirection.rtl);
  _minimizeGolden('minimize_midpoint_light.png', midpoint: true);
}

void _minimizeGolden(
  String name, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool glass = true,
  bool midpoint = false,
}) {
  testWidgets(name, (tester) async {
    tester.view
      ..physicalSize = const Size(400, 200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = BottomBarController();
    addTearDown(controller.dispose);
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
            body: const _Stripes(),
            layout: const BottomBarLayout(width: 360),
            theme: BottomBarThemeData(
              surface: glass
                  ? const BottomBarSurface.glass()
                  : const BottomBarSurface.solid(),
            ),
            scrollBehavior: const BottomBarScrollBehavior(
              minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
            ),
            controller: controller,
            child: BottomBarItems(
              selectedIndex: 0,
              indicator: const BottomBarIndicator.pill(),
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  BottomBarItem(
                    icon: Icon(_tabs[i].$1),
                    label: Text(_tabs[i].$2),
                    badge: i == 0 ? const BottomBarBadge.count(3) : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    controller.minimize();
    if (!midpoint) {
      await tester.pumpAndSettle();
    } else {
      final surface = tester.renderObject<RenderBarSurface>(
        find.byType(BarSurface),
      );
      for (var i = 0; i < 120 && surface.morph < 0.5; i++) {
        await tester.pump(const Duration(milliseconds: 8));
      }
    }

    expect(
      controller.visibility.value,
      BottomBarVisibility.minimized,
      reason: 'a hidden bar would make this golden show nothing',
    );
    await expectLater(find.byType(BottomBar), matchesGoldenFile(name));
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
