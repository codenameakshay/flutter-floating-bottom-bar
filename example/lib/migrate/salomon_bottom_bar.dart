import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [_Page('Home'), _Page('Search'), _Page('Profile')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(maxWidth: 420),
        body: BottomBarBodyPadding(child: _pages[_index]),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: BottomBarItems(
            labelBehavior: BottomBarLabelBehavior.onlySelected,
            indicator: const BottomBarIndicator.tint(),
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            children: const [
              BottomBarItem(
                icon: Icon(Icons.home),
                label: Text('Home'),
                selectedColor: Colors.purple,
              ),
              BottomBarItem(
                icon: Icon(Icons.search),
                label: Text('Search'),
                selectedColor: Colors.orange,
              ),
              BottomBarItem(
                icon: Icon(Icons.person),
                label: Text('Profile'),
                selectedColor: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: PageStorageKey(title),
      itemCount: 40,
      itemBuilder: (_, i) => ListTile(title: Text('$title row $i')),
    );
  }
}
