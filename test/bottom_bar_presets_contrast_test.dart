import 'dart:math' as math;

import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _textMin = 4.5;
const _iconMin = 3.0;

const _seeds = <Color>[
  Colors.indigo,
  Colors.teal,
  Colors.deepOrange,
  Colors.pink,
  Colors.green,
  Colors.amber,
];

const _white = Color(0xFFFFFFFF);
const _black = Color(0xFF000000);

/// How each preset fills behind the selected item. Pill and tint
/// indicators paint on a canvas, so the test restates their documented
/// fills.
final _presets =
    <
      String,
      ({
        BottomBarThemeData Function() theme,
        Color Function(ColorScheme cs, Color bar) selectedFill,
      })
    >{
      'glass': (
        theme: BottomBarThemeData.glass,
        selectedFill: (cs, bar) =>
            Color.alphaBlend(cs.primary.withValues(alpha: 0.12), bar),
      ),
      'material3': (
        theme: BottomBarThemeData.material3,
        selectedFill: (cs, bar) => cs.secondaryContainer,
      ),
      'pill': (
        theme: BottomBarThemeData.pill,
        selectedFill: (cs, bar) => cs.primary,
      ),
      'minimal': (
        theme: BottomBarThemeData.minimal,
        selectedFill: (cs, bar) => bar,
      ),
    };

double _luminance(Color c) => c.computeLuminance();

double _ratio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Color _textColor(WidgetTester tester, Finder text) => tester
    .widget<RichText>(
      find.descendant(of: text, matching: find.byType(RichText)).first,
    )
    .text
    .style!
    .color!;

/// Every colour the item's label or icon paints in. A selected item under a
/// pill or tint mounts its content twice: the plain copy outside the
/// indicator and the selected copy inside it.
Set<Color> _colors(WidgetTester tester, Finder finder) => {
  for (final text in tester.widgetList<RichText>(
    find.descendant(of: finder, matching: find.byType(RichText)),
  ))
    text.text.style!.color!,
};

void main() {
  testWidgets('material3 indicatorColor picks a contrasting icon colour', (
    tester,
  ) async {
    late ColorScheme colors;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        builder: (context, child) {
          colors = Theme.of(context).colorScheme;
          return child!;
        },
        home: Scaffold(
          body: BottomBar(
            theme: BottomBarThemeData.material3(indicatorColor: Colors.indigo),
            body: const SizedBox.expand(),
            child: BottomBarItems(
              selectedIndex: 0,
              children: const [
                BottomBarItem(icon: Icon(Icons.home), label: Text('On')),
                BottomBarItem(icon: Icon(Icons.search), label: Text('Off')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.renderObject(find.byType(IndicatorTrack)),
      paints..rrect(color: Colors.indigo),
    );
    final foreground = _textColor(tester, find.byIcon(Icons.home));
    expect(foreground, Colors.white);
    expect(_ratio(foreground, Colors.indigo), greaterThanOrEqualTo(_iconMin));
    expect(_textColor(tester, find.text('On')), colors.onSurface);
  });
  for (final MapEntry(key: name, value: preset) in _presets.entries) {
    for (final brightness in Brightness.values) {
      for (final highContrast in [false, true]) {
        testWidgets(
          '$name keeps contrast in $brightness (highContrast: $highContrast)',
          (tester) async {
            final failures = <String>[];
            for (final seed in _seeds) {
              await tester.pumpWidget(
                MaterialApp(
                  theme: ThemeData(
                    colorSchemeSeed: seed,
                    brightness: brightness,
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(highContrast: highContrast),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: BottomBar(
                      theme: preset.theme(),
                      showIcon: false,
                      body: const SizedBox.expand(),
                      child: BottomBarItems(
                        selectedIndex: 0,
                        children: const [
                          BottomBarItem(
                            icon: Icon(Icons.home),
                            label: Text('On'),
                          ),
                          BottomBarItem(
                            icon: Icon(Icons.search),
                            label: Text('Off'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final cs = Theme.of(
                tester.element(find.byType(BottomBar)),
              ).colorScheme;
              final surface = tester
                  .widget<BarSurface>(find.byType(BarSurface))
                  .surface!;
              final tint = surface.tint!;
              final fill = switch (name) {
                'glass' => cs.primary.withValues(alpha: 0.12),
                'material3' => cs.secondaryContainer,
                'pill' => cs.primary,
                'minimal' => cs.primary,
                _ => throw StateError('Unexpected preset $name'),
              };
              expect(
                tester.renderObject(find.byType(IndicatorTrack)),
                paints..rrect(color: fill),
                reason: '$name rendered indicator fill',
              );
              final layer = tint.withValues(
                alpha: tint.a * surface.fillOpacity,
              );
              final backdrops = layer.a == 1 ? [_white] : [_white, _black];

              final hasOff = tester.any(find.text('Off'));
              final offText = hasOff
                  ? _textColor(tester, find.text('Off'))
                  : null;
              final offIcon = _textColor(tester, find.byIcon(Icons.search));
              final onText = _colors(tester, find.text('On'))..remove(offText);
              final onIcon = _colors(tester, find.byIcon(Icons.home))
                ..remove(offIcon);
              expect(onText, isNotEmpty, reason: '$name selected label colour');
              expect(onIcon, isNotEmpty, reason: '$name selected icon colour');

              for (final backdrop in backdrops) {
                final bar = Color.alphaBlend(layer, backdrop);
                final selected = preset.selectedFill(cs, bar);

                void check(String what, Color fg, Color bg, double min) {
                  final r = _ratio(fg, bg);
                  if (r < min) {
                    failures.add(
                      '$what ${r.toStringAsFixed(2)} < $min '
                      '(seed $seed, backdrop $backdrop)',
                    );
                  }
                }

                if (offText != null) {
                  check('unselected label', offText, bar, _textMin);
                }
                check('unselected icon', offIcon, bar, _iconMin);
                if (name == 'minimal') {
                  check('selection dot', cs.primary, bar, _iconMin);
                }
                for (final c in onText) {
                  check(
                    'selected label',
                    c,
                    name == 'material3' ? bar : selected,
                    _textMin,
                  );
                }
                for (final c in onIcon) {
                  check('selected icon', c, selected, _iconMin);
                }
              }
            }
            expect(failures, isEmpty, reason: failures.join('\n'));
          },
        );
      }
    }
  }
}
