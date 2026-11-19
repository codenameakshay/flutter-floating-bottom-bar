import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_config.dart';
import 'package:flutter_test/flutter_test.dart';

BarConfig setAny<T extends Object>(BarConfig c, Knob<T> k, Object v) =>
    c.set(k, v as T);

List<Object> valuesOf<T extends Object>(Knob<T> knob) {
  final range = knob.range;
  if (range != null) return [range.$1, range.$2, 6.0];
  return knob.options!;
}

void main() {
  group('round trip', () {
    for (final knob in Knob.values) {
      for (final value in valuesOf(knob)) {
        test('${knob.name} = $value survives encode and decode', () {
          final config = setAny(BarConfig.defaults, knob, value);
          expect(BarConfig.decode(config.encode()), config);
        });
      }
    }

    test('many knobs changed at once survive encode and decode', () {
      final config = BarConfig.defaults
          .set(Knob.preset, BarPreset.pill)
          .set(Knob.indicator, IndicatorStyle.dot)
          .set(Knob.surface, SurfaceStyle.glass)
          .set(Knob.blur, 24.0)
          .set(Knob.tint, BarTint.pink)
          .set(Knob.layout, LayoutStyle.floating)
          .set(Knob.offset, 20.0)
          .set(Knob.motion, MotionStyle.bouncy)
          .set(Knob.hideOnScroll, false)
          .set(Knob.minimize, BottomBarMinimizeBehavior.onScrollUp)
          .set(Knob.showAtStart, true)
          .set(Knob.items, 5)
          .set(Knob.labels, false)
          .set(Knob.badge, true)
          .set(Knob.center, CenterStyle.notched)
          .set(Knob.accessory, true)
          .set(Knob.dark, true)
          .set(Knob.rtl, true)
          .set(Knob.textScale, 2.0);

      expect(BarConfig.decode(config.encode()), config);
    });

    test('many knobs changed at once survive a location round trip', () {
      final config = BarConfig.defaults
          .set(Knob.preset, BarPreset.pill)
          .set(Knob.indicator, IndicatorStyle.dot)
          .set(Knob.surface, SurfaceStyle.glass)
          .set(Knob.blur, 24.0)
          .set(Knob.tint, BarTint.pink)
          .set(Knob.layout, LayoutStyle.floating)
          .set(Knob.offset, 20.0)
          .set(Knob.motion, MotionStyle.bouncy)
          .set(Knob.hideOnScroll, false)
          .set(Knob.minimize, BottomBarMinimizeBehavior.onScrollUp)
          .set(Knob.showAtStart, true)
          .set(Knob.items, 5)
          .set(Knob.labels, false)
          .set(Knob.badge, true)
          .set(Knob.center, CenterStyle.notched)
          .set(Knob.accessory, true)
          .set(Knob.dark, true)
          .set(Knob.rtl, true)
          .set(Knob.textScale, 2.0);

      final encoded = Uri.parse(config.location).queryParameters['c'];
      expect(BarConfig.decode(encoded), config);
    });
  });

  group('literal encodings', () {
    test('defaults encode to an empty string at the bare route', () {
      expect(BarConfig.defaults.encode(), '');
      expect(BarConfig.defaults.location, '/configurator');
    });

    test('changed knobs encode as key:value pairs in panel order', () {
      final config = BarConfig.defaults
          .set(Knob.blur, 24.0)
          .set(Knob.rtl, true);
      expect(config.location, '/configurator?c=blur:24,rtl:1');
    });

    test('a preset change encodes as preset:name alone', () {
      expect(
        BarConfig.defaults.set(Knob.preset, BarPreset.pill).encode(),
        'preset:pill',
      );
    });
  });

  group('bad links fall back to defaults', () {
    test('null and empty links', () {
      expect(BarConfig.decode(null), BarConfig.defaults);
      expect(BarConfig.decode(''), BarConfig.defaults);
    });

    test('links with no key and value pairs', () {
      expect(BarConfig.decode('garbage'), BarConfig.defaults);
      expect(BarConfig.decode(':::,,,'), BarConfig.defaults);
    });

    test('unknown preset', () {
      expect(BarConfig.decode('preset:nope'), BarConfig.defaults);
    });

    test('non-numeric slider value', () {
      expect(BarConfig.decode('blur:abc'), BarConfig.defaults);
    });

    test('slider value above its range', () {
      expect(BarConfig.decode('blur:999'), BarConfig.defaults);
    });

    test('slider value below its range', () {
      expect(BarConfig.decode('blur:-1'), BarConfig.defaults);
    });

    test('option value outside the knob options', () {
      expect(BarConfig.decode('items:7'), BarConfig.defaults);
    });

    test('unknown key', () {
      expect(BarConfig.decode('unknown:1'), BarConfig.defaults);
    });

    test('bool value that is not 0 or 1', () {
      expect(BarConfig.decode('rtl:yes'), BarConfig.defaults);
    });

    test('a bad entry next to a good one keeps the good one', () {
      expect(
        BarConfig.decode('blur:abc,rtl:1'),
        BarConfig.defaults.set(Knob.rtl, true),
      );
    });

    test('a bad preset next to a good knob keeps the good knob', () {
      expect(
        BarConfig.decode('preset:nope,lay:docked'),
        BarConfig.defaults
            .set(Knob.layout, LayoutStyle.docked)
            .set(Knob.radius, 100.0),
      );
    });
  });

  group('presets', () {
    test('glass is the defaults preset', () {
      expect(
        BarConfig.defaults.withPreset(BarPreset.glass),
        BarConfig.defaults,
      );
    });

    test('switching preset resets styling and keeps other knobs', () {
      final config = BarConfig.defaults
          .set(Knob.blur, 30.0)
          .set(Knob.rtl, true)
          .set(Knob.preset, BarPreset.material3);

      expect(config.get(Knob.blur), 16.0);
      expect(config.get(Knob.rtl), true);
      expect(config.get(Knob.layout), LayoutStyle.docked);
      expect(config.get(Knob.radius), 0.0);
    });
  });

  group('docking rule', () {
    test(
      'docking squares the corners and undocking restores the glass radius',
      () {
        final docked = BarConfig.defaults.set(Knob.layout, LayoutStyle.docked);
        expect(docked.get(Knob.radius), 0.0);

        final undocked = docked.set(Knob.layout, LayoutStyle.adaptive);
        expect(undocked.get(Knob.radius), 100.0);
      },
    );

    test('undocking from the material3 preset gives the 28 default', () {
      final config = BarConfig.defaults
          .set(Knob.preset, BarPreset.material3)
          .set(Knob.layout, LayoutStyle.floating);
      expect(config.get(Knob.radius), 28.0);
    });

    test('a custom radius survives a switch to floating', () {
      final config = BarConfig.defaults
          .set(Knob.radius, 8.0)
          .set(Knob.layout, LayoutStyle.floating);
      expect(config.get(Knob.radius), 8.0);
    });
  });

  group('disabled knobs', () {
    test('blur is disabled on the solid surface and enabled on glass', () {
      final solid = BarConfig.defaults.set(Knob.surface, SurfaceStyle.solid);
      expect(solid.disabledReason(Knob.blur), 'Blur needs the glass surface.');
      expect(BarConfig.defaults.disabledReason(Knob.blur), isNull);
    });

    test('offset is disabled when docked', () {
      final docked = BarConfig.defaults.set(Knob.layout, LayoutStyle.docked);
      expect(
        docked.disabledReason(Knob.offset),
        'A docked bar sits on the bottom edge.',
      );
    });

    test('leading and trailing are disabled when docked', () {
      final docked = BarConfig.defaults.set(Knob.layout, LayoutStyle.docked);
      expect(
        docked.disabledReason(Knob.leading),
        'A docked bar has no side buttons.',
      );
      expect(
        docked.disabledReason(Knob.trailing),
        'A docked bar has no side buttons.',
      );
    });

    test('hide on scroll and follow the finger are disabled by minimize', () {
      final minimizing = BarConfig.defaults.set(
        Knob.minimize,
        BottomBarMinimizeBehavior.onScrollDown,
      );
      expect(
        minimizing.disabledReason(Knob.hideOnScroll),
        'Minimize replaces hide on scroll.',
      );
      expect(
        minimizing.disabledReason(Knob.followScroll),
        'Minimize replaces hide on scroll.',
      );
    });

    test('follow the finger is disabled when hide on scroll is off', () {
      final hidden = BarConfig.defaults.set(Knob.hideOnScroll, false);
      expect(
        hidden.disabledReason(Knob.followScroll),
        'Following the finger needs hide on scroll.',
      );
    });

    test('no knob is disabled in the defaults', () {
      for (final knob in Knob.values) {
        expect(
          BarConfig.defaults.disabledReason(knob),
          isNull,
          reason: knob.name,
        );
      }
    });

    test('effective uses the baseline value while a knob is disabled', () {
      final config = BarConfig.defaults
          .set(Knob.surface, SurfaceStyle.solid)
          .set(Knob.blur, 30.0);
      expect(config.effective(Knob.blur), 16.0);
      expect(config.get(Knob.blur), 30.0);
    });
  });
}
