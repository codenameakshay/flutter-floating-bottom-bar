import '../golden_case.dart';
import 'accessory.dart';
import 'badges.dart';
import 'basics.dart';
import 'center_action.dart';
import 'docked.dart';
import 'glass.dart';
import 'groups.dart';
import 'indicators.dart';
import 'item_theme.dart';
import 'large_text.dart';
import 'minimize.dart';
import 'panel.dart';
import 'presets.dart';
import 'rail.dart';
import 'scroll_edge.dart';
import 'switcher.dart';
import 'transitions.dart';

/// Every golden, grouped the way the gallery shows them. A case renders once
/// per shot, to `<id>_<shot>.png` in test/goldens/.
final goldenFeatures = <GoldenFeature>[
  basicsFeature,
  presetsFeature,
  indicatorsFeature,
  itemThemeFeature,
  badgesFeature,
  glassFeature,
  scrollEdgeFeature,
  centerActionFeature,
  groupsFeature,
  dockedFeature,
  rtlFeature,
  edgeToEdgeFeature,
  minimizeFeature,
  accessoryFeature,
  railFeature,
  switcherFeature,
  panelFeature,
  largeTextFeature,
  transitionsFeature,
];
