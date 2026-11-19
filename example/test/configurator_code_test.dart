import 'dart:io';

import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_code.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'configurator_configs.dart';

/// Run with `UPDATE_SNAPSHOTS=1 fvm flutter test test/configurator_code_test.dart`,
/// then `fvm dart format test/configurator_snapshots`, to rewrite them.
final _update = Platform.environment['UPDATE_SNAPSHOTS'] == '1';

/// Drops what dart format may change: whitespace and trailing commas.
String _normalize(String code) => code
    .replaceAll(RegExp(r'\s+'), '')
    .replaceAll(',)', ')')
    .replaceAll(',]', ']');

void main() {
  final dir = Directory('test/configurator_snapshots');

  for (final MapEntry(key: name, value: config) in snapshotConfigs.entries) {
    test('$name generates its committed snapshot', () {
      final file = File('${dir.path}/$name.dart');
      final code = generateCode(config);
      if (_update) file.writeAsStringSync(code);
      expect(_normalize(code), _normalize(file.readAsStringSync()));
    });
  }

  test('every snapshot file has a config', () {
    final files = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last.replaceAll('.dart', ''))
        .toSet();
    expect(files, snapshotConfigs.keys.toSet());
  });

  test('the bare preset generates no copyWith', () {
    expect(
      generateCode(BarConfig.defaults),
      contains('theme: BottomBarThemeData.glass(),'),
    );
    expect(generateCode(BarConfig.defaults), isNot(contains('copyWith')));
    expect(
      generateCode(BarConfig.defaults.set(Knob.preset, BarPreset.none)),
      isNot(contains('BottomBarThemeData')),
    );
  });

  test('every bare preset omits overrides and constructor defaults', () {
    for (final preset in BarPreset.values) {
      final config = BarConfig.defaults.set(Knob.preset, preset);
      final code = generateCode(config);
      expect(code, isNot(contains('copyWith')));
      expect(code, isNot(contains('indicator:')));
      expect(code, isNot(contains('scrollBehavior:')));
      expect(code, isNot(contains('labelBehavior:')));
      expect(code, isNot(contains('BottomBarLayout')));
    }
  });

  test('a changed knob adds only its own field', () {
    final code = generateCode(
      BarConfig.defaults.set(Knob.motion, MotionStyle.bouncy),
    );
    expect(
      _normalize(code),
      contains(
        _normalize('''
theme: BottomBarThemeData.glass().copyWith(
  motion: const BottomBarMotion.cupertino(
    preset: BottomBarCupertinoMotion.bouncy,
  ),
),'''),
      ),
    );
  });

  test('a disabled knob leaves no trace in the code', () {
    final glass = BarConfig.defaults;
    expect(
      generateCode(
        glass.set(Knob.surface, SurfaceStyle.solid).set(Knob.blur, 30.0),
      ),
      generateCode(glass.set(Knob.surface, SurfaceStyle.solid)),
    );
  });

  test('preset matrix keeps the selected layout, surface and edge', () {
    for (final preset in BarPreset.values) {
      for (final layout in LayoutStyle.values) {
        for (final surface in SurfaceStyle.values) {
          for (final edge in [false, true]) {
            for (final tint in BarTint.values) {
              final config = BarConfig.defaults
                  .set(Knob.preset, preset)
                  .set(Knob.layout, layout)
                  .set(Knob.surface, surface)
                  .set(Knob.scrollEdge, edge)
                  .set(Knob.tint, tint);
              final theme = buildTheme(config)?.value;
              final resolvedLayout = theme?.layout ?? const BottomBarLayout();
              expect(resolvedLayout.docked, layout == LayoutStyle.docked);
              expect(
                resolvedLayout.width.isInfinite,
                layout != LayoutStyle.floating,
              );
              if (layout == LayoutStyle.adaptive) {
                expect(resolvedLayout.maxWidth, preset.maxWidth);
              }
              if (theme?.surface case final actual?) {
                expect(actual.blur, surface == SurfaceStyle.glass ? 16 : 0);
                expect(actual.tint, tint.color);
              }
              if (edge) {
                expect(theme?.scrollEdgeSurface?.fillOpacity, 0);
              } else if (theme?.scrollEdgeSurface case final actual?) {
                expect(actual, theme!.surface);
              }
              final code = generateCode(config);
              expect(code, isNot(contains('NaN')));
              expect(code, isNot(contains('Infinity')));
            }
          }
        }
      }
    }
  });

  test('every indicator preserves the preset choice or overrides it', () {
    for (final preset in BarPreset.values) {
      final base = BarConfig.defaults.set(Knob.preset, preset);
      for (final indicator in IndicatorStyle.values) {
        final part = buildIndicator(base.set(Knob.indicator, indicator));
        if (indicator == base.get(Knob.indicator)) {
          expect(part, isNull);
        } else {
          expect(part, isNotNull);
          expect(
            generateCode(base.set(Knob.indicator, indicator)),
            contains('const BottomBarIndicator.${indicator.name}()'),
          );
        }
      }
    }
  });

  test('all disabled controls and environment knobs leave no code trace', () {
    for (final preset in BarPreset.values) {
      final base = BarConfig.defaults.set(Knob.preset, preset);
      final solid = base.set(Knob.surface, SurfaceStyle.solid);
      expect(generateCode(solid.set(Knob.blur, 40.0)), generateCode(solid));
      final docked = base.set(Knob.layout, LayoutStyle.docked);
      expect(
        generateCode(
          docked
              .set(Knob.offset, 32.0)
              .set(Knob.leading, true)
              .set(Knob.trailing, true),
        ),
        generateCode(docked),
      );
      for (final minimize in BottomBarMinimizeBehavior.values.skip(1)) {
        final minimized = base.set(Knob.minimize, minimize);
        expect(
          generateCode(
            minimized
                .set(Knob.hideOnScroll, false)
                .set(Knob.followScroll, true),
          ),
          generateCode(minimized),
        );
      }
      final noHide = base.set(Knob.hideOnScroll, false);
      expect(
        generateCode(noHide.set(Knob.followScroll, true)),
        generateCode(noHide),
      );
      expect(
        generateCode(
          base
              .set(Knob.dark, true)
              .set(Knob.rtl, true)
              .set(Knob.textScale, 2.0),
        ),
        generateCode(base),
      );
    }
  });
}
