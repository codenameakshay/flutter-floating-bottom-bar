import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
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

final minimizeFeature = GoldenFeature(
  'Minimize on scroll',
  readme: 'minimize-on-scroll',
  demo: 'minimize',
  cases: [
    GoldenCase(
      'minimize_glass',
      caption: 'Minimized glass bar',
      shots: themedRtl,
      size: const Size(400, 200),
      run: _minimizeRun(),
    ),
    GoldenCase(
      'minimize_solid',
      caption: 'Minimized solid bar',
      size: const Size(400, 200),
      run: _minimizeRun(glass: false),
    ),
    GoldenCase(
      'minimize_midpoint',
      caption: 'Glass bar halfway through minimizing',
      shots: const [Shot.light],
      size: const Size(400, 200),
      run: _minimizeRun(midpoint: true),
    ),
    GoldenCase(
      'minimize_pieces',
      caption: 'Minimized glass bar with leading and trailing buttons',
      shots: themedRtl,
      size: const Size(400, 200),
      run: _minimizeRun(pieces: true),
    ),
  ],
);

Future<void> Function(WidgetTester, Shot) _minimizeRun({
  bool glass = true,
  bool midpoint = false,
  bool pieces = false,
}) {
  return (tester, shot) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      goldenApp(
        shot,
        BottomBar(
          body: const _Stripes(),
          layout: const BottomBarLayout(width: 360),
          leading: pieces
              ? IconButton(onPressed: () {}, icon: const Icon(Icons.person))
              : null,
          trailing: pieces
              ? IconButton(onPressed: () {}, icon: const Icon(Icons.search))
              : null,
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
  };
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
