import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

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
      (previous as LocalFileComparator).basedir.resolve('panel_test.dart'),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _panelGolden('panel_open_glass_light.png');
  _panelGolden('panel_open_glass_dark.png', brightness: Brightness.dark);
  _panelGolden('panel_open_solid_light.png', glass: false);
  _panelGolden(
    'panel_open_solid_dark.png',
    glass: false,
    brightness: Brightness.dark,
  );
  _panelGolden('panel_midpoint_glass_light.png', midpoint: true);
  _panelGolden(
    'panel_midpoint_glass_dark.png',
    midpoint: true,
    brightness: Brightness.dark,
  );
  _panelGolden('panel_open_glass_rtl.png', direction: TextDirection.rtl);
}

void _panelGolden(
  String name, {
  Brightness brightness = Brightness.light,
  bool glass = true,
  bool midpoint = false,
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(name, (tester) async {
    tester.view
      ..physicalSize = const Size(400, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _Harness(brightness: brightness, glass: glass, direction: direction),
    );
    await tester.pumpAndSettle();

    showBottomBarPanel<void>(
      tester.element(find.byType(BottomBarItems)),
      semanticLabel: 'Panel',
      builder: (context) => const _PanelContent(),
    );
    await tester.pump();
    if (midpoint) {
      await tester.pump(const Duration(milliseconds: 200));
    } else {
      await tester.pumpAndSettle();
    }

    await expectLater(find.byType(MaterialApp), matchesGoldenFile(name));
  });
}

class _Harness extends StatelessWidget {
  const _Harness({
    required this.brightness,
    required this.glass,
    required this.direction,
  });

  final Brightness brightness;
  final bool glass;
  final TextDirection direction;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: brightness,
      ),
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: BottomBar(
        body: const _Stripes(),
        layout: const BottomBarLayout(width: 360),
        theme: BottomBarThemeData(
          surface: glass
              ? const BottomBarSurface.glass()
              : const BottomBarSurface.solid(),
        ),
        motion: const BottomBarMotion.curved(
          duration: Duration(milliseconds: 400),
          curve: Curves.linear,
        ),
        child: BottomBarItems(
          selectedIndex: 0,
          onSelected: (_) {},
          children: const [
            BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
            BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
            BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
          ],
        ),
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PanelAction(icon: Icons.photo_camera_outlined, label: 'Photo'),
              _PanelAction(icon: Icons.edit_note, label: 'Note'),
              _PanelAction(icon: Icons.event, label: 'Event'),
              _PanelAction(icon: Icons.link, label: 'Link'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 24, child: Icon(icon)),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
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
