import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final presets = <String, BottomBarThemeData Function()>{
  'glass': BottomBarThemeData.glass,
  'material3': BottomBarThemeData.material3,
  'pill': BottomBarThemeData.pill,
  'minimal': BottomBarThemeData.minimal,
};

const _brightnesses = [Brightness.light, Brightness.dark];

BottomBarItems _row({bool badge = false, bool notched = false}) =>
    BottomBarItems(
      selectedIndex: 0,
      onSelected: (_) {},
      centerAction: notched
          ? BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Create',
              style: BottomBarCenterActionStyle.notched,
              onPressed: () {},
            )
          : null,
      children: [
        const BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
        BottomBarItem(
          icon: const Icon(Icons.search),
          label: const Text('Search'),
          badge: badge ? const BottomBarBadge.count(3) : null,
        ),
        const BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
        if (notched)
          const BottomBarItem(
            icon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
      ],
    );

/// Every resolved [BarSurface] in the tree. A leading or trailing action
/// builds a group with more than one bar surface.
Future<List<BarSurface>> _pump(
  WidgetTester tester, {
  BottomBarThemeData? theme,
  Brightness brightness = Brightness.light,
  List<ThemeExtension<dynamic>> extensions = const [],
  bool badge = false,
  bool notched = false,
  bool leading = false,
  bool rtl = false,
  bool highContrast = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: brightness,
        extensions: extensions,
      ),
      builder: (context, child) => highContrast
          ? MediaQuery(
              data: const MediaQueryData(highContrast: true),
              child: child!,
            )
          : child!,
      home: Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: BottomBar(
            theme: theme,
            leading: leading
                ? IconButton(onPressed: () {}, icon: const Icon(Icons.menu))
                : null,
            body: ListView(
              children: [
                for (var i = 0; i < 40; i++) ListTile(title: Text('Row $i')),
              ],
            ),
            child: _row(badge: badge, notched: notched),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widgetList<BarSurface>(find.byType(BarSurface)).toList();
}

ColorScheme _scheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(BottomBar))).colorScheme;

