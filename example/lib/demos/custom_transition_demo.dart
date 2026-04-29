import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class CustomTransitionDemoPage extends StatelessWidget {
  const CustomTransitionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom transition demo')),
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        motion: BottomBarMotion(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          transitionBuilder: (ctx, anim, child) {
            return Opacity(
              opacity: anim.value,
              child: Transform.scale(
                scale: 0.6 + 0.4 * anim.value,
                child: child,
              ),
            );
          },
        ),
        body: ListView.builder(
          itemCount: 200,
          itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Custom fade + scale transition'),
        ),
      ),
    );
  }
}
