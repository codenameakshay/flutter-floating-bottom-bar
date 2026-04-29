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
}
