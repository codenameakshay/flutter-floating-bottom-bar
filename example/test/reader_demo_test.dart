import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/demos/reader_demo.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reveals controls without moving the reading position', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.drag(
      find.byKey(const Key('reader-list')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    final pixels = scrollable.position.pixels;
    expect(pixels, greaterThan(0));
    expect(controller.isVisible, isFalse);
    expect(find.byKey(const Key('reader-reveal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-reveal')));
    await tester.pumpAndSettle();

    expect(controller.isVisible, isTrue);
    expect(scrollable.position.pixels, closeTo(pixels, 0.01));
    expect(find.byKey(const Key('reader-reveal')), findsNothing);
  });

  testWidgets('exposes labeled reveal and action controls', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_harness(controller));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Use large text'), findsOneWidget);
      expect(find.byTooltip('Bookmark article'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('reader-list')),
        const Offset(0, -420),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Show reading controls'), findsOneWidget);
      final revealData = tester
          .getSemantics(find.bySemanticsLabel('Show reading controls'))
          .getSemanticsData();
      expect(revealData.flagsCollection.isButton, isTrue);
      expect(revealData.hasAction(SemanticsAction.tap), isTrue);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('reduced motion snaps the controls into view', (tester) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    await tester.drag(
      find.byKey(const Key('reader-list')),
      const Offset(0, -420),
    );
    await tester.pump();
    expect(controller.isVisible, isFalse);
    expect(find.byKey(const Key('reader-reveal')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-reveal')));
    await tester.pump();
    expect(controller.isVisible, isTrue);
    final barSlide = tester.widget<SlideTransition>(
      find
          .ancestor(
            of: find.byKey(const Key('reader-controls')),
            matching: find.byType(SlideTransition),
          )
          .first,
    );
    expect(barSlide.position.value, Offset.zero);
  });

  testWidgets('reading actions change their state and text size', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_harness(controller));
    await tester.pumpAndSettle();

    final paragraph = find.text(
      'Good reading starts before the first sentence. Put the phone aside, notice the pace of your breathing, and let the page become the only place you need to be for a while.',
    );
    final regularHeight = tester.getSize(paragraph).height;

    await tester.tap(find.byKey(const Key('reader-text-size')));
    await tester.pump();
    expect(find.byTooltip('Use regular text'), findsOneWidget);
    expect(tester.getSize(paragraph).height, greaterThan(regularHeight));

    await tester.tap(find.byKey(const Key('reader-bookmark')));
    await tester.pump();
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('reading preference preserves the inherited text scaler', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_harness(controller, textScale: 2));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('reader-list')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(
        'Good reading starts before the first sentence. Put the phone aside, notice the pace of your breathing, and let the page become the only place you need to be for a while.',
        skipOffstage: false,
      ),
    );
    expect(paragraph.textScaler.scale(17), closeTo(34, 0.01));
  });

  testWidgets('reveal action stays above the home indicator', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_harness(controller, bottomInset: 34));
    await tester.pumpAndSettle();

    controller.hide();
    await tester.pumpAndSettle();

    final reveal = tester.getRect(find.byKey(const Key('reader-reveal')));
    expect(reveal.bottom, lessThanOrEqualTo(800 - 34 - 20));
  });
}

Widget _harness(
  BottomBarController controller, {
  double textScale = 1,
  double bottomInset = 0,
}) {
  return MaterialApp(
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: ReaderDemoPage(controller: controller),
  );
}
