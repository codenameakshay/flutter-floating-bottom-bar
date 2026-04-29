import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BasicDemoPage extends StatelessWidget {
  const BasicDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Basic demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This is the floating widget',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
