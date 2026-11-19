import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import 'bar_code.dart';
import 'bar_config.dart';

/// The bar [config] describes, over a colourful feed, built from the same
/// values the generated code prints.
class BarPreview extends StatefulWidget {
  const BarPreview({super.key, required this.config});

  final BarConfig config;

  @override
  State<BarPreview> createState() => _BarPreviewState();
}

class _BarPreviewState extends State<BarPreview> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final center = config.get(Knob.center);
    final count = config.get(Knob.items);
    return AnimatedTheme(
      data: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: config.get(Knob.dark) ? Brightness.dark : Brightness.light,
      ),
      child: Directionality(
        textDirection: config.get(Knob.rtl)
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(config.get(Knob.textScale))),
          child: ScaffoldMessenger(
            child: Scaffold(
              body: BottomBar(
                theme: buildTheme(config)?.value,
                leading: config.effective(Knob.leading)
                    ? IconButton(
                        tooltip: 'Profile',
                        onPressed: () {},
                        icon: const Icon(Icons.person_rounded),
                      )
                    : null,
                trailing: config.effective(Knob.trailing)
                    ? IconButton(
                        tooltip: 'Search',
                        onPressed: () {},
                        icon: const Icon(Icons.search_rounded),
                      )
                    : null,
                accessory: config.get(Knob.accessory)
                    ? const ListTile(
                        leading: Icon(Icons.music_note_rounded),
                        title: Text('Now playing'),
                      )
                    : null,
                body: const BottomBarBodyPadding(child: _Feed()),
                child: BottomBarItems(
                  selectedIndex: _index.clamp(0, count - 1),
                  onSelected: (i) => setState(() => _index = i),
                  labelBehavior: config.get(Knob.labels)
                      ? null
                      : BottomBarLabelBehavior.alwaysHide,
                  indicator: buildIndicator(config)?.value,
                  centerAction: center == CenterStyle.none
                      ? null
                      : BottomBarCenterAction(
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Create',
                          style: BottomBarCenterActionStyle.values.byName(
                            center.name,
                          ),
                          onPressed: () {},
                        ),
                  children: [
                    for (final (i, item) in barItems.take(count).indexed)
                      BottomBarItem(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                        badge: config.get(Knob.badge) && i == badgeIndex
                            ? const BottomBarBadge.count(badgeCount)
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed();

  static const _icons = [
    Icons.palette_rounded,
    Icons.landscape_rounded,
    Icons.music_note_rounded,
    Icons.local_florist_rounded,
    Icons.architecture_rounded,
    Icons.camera_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      itemCount: 24,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 150 + (i % 3) * 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(
                  1,
                  (i * 37 % 360).toDouble(),
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
          child: Icon(_icons[i % 6], size: 40, color: Colors.white70),
        ),
      ),
    );
  }
}
