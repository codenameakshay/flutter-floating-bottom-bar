import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_center_action_theme.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_item_theme.dart';

void main() {
  test('merge takes the non-null fields of other and keeps the rest', () {
    const base = BottomBarCenterActionThemeData(
      backgroundColor: Color(0xFF000001),
      foregroundColor: Color(0xFF000002),
      size: 40,
      elevation: 1,
    );
    const other = BottomBarCenterActionThemeData(
      backgroundColor: Color(0xFF0000AA),
      size: 60,
      raise: 10,
    );

    final merged = base.merge(other);

    expect(merged.backgroundColor, const Color(0xFF0000AA));
    expect(merged.foregroundColor, const Color(0xFF000002));
    expect(merged.size, 60);
    expect(merged.elevation, 1);
    expect(merged.raise, 10);
    expect(base.merge(null), same(base));
  });

  test('copyWith replaces only the given fields', () {
    const base = BottomBarCenterActionThemeData(size: 40, raise: 5);

    final copy = base.copyWith(size: 56);

    expect(copy.size, 56);
    expect(copy.raise, 5);
    expect(copy.notchMargin, isNull);
  });

  test('lerp interpolates sizes, raise and colours at the midpoint', () {
    const a = BottomBarCenterActionThemeData(
      backgroundColor: Color(0xFF000000),
      size: 40,
      raise: 10,
    );
    const b = BottomBarCenterActionThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      size: 60,
      raise: 30,
    );

    final mid = BottomBarCenterActionThemeData.lerp(a, b, 0.5)!;

    expect(mid.size, 50);
    expect(mid.raise, 20);
    expect(
      mid.backgroundColor,
      Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
    );
  });

  test('lerp of two nulls is null and identical instances return as is', () {
    const a = BottomBarCenterActionThemeData(size: 40);

    expect(BottomBarCenterActionThemeData.lerp(null, null, 0.5), isNull);
    expect(BottomBarCenterActionThemeData.lerp(a, a, 0.5), same(a));
  });

  test('equal instances are == and share a hashCode', () {
    const a = BottomBarCenterActionThemeData(
      size: 56,
      raise: 28,
      notchMargin: 6,
    );
    const b = BottomBarCenterActionThemeData(
      size: 56,
      raise: 28,
      notchMargin: 6,
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('changing any single field makes instances unequal', () {
    const base = BottomBarCenterActionThemeData(
      backgroundColor: Color(0xFF000001),
      foregroundColor: Color(0xFF000002),
      size: 56,
      shape: CircleBorder(),
      elevation: 3,
      shadowColor: Color(0xFF000003),
      raise: 28,
      notchMargin: 6,
    );
    final variants = [
      base.copyWith(backgroundColor: const Color(0xFF0000FF)),
      base.copyWith(foregroundColor: const Color(0xFF0000FE)),
      base.copyWith(size: 48),
      base.copyWith(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      base.copyWith(elevation: 0),
      base.copyWith(shadowColor: const Color(0xFF0000FD)),
      base.copyWith(raise: 20),
      base.copyWith(notchMargin: 8),
    ];

    expect(variants, hasLength(8));
    for (final variant in variants) {
      expect(variant, isNot(base));
    }
  });

  test('BottomBarItemThemeData.merge combines centerAction field-wise', () {
    const a = BottomBarItemThemeData(
      centerAction: BottomBarCenterActionThemeData(size: 40),
    );
    const b = BottomBarItemThemeData(
      centerAction: BottomBarCenterActionThemeData(raise: 10),
    );

    final merged = a.merge(b).centerAction!;

    expect(merged.size, 40);
    expect(merged.raise, 10);
  });

  test('BottomBarItemThemeData.copyWith sets centerAction', () {
    const base = BottomBarItemThemeData(color: Color(0xFF123456));

    final copy = base.copyWith(
      centerAction: const BottomBarCenterActionThemeData(size: 56),
    );

    expect(copy.centerAction?.size, 56);
    expect(copy.color, const Color(0xFF123456));
  });

  test('BottomBarItemThemeData.lerp interpolates centerAction', () {
    const a = BottomBarItemThemeData(
      centerAction: BottomBarCenterActionThemeData(size: 40),
    );
    const b = BottomBarItemThemeData(
      centerAction: BottomBarCenterActionThemeData(size: 60),
    );

    final mid = BottomBarItemThemeData.lerp(a, b, 0.5)!;

    expect(mid.centerAction?.size, 50);
  });

  test(
    'BottomBarItemThemeData equality differs when only centerAction does',
    () {
      const a = BottomBarItemThemeData(
        centerAction: BottomBarCenterActionThemeData(size: 40),
      );
      const b = BottomBarItemThemeData(
        centerAction: BottomBarCenterActionThemeData(size: 41),
      );

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    },
  );
}
