import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

enum BarPreset {
  none('None'),
  glass('Glass'),
  material3('M3'),
  pill('Pill'),
  minimal('Minimal');

  const BarPreset(this.label);

  final String label;

  /// The knob values that rebuild this preset exactly, so a config with
  /// these values generates the bare preset and nothing else.
  Map<Knob, Object> get styling => switch (this) {
    none => _styling(
      IndicatorStyle.none,
      SurfaceStyle.solid,
      false,
      LayoutStyle.floating,
      28,
      10,
      MotionStyle.snappy,
    ),
    glass => _styling(
      IndicatorStyle.tint,
      SurfaceStyle.glass,
      true,
      LayoutStyle.adaptive,
      100,
      16,
      MotionStyle.smooth,
    ),
    material3 => _styling(
      IndicatorStyle.container,
      SurfaceStyle.solid,
      false,
      LayoutStyle.docked,
      0,
      10,
      MotionStyle.curved,
    ),
    pill => _styling(
      IndicatorStyle.pill,
      SurfaceStyle.solid,
      false,
      LayoutStyle.adaptive,
      100,
      16,
      MotionStyle.snappy,
    ),
    minimal => _styling(
      IndicatorStyle.dot,
      SurfaceStyle.solid,
      false,
      LayoutStyle.adaptive,
      20,
      16,
      MotionStyle.curved,
    ),
  };

  /// The cap the preset gives an adaptive layout.
  double get maxWidth => switch (this) {
    pill => 420,
    minimal => 360,
    none || glass || material3 => 440,
  };
}

Map<Knob, Object> _styling(
  IndicatorStyle indicator,
  SurfaceStyle surface,
  bool scrollEdge,
  LayoutStyle layout,
  double radius,
  double offset,
  MotionStyle motion,
) => {
  Knob.indicator: indicator,
  Knob.surface: surface,
  Knob.blur: 16.0,
  Knob.tint: BarTint.none,
  Knob.scrollEdge: scrollEdge,
  Knob.layout: layout,
  Knob.radius: radius,
  Knob.offset: offset,
  Knob.motion: motion,
};

enum IndicatorStyle {
  none('None'),
  pill('Pill'),
  tint('Tint'),
  underline('Underline'),
  dot('Dot'),
  container('Container');

  const IndicatorStyle(this.label);

  final String label;
}

enum SurfaceStyle {
  solid('Solid'),
  glass('Glass');

  const SurfaceStyle(this.label);

  final String label;
}

enum BarTint {
  none('None', null),
  blue('Blue', Color(0xFF2F6BFF)),
  pink('Pink', Color(0xFFFF4F8B)),
  green('Green', Color(0xFF1FA463)),
  amber('Amber', Color(0xFFFFB020));

  const BarTint(this.label, this.color);

  final String label;
  final Color? color;
}

enum LayoutStyle {
  floating('Floating'),
  adaptive('Adaptive'),
  docked('Docked');

  const LayoutStyle(this.label);

  final String label;
}

enum MotionStyle {
  curved('Curved'),
  smooth('Smooth'),
  snappy('Snappy'),
  bouncy('Bouncy'),
  interactive('Interactive');

  const MotionStyle(this.label);

  final String label;
}

enum CenterStyle {
  none('None'),
  inline('Inline'),
  raised('Raised'),
  notched('Notched');

  const CenterStyle(this.label);

  final String label;
}

