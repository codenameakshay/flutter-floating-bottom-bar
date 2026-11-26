import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

final transitionsFeature = GoldenFeature(
  'Custom transitions',
  readme: 'custom-transitions',
  demo: 'custom-transition',
  cases: [
    _transitionCase(
      'bottom_bar_transition_fade',
      'Fade transition halfway through hiding',
      BottomBarTransition.fade,
    ),
    _transitionCase(
      'bottom_bar_transition_scale',
      'Scale transition halfway through hiding',
      BottomBarTransition.scale,
    ),
    _transitionCase(
      'bottom_bar_transition_slide',
      'Slide transition halfway through hiding',
      BottomBarTransition.slide,
    ),
    _transitionCase(
      'bottom_bar_transition_slideAndFade',
      'Slide and fade transition halfway through hiding',
      BottomBarTransition.slideAndFade,
    ),
  ],
);

GoldenCase _transitionCase(
  String id,
  String caption,
  BottomBarTransition transition,
) {
  return GoldenCase(
    id,
    caption: caption,
    shots: const [Shot('')],
    run: (tester, _) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              showIcon: false,
              motion: BottomBarMotion.curved(
                transition: transition,
                duration: const Duration(milliseconds: 400),
                curve: Curves.linear,
                // Keep both sliding bars in view at the capture time.
                slideStart: const Offset(0, 0.5),
              ),
              body: const SizedBox.expand(),
              child: const SizedBox(
                height: 56,
                child: Center(child: Text('Bar')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final label = find.text('Bar');
      final shown = tester.getCenter(label);
      controller.hide();
      // The ticker measures elapsed time from its first frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      if (transition == BottomBarTransition.slide ||
          transition == BottomBarTransition.slideAndFade) {
        expect(
          tester.getCenter(label).dy,
          allOf(
            greaterThan(shown.dy),
            lessThan(tester.getSize(find.byType(Scaffold)).height),
          ),
        );
      }
      if (transition == BottomBarTransition.fade ||
          transition == BottomBarTransition.slideAndFade) {
        final fade = tester.widget<FadeTransition>(
          find.ancestor(of: label, matching: find.byType(FadeTransition)).first,
        );
        expect(fade.opacity.value, closeTo(0.5, 0.01));
      }
      if (transition == BottomBarTransition.scale) {
        final scale = tester.widget<ScaleTransition>(
          find
              .ancestor(of: label, matching: find.byType(ScaleTransition))
              .first,
        );
        expect(scale.scale.value, closeTo(0.5, 0.01));
      }
    },
  );
}
