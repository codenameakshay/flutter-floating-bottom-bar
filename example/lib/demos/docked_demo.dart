import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class DockedDemoPage extends StatefulWidget {
  const DockedDemoPage({super.key});

  @override
  State<DockedDemoPage> createState() => _DockedDemoPageState();
}

class _DockedDemoPageState extends State<DockedDemoPage> {
  int _index = 0;
  bool _docked = true;
  bool _glass = false;
  bool _rtl = false;

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              key: const Key('docked-mode'),
              segments: const [
                ButtonSegment(value: false, label: Text('Floating')),
                ButtonSegment(value: true, label: Text('Docked')),
              ],
              selected: {_docked},
              onSelectionChanged: (selection) =>
                  setState(() => _docked = selection.first),
            ),
          ),
          SwitchListTile(
            key: const Key('docked-glass'),
            title: const Text('Glass'),
            value: _glass,
            onChanged: (value) => setState(() => _glass = value),
          ),
          SwitchListTile(
            key: const Key('docked-rtl'),
            title: const Text('Right to left'),
            value: _rtl,
            onChanged: (value) => setState(() => _rtl = value),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              key: const Key('docked-field'),
              decoration: const InputDecoration(
                hintText: 'Type to open the keyboard',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('Docked')),
        resizeToAvoidBottomInset: false,
        extendBody: true,
        body: BottomBar(
          layout: _docked
              ? const BottomBarLayout.docked()
              : const BottomBarLayout.adaptive(maxWidth: 480),
          theme: BottomBarThemeData(
            surface: _glass
                ? const BottomBarSurface.glass()
                : const BottomBarSurface.solid(),
          ),
          body: BottomBarBodyPadding(
            child: ListView(
              children: [
                _buildControls(),
                for (var i = 1; i <= 40; i++) ListTile(title: Text('Item $i')),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: BottomBarItems(
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
              indicator: const BottomBarIndicator.pill(),
              children: const [
                BottomBarItem(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
                BottomBarItem(
                  icon: Icon(Icons.inbox_outlined),
                  selectedIcon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
