import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarLayout', () {
    test('default values match the documented defaults', () {
      const layout = BottomBarLayout();
      expect(layout.width, 300);
      expect(layout.offset, 10);
      expect(layout.borderRadius, BorderRadius.zero);
      expect(layout.alignment, Alignment.bottomCenter);
      expect(layout.fit, StackFit.loose);
      expect(layout.clip, Clip.hardEdge);
      expect(layout.respectSafeArea, true);
    });

    test('copyWith preserves untouched fields', () {
      const layout = BottomBarLayout();
      final updated = layout.copyWith(width: 200);
      expect(updated.width, 200);
      expect(updated.offset, 10);
      expect(updated.respectSafeArea, true);
    });

    test('equality and hashCode are value-based', () {
      const a = BottomBarLayout(width: 250);
      const b = BottomBarLayout(width: 250);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