/// Every control the configurator offers, in panel order.
///
/// A knob is either a choice among [options] or a slider over [range].
/// [key] names it in share links, so renaming one breaks old links.
enum Knob<T extends Object> {
  preset<BarPreset>(
    'Preset',
    'Preset',
    'preset',
    BarPreset.glass,
    options: BarPreset.values,
  ),
  indicator<IndicatorStyle>(
    'Indicator',
    'Style',
    'ind',
    IndicatorStyle.tint,
    options: IndicatorStyle.values,
  ),
  surface<SurfaceStyle>(
    'Surface',
    'Material',
    'surf',
    SurfaceStyle.glass,
    options: SurfaceStyle.values,
  ),
  blur<double>('Surface', 'Blur', 'blur', 16.0, range: (0, 40)),
  tint<BarTint>(
    'Surface',
    'Tint',
    'tint',
    BarTint.none,
    options: BarTint.values,
  ),
  scrollEdge<bool>(
    'Surface',
    'Clear at the scroll edge',
    'edge',
    true,
    options: [false, true],
  ),
  layout<LayoutStyle>(
    'Layout',
    'Kind',
    'lay',
    LayoutStyle.adaptive,
    options: LayoutStyle.values,
  ),
  radius<double>(
    'Layout',
    'Corner radius',
    'rad',
    100.0,
    options: [0.0, 8.0, 16.0, 20.0, 28.0, 100.0],
  ),
  offset<double>('Layout', 'Offset', 'off', 16.0, range: (0, 32)),
  motion<MotionStyle>(
    'Motion',
    'Spring',
    'mo',
    MotionStyle.smooth,
    options: MotionStyle.values,
  ),
  hideOnScroll<bool>(
    'Scroll',
    'Hide on scroll',
    'hide',
    true,
    options: [false, true],
  ),
  followScroll<bool>(
    'Scroll',
    'Follow the finger',
    'follow',
    false,
    options: [false, true],
  ),
  minimize<BottomBarMinimizeBehavior>(
    'Scroll',
    'Minimize',
    'min',
    BottomBarMinimizeBehavior.never,
    options: BottomBarMinimizeBehavior.values,
  ),
  showAtStart<bool>(
    'Scroll',
    'Show at the start',
    'start',
    false,
    options: [false, true],
  ),
  items<int>('Items', 'Count', 'items', 4, options: [3, 4, 5]),
  labels<bool>('Items', 'Labels', 'labels', true, options: [false, true]),
  badge<bool>('Items', 'Badge', 'badge', false, options: [false, true]),
  center<CenterStyle>(
    'Items',
    'Centre action',
    'center',
    CenterStyle.none,
    options: CenterStyle.values,
  ),
  leading<bool>(
    'Groups',
    'Leading button',
    'lead',
    false,
    options: [false, true],
  ),
  trailing<bool>(
    'Groups',
    'Trailing button',
    'trail',
    false,
    options: [false, true],
  ),
  accessory<bool>('Groups', 'Accessory', 'acc', false, options: [false, true]),
  dark<bool>('Preview', 'Dark', 'dark', false, options: [false, true]),
  rtl<bool>('Preview', 'Right to left', 'rtl', false, options: [false, true]),
  textScale<double>(
    'Preview',
    'Text scale',
    'scale',
    1.0,
    options: [1.0, 1.3, 2.0],
  );

  const Knob(
    this.group,
    this.label,
    this.key,
    this.initial, {
    this.options,
    this.range,
  });

  final String group;
  final String label;
  final String key;
  final T initial;
  final List<T>? options;
  final (double, double)? range;

  /// [value] as it appears in a share link.
  String encode(T value) => switch (value) {
    Enum(:final name) => name,
    bool() => value ? '1' : '0',
    double() => formatNumber(value),
    _ => '$value',
  };

  /// The value [raw] names, or null when it names none.
  T? decode(String raw) {
    final options = this.options;
    if (options != null) {
      for (final option in options) {
        if (encode(option) == raw) return option;
      }
      return null;
    }
    final (min, max) = range!;
    final parsed = double.tryParse(raw);
    if (parsed == null || !parsed.isFinite || parsed < min || parsed > max) {
      return null;
    }
    return parsed as T;
  }
}

/// `16.0` as `16` and `1.3` as `1.3`.
String formatNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

/// One configurator state: a value for every [Knob].
@immutable
class BarConfig {
  const BarConfig._(this._values);

  static final BarConfig defaults = BarConfig._({
    for (final knob in Knob.values) knob: knob.initial,
  });

  static const route = '/configurator';

  final Map<Knob, Object> _values;

