import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness(BottomBarController controller, Offset iconOffset) {
    return MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          layout: BottomBarLayout(iconOffset: iconOffset),
          body: ListView.builder(
            itemCount: 200,
            itemBuilder: (context, index) =>
                ListTile(title: Text('Item $index')),
          ),
          child: const SizedBox(
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
        ),
      ),
    );
  }

  // Hides the bar (revealing the back-to-top icon), taps the icon at its
  // rendered position, and reports whether the tap re-showed the bar.
  Future<bool> tapBackToTopIcon(
    WidgetTester tester,
    BottomBarController controller,
  ) async {
    // Scroll down so the bar hides and a scroll position is recorded.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(controller.isVisible, isFalse,
        reason: 'bar should hide after scrolling down');

    // Tap the icon at its actual rendered (translated) location.
    await tester.tap(find.byTooltip('Scroll to top'), warnIfMissed: false);
    await tester.pumpAndSettle();

    return controller.isVisible;
  }

  testWidgets('back-to-top icon is tappable with a small iconOffset',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(buildHarness(controller, const Offset(5, 0)));

    expect(await tapBackToTopIcon(tester, controller), isTrue);
  });

  testWidgets('back-to-top icon is tappable with a large iconOffset',
      (tester) async {
    final controller = BottomBarController();
    await tester.pumpWidget(buildHarness(controller, const Offset(100, 0)));

    expect(
      await tapBackToTopIcon(tester, controller),
      isTrue,
      reason: 'tapping the icon at a large offset should still register and '
          'scroll the bar back into view',
    );
  });
}
