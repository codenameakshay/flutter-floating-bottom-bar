import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = ['Home', 'Search', 'Profile'];
  final _navigators = [for (final _ in _tabs) GlobalKey<NavigatorState>()];

  bool _canPopTab(int i) => _navigators[i].currentState?.canPop() ?? false;

  void _back() {
    if (_canPopTab(_index)) {
      _navigators[_index].currentState!.pop();
    } else {
      setState(() => _index = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<NavigationNotification>(
      onNotification: (_) {
        setState(() {});
        return false;
      },
      child: PopScope(
        canPop: _index == 0 && !_canPopTab(0),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          body: BottomBar(
            layout: const BottomBarLayout.adaptive(maxWidth: 420),
            body: BottomBarBodyPadding(
              child: IndexedStack(
                index: _index,
                children: [
                  for (final (i, tab) in _tabs.indexed)
                    Navigator(
                      key: _navigators[i],
                      onGenerateRoute: (_) =>
                          MaterialPageRoute<void>(builder: (_) => _Page(tab)),
                    ),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: BottomBarItems(
                selectedIndex: _index,
                onSelected: (i) => setState(() => _index = i),
                onReselected: (i) =>
                    _navigators[i].currentState?.popUntil((r) => r.isFirst),
                scrollToStartOnReselect: !_canPopTab(_index),
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                  BottomBarItem(
                    icon: Icon(Icons.person),
                    label: Text('Profile'),
                  ),
                ],
              ),
            ),
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        key: PageStorageKey(title),
        itemCount: 40,
        itemBuilder: (_, i) => ListTile(
          title: Text('$title row $i'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  Scaffold(appBar: AppBar(title: Text('$title item $i'))),
            ),
          ),
        ),
      ),
    );
  }
}
