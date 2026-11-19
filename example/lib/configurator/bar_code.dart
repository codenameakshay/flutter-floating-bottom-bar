import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import 'bar_config.dart';
import 'dart_code.dart';

/// A value the preview uses, and the source that builds the same value.
/// Each pair is written in one place, so the preview and the copied code
/// cannot drift apart.
typedef Part<T> = ({T value, Code code});

const barItems = [
  (
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    code: ('Icons.home_outlined', 'Icons.home_rounded'),
  ),
  (
    label: 'Explore',
    icon: Icons.explore_outlined,
    selectedIcon: Icons.explore_rounded,
    code: ('Icons.explore_outlined', 'Icons.explore_rounded'),
  ),
  (
    label: 'Saved',
    icon: Icons.bookmark_outline_rounded,
    selectedIcon: Icons.bookmark_rounded,
    code: ('Icons.bookmark_outline_rounded', 'Icons.bookmark_rounded'),
  ),
  (
    label: 'Inbox',
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox_rounded,
    code: ('Icons.inbox_outlined', 'Icons.inbox_rounded'),
  ),
  (
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    code: ('Icons.person_outline_rounded', 'Icons.person_rounded'),
  ),
];

/// The item that carries the badge when [Knob.badge] is on.
const badgeIndex = 1;
const badgeCount = 3;

/// The theme for [config]: its preset, plus `copyWith` for each part that
/// differs from the preset. Null when the bar needs no theme.
Part<BottomBarThemeData>? buildTheme(BarConfig config) {
  final layout = _layout(config);
  final motion = _motion(config);
  final (surface, scrollEdge) = _surfaces(config);
  final scroll = _scroll(config);
  final overrides = <String, Code>{
    'layout': ?layout?.code,
    'motion': ?motion?.code,
    'surface': ?surface?.code,
    'scrollEdgeSurface': ?scrollEdge?.code,
    'scrollBehavior': ?scroll?.code,
  };
  final preset = switch (config.preset) {
    BarPreset.none => null,
    BarPreset.glass => BottomBarThemeData.glass(),
    BarPreset.material3 => BottomBarThemeData.material3(),
    BarPreset.pill => BottomBarThemeData.pill(),
    BarPreset.minimal => BottomBarThemeData.minimal(),
  };
  if (preset == null) {
    if (overrides.isEmpty) return null;
    return (
      value: BottomBarThemeData(
        layout: layout?.value,
        motion: motion?.value,
        surface: surface?.value,
        scrollEdgeSurface: scrollEdge?.value,
        scrollBehavior: scroll?.value,
      ),
      code: Call('BottomBarThemeData', named: overrides),
    );
  }
  final presetCode = Call(
    'BottomBarThemeData.${config.preset.name}',
    constructor: false,
  );
  return (
    value: preset.copyWith(
      layout: layout?.value,
      motion: motion?.value,
      surface: surface?.value,
      scrollEdgeSurface: scrollEdge?.value,
      scrollBehavior: scroll?.value,
    ),
    code: overrides.isEmpty
        ? presetCode
        : Call('copyWith', target: presetCode, named: overrides),
  );
}

/// The row's indicator when it differs from the preset's, else null.
Part<BottomBarIndicator>? buildIndicator(BarConfig config) {
  final style = config.get(Knob.indicator);
  if (style == config.baseline.get(Knob.indicator)) return null;
  return (
    value: switch (style) {
      IndicatorStyle.none => const BottomBarIndicator.none(),
      IndicatorStyle.pill => const BottomBarIndicator.pill(),
      IndicatorStyle.tint => const BottomBarIndicator.tint(),
      IndicatorStyle.underline => const BottomBarIndicator.underline(),
      IndicatorStyle.dot => const BottomBarIndicator.dot(),
      IndicatorStyle.container => const BottomBarIndicator.container(),
    },
    code: Call('BottomBarIndicator.${style.name}'),
  );
}

Code _number(double value) => Raw(formatNumber(value));

