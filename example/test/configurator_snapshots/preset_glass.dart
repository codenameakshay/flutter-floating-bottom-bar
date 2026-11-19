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
      body: BottomBar(
        theme: BottomBarThemeData.glass(),
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 40,
            itemBuilder: (context, i) => ListTile(title: Text('Item $i')),
          ),
        ),
        child: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          children: const [
            BottomBarItem(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: Text('Home'),
            ),
            BottomBarItem(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: Text('Explore'),
            ),
            BottomBarItem(
              icon: Icon(Icons.bookmark_outline_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded),
              label: Text('Saved'),
            ),
            BottomBarItem(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: Text('Inbox'),
            ),
          ],
        ),
      ),
    );
  }
}
