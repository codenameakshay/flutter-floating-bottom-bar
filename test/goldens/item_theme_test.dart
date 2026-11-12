import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.search, Icons.search, 'Search'),
  (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
  (Icons.person_outline, Icons.person, 'Profile'),
];

void main() {
  late GoldenFileComparator previous;
  setUpAll(() {
    previous = goldenFileComparator;
    goldenFileComparator = _TolerantComparator(
      (previous as LocalFileComparator).basedir.resolve('item_theme_test.dart'),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _itemThemeGolden(
    'item_theme_quiet_light.png',
    quietItemTheme,
    BottomBarLabelBehavior.alwaysShow,
    Brightness.light,
  );
  _itemThemeGolden(
    'item_theme_quiet_dark.png',
    quietItemTheme,
    BottomBarLabelBehavior.alwaysShow,
    Brightness.dark,
  );
  _itemThemeGolden(
    'item_theme_bold_light.png',
    boldItemTheme,
    BottomBarLabelBehavior.onlySelected,
    Brightness.light,
  );
  _itemThemeGolden(
    'item_theme_bold_dark.png',
    boldItemTheme,
    BottomBarLabelBehavior.onlySelected,
    Brightness.dark,
  );
  _itemThemeGolden(
    'item_theme_icon_only_light.png',
    iconOnlyItemTheme,
    BottomBarLabelBehavior.alwaysHide,
    Brightness.light,
  );
  _itemThemeGolden(
    'item_theme_icon_only_dark.png',
    iconOnlyItemTheme,
    BottomBarLabelBehavior.alwaysHide,
    Brightness.dark,
  );
  _itemThemeGolden(
    'item_theme_bold_rtl.png',
    boldItemTheme,
    BottomBarLabelBehavior.onlySelected,
    Brightness.light,
    direction: TextDirection.rtl,
  );
}

BottomBarItemThemeData quietItemTheme(ColorScheme cs) => BottomBarItemThemeData(
  color: cs.onSurfaceVariant,
  selectedColor: cs.onSecondaryContainer,
  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
  iconLabelGap: 4,
  indicator: BottomBarIndicator.tint(
    color: cs.secondaryContainer,
    foregroundColor: cs.onSecondaryContainer,
  ),
);

BottomBarItemThemeData boldItemTheme(ColorScheme cs) => BottomBarItemThemeData(
  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  selectedLabelStyle: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),
  iconSize: 22,
  selectedIconSize: 24,
  pressedScale: 0.9,
  indicator: BottomBarIndicator.pill(color: cs.tertiary, stretch: true),
);

BottomBarItemThemeData iconOnlyItemTheme(ColorScheme cs) =>
    BottomBarItemThemeData(
      color: cs.outline,
      selectedColor: cs.primary,
      iconSize: 26,
      selectedIconSize: 30,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      indicator: const BottomBarIndicator.dot(),
    );

void _itemThemeGolden(
  String fileName,
  BottomBarItemThemeData Function(ColorScheme cs) itemTheme,
  BottomBarLabelBehavior labelBehavior,
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
            body: Builder(
              builder: (context) => BottomBar(
                theme: BottomBarThemeData(
                  items: itemTheme(Theme.of(context).colorScheme),
                ),
                body: const SizedBox.shrink(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BottomBarItems(
                    selectedIndex: 1,
                    labelBehavior: labelBehavior,
                    children: [
                      for (final tab in _tabs)
                        BottomBarItem(
                          icon: Icon(tab.$1),
                          selectedIcon: Icon(tab.$2),
                          label: Text(tab.$3),
                        ),
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
