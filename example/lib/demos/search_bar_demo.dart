import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class SearchBarDemoPage extends StatelessWidget {
  const SearchBarDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search bar demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(32),
          alignment: Alignment.bottomCenter,
        ),
        motion: const BottomBarMotion(
          duration: Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Result $i')),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.search),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search...',
                  ),
                ),
              ),
              Icon(Icons.tune),
            ],
          ),
        ),
      ),
    );
  }
}
