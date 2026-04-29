import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class NestedScrollDemoPage extends StatelessWidget {
  const NestedScrollDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => const [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(title: Text('Nested scroll')),
            ),
          ],
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Bar over a NestedScrollView'),
        ),
      ),
    );
  }
}
