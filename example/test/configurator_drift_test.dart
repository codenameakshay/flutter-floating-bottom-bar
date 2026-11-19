import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'configurator_configs.dart';
import 'configurator_snapshots/disabled_knobs_ignored.dart'
    as disabled_knobs_ignored;
import 'configurator_snapshots/docked_glass_minimize.dart'
    as docked_glass_minimize;
import 'configurator_snapshots/five_raised_badge.dart' as five_raised_badge;
import 'configurator_snapshots/glass_edge_off_follow.dart'
    as glass_edge_off_follow;
import 'configurator_snapshots/invalid_ranges_fall_back.dart'
    as invalid_ranges_fall_back;
import 'configurator_snapshots/material3_glass_adaptive.dart'
    as material3_glass_adaptive;
import 'configurator_snapshots/minimal_five_items.dart' as minimal_five_items;
import 'configurator_snapshots/minimal_tinted_solid.dart'
    as minimal_tinted_solid;
import 'configurator_snapshots/none_custom.dart' as none_custom;
import 'configurator_snapshots/pill_tinted_glass.dart' as pill_tinted_glass;
import 'configurator_snapshots/pill_tinted_solid.dart' as pill_tinted_solid;
import 'configurator_snapshots/preset_glass.dart' as preset_glass;
import 'configurator_snapshots/preset_material3.dart' as preset_material3;
import 'configurator_snapshots/preset_minimal.dart' as preset_minimal;
import 'configurator_snapshots/preset_none.dart' as preset_none;
import 'configurator_snapshots/preset_pill.dart' as preset_pill;
import 'configurator_snapshots/glass_pink_tint.dart' as glass_pink_tint;
import 'configurator_snapshots/rtl_groups_accessory.dart'
    as rtl_groups_accessory;
import 'configurator_snapshots/three_inline_badge.dart' as three_inline_badge;

final _snapshotMains = <String, VoidCallback>{
  'minimal_tinted_solid': minimal_tinted_solid.main,
  'pill_tinted_solid': pill_tinted_solid.main,
  'three_inline_badge': three_inline_badge.main,
  'five_raised_badge': five_raised_badge.main,
  'invalid_ranges_fall_back': invalid_ranges_fall_back.main,
  'glass_pink_tint': glass_pink_tint.main,
  'disabled_knobs_ignored': disabled_knobs_ignored.main,
  'docked_glass_minimize': docked_glass_minimize.main,
  'glass_edge_off_follow': glass_edge_off_follow.main,
  'material3_glass_adaptive': material3_glass_adaptive.main,
  'minimal_five_items': minimal_five_items.main,
  'none_custom': none_custom.main,
  'pill_tinted_glass': pill_tinted_glass.main,
  'preset_glass': preset_glass.main,
  'preset_material3': preset_material3.main,
  'preset_minimal': preset_minimal.main,
  'preset_none': preset_none.main,
  'preset_pill': preset_pill.main,
  'rtl_groups_accessory': rtl_groups_accessory.main,
};

/// Everything about the built bar that the config controls.
List<Object?> _fingerprint(WidgetTester tester) {
  final bar = tester.widget<BottomBar>(find.byType(BottomBar));
  final row = tester.widget<BottomBarItems>(find.byType(BottomBarItems));
  return [
    Theme.of(tester.element(find.byType(BottomBar))).colorScheme,
    bar.theme,
    bar.layout,
    bar.motion,
    bar.scrollBehavior,
    bar.leading != null,
    bar.trailing != null,
    bar.accessory != null,
    row.labelBehavior,
    row.indicator,
    row.centerAction?.style,
    for (final item in row.children.cast<BottomBarItem>())
      [
        (item.icon as Icon).icon,
        (item.selectedIcon! as Icon).icon,
        (item.label! as Text).data,
        item.badge != null,
      ],
  ];
}

void main() {
  test('every snapshot is pumped', () {
    expect(_snapshotMains.keys.toSet(), snapshotConfigs.keys.toSet());
  });

  for (final MapEntry(key: name, value: config) in snapshotConfigs.entries) {
    testWidgets('$name preview builds the bar its code builds', (tester) async {
      _snapshotMains[name]!();
      await tester.pump();
      final fromCode = _fingerprint(tester);
      await tester.pumpWidget(MaterialApp(home: BarPreview(config: config)));
      expect(_fingerprint(tester), fromCode);
      expect(tester.takeException(), isNull);
    });
  }
}
