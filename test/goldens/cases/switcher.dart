import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

const _navTabs = <(IconData, String)>[
  (Icons.photo_library, 'Library'),
  (Icons.collections, 'Albums'),
  (Icons.search, 'Search'),
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

Future<void> Function(WidgetTester tester, Shot shot) _switcherRun({
  String? switchTo,
  bool midpoint = false,
}) {
  return (tester, shot) async {
    await tester.pumpWidget(_Harness(brightness: shot.brightness));
    await tester.pumpAndSettle();

    final harness = tester.state<_HarnessState>(find.byType(_Harness));
    if (switchTo != null && !midpoint) {
      harness.setMode(switchTo);
      await tester.pumpAndSettle();
    } else if (midpoint) {
      harness.setMode(switchTo!);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }
  };
}

final switcherFeature = GoldenFeature(
  'Morph between bars',
  readme: 'morph-between-bars',
  demo: 'switcher',
  cases: [
    GoldenCase(
      'switcher_nav',
      caption: 'Navigation items before switching',
      size: const Size(400, 260),
      build: (shot) => _Harness(brightness: shot.brightness),
    ),
    GoldenCase(
      'switcher_actions',
      caption: 'Selection actions after switching',
      size: const Size(400, 260),
      run: _switcherRun(switchTo: 'actions'),
    ),
    GoldenCase(
      'switcher_composer',
      caption: 'Message composer after switching',
      size: const Size(400, 260),
      run: _switcherRun(switchTo: 'composer'),
    ),
    GoldenCase(
      'switcher_midpoint',
      caption: 'Switcher halfway through the morph into the composer',
      size: const Size(400, 260),
      run: _switcherRun(switchTo: 'composer', midpoint: true),
    ),
  ],
);

class _Harness extends StatefulWidget {
  const _Harness({required this.brightness});

  final Brightness brightness;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String mode = 'nav';

  void setMode(String value) => setState(() => mode = value);

  Widget _content() {
    switch (mode) {
      case 'actions':
        return SizedBox(
          key: const ValueKey('actions'),
          height: 64,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Text('3 selected'),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.close)),
            ],
          ),
        );
      case 'composer':
        return Padding(
          key: const ValueKey('composer'),
          padding: const EdgeInsets.all(12),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share 3 photos'),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add a message',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      default:
        return BottomBarItems(
          key: const ValueKey('nav'),
          selectedIndex: 0,
          onSelected: (_) {},
          children: [
            for (final tab in _navTabs)
              BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: widget.brightness,
      ),
      home: BottomBar(
        body: const _Stripes(),
        layout: const BottomBarLayout(width: 360),
        theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
        motion: const BottomBarMotion.curved(
          duration: Duration(milliseconds: 400),
          curve: Curves.linear,
        ),
        child: BottomBarSwitcher(child: _content()),
      ),
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
