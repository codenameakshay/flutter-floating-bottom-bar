import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BadgesDemoPage extends StatefulWidget {
  const BadgesDemoPage({super.key});

  @override
  State<BadgesDemoPage> createState() => _BadgesDemoPageState();
}

class _BadgesDemoPageState extends State<BadgesDemoPage> {
  int _index = 0;

  Widget _badge(String count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          count,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(28),
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: const Text('Home'),
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              BottomBarItem(
                icon: const Icon(Icons.inbox_outlined),
                selectedIcon: const Icon(Icons.inbox),
                label: const Text('Inbox'),
                badge: _badge('3'),
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              BottomBarItem(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: const Text('Profile'),
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
