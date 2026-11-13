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
      (previous as LocalFileComparator).basedir.resolve('bar_group_test.dart'),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _groupGolden('group_glass_light.png');
  _groupGolden('group_glass_dark.png', brightness: Brightness.dark);
  _groupGolden(
    'group_solid_light.png',
    surface: const BottomBarSurface.solid(),
  );
  _groupGolden(
    'group_solid_dark.png',
    surface: const BottomBarSurface.solid(),
    brightness: Brightness.dark,
  );
  _groupGolden('group_glass_rtl.png', direction: TextDirection.rtl);
}

void _groupGolden(
  String fileName, {
  BottomBarSurface surface = const BottomBarSurface.glass(),
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(fileName, (tester) async {
    tester.view
      ..physicalSize = const Size(520, 200)
      ..devicePixelRatio = 1;
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
