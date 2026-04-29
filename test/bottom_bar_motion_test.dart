import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarMotion', () {
    test('default values match the documented defaults', () {
      const motion = BottomBarMotion();
      expect(motion.duration, const Duration(milliseconds: 240));
      expect(motion.curve, Curves.easeOutCubic);
      expect(motion.transition, BottomBarTransition.slide);
      expect(motion.transitionBuilder, isNull);
      expect(motion.slideStart, const Offset(0, 2));
      expect(motion.slideEnd, Offset.zero);
    });

    test('copyWith preserves untouched fields', () {
      const motion = BottomBarMotion();
      final updated = motion.copyWith(transition: BottomBarTransition.fade);
      expect(updated.transition, BottomBarTransition.fade);
      expect(updated.duration, const Duration(milliseconds: 240));
    });

    test('equality is value-based', () {
      const a = BottomBarMotion(curve: Curves.linear);
      const b = BottomBarMotion(curve: Curves.linear);
      expect(a, b);
    });
  });

  // The bar's child is wrapped in a FadeTransition when transition is fade.
  // We use a Key on the bar child to narrow the search past
  // MaterialApp/Navigator route fades and the icon's AnimatedOpacity.
  testWidgets('BottomBarTransition.fade renders a FadeTransition',
      (tester) async {
    const barKey = Key('bar-content');
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BottomBar(
          motion: BottomBarMotion(transition: BottomBarTransition.fade),
          body: SizedBox.shrink(),
          child: SizedBox(
            key: barKey,
            height: 56,
            child: Center(child: Text('c')),
          ),
        ),
      ),
    ));

    // VisibilityAnimator wraps the bar's Container (which contains the
    // keyed SizedBox) in exactly one FadeTransition.
    final fades = find.ancestor(
      of: find.byKey(barKey),
      matching: find.byType(FadeTransition),
    );
    expect(fades, findsWidgets);
    // At least one of those FadeTransitions is the one we just inserted.
    // We verify it's the immediate wrapper of the bar's Container by
    // checking its child contains the keyed SizedBox.
    bool hasBarFade = false;
    for (final element in fades.evaluate()) {
      final fade = element.widget as FadeTransition;
      if (fade.child is Container) {
        hasBarFade = true;
        break;
      }
    }
    expect(hasBarFade, isTrue,
        reason: 'expected a FadeTransition wrapping the bar Container');
  });

  testWidgets('BottomBarMotion.transitionBuilder overrides the enum',
      (tester) async {
    bool builderCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          motion: BottomBarMotion(
            transitionBuilder: (ctx, anim, child) {
              builderCalled = true;
              return Opacity(opacity: anim.value, child: child);
            },
          ),
          body: const SizedBox.shrink(),
          child: const SizedBox(height: 56, child: Center(child: Text('c'))),
        ),
      ),
    ));

    expect(builderCalled, isTrue);
  });

  testWidgets(
      'overshooting curve does not produce negative icon constraints',
      (tester) async {
    final controller = BottomBarController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          motion: const BottomBarMotion(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
          ),
          body: const SizedBox.shrink(),
          child: const SizedBox(height: 56, child: Center(child: Text('c'))),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Hide the bar — this triggers the back-to-top icon's AnimatedContainer
    // to grow from 0 → iconWidth. If the icon shared the user's curve
    // (`Curves.easeOutBack` overshoots into negative territory), the
    // implicit width/height tween would emit negative BoxConstraints
    // mid-animation and crash layout.
    controller.hide();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull,
          reason: 'No layout exceptions allowed mid-animation.');
    }
    await tester.pumpAndSettle();
  });
}
