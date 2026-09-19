import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/demos/scroll_under_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('last row clears the visible floating dock at scroll end', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = BottomBarController();

    await tester.pumpWidget(_buildPage(controller, bottomInset: 24));
    await tester.pumpAndSettle();

    final dock = find.byKey(const ValueKey<String>('scroll-under-dock'));
    final compactDockHeight = tester.getSize(dock).height;
    final expectedClearance = compactDockHeight + (16 * 2) + 24;
    expect(_clearance(tester), closeTo(expectedClearance, 0.01));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
    await tester.pumpAndSettle();
    controller.show();
    await tester.pumpAndSettle();

    final lastRow = find.byKey(const ValueKey<String>('scroll-under-last-row'));
    expect(
      tester.getBottomLeft(lastRow).dy,
      lessThanOrEqualTo(tester.getTopLeft(dock).dy + 0.01),
    );
    final pinnedHeaderTop = tester.getTopLeft(find.text('Scroll under')).dy;
    controller.hide();
    await tester.pumpAndSettle();
    expect(_clearance(tester), closeTo(expectedClearance, 0.01));
    expect(
      tester.getTopLeft(find.text('Scroll under')).dy,
      closeTo(pinnedHeaderTop, 0.01),
    );
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets(
    'expanded dock grows clearance and keeps the end reachable at 2x text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = BottomBarController();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            padding: EdgeInsets.only(bottom: 24),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(home: ScrollUnderDemoPage(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();

      final compactClearance = _clearance(tester);
      await tester.tap(find.byTooltip('Expand dock'));
      await tester.pumpAndSettle();
      final expandedClearance = _clearance(tester);
      expect(expandedClearance, greaterThan(compactClearance));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
      await tester.pumpAndSettle();
      controller.show();
      await tester.pumpAndSettle();

      final lastRow = find.byKey(
        const ValueKey<String>('scroll-under-last-row'),
      );
      final dock = find.byKey(const ValueKey<String>('scroll-under-dock'));
      expect(
        tester.getBottomLeft(lastRow).dy,
        lessThanOrEqualTo(tester.getTopLeft(dock).dy + 0.01),
      );
      expect(tester.takeException(), isNull);
      controller.dispose();
    },
  );

  testWidgets(
    'dock toggle has one native accessible label and updates clearance',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(const MaterialApp(home: ScrollUnderDemoPage()));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Expand dock'), findsOneWidget);
        final toggleSemantics = tester
            .getSemantics(find.byTooltip('Expand dock'))
            .getSemanticsData();
        expect(toggleSemantics.flagsCollection.isButton, isTrue);
        expect(toggleSemantics.tooltip, 'Expand dock');
        final compactClearance = _clearance(tester);

        await tester.tap(find.byTooltip('Expand dock'));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Collapse dock'), findsOneWidget);
        expect(_clearance(tester), greaterThan(compactClearance));
      } finally {
        semantics.dispose();
      }
    },
  );
}

Widget _buildPage(
  BottomBarController controller, {
  required double bottomInset,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: const Size(400, 800),
      padding: EdgeInsets.only(bottom: bottomInset),
    ),
    child: MaterialApp(home: ScrollUnderDemoPage(controller: controller)),
  );
}

double _clearance(WidgetTester tester) {
  return tester
      .widget<SliverPadding>(find.byType(SliverPadding))
      .padding
      .resolve(TextDirection.ltr)
      .bottom;
}
