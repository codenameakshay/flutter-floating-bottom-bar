import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_config.dart';

final _glass = BarConfig.defaults;

/// Configs whose generated code is committed under
/// `test/configurator_snapshots/`, keyed by file name.
final snapshotConfigs = <String, BarConfig>{
  for (final preset in BarPreset.values)
    'preset_${preset.name}': _glass.set(Knob.preset, preset),
  'invalid_ranges_fall_back': BarConfig.decode('blur:NaN,off:NaN'),
  'minimal_tinted_solid': _glass
      .set(Knob.preset, BarPreset.minimal)
      .set(Knob.tint, BarTint.green),
  'pill_tinted_solid': _glass
      .set(Knob.preset, BarPreset.pill)
      .set(Knob.tint, BarTint.blue),
  'three_inline_badge': _glass
      .set(Knob.items, 3)
      .set(Knob.center, CenterStyle.inline)
      .set(Knob.badge, true),
  'five_raised_badge': _glass
      .set(Knob.items, 5)
      .set(Knob.center, CenterStyle.raised)
      .set(Knob.badge, true),
  'glass_pink_tint': _glass.set(Knob.tint, BarTint.pink),
  'docked_glass_minimize': _glass
      .set(Knob.layout, LayoutStyle.docked)
      .set(Knob.minimize, BottomBarMinimizeBehavior.onScrollDown),
  'rtl_groups_accessory': _glass
      .set(Knob.rtl, true)
      .set(Knob.leading, true)
      .set(Knob.trailing, true)
      .set(Knob.accessory, true),
  'pill_tinted_glass': _glass
      .set(Knob.preset, BarPreset.pill)
      .set(Knob.surface, SurfaceStyle.glass)
      .set(Knob.blur, 24.0)
      .set(Knob.tint, BarTint.pink)
      .set(Knob.scrollEdge, true),
  'minimal_five_items': _glass
      .set(Knob.preset, BarPreset.minimal)
      .set(Knob.items, 5)
      .set(Knob.labels, false)
      .set(Knob.badge, true)
      .set(Knob.center, CenterStyle.notched)
      .set(Knob.indicator, IndicatorStyle.underline),
  'none_custom': _glass
      .set(Knob.preset, BarPreset.none)
      .set(Knob.radius, 8.0)
      .set(Knob.offset, 24.0)
      .set(Knob.motion, MotionStyle.bouncy)
      .set(Knob.hideOnScroll, false)
      .set(Knob.showAtStart, true)
      .set(Knob.tint, BarTint.amber)
      .set(Knob.center, CenterStyle.raised)
      .set(Knob.items, 3),
  'glass_edge_off_follow': _glass
      .set(Knob.scrollEdge, false)
      .set(Knob.followScroll, true)
      .set(Knob.indicator, IndicatorStyle.dot)
      .set(Knob.layout, LayoutStyle.floating),
  'material3_glass_adaptive': _glass
      .set(Knob.preset, BarPreset.material3)
      .set(Knob.surface, SurfaceStyle.glass)
      .set(Knob.layout, LayoutStyle.adaptive)
      .set(Knob.center, CenterStyle.inline)
      .set(Knob.motion, MotionStyle.interactive),
  'disabled_knobs_ignored': _glass
      .set(Knob.surface, SurfaceStyle.solid)
      .set(Knob.blur, 30.0)
      .set(Knob.layout, LayoutStyle.docked)
      .set(Knob.offset, 30.0)
      .set(Knob.leading, true)
      .set(Knob.minimize, BottomBarMinimizeBehavior.onScrollUp)
      .set(Knob.hideOnScroll, false)
      .set(Knob.followScroll, true),
};