Part<BottomBarLayout>? _layout(BarConfig config) {
  final base = config.baseline;
  final kind = config.get(Knob.layout);
  final radius = config.get(Knob.radius);
  final offset = config.effective(Knob.offset);
  if (kind == base.get(Knob.layout) &&
      radius == base.get(Knob.radius) &&
      offset == base.get(Knob.offset)) {
    return null;
  }
  final borderRadius = BorderRadius.all(Radius.circular(radius));
  final radiusCode = Call(
    'BorderRadius.all',
    args: [
      Call('Radius.circular', args: [_number(radius)]),
    ],
  );
  const defaults = BottomBarLayout();
  final floating = <String, Code>{
    if (offset != defaults.offset) 'offset': _number(offset),
    if (borderRadius != defaults.borderRadius) 'borderRadius': radiusCode,
  };
  final maxWidth = config.preset.maxWidth;
  return switch (kind) {
    LayoutStyle.floating => (
      value: BottomBarLayout(offset: offset, borderRadius: borderRadius),
      code: Call('BottomBarLayout', named: floating),
    ),
    LayoutStyle.adaptive => (
      value: BottomBarLayout.adaptive(
        maxWidth: maxWidth,
        offset: offset,
        borderRadius: borderRadius,
      ),
      code: Call(
        'BottomBarLayout.adaptive',
        named: {'maxWidth': _number(maxWidth), ...floating},
      ),
    ),
    LayoutStyle.docked => (
      value: BottomBarLayout.docked(borderRadius: borderRadius),
      code: Call(
        'BottomBarLayout.docked',
        named: {if (radius != 0) 'borderRadius': radiusCode},
      ),
    ),
  };
}

Part<BottomBarMotion>? _motion(BarConfig config) {
  final style = config.get(Knob.motion);
  if (style == config.baseline.get(Knob.motion)) return null;
  if (style == MotionStyle.curved) {
    return (
      value: const BottomBarMotion.curved(),
      code: const Call('BottomBarMotion.curved'),
    );
  }
  final preset = BottomBarCupertinoMotion.values.byName(style.name);
  return (
    value: BottomBarMotion.cupertino(preset: preset),
    code: Call(
      'BottomBarMotion.cupertino',
      named: {
        if (preset != BottomBarCupertinoMotion.snappy)
          'preset': Raw('BottomBarCupertinoMotion.${preset.name}'),
      },
    ),
  );
}

/// The surface and scroll edge surface, each null when the preset's holds.
///
/// The surface is rebuilt from the knobs when any surface knob changed. The
/// scroll edge is a clear bar when [Knob.scrollEdge] is on, else the
/// surface, so a preset's own edge never outlives a changed surface.
(Part<BottomBarSurface>?, Part<BottomBarSurface>?) _surfaces(BarConfig config) {
  final base = config.baseline;
  final style = config.get(Knob.surface);
  final blur = config.effective(Knob.blur);
  final tint = config.get(Knob.tint).color;
  final clearEdge = config.get(Knob.scrollEdge);
  final surfaceChanged =
      style != base.get(Knob.surface) ||
      blur != base.get(Knob.blur) ||
      config.get(Knob.tint) != base.get(Knob.tint);
  final edgeChanged = clearEdge != base.get(Knob.scrollEdge);

  final tintCode = tint == null
      ? null
      : Raw('Color(0x${tint.toARGB32().toRadixString(16).toUpperCase()})');
  final Part<BottomBarSurface> surface;
  if (style == SurfaceStyle.glass) {
    const glass = BottomBarSurface.glass();
    final fillOpacity = config.preset == BarPreset.glass
        ? BottomBarThemeData.glass().surface!.fillOpacity
        : glass.fillOpacity;
    surface = (
      value: BottomBarSurface.glass(
        blur: blur,
        tint: tint,
        fillOpacity: fillOpacity,
      ),
      code: Call(
        'BottomBarSurface.glass',
        named: {
          if (blur != glass.blur) 'blur': _number(blur),
          'tint': ?tintCode,
          if (fillOpacity != glass.fillOpacity)
            'fillOpacity': _number(fillOpacity),
        },
      ),
    );
  } else {
    surface = (
      value: BottomBarSurface.solid(color: tint),
      code: Call('BottomBarSurface.solid', named: {'color': ?tintCode}),
    );
  }

  final Part<BottomBarSurface>? edge;
  if (clearEdge) {
    edge = edgeChanged
        ? (
            value: const BottomBarSurface(fillOpacity: 0),
            code: const Call(
              'BottomBarSurface',
              named: {'fillOpacity': Raw('0')},
            ),
          )
        : null;
  } else {
    final presetEdgeIsStale = surfaceChanged && config.preset != BarPreset.none;
    edge = edgeChanged || presetEdgeIsStale ? surface : null;
  }
  return (surfaceChanged ? surface : null, edge);
}

