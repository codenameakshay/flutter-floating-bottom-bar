import 'package:flutter/material.dart' as fm;
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'configurator_configs.dart';
import 'configurator_snapshots/disabled_knobs_ignored.dart'
    as disabled_knobs_ignored;
import 'configurator_snapshots/docked_glass_minimize.dart'
    as docked_glass_minimize;
import 'configurator_snapshots/glass_edge_off_follow.dart'
    as glass_edge_off_follow;
import 'configurator_snapshots/material3_glass_adaptive.dart'
    as material3_glass_adaptive;
import 'configurator_snapshots/minimal_five_items.dart' as minimal_five_items;
import 'configurator_snapshots/none_custom.dart' as none_custom;
import 'configurator_snapshots/pill_tinted_glass.dart' as pill_tinted_glass;
import 'configurator_snapshots/preset_glass.dart' as preset_glass;
import 'configurator_snapshots/preset_material3.dart' as preset_material3;
import 'configurator_snapshots/preset_minimal.dart' as preset_minimal;
import 'configurator_snapshots/preset_none.dart' as preset_none;
import 'configurator_snapshots/preset_pill.dart' as preset_pill;
import 'configurator_snapshots/rtl_groups_accessory.dart'
    as rtl_groups_accessory;

final _snapshotPages = <String, Widget Function()>{
  'disabled_knobs_ignored': () => const disabled_knobs_ignored.BarPage(),
  'docked_glass_minimize': () => const docked_glass_minimize.BarPage(),
  'glass_edge_off_follow': () => const glass_edge_off_follow.BarPage(),
  'material3_glass_adaptive': () => const material3_glass_adaptive.BarPage(),
  'minimal_five_items': () => const minimal_five_items.BarPage(),
  'none_custom': () => const none_custom.BarPage(),
  'pill_tinted_glass': () => const pill_tinted_glass.BarPage(),
  'preset_glass': () => const preset_glass.BarPage(),
  'preset_material3': () => const preset_material3.BarPage(),
  'preset_minimal': () => const preset_minimal.BarPage(),
  'preset_none': () => const preset_none.BarPage(),
  'preset_pill': () => const preset_pill.BarPage(),
  'rtl_groups_accessory': () => const rtl_groups_accessory.BarPage(),
};

/// Everything about the built bar that the config controls.
List<Object?> _fingerprint(WidgetTester tester) {
  final bar = tester.widget<BottomBar>(find.byType(BottomBar));
  final row = tester.widget<BottomBarItems>(find.byType(BottomBarItems));
  return [
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
    expect(_snapshotPages.keys.toSet(), snapshotConfigs.keys.toSet());
  });

  for (final MapEntry(key: name, value: config) in snapshotConfigs.entries) {
    testWidgets('$name preview builds the bar its code builds', (tester) async {
      await tester.pumpWidget(fm.MaterialApp(home: _snapshotPages[name]!()));
      final fromCode = _fingerprint(tester);
      await tester.pumpWidget(MaterialApp(home: BarPreview(config: config)));
      expect(_fingerprint(tester), fromCode);
      expect(tester.takeException(), isNull);
    });
  }
}
