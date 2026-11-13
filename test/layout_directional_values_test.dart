import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarLayout directional fields', () {
    const base = BottomBarLayout(
      width: 240,
      offset: 12,
      groupSpacing: 4,
      respectSafeArea: false,
    );

    test('copyWith sets each directional field and keeps the others', () {
      final copy = base.copyWith(
        directionalAlignment: AlignmentDirectional.bottomEnd,
        directionalBorderRadius: const BorderRadiusDirectional.only(
          topEnd: Radius.circular(9),
        ),
        directionalIconOffset: const Offset(3, 0),
        docked: true,
      );

      expect(copy.directionalAlignment, AlignmentDirectional.bottomEnd);
      expect(
        copy.directionalBorderRadius,
        const BorderRadiusDirectional.only(topEnd: Radius.circular(9)),
      );
      expect(copy.directionalIconOffset, const Offset(3, 0));
      expect(copy.docked, isTrue);
      expect(copy.width, 240);
      expect(copy.offset, 12);
      expect(copy.groupSpacing, 4);
      expect(copy.respectSafeArea, isFalse);
      expect(copy.alignment, Alignment.bottomCenter);
      expect(copy.iconOffset, Offset.zero);
    });

    test('copyWith keeps docked true on a docked layout', () {
      expect(
        const BottomBarLayout.docked()
            .copyWith(iconOffset: const Offset(1, 0))
            .docked,
        isTrue,
      );
    });

    test('copyWith sets docked on a plain layout', () {
      expect(const BottomBarLayout().copyWith(docked: true).docked, isTrue);
    });

    test('equality and hashCode differ when each new field differs', () {
      const plain = BottomBarLayout();
      final variants = <BottomBarLayout>[
        plain.copyWith(directionalAlignment: AlignmentDirectional.bottomEnd),
        plain.copyWith(
          directionalBorderRadius: const BorderRadiusDirectional.only(
            topEnd: Radius.circular(9),
          ),
        ),
        plain.copyWith(directionalIconOffset: const Offset(3, 0)),
        plain.copyWith(docked: true),
      ];

      for (final variant in variants) {
        expect(variant == plain, isFalse);
        expect(variant.hashCode, isNot(plain.hashCode));
      }
    });

    test('equal directional fields compare equal with equal hashCodes', () {
      const plain = BottomBarLayout();
      final a = plain.copyWith(
        directionalAlignment: AlignmentDirectional.bottomEnd,
      );
      final b = plain.copyWith(
        directionalAlignment: AlignmentDirectional.bottomEnd,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('effectiveAlignment prefers the directional alignment', () {
      const physical = BottomBarLayout(alignment: Alignment.topLeft);
      expect(physical.effectiveAlignment, Alignment.topLeft);

      final directional = physical.copyWith(
        directionalAlignment: AlignmentDirectional.bottomEnd,
      );
      expect(
        directional.effectiveAlignment.resolve(TextDirection.ltr),
        Alignment.bottomRight,
      );
      expect(
        directional.effectiveAlignment.resolve(TextDirection.rtl),
        Alignment.bottomLeft,
      );
    });

    test('effectiveBorderRadius prefers the directional radius', () {
      const physical = BottomBarLayout(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      );
      expect(
        physical.effectiveBorderRadius,
        const BorderRadius.all(Radius.circular(10)),
      );

      final directional = physical.copyWith(
        directionalBorderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(20),
        ),
      );
      expect(
        directional.effectiveBorderRadius.resolve(TextDirection.rtl),
        const BorderRadius.only(topRight: Radius.circular(20)),
      );
      expect(
        directional.effectiveBorderRadius.resolve(TextDirection.ltr),
        const BorderRadius.only(topLeft: Radius.circular(20)),
      );
    });

    test(
      'resolveIconOffset uses iconOffset when no directional offset is set',
      () {
        const layout = BottomBarLayout(iconOffset: Offset(5, 0));
        expect(layout.resolveIconOffset(TextDirection.ltr), const Offset(5, 0));
        expect(layout.resolveIconOffset(TextDirection.rtl), const Offset(5, 0));
      },
    );

    test('resolveIconOffset mirrors dx under RTL and wins over iconOffset', () {
      const layout = BottomBarLayout(
        iconOffset: Offset(5, 0),
        directionalIconOffset: Offset(20, 4),
      );
      expect(layout.resolveIconOffset(TextDirection.ltr), const Offset(20, 4));
      expect(layout.resolveIconOffset(TextDirection.rtl), const Offset(-20, 4));
    });

    test('lerp interpolates alignment into the directional field', () {
      const a = BottomBarLayout(alignment: Alignment.bottomLeft);
      const b = BottomBarLayout(
        directionalAlignment: AlignmentDirectional.bottomEnd,
      );

      final start = BottomBarLayout.lerp(a, b, 0)!;
      expect(
        start.effectiveAlignment.resolve(TextDirection.ltr),
        Alignment.bottomLeft,
      );

      final end = BottomBarLayout.lerp(a, b, 1)!;
      expect(
        end.effectiveAlignment.resolve(TextDirection.ltr),
        Alignment.bottomRight,
      );
      expect(
        end.effectiveAlignment.resolve(TextDirection.rtl),
        Alignment.bottomLeft,
      );
    });

    test('lerp interpolates border radius into the directional field', () {
      const a = BottomBarLayout(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      );
      const b = BottomBarLayout(
        directionalBorderRadius: BorderRadiusDirectional.only(
          topEnd: Radius.circular(20),
        ),
      );

      final start = BottomBarLayout.lerp(a, b, 0)!;
      expect(
        start.effectiveBorderRadius.resolve(TextDirection.ltr),
        const BorderRadius.all(Radius.circular(4)),
      );

      final end = BottomBarLayout.lerp(a, b, 1)!;
      expect(
        end.effectiveBorderRadius.resolve(TextDirection.ltr),
        const BorderRadius.only(topRight: Radius.circular(20)),
      );
    });

    test('lerp interpolates directionalIconOffset when both sides set it', () {
      const a = BottomBarLayout(directionalIconOffset: Offset.zero);
      const b = BottomBarLayout(directionalIconOffset: Offset(10, 0));

      expect(
        BottomBarLayout.lerp(a, b, 0.5)!.directionalIconOffset,
        const Offset(5, 0),
      );
    });

    test(
      'lerp steps directionalIconOffset at 0.5 when only one side sets it',
      () {
        const a = BottomBarLayout();
        const b = BottomBarLayout(directionalIconOffset: Offset(10, 0));

        expect(BottomBarLayout.lerp(a, b, 0.49)!.directionalIconOffset, isNull);
        expect(
          BottomBarLayout.lerp(a, b, 0.5)!.directionalIconOffset,
          const Offset(10, 0),
        );
      },
    );

    test('lerp steps docked at 0.5', () {
      const a = BottomBarLayout();
      final b = const BottomBarLayout.docked();

      expect(BottomBarLayout.lerp(a, b, 0.49)!.docked, isFalse);
      expect(BottomBarLayout.lerp(a, b, 0.5)!.docked, isTrue);
    });
  });

  group('BottomBarMotion directionalSlide', () {
    test('defaults to false', () {
      expect(const BottomBarMotion().directionalSlide, isFalse);
    });

    test('copyWith sets directionalSlide on the curved constructor', () {
      const motion = BottomBarMotion.curved();
      final copy = motion.copyWith(directionalSlide: true);

      expect(copy.directionalSlide, isTrue);
      expect(copy.mode, BottomBarMotionMode.curved);
      expect(copy == motion, isFalse);
    });

    test('copyWith sets directionalSlide on the cupertino constructor', () {
      const motion = BottomBarMotion.cupertino();
      final copy = motion.copyWith(directionalSlide: true);

      expect(copy.directionalSlide, isTrue);
      expect(copy.mode, BottomBarMotionMode.cupertino);
      expect(copy == motion, isFalse);
    });
  });
}
