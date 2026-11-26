@Tags(['golden'])
library;

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
  _accessoryGolden('accessory_expanded_glass_light.png');
  _accessoryGolden(
    'accessory_expanded_glass_dark.png',
    brightness: Brightness.dark,
  );
  _accessoryGolden('accessory_expanded_solid_light.png', glass: false);
  _accessoryGolden(
    'accessory_expanded_solid_dark.png',
    glass: false,
    brightness: Brightness.dark,
  );
  _accessoryGolden(
    'accessory_expanded_glass_rtl.png',
    direction: TextDirection.rtl,
  );
  _accessoryGolden('accessory_inline_glass_light.png', minimized: true);
  _accessoryGolden(
    'accessory_inline_glass_dark.png',
    minimized: true,
    brightness: Brightness.dark,
  );
  _accessoryGolden(
    'accessory_inline_solid_light.png',
    minimized: true,
    glass: false,
  );
  _accessoryGolden(
    'accessory_inline_solid_dark.png',
    minimized: true,
    glass: false,
    brightness: Brightness.dark,
  );
  _accessoryGolden(
    'accessory_inline_glass_rtl.png',
    minimized: true,
    direction: TextDirection.rtl,
  );
}

void _accessoryGolden(
  String name, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  bool glass = true,
  bool minimized = false,
}) {
  testWidgets(name, (tester) async {
    tester.view
      ..physicalSize = const Size(400, 260)
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
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            accessory: Builder(builder: _accessory),
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

    if (minimized) {
      controller.minimize();
      await tester.pumpAndSettle();
    }

    expect(
      controller.visibility.value,
      minimized ? BottomBarVisibility.minimized : BottomBarVisibility.shown,
      reason: minimized
          ? 'a hidden bar would make this golden show nothing'
          : 'the expanded golden needs the full bar on screen',
    );
    await expectLater(find.byType(BottomBar), matchesGoldenFile(name));
  });
}

Widget _accessory(BuildContext context) {
  final placement = BottomBarAccessoryPlacement.of(context);
  final artwork = DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.deepOrange,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(child: Icon(Icons.music_note, color: Colors.white)),
  );
  if (placement == BottomBarAccessoryPlacement.inline) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          SizedBox.square(dimension: 36, child: artwork),
          const Spacer(),
          const Icon(Icons.play_arrow_rounded),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
  return SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox.square(dimension: 40, child: artwork),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Midnight City',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.play_arrow_rounded),
          const SizedBox(width: 8),
        ],
      ),
    ),
  );
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
