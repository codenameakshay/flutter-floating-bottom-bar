// Existing v1.x usage of flutter_floating_bottom_bar.
// pubspec.yaml currently has: flutter_floating_bottom_bar: ^1.5.0
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        body: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Post $i')),
        ),
        barColor: Colors.white,
        width: MediaQuery.of(context).size.width * 0.9,
        borderRadius: BorderRadius.circular(28),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        start: 2,
        end: 0,
        hideOnScroll: true,
        scrollOpposite: false,
        scrollDeltaThreshold: 12,
        iconWidth: 32,
        iconHeight: 32,
        iconDecoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navButton(0, Icons.home),
              _navButton(1, Icons.explore),
              _navButton(2, Icons.notifications),
              _navButton(3, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(int index, IconData icon) {
    final selected = _tab == index;
    return IconButton(
      onPressed: () => setState(() => _tab = index),
      icon: Icon(icon, color: selected ? Colors.deepPurple : Colors.black54),
    );
  }
}
