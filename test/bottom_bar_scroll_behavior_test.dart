import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarScrollBehavior', () {
    test('default values match the documented defaults', () {
      const behavior = BottomBarScrollBehavior();
      expect(behavior.hideOnScroll, true);
      expect(behavior.reverse, false);
      expect(behavior.scrollOpposite, false);
      expect(behavior.deltaThreshold, 8);
      expect(behavior.predicate, isNull);
    });

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
    });
  });
}