  T get<T extends Object>(Knob<T> knob) => _values[knob]! as T;

  BarPreset get preset => get(Knob.preset);

  /// Changing [Knob.preset] resets the styling knobs to the new preset's.
  /// Docking squares the corners, and undocking rounds them again.
  BarConfig set<T extends Object>(Knob<T> knob, T value) {
    if (knob == Knob.preset) return withPreset(value as BarPreset);
    final next = {..._values, knob: value};
    if (knob == Knob.layout && value != get(Knob.layout)) {
      final base = baseline;
      next[Knob.radius] = switch (value) {
        LayoutStyle.docked => 0.0,
        _ when get(Knob.layout) != LayoutStyle.docked => get(Knob.radius),
        _ when base.get(Knob.layout) != LayoutStyle.docked => base.get(
          Knob.radius,
        ),
        _ => 28.0,
      };
    }
    return BarConfig._(next);
  }

  BarConfig withPreset(BarPreset preset) =>
      BarConfig._({..._values, Knob.preset: preset, ...preset.styling});

  /// The config [preset] starts from, which the generated code leaves out.
  BarConfig get baseline => defaults.withPreset(preset);

  /// Why [knob] does nothing in this config, or null when it does something.
  String? disabledReason(Knob knob) {
    final docked = get(Knob.layout) == LayoutStyle.docked;
    final minimizes = get(Knob.minimize) != BottomBarMinimizeBehavior.never;
    return switch (knob) {
      Knob.blur when get(Knob.surface) != SurfaceStyle.glass =>
        'Blur needs the glass surface.',
      Knob.offset when docked => 'A docked bar sits on the bottom edge.',
      Knob.leading ||
      Knob.trailing when docked => 'A docked bar has no side buttons.',
      Knob.hideOnScroll ||
      Knob.followScroll when minimizes => 'Minimize replaces hide on scroll.',
      Knob.followScroll when !get(Knob.hideOnScroll) =>
        'Following the finger needs hide on scroll.',
      _ => null,
    };
  }

  /// The value [knob] has an effect with: its baseline value while disabled.
  T effective<T extends Object>(Knob<T> knob) =>
      disabledReason(knob) == null ? get(knob) : baseline.get(knob);

  /// The `c` link parameter: every knob that differs from [baseline].
  String encode() {
    final base = baseline;
    return [
      if (preset != defaults.preset) 'preset:${preset.name}',
      for (final knob in Knob.values)
        if (knob != Knob.preset && _values[knob] != base._values[knob])
          '${knob.key}:${_encodeValue(knob)}',
    ].join(',');
  }

  String _encodeValue<T extends Object>(Knob<T> knob) => knob.encode(get(knob));

  /// The config a `c` link parameter names. Unknown keys and bad values
  /// keep their defaults.
  static BarConfig decode(String? encoded) {
    final raw = <String, String>{};
    for (final entry in (encoded ?? '').split(',')) {
      final colon = entry.indexOf(':');
      if (colon > 0) {
        raw[entry.substring(0, colon)] = entry.substring(colon + 1);
      }
    }
    var config = defaults.withPreset(
      Knob.preset.decode(raw['preset'] ?? '') ?? defaults.preset,
    );
    for (final knob in Knob.values) {
      if (knob == Knob.preset) continue;
      config = config._decodeInto(knob, raw[knob.key]);
    }
    return config;
  }

  BarConfig _decodeInto<T extends Object>(Knob<T> knob, String? raw) {
    final value = raw == null ? null : knob.decode(raw);
    return value == null ? this : BarConfig._({..._values, knob: value});
  }

  /// The route that opens this config, such as `/configurator?c=lay:docked`.
  String get location {
    final encoded = encode();
    return encoded.isEmpty ? route : '$route?c=$encoded';
  }

  @override
  bool operator ==(Object other) =>
      other is BarConfig && mapEquals(other._values, _values);

  @override
  int get hashCode =>
      Object.hashAll([for (final knob in Knob.values) _values[knob]]);

  @override
  String toString() => 'BarConfig(${encode()})';
}
