import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inner scroll ending at min shows bar under collapsed header', (
    tester,
  ) async {
    final controller = BottomBarController();
    final nestedKey = GlobalKey<NestedScrollViewState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            scrollBehavior: const BottomBarScrollBehavior(
              deltaThreshold: 10000,
            ),
            body: NestedScrollView(
              key: nestedKey,
              headerSliverBuilder: (_, _) => const [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  title: Text('Nested'),
                ),
              ],
              body: ListView.builder(
                itemCount: 200,
                itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
              ),
            ),
            child: const SizedBox(height: 56),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -600));
    await tester.pumpAndSettle();

    final nested = nestedKey.currentState!;
    final outer = nested.outerController.position;
    final inner = nested.innerController.position;
    expect(outer.pixels, greaterThan(outer.minScrollExtent));
    expect(inner.pixels, greaterThan(inner.minScrollExtent));

    // Hold the bar hidden while returning the inner list to its own minimum.
    // Scroll-end visibility is per-scrollable: the inner boundary counts as
    // its start even while the outer header remains partially collapsed.
    controller.hide();
    expect(controller.isVisible, isFalse);
    await tester.drag(
      find.byType(Scrollable).last,
      Offset(0, inner.pixels + 40),
    );
    await tester.pumpAndSettle();

    expect(inner.pixels, inner.minScrollExtent);
    expect(outer.pixels, greaterThan(outer.minScrollExtent));
    expect(controller.isVisible, isTrue);
  });
}
