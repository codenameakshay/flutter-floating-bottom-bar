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
        motion: BottomBarMotion.curved(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          transitionBuilder: (ctx, anim, child) {
            final value = anim.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 0.6 + 0.4 * value,
                child: child,
              ),
            );
          },
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 28,
                offset: Offset(0, 16),
              ),
            ],
          ),
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
