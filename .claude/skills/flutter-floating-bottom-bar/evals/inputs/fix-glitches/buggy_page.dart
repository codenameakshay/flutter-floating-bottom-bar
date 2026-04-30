// Multiple things are wrong with this file. The user reports:
//   - "Bar flickers/inverts when it shows on a NestedScrollView page"
//   - "Last list item is always hidden behind the bar"
//   - "Bar reacts to the SliverAppBar collapsing instead of the inner list scroll"
import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BuggyPage extends StatelessWidget {
  const BuggyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        layout: BottomBarLayout(
          width: 280,
          borderRadius: BorderRadius.circular(28),
        ),
        // Custom transition that overshoots and inverts.
        motion: BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.bouncy,
          extraBounce: 0.06,
          transitionBuilder: (context, anim, child) {
            return Opacity(
              opacity: anim.value,
              child: Transform.scale(
                scale: anim.value,
                child: child,
              ),
            );
          },
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => const [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(title: Text('Buggy page')),
            ),
          ],
          body: ListView.builder(
            itemCount: 100,
            itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Floating bar'),
        ),
      ),
    );
  }
}