Part<BottomBarScrollBehavior>? _scroll(BarConfig config) {
  final hide = config.effective(Knob.hideOnScroll);
  final follow = config.effective(Knob.followScroll);
  final minimize = config.get(Knob.minimize);
  final showAtStart = config.get(Knob.showAtStart);
  const defaults = BottomBarScrollBehavior();
  final named = <String, Code>{
    if (hide != defaults.hideOnScroll) 'hideOnScroll': Raw('$hide'),
    if (follow != defaults.followScroll) 'followScroll': Raw('$follow'),
    if (minimize != defaults.minimizeBehavior)
      'minimizeBehavior': Raw('BottomBarMinimizeBehavior.${minimize.name}'),
    if (showAtStart != defaults.showAtStart) 'showAtStart': Raw('$showAtStart'),
  };
  if (named.isEmpty) return null;
  return (
    value: BottomBarScrollBehavior(
      hideOnScroll: hide,
      followScroll: follow,
      minimizeBehavior: minimize,
      showAtStart: showAtStart,
    ),
    code: Call('BottomBarScrollBehavior', named: named),
  );
}

Code _icon(String name) => Call('Icon', args: [Raw(name)]);

Code _button(String tooltip, String icon) => Call(
  'IconButton',
  named: {
    'tooltip': string(tooltip),
    'onPressed': const Raw('() {}', isConst: false),
    'icon': _icon(icon),
  },
);

/// The `BottomBar(...)` expression for [config].
Code barCode(BarConfig config) {
  final center = config.get(Knob.center);
  return Call(
    'BottomBar',
    named: {
      'theme': ?buildTheme(config)?.code,
      if (config.effective(Knob.leading))
        'leading': _button('Profile', 'Icons.person_rounded'),
      if (config.effective(Knob.trailing))
        'trailing': _button('Search', 'Icons.search_rounded'),
      if (config.get(Knob.accessory))
        'accessory': Call(
          'ListTile',
          named: {
            'leading': _icon('Icons.music_note_rounded'),
            'title': Call('Text', args: [string('Now playing')]),
          },
        ),
      'body': Call(
        'BottomBarBodyPadding',
        named: {
          'child': Call(
            'ListView.builder',
            named: {
              'itemCount': const Raw('40'),
              'itemBuilder': const Raw(
                r"(context, i) => ListTile(title: Text('Item $i'))",
                isConst: false,
              ),
            },
          ),
        },
      ),
      'child': Call(
        'BottomBarItems',
        named: {
          'selectedIndex': const Raw('_index', isConst: false),
          'onSelected': const Raw(
            '(i) => setState(() => _index = i)',
            isConst: false,
          ),
          if (!config.get(Knob.labels))
            'labelBehavior': const Raw('BottomBarLabelBehavior.alwaysHide'),
          'indicator': ?buildIndicator(config)?.code,
          if (center != CenterStyle.none)
            'centerAction': Call(
              'BottomBarCenterAction',
              named: {
                'icon': _icon('Icons.add_rounded'),
                'tooltip': string('Create'),
                if (center != CenterStyle.inline)
                  'style': Raw('BottomBarCenterActionStyle.${center.name}'),
                'onPressed': const Raw('() {}', isConst: false),
              },
            ),
          'children': ListCode([
            for (final (i, item)
                in barItems.take(config.get(Knob.items)).indexed)
              Call(
                'BottomBarItem',
                named: {
                  'icon': _icon(item.code.$1),
                  'selectedIcon': _icon(item.code.$2),
                  'label': Call('Text', args: [string(item.label)]),
                  if (config.get(Knob.badge) && i == badgeIndex)
                    'badge': Call(
                      'BottomBarBadge.count',
                      args: [Raw('$badgeCount')],
                    ),
                },
              ),
          ]),
        },
      ),
    },
  );
}

/// A runnable `main.dart` that shows the bar [config] describes.
String generateCode(BarConfig config) =>
    '''
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

void main() => runApp(const MaterialApp(home: BarPage()));

class BarPage extends StatefulWidget {
  const BarPage({super.key});

  @override
  State<BarPage> createState() => _BarPageState();
}

class _BarPageState extends State<BarPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ${printCode(barCode(config), indent: 6, column: 12)},
    );
  }
}
''';
