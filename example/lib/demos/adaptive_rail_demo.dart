import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

enum _Preset { glass, material3 }

const _labels = ['Home', 'Inbox', 'Saved', 'Profile'];

class AdaptiveRailDemoPage extends StatefulWidget {
  const AdaptiveRailDemoPage({super.key});

  @override
  State<AdaptiveRailDemoPage> createState() => _AdaptiveRailDemoPageState();
}

class _AdaptiveRailDemoPageState extends State<AdaptiveRailDemoPage> {
  int _index = 0;
  _Preset _preset = _Preset.glass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBarAdaptive(
        theme: _preset == _Preset.glass
            ? BottomBarThemeData.glass()
            : BottomBarThemeData.material3(),
        railLeading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () {},
        ),
        items: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          scrollToStartOnReselect: true,
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add),
            tooltip: 'New post',
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('New post'))),
          ),
          children: const [
            BottomBarItem(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Text('Home'),
              badge: BottomBarBadge.dot(),
            ),
            BottomBarItem(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: Text('Inbox'),
              badge: BottomBarBadge.count(4),
            ),
            BottomBarItem(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: Text('Saved'),
            ),
            BottomBarItem(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text('Profile'),
              badge: BottomBarBadge.label('New'),
            ),
          ],
        ),
        body: _Body(
          label: _labels[_index],
          preset: _preset,
          onPresetChanged: (preset) => setState(() => _preset = preset),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.label,
    required this.preset,
    required this.onPresetChanged,
  });

  final String label;
  final _Preset preset;
  final ValueChanged<_Preset> onPresetChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BottomBarBodyPadding(
      child: CustomScrollView(
        key: const PageStorageKey('adaptive-rail-list'),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adaptive rail', style: textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      'Resize the window. Below 600 wide it is a bar, at 600 and above a rail.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<_Preset>(
                segments: const [
                  ButtonSegment(value: _Preset.glass, label: Text('Glass')),
                  ButtonSegment(
                    value: _Preset.material3,
                    label: Text('Material 3'),
                  ),
                ],
                selected: {preset},
                onSelectionChanged: (selection) =>
                    onPresetChanged(selection.first),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Draft (survives the switch)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (context, i) => ListTile(title: Text('$label row $i')),
          ),
        ],
      ),
    );
  }
}
