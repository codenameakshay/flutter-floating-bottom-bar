import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class CenterActionDemoPage extends StatefulWidget {
  const CenterActionDemoPage({super.key});

  @override
  State<CenterActionDemoPage> createState() => _CenterActionDemoPageState();
}

class _CenterActionDemoPageState extends State<CenterActionDemoPage> {
  int _index = 0;
  BottomBarCenterActionStyle _style = BottomBarCenterActionStyle.notched;

  String get _caption => switch (_style) {
    BottomBarCenterActionStyle.inline =>
      'Inline: the button sits in the bar, in the middle slot.',
    BottomBarCenterActionStyle.raised =>
      'Raised: the button sits above the bar\'s top edge.',
    BottomBarCenterActionStyle.notched =>
      'Notched: the bar is cut around a raised button.',
  };

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Create',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            ListTile(
              title: const Text('New post'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            ListTile(
              title: const Text('New playlist'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            ListTile(
              title: const Text('Upload'),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Centre action')),
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: 420,
          offset: 16,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
        ),
        body: BottomBarBodyPadding(
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<BottomBarCenterActionStyle>(
                  segments: const [
                    ButtonSegment(
                      value: BottomBarCenterActionStyle.inline,
                      label: Text('Inline'),
                    ),
                    ButtonSegment(
                      value: BottomBarCenterActionStyle.raised,
                      label: Text('Raised'),
                    ),
                    ButtonSegment(
                      value: BottomBarCenterActionStyle.notched,
                      label: Text('Notched'),
                    ),
                  ],
                  selected: {_style},
                  onSelectionChanged: (selection) =>
                      setState(() => _style = selection.first),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _caption,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (var i = 1; i <= 40; i++) ListTile(title: Text('Item $i')),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomBarItems(
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            indicator: const BottomBarIndicator.pill(),
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Create',
              style: _style,
              onPressed: _openSheet,
            ),
            children: const [
              BottomBarItem(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: Text('Library'),
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
    );
  }
}
