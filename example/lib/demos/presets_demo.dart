import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

enum _Preset {
  glass(label: 'Glass', code: 'BottomBarThemeData.glass()'),
  material3(label: 'Material 3', code: 'BottomBarThemeData.material3()'),
  pill(label: 'Pill', code: 'BottomBarThemeData.pill()'),
  minimal(label: 'Minimal', code: 'BottomBarThemeData.minimal()');

  const _Preset({required this.label, required this.code});

  final String label;
  final String code;

  BottomBarThemeData get theme => switch (this) {
    _Preset.glass => BottomBarThemeData.glass(),
    _Preset.material3 => BottomBarThemeData.material3(),
    _Preset.pill => BottomBarThemeData.pill(),
    _Preset.minimal => BottomBarThemeData.minimal(),
  };
}

class PresetsDemoPage extends StatefulWidget {
  const PresetsDemoPage({super.key});

  @override
  State<PresetsDemoPage> createState() => _PresetsDemoPageState();
}

class _PresetsDemoPageState extends State<PresetsDemoPage> {
  static const _icons = [
    Icons.palette_rounded,
    Icons.landscape_rounded,
    Icons.music_note_rounded,
    Icons.local_florist_rounded,
    Icons.architecture_rounded,
    Icons.camera_rounded,
  ];
  static const _heights = [220.0, 160.0, 260.0, 190.0, 240.0, 170.0];

  _Preset _preset = _Preset.glass;
  bool _dark = false;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
      child: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            body: BottomBar(
              theme: _preset.theme,
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: const Text('Presets'),
                    actions: [
                      IconButton(
                        tooltip: _dark ? 'Light mode' : 'Dark mode',
                        icon: Icon(
                          _dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                        onPressed: () => setState(() => _dark = !_dark),
                      ),
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(104),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          children: [
                            SegmentedButton<_Preset>(
                              showSelectedIcon: false,
                              segments: [
                                for (final p in _Preset.values)
                                  ButtonSegment(value: p, label: Text(p.label)),
                              ],
                              selected: {_preset},
                              onSelectionChanged: (s) =>
                                  setState(() => _preset = s.first),
                            ),
                            const SizedBox(height: 10),
                            _codeLine(colorScheme),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                for (var i = 0; i < 40; i += 2)
                                  _tile(i, _heights[i % 6]),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                for (var i = 1; i < 40; i += 2)
                                  _tile(i, _heights[(i + 3) % 6]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: BottomBarBodyPadding(child: SizedBox(height: 16)),
                  ),
                ],
              ),
              child: BottomBarItems(
                selectedIndex: _index,
                onSelected: (i) => setState(() => _index = i),
                labelBehavior: _preset == _Preset.minimal
                    ? BottomBarLabelBehavior.onlySelected
                    : BottomBarLabelBehavior.alwaysShow,
                children: [
                  const BottomBarItem(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: Text('Home'),
                  ),
                  const BottomBarItem(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore_rounded),
                    label: Text('Explore'),
                  ),
                  const BottomBarItem(
                    icon: Icon(Icons.bookmark_outline_rounded),
                    selectedIcon: Icon(Icons.bookmark_rounded),
                    label: Text('Saved'),
                    badge: BottomBarBadge.count(3),
                  ),
                  const BottomBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _codeLine(ColorScheme colorScheme) {
    return Semantics(
      label: 'Code: ${_preset.code}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.code_rounded, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _preset.code,
                  key: ValueKey(_preset),
                  style: TextStyle(
                    fontFamily: 'Menlo',
                    fontFamilyFallback: const ['Courier', 'monospace'],
                    fontSize: 13,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(int i, double height) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromAHSL(
                    1,
                    ((i * 37) % 360).toDouble(),
                    0.75,
                    0.6,
                  ).toColor(),
                  HSLColor.fromAHSL(
                    1,
                    ((i * 37 + 50) % 360).toDouble(),
                    0.8,
                    0.45,
                  ).toColor(),
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(_icons[i % 6], size: 40, color: Colors.white70),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Board ${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
