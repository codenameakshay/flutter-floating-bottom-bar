import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarScrollBehavior', () {
    test('asserts deltaThreshold is non-negative', () {
      expect(
        () => BottomBarScrollBehavior(deltaThreshold: -1),
        throwsAssertionError,
      );
    });

    test('copyWith preserves untouched fields', () {
      const behavior = BottomBarScrollBehavior();
      final updated = behavior.copyWith(reverse: true);
      expect(updated.reverse, true);
      expect(updated.deltaThreshold, 8);
      expect(updated.showAtStart, false);
      expect(updated.showOnScrollEnd, false);
      expect(updated.keepVisibleOnFocus, true);
    });

    test('copyWith updates keepVisibleOnFocus', () {
      const behavior = BottomBarScrollBehavior();
      final updated = behavior.copyWith(keepVisibleOnFocus: false);
      expect(updated.keepVisibleOnFocus, false);
    });

    test('copyWith updates the settling flags', () {
      const behavior = BottomBarScrollBehavior();
      final updated = behavior.copyWith(
        showAtStart: true,
        showOnScrollEnd: true,
      );

      expect(updated.showAtStart, true);
      expect(updated.showOnScrollEnd, true);
    });

    test('equality and hashCode include the settling flags', () {
      const base = BottomBarScrollBehavior();
      const showAtStart = BottomBarScrollBehavior(showAtStart: true);
      const showOnScrollEnd = BottomBarScrollBehavior(showOnScrollEnd: true);

      expect(showAtStart, isNot(base));
      expect(showOnScrollEnd, isNot(base));
      expect(showAtStart.hashCode, isNot(base.hashCode));
      expect(showOnScrollEnd.hashCode, isNot(base.hashCode));
    });

    test('equality and hashCode include keepVisibleOnFocus', () {
      const base = BottomBarScrollBehavior();
      const disabled = BottomBarScrollBehavior(keepVisibleOnFocus: false);

      expect(disabled, isNot(base));
      expect(disabled.hashCode, isNot(base.hashCode));
    });

    test('keepVisibleOnFocus defaults to true', () {
      const behavior = BottomBarScrollBehavior();
      expect(behavior.keepVisibleOnFocus, true);
    });
  });
}
