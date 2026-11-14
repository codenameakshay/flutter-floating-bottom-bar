import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import 'bottom_bar_theme.dart';
import 'config/bottom_bar_layout.dart';
import 'config/bottom_bar_motion.dart';
import 'widgets/bottom_bar_indicator.dart';
import 'widgets/bottom_bar_item_theme.dart';
import 'widgets/bottom_bar_items.dart' show BottomBarLabelBehavior;
import 'widgets/bottom_bar_surface.dart';

const _capsule = BorderRadius.all(Radius.circular(100));

// Indicators have no value equality, so the defaults stay const and two calls
// to one preset compare equal.

BottomBarThemeData glassPreset({
  Color? accent,
  BottomBarIndicator? indicator,
}) => BottomBarThemeData(
  layout: const BottomBarLayout.adaptive(
    maxWidth: 440,
    offset: 16,
    borderRadius: _capsule,
  ),
  motion: const BottomBarMotion.cupertino(
    preset: BottomBarCupertinoMotion.smooth,
  ),
  surface: const BottomBarSurface.glass(fillOpacity: 0.98),
  scrollEdgeSurface: const BottomBarSurface(fillOpacity: 0),
  items: BottomBarItemThemeData(
    selectedColor: accent,
    iconSize: 24,
    labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    iconLabelGap: 2,
    inkBorderRadius: _capsule,
    motion: const CupertinoMotion.bouncy(),
    indicator:
        indicator ??
        (accent == null
            ? const BottomBarIndicator.tint(
                inset: EdgeInsets.all(4),
                borderRadius: _capsule,
                stretch: true,
              )
            : BottomBarIndicator.tint(
                color: accent.withValues(alpha: 0.12),
                inset: const EdgeInsets.all(4),
                borderRadius: _capsule,
                stretch: true,
              )),
    indicatorMotion: const CupertinoMotion.bouncy(),
    haptics: BottomBarHaptics.selectionClick,
  ),
);

/// Icon size, indicator height and label gap of Flutter's Material 3
/// [NavigationBar].
const _m3IconSize = 24.0;
const _m3IndicatorHeight = 32.0;
const _m3LabelGap = 4.0;

BottomBarThemeData material3Preset({
  Color? backgroundColor,
  Color? indicatorColor,
}) => BottomBarThemeData(
  layout: const BottomBarLayout.docked(),
  motion: const BottomBarMotion.curved(curve: Curves.easeInOutCubicEmphasized),
  surface: BottomBarSurface.solid(color: backgroundColor),
  scrollEdgeSurface: BottomBarSurface.solid(color: backgroundColor),
  items: BottomBarItemThemeData(
    iconSize: _m3IconSize,
    labelStyle: const TextStyle(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    // An 80 tall row: the indicator band and label sit centred, as in
    // NavigationBar, with the label 4 below the indicator.
    padding: const EdgeInsets.only(top: 18, bottom: 14),
    iconLabelGap: (_m3IndicatorHeight - _m3IconSize) / 2 + _m3LabelGap,
    inkBorderRadius: const BorderRadius.all(Radius.circular(16)),
    indicator: indicatorColor == null
        ? const BottomBarIndicator.container()
        : BottomBarIndicator.container(color: indicatorColor),
  ),
);

BottomBarThemeData pillPreset({
  Color? accent,
  BottomBarIndicator? indicator,
}) => BottomBarThemeData(
  layout: const BottomBarLayout.adaptive(
    maxWidth: 420,
    offset: 16,
    borderRadius: _capsule,
  ),
  motion: const BottomBarMotion.cupertino(),
  surface: const BottomBarSurface.solid(
    shadows: [
      BoxShadow(color: Color(0x24000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
  ),
  scrollEdgeSurface: const BottomBarSurface.solid(
    shadows: [
      BoxShadow(color: Color(0x24000000), blurRadius: 20, offset: Offset(0, 6)),
    ],
  ),
  items: BottomBarItemThemeData(
    iconSize: 22,
    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    inkBorderRadius: _capsule,
    pressedScale: 0.92,
    indicator:
        indicator ??
        (accent == null
            ? const BottomBarIndicator.pill(
                inset: EdgeInsets.all(6),
                stretch: true,
              )
            : BottomBarIndicator.pill(
                color: accent,
                inset: const EdgeInsets.all(6),
                stretch: true,
              )),
    indicatorMotion: const CupertinoMotion.snappy(),
    haptics: BottomBarHaptics.selectionClick,
  ),
);

BottomBarThemeData minimalPreset({
  Color? accent,
  BottomBarIndicator? indicator,
}) => BottomBarThemeData(
  layout: const BottomBarLayout.adaptive(
    maxWidth: 360,
    offset: 16,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
  motion: const BottomBarMotion.curved(
    duration: Duration(milliseconds: 200),
    transition: BottomBarTransition.fade,
  ),
  surface: const BottomBarSurface.solid(),
  scrollEdgeSurface: const BottomBarSurface.solid(),
  items: BottomBarItemThemeData(
    selectedColor: accent,
    labelBehavior: BottomBarLabelBehavior.onlySelected,
    iconSize: 24,
    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
    splashFactory: NoSplash.splashFactory,
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    motion: const CurvedMotion(Duration(milliseconds: 200), Curves.easeOut),
    indicator:
        indicator ??
        (accent == null
            ? const BottomBarIndicator.dot()
            : BottomBarIndicator.dot(color: accent)),
    indicatorMotion: const CupertinoMotion.smooth(
      duration: Duration(milliseconds: 350),
    ),
  ),
);
