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

const _indicatorStyles = [
  'pill',
  'tint',
  'underline',
  'dot',
  'container',
  'none',
];

BottomBarIndicator _indicatorNamed(String style) => switch (style) {
  'pill' => const BottomBarIndicator.pill(),
  'tint' => const BottomBarIndicator.tint(),
  'underline' => const BottomBarIndicator.underline(),
  'dot' => const BottomBarIndicator.dot(),
  'container' => const BottomBarIndicator.container(),
  'none' => const BottomBarIndicator.none(),
  _ => throw StateError('Unexpected indicator $style'),
};

/// The default fill a covering indicator paints behind selected content, or
/// null when the indicator paints beneath the content instead.
Color? _indicatorPaint(String style, ColorScheme cs) => switch (style) {
  'pill' => cs.primary,
  'tint' => cs.primary.withValues(alpha: 0.12),
  'container' => cs.secondaryContainer,
  _ => null,
};

Future<ColorScheme> _pumpBar(
  WidgetTester tester, {
  required Color seed,
  required Brightness brightness,
  required bool highContrast,
  required BottomBarThemeData theme,
  BottomBarIndicator? indicator,
  bool badge = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: seed, brightness: brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: child!,
      ),
      home: Scaffold(
        body: BottomBar(
          theme: theme,
          showIcon: false,
          body: const SizedBox.expand(),
          child: BottomBarItems(
            selectedIndex: 0,
            indicator: indicator,
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home),
                label: const Text('On'),
                badge: badge ? BottomBarBadge.count(3) : null,
              ),
              const BottomBarItem(icon: Icon(Icons.search), label: Text('Off')),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return Theme.of(tester.element(find.byType(BottomBar))).colorScheme;
}

/// The selected look of an item. Where the indicator reveals it, that is the
/// copy under [IndicatorInk]; the plain copy outside it sits on the bar. An
/// item with no reveal has one copy, which is the selected look.
Set<Color> _selectedColors(WidgetTester tester, Finder finder) {
  final inked = <Color>{};
  final all = <Color>{};
  for (final element
      in find
          .descendant(of: finder, matching: find.byType(RichText))
          .evaluate()) {
    final color = (element.widget as RichText).text.style!.color!;
    all.add(color);
    if (element.findAncestorWidgetOfExactType<IndicatorInk>() != null) {
      inked.add(color);
    }
  }
  return inked.isEmpty ? all : inked;
}

({Color? offText, Color offIcon, Set<Color> onText, Set<Color> onIcon})
_readItems(WidgetTester tester) {
  final offText = tester.any(find.text('Off'))
      ? _textColor(tester, find.text('Off'))
      : null;
  final offIcon = _textColor(tester, find.byIcon(Icons.search));
  return (
    offText: offText,
    offIcon: offIcon,
    onText: _selectedColors(tester, find.text('On')),
    onIcon: _selectedColors(tester, find.byIcon(Icons.home)),
  );
}

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

  group('indicator styles over presets', () {
    for (final MapEntry(key: name, value: preset) in _presets.entries) {
      for (final style in _indicatorStyles) {
        for (final brightness in Brightness.values) {
          for (final highContrast in [false, true]) {
            testWidgets(
              '$name with $style indicator keeps contrast in $brightness '
              '(highContrast: $highContrast)',
              (tester) async {
                final failures = <String>[];
                for (final seed in _seeds) {
                  final cs = await _pumpBar(
                    tester,
                    seed: seed,
                    brightness: brightness,
                    highContrast: highContrast,
                    theme: preset.theme(),
                    indicator: _indicatorNamed(style),
                  );
                  final surface = tester
                      .widget<BarSurface>(find.byType(BarSurface))
                      .surface!;
                  final tint = surface.tint!;
                  final layer = tint.withValues(
                    alpha: tint.a * surface.fillOpacity,
                  );
                  final backdrops = layer.a == 1 ? [_white] : [_white, _black];
                  final painted = _indicatorPaint(style, cs);
                  if (painted != null) {
                    expect(
                      tester.renderObject(find.byType(IndicatorTrack)),
                      paints..rrect(color: painted),
                      reason: '$name $style rendered indicator fill',
                    );
                  }
                  final items = _readItems(tester);
                  expect(
                    items.onText,
                    isNotEmpty,
                    reason: '$name $style selected label colour',
                  );
                  expect(
                    items.onIcon,
                    isNotEmpty,
                    reason: '$name $style selected icon colour',
                  );

                  for (final backdrop in backdrops) {
                    final bar = Color.alphaBlend(layer, backdrop);
                    final fill = painted == null
                        ? null
                        : Color.alphaBlend(painted, bar);
                    final iconBacking = fill ?? bar;
                    final labelBacking = style == 'container'
                        ? bar
                        : fill ?? bar;

                    void check(String what, Color fg, Color bg, double min) {
                      final r = _ratio(fg, bg);
                      if (r < min) {
                        failures.add(
                          '$what ${r.toStringAsFixed(2)} < $min '
                          '(seed $seed, backdrop $backdrop, fg $fg, bg $bg)',
                        );
                      }
                    }

                    if (items.offText != null) {
                      check('unselected label', items.offText!, bar, _textMin);
                    }
                    check('unselected icon', items.offIcon, bar, _iconMin);
                    for (final c in items.onText) {
                      check('selected label', c, labelBacking, _textMin);
                    }
                    for (final c in items.onIcon) {
                      check('selected icon', c, iconBacking, _iconMin);
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
  });

  group('badge text over its fill', () {
    for (final MapEntry(key: name, value: preset) in _presets.entries) {
      for (final brightness in Brightness.values) {
        for (final highContrast in [false, true]) {
          testWidgets('$name badge text keeps contrast in $brightness '
              '(highContrast: $highContrast)', (tester) async {
            final failures = <String>[];
            for (final seed in _seeds) {
              final theme = preset.theme();
              final cs = await _pumpBar(
                tester,
                seed: seed,
                brightness: brightness,
                highContrast: highContrast,
                theme: theme,
                badge: true,
              );
              expect(find.text('3'), findsOneWidget, reason: '$name badge');
              final fill = theme.items?.badge?.backgroundColor ?? cs.error;
              final text = _textColor(tester, find.text('3'));
              final r = _ratio(text, fill);
              if (r < _textMin) {
                failures.add(
                  'badge text ${r.toStringAsFixed(2)} < $_textMin '
                  '(seed $seed, fill $fill, text $text)',
                );
              }
            }
            expect(failures, isEmpty, reason: failures.join('\n'));
          });
        }
      }
    }
  });

  group('high-contrast fallback', () {
    for (final brightness in Brightness.values) {
      testWidgets('glass bar is opaque and readable in $brightness', (
        tester,
      ) async {
        final failures = <String>[];
        for (final seed in _seeds) {
          final cs = await _pumpBar(
            tester,
            seed: seed,
            brightness: brightness,
            highContrast: true,
            theme: _presets['glass']!.theme(),
          );
          final surface = tester
              .widget<BarSurface>(find.byType(BarSurface))
              .surface!;
          final bar = surface.tint!;
          expect(bar.a, 1.0, reason: 'seed $seed glass tint is opaque');
          final fill = _presets['glass']!.selectedFill(cs, bar);
          final items = _readItems(tester);

          void check(String what, Color fg, Color bg, double min) {
            final r = _ratio(fg, bg);
            if (r < min) {
              failures.add(
                '$what ${r.toStringAsFixed(2)} < $min '
                '(seed $seed, fg $fg, bg $bg)',
              );
            }
          }

          if (items.offText != null) {
            check('unselected label', items.offText!, bar, _textMin);
          }
          check('unselected icon', items.offIcon, bar, _iconMin);
          for (final c in items.onText) {
            check('selected label', c, fill, _textMin);
          }
          for (final c in items.onIcon) {
            check('selected icon', c, fill, _iconMin);
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      });
    }
  });
}
