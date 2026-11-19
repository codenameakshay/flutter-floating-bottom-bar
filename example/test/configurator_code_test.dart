import 'dart:io';

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
      isNot(contains('theme:')),
    );
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
}
