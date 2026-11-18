import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

enum _Dock { nav, selection, composer }

class SwitcherDemoPage extends StatefulWidget {
  const SwitcherDemoPage({super.key});

  @override
  State<SwitcherDemoPage> createState() => _SwitcherDemoPageState();
}

class _SwitcherDemoPageState extends State<SwitcherDemoPage> {
  final _selected = <int>{};
  final _messageController = TextEditingController();
  bool _composing = false;
  int _tab = 0;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  _Dock get _dock {
    if (_composing) return _Dock.composer;
    if (_selected.isNotEmpty) return _Dock.selection;
    return _Dock.nav;
  }

  void _toggle(int index) {
    setState(() {
      if (!_selected.remove(index)) _selected.add(index);
      if (_selected.isEmpty) _composing = false;
    });
  }

  void _clearSelection() {
    setState(() {
      _selected.clear();
      _composing = false;
    });
  }

  void _delete() {
    final count = _selected.length;
    _clearSelection();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Deleted $count photos')));
  }

  void _send() {
    _messageController.clear();
    _clearSelection();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sent')));
  }

  Widget _selectionDock() {
    return SizedBox(
      key: const ValueKey('selection'),
      height: 64,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_selected.length} selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Share',
              onPressed: () {},
              icon: const Icon(Icons.ios_share),
            ),
            IconButton(
              tooltip: 'Compose',
              onPressed: () => setState(() => _composing = true),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: _clearSelection,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerDock() {
    return Padding(
      key: const ValueKey('composer'),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text('Share ${_selected.length} photos')),
              IconButton(
                tooltip: 'Close',
                onPressed: () => setState(() => _composing = false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Send',
                onPressed: _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Morph between bars')),
      body: BottomBar(
        theme: BottomBarThemeData(
          surface: BottomBarSurface.glass(
            blur: 16,
            fillOpacity: 0.8,
            edgeHighlight: const Color(0x59FFFFFF),
          ),
        ),
        body: BottomBarBodyPadding(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 60,
            itemBuilder: (context, index) => _Tile(
              index: index,
              selected: _selected.contains(index),
              onTap: _selected.isEmpty ? null : () => _toggle(index),
              onLongPress: () => _toggle(index),
            ),
          ),
        ),
        child: BottomBarSwitcher(
          child: switch (_dock) {
            _Dock.nav => BottomBarItems(
              key: const ValueKey('nav'),
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
              children: const [
                BottomBarItem(
                  icon: Icon(Icons.photo_library_outlined),
                  selectedIcon: Icon(Icons.photo_library),
                  label: Text('Library'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.collections_outlined),
                  selectedIcon: Icon(Icons.collections),
                  label: Text('Albums'),
                ),
                BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              ],
            ),
            _Dock.selection => _selectionDock(),
            _Dock.composer => _composerDock(),
          },
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final int index;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final swatch = Colors.primaries[index % Colors.primaries.length];
    final color = swatch[200 + (index ~/ Colors.primaries.length) * 100]!;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedScale(
        scale: selected ? 0.92 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(selected ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(selected ? 12 : 0),
                ),
              ),
            ),
            if (selected)
              PositionedDirectional(
                top: 6,
                end: 6,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 22, color: primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
