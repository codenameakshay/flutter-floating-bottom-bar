import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              motion: BottomBarMotion.curved(
                transition: transition,
                duration: const Duration(milliseconds: 400),
              ),
              body: const SizedBox.shrink(),
              child: const SizedBox(
                height: 56,
                child: Center(child: Text('Bar')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.hide();
      await tester.pump(const Duration(milliseconds: 200));
    },
  );
}
