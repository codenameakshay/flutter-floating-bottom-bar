@Tags(['golden'])
library;

import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
  _railGolden('rail_glass_floating_light.png', BottomBarThemeData.glass);
  _railGolden(
    'rail_glass_floating_dark.png',
    BottomBarThemeData.glass,
    brightness: Brightness.dark,
  );
  _railGolden(
    'rail_glass_floating_rtl.png',
    BottomBarThemeData.glass,
    direction: TextDirection.rtl,
  );
  _railGolden(
    'rail_material3_attached_light.png',
    BottomBarThemeData.material3,
  );
  _railGolden(
    'rail_material3_attached_dark.png',
    BottomBarThemeData.material3,
    brightness: Brightness.dark,
  );
  _railGolden(
    'rail_material3_attached_rtl.png',
    BottomBarThemeData.material3,
    direction: TextDirection.rtl,
  );
  _railGolden(
    'rail_labels_selected_light.png',
    BottomBarThemeData.material3,
    labels: BottomBarLabelBehavior.onlySelected,
  );
  _railGolden(
    'rail_labels_all_light.png',
    BottomBarThemeData.glass,
    labels: BottomBarLabelBehavior.alwaysShow,
  );
}

void _railGolden(
  String file,
  BottomBarThemeData Function() preset, {
  Brightness brightness = Brightness.light,
  TextDirection direction = TextDirection.ltr,
  BottomBarLabelBehavior? labels,
}) {
  testWidgets(file, (tester) async {
    tester.view.physicalSize = const Size(720, 560);
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
          child: Scaffold(
            body: BottomBarAdaptive(
              theme: preset(),
              railLabelBehavior: labels,
              items: BottomBarItems(
                selectedIndex: 1,
                onSelected: (_) {},
                centerAction: BottomBarCenterAction(
                  icon: const Icon(Icons.add),
                  tooltip: 'Create',
                  onPressed: () {},
                ),
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    BottomBarItem(
                      icon: Icon(_tabs[i].$1),
                      selectedIcon: Icon(_tabs[i].$2),
                      label: Text(_tabs[i].$3),
                      badge: switch (i) {
                        2 => const BottomBarBadge.count(3),
                        3 => const BottomBarBadge.dot(),
                        _ => null,
                      },
                    ),
                ],
              ),
              body: Row(
                children: [
                  for (final c in _backdropColors)
                    Expanded(
                      child: ColoredBox(
                        color: c,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(BottomBarAdaptive), matchesGoldenFile(file));
  });
}