void main() {
  for (final entry in presets.entries) {
    testWidgets(
      '${entry.key} pumps in light and dark and fills its tint from the scheme',
      (tester) async {
        final tints = <Brightness, Color>{};
        for (final brightness in _brightnesses) {
          final surface = (await _pump(
            tester,
            theme: entry.value(),
            brightness: brightness,
          )).single;
          expect(tester.takeException(), isNull);
          final tint = _scheme(tester).surfaceContainer;
          expect(surface.surface!.tint, tint);
          tints[brightness] = tint;
        }
        expect(tints[Brightness.light], isNot(tints[Brightness.dark]));
      },
    );

    testWidgets(
      '${entry.key} resolves the same surface as theme and as an extension',
      (tester) async {
        final asTheme = (await _pump(tester, theme: entry.value())).single;
        final asExtension = (await _pump(
          tester,
          extensions: [entry.value()],
        )).single;
        expect(asTheme.surface, isNotNull);
        expect(asExtension.surface, equals(asTheme.surface));
      },
    );

    test(
      '${entry.key} copyWith replaces motion and keeps the other fields',
      () {
        final t = entry.value().copyWith(
          motion: const BottomBarMotion.curved(),
        );
        final base = entry.value();
        expect(t.motion, const BottomBarMotion.curved());
        expect(t.layout, base.layout);
        expect(t.surface, base.surface);
        expect(t.items, base.items);
      },
    );

    test(
      '${entry.key} copyWith changing surface preserves the edge surface',
      () {
        final base = entry.value();
        final surface = const BottomBarSurface.solid(color: Colors.orange);
        final copy = base.copyWith(surface: surface);
        expect(copy.surface, surface);
        expect(copy.scrollEdgeSurface, base.scrollEdgeSurface);
      },
    );

    test('${entry.key} merge keeps the fields the override leaves null', () {
      final base = entry.value();
      final merged = base.merge(
        const BottomBarThemeData(
          items: BottomBarItemThemeData(haptics: BottomBarHaptics.none),
        ),
      );
      expect(merged.layout, base.layout);
      expect(merged.surface, base.surface);
      expect(merged.scrollEdgeSurface, base.scrollEdgeSurface);
      expect(merged.motion, base.motion);
      expect(merged.items!.indicator, base.items!.indicator);
      expect(merged.items!.labelStyle, base.items!.labelStyle);
      expect(merged.items!.haptics, BottomBarHaptics.none);
    });

    test('${entry.key} equals a fresh copy of itself', () {
      expect(entry.value() == entry.value(), isTrue);
    });
  }

  testWidgets('glass fills its edge surface from the scheme and stays clear', (
    tester,
  ) async {
    for (final brightness in _brightnesses) {
      final surface = (await _pump(
        tester,
        theme: BottomBarThemeData.glass(),
        brightness: brightness,
      )).single;
      expect(tester.takeException(), isNull);
      expect(surface.edgeSurface!.tint, _scheme(tester).surfaceContainer);
      expect(surface.edgeSurface!.fillOpacity, 0);
    }
  });

  test('only material3 is docked', () {
    expect(BottomBarThemeData.material3().layout!.docked, isTrue);
    expect(BottomBarThemeData.glass().layout!.docked, isFalse);
    expect(BottomBarThemeData.pill().layout!.docked, isFalse);
    expect(BottomBarThemeData.minimal().layout!.docked, isFalse);
  });

  for (final entry in presets.entries) {
    testWidgets('${entry.key} extension styles a standalone item', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            extensions: [entry.value()],
          ),
          home: const Scaffold(
            body: BottomBarItem(
              icon: Icon(Icons.home),
              label: Text('Standalone'),
              selected: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final primary = Theme.of(
        tester.element(find.byType(BottomBarItem)),
      ).colorScheme.primary;
      expect(
        tester
            .widgetList<IconTheme>(
              find.descendant(
                of: find.byType(BottomBarItem),
                matching: find.byType(IconTheme),
              ),
            )
            .any((theme) => theme.data.color == primary),
        isTrue,
      );
      expect(find.text('Standalone'), findsOneWidget);
      final labelStyle = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Standalone'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(labelStyle.style.color, primary);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'merging glass onto material3 takes glass surface, layout and indicator',
    () {
      final merged = BottomBarThemeData.material3().merge(
        BottomBarThemeData.glass(),
      );
      expect(merged.surface, BottomBarThemeData.glass().surface);
      expect(merged.layout, BottomBarThemeData.glass().layout);
      expect(
        merged.items!.indicator,
        BottomBarThemeData.glass().items!.indicator,
      );
    },
  );

  final nonGlassPresets = {
    'material3': BottomBarThemeData.material3,
    'pill': BottomBarThemeData.pill,
    'minimal': BottomBarThemeData.minimal,
  };
  for (final entry in nonGlassPresets.entries) {
    test('merging ${entry.key} onto glass uses its scrollEdgeSurface', () {
      final preset = entry.value();
      final merged = BottomBarThemeData.glass().merge(preset);
      expect(merged.surface, preset.surface);
      expect(merged.layout, preset.layout);
      expect(merged.scrollEdgeSurface, preset.scrollEdgeSurface);
    });

    testWidgets('${entry.key} stays solid at the real scroll edge', (
      tester,
    ) async {
      final theme = BottomBarThemeData.glass().merge(entry.value());
      final surface = (await _pump(tester, theme: theme)).single;
      expect(surface.surface!.fillOpacity, 1);
      expect(surface.edgeSurface!.fillOpacity, 1);

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(surface.edge!.value, 1);
    });
  }

  test('accent colours the selected item in glass and minimal', () {
    expect(
      BottomBarThemeData.glass(accent: Colors.red).items!.selectedColor,
      Colors.red,
    );
    expect(
      BottomBarThemeData.minimal(accent: Colors.red).items!.selectedColor,
      Colors.red,
    );
  });

  test('indicator replaces the default indicator in pill and minimal', () {
    expect(
      BottomBarThemeData.pill(
        indicator: const BottomBarIndicator.dot(),
      ).items!.indicator,
      const BottomBarIndicator.dot(),
    );
    expect(
      BottomBarThemeData.minimal(
        indicator: const BottomBarIndicator.underline(),
      ).items!.indicator,
      const BottomBarIndicator.underline(),
    );
  });

  for (final entry in presets.entries) {
    testWidgets(
      '${entry.key} survives centre action, badge, leading, RTL and high contrast',
      (tester) async {
        for (final notched in [false, true]) {
          for (final leading in [false, true]) {
            for (final rtl in [false, true]) {
              for (final highContrast in [false, true]) {
                final combination =
                    'notched=$notched leading=$leading rtl=$rtl '
                    'highContrast=$highContrast';
                final surfaces = await _pump(
                  tester,
                  theme: entry.value(),
                  badge: true,
                  notched: notched,
                  leading: leading,
                  rtl: rtl,
                  highContrast: highContrast,
                );
                expect(tester.takeException(), isNull, reason: combination);
                expect(find.text('3'), findsOneWidget, reason: combination);
                expect(surfaces, isNotEmpty, reason: combination);
                if (highContrast) {
                  for (final surface in surfaces) {
                    expect(
                      surface.surface!.fillOpacity,
                      1,
                      reason: combination,
                    );
                    expect(surface.surface!.blur, 0, reason: combination);
                  }
                }
              }
            }
          }
        }
      },
    );
  }
}
