import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class SelectionDockRecipe extends StatefulWidget {
  const SelectionDockRecipe({super.key});

  @override
  State<SelectionDockRecipe> createState() => _SelectionDockRecipeState();
}

class _SelectionDockRecipeState extends State<SelectionDockRecipe> {
  final _rows = List.generate(30, (i) => 'Message ${i + 1}');
  final _selected = <String>{};
  int _tab = 0;

  void _toggle(String row) => setState(
    () => _selected.contains(row) ? _selected.remove(row) : _selected.add(row),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selection dock')),
      body: BottomBar(
        body: BottomBarBodyPadding(
          child: ListView(
            children: [
              for (final row in _rows)
                ListTile(
                  title: Text(row),
                  selected: _selected.contains(row),
                  trailing: _selected.contains(row)
                      ? const Icon(Icons.check_circle)
                      : null,
                  onLongPress: () => _toggle(row),
                  onTap: _selected.isEmpty ? null : () => _toggle(row),
                ),
            ],
          ),
        ),
        child: BottomBarSwitcher(
          child: _selected.isEmpty
              ? BottomBarItems(
                  key: const ValueKey('nav'),
                  selectedIndex: _tab,
                  onSelected: (i) => setState(() => _tab = i),
                  indicator: const BottomBarIndicator.pill(),
                  children: const [
                    BottomBarItem(
                      icon: Icon(Icons.inbox),
                      label: Text('Inbox'),
                    ),
                    BottomBarItem(
                      icon: Icon(Icons.star),
                      label: Text('Starred'),
                    ),
                    BottomBarItem(icon: Icon(Icons.send), label: Text('Sent')),
                  ],
                )
              : Row(
                  key: const ValueKey('selection'),
                  children: [
                    IconButton(
                      tooltip: 'Clear selection',
                      onPressed: () => setState(_selected.clear),
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(child: Text('${_selected.length} selected')),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => setState(() {
                        _rows.removeWhere(_selected.contains);
                        _selected.clear();
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
