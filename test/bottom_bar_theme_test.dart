import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarThemeData', () {
    test('merge: other wins over this', () {
      const a = BottomBarThemeData(iconWidth: 30);
      const b = BottomBarThemeData(iconWidth: 40, iconHeight: 40);
      final merged = a.merge(b);
      expect(merged.iconWidth, 40);
      expect(merged.iconHeight, 40);
    });

    test('merge: null other returns this', () {
      const a = BottomBarThemeData(iconWidth: 30);
      expect(a.merge(null), a);
    });

    test('merge: this fields preserved when other has nulls', () {
      const a = BottomBarThemeData(iconWidth: 30, iconHeight: 30);
      const b = BottomBarThemeData(iconWidth: 50);
      final merged = a.merge(b);
      expect(merged.iconWidth, 50);
      expect(merged.iconHeight, 30);
    });

    test('lerp at t=0 returns this; at t=1 returns other', () {
      const a = BottomBarThemeData(iconWidth: 10);
      const b = BottomBarThemeData(iconWidth: 50);
      final l0 = a.lerp(b, 0.0);
      final l1 = a.lerp(b, 1.0);
      expect(l0.iconWidth, 10);
      expect(l1.iconWidth, 50);
    });

    test('copyWith preserves untouched fields', () {
      const a = BottomBarThemeData(iconWidth: 30, iconHeight: 30);
      final updated = a.copyWith(iconWidth: 40);
      expect(updated.iconWidth, 40);
      expect(updated.iconHeight, 30);
    });
  });
}
