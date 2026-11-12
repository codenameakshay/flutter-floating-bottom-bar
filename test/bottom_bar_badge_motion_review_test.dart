import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  BottomBarBadge badge, {
  bool reducedMotion = false,
  double textScale = 1,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reducedMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: Theme(
      data: ThemeData(useMaterial3: true),
      child: Center(child: SizedBox(width: 24, height: 24, child: badge)),
    ),
  ),
);

Finder get _pill => find.descendant(
  of: find.byType(BottomBarBadge),
  matching: find.byType(Container),
);

Size _pillSize(WidgetTester tester) {
  final constraints = tester.widget<Container>(_pill).constraints!;
  return Size(constraints.maxWidth, constraints.maxHeight);
}

double _textOffset(WidgetTester tester, String text) => tester
    .widget<Transform>(
      find
          .ancestor(of: find.text(text), matching: find.byType(Transform))
          .first,
    )
    .transform
    .storage[13];

void main() {
  testWidgets('capped count updates retain the latest numeric roll direction', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(200)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(const BottomBarBadge.count(250)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const BottomBarBadge.count(201, max: 500)));
    await tester.pump(const Duration(milliseconds: 40));

    expect(_textOffset(tester, '201'), lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('201'), findsOneWidget);
    expect(find.text('99+'), findsNothing);
  });

  testWidgets(
    'reduced motion cancels a width spring already at its new target',
    (tester) async {
      await tester.pumpWidget(_app(const BottomBarBadge.count(9)));
      await tester.pumpAndSettle();
      final size = _pillSize(tester);
      await tester.pumpWidget(_app(const BottomBarBadge.count(10)));
      await tester.pumpWidget(
        _app(const BottomBarBadge.count(9), reducedMotion: true),
      );

      expect(_pillSize(tester), size);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_pillSize(tester), size);
      expect(find.text('10'), findsNothing);
    },
  );

  testWidgets('hiding as a different kind preserves the outgoing pill', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(150)));
    await tester.pumpAndSettle();
    final size = _pillSize(tester);

    await tester.pumpWidget(_app(const BottomBarBadge.dot(show: false)));
    expect(_pillSize(tester), size);
    expect(find.text('99+'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 30));
    expect(_pillSize(tester), size);
    await tester.pumpAndSettle();
    expect(_pill, findsNothing);
  });

  for (final next in [100, 9]) {
    testWidgets('late roll retarget to $next preserves shared text positions', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const BottomBarBadge.count(9)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const BottomBarBadge.count(10)));
      for (var frame = 0; frame < 20; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (_textOffset(tester, '10') < _pillSize(tester).height / 2) break;
      }
      expect(_textOffset(tester, '10'), greaterThan(0));
      final incoming = _textOffset(tester, '10');
      final outgoing = _textOffset(tester, '9');
      final width = _pillSize(tester).width;

      await tester.pumpWidget(_app(BottomBarBadge.count(next)));

      expect(_textOffset(tester, '10'), closeTo(incoming, 0.0001));
      if (next == 9) {
        expect(_textOffset(tester, '9'), closeTo(outgoing, 0.0001));
      }
      expect(_pillSize(tester).width, closeTo(width, 0.0001));
      await tester.pumpAndSettle();
      expect(find.text(next > 99 ? '99+' : '$next'), findsOneWidget);
      expect(find.text('10'), findsNothing);
    });
  }

  testWidgets('visible kind switches reuse state and clear obsolete layers', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BottomBarBadge.dot()));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(BottomBarBadge));
    expect(_pillSize(tester), const Size.square(6));

    await tester.pumpWidget(_app(const BottomBarBadge.count(12)));
    expect(tester.state(find.byType(BottomBarBadge)), same(state));
    expect(find.text('12'), findsOneWidget);
    expect(_pillSize(tester).height, 16);
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const BottomBarBadge.label('New')));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(BottomBarBadge)), same(state));
    expect(find.text('New'), findsOneWidget);
    expect(find.text('12'), findsNothing);

    await tester.pumpWidget(_app(const BottomBarBadge.dot()));
    expect(tester.state(find.byType(BottomBarBadge)), same(state));
    expect(find.text('New'), findsNothing);
    expect(_pillSize(tester), const Size.square(6));
    await tester.pumpAndSettle();
  });

  testWidgets('hidden changes show only the latest content on reappearance', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(12)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(const BottomBarBadge.count(0)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(const BottomBarBadge.label('Queued', show: false)),
    );
    await tester.pumpWidget(_app(const BottomBarBadge.dot(show: false)));
    expect(_pill, findsNothing);

    await tester.pumpWidget(_app(const BottomBarBadge.label('Latest')));
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Queued'), findsNothing);
    expect(find.text('12'), findsNothing);
    await tester.pumpAndSettle();
    expect(_pillSize(tester).width, greaterThan(_pillSize(tester).height));
  });

  testWidgets(
    'disposing during presence, roll and width motion stops tickers',
    (tester) async {
      await tester.pumpWidget(_app(const BottomBarBadge.count(1)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const BottomBarBadge.count(150)));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(_app(const BottomBarBadge.count(0)));
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  for (final next in [100, 9]) {
    testWidgets(
      'early roll retarget to $next preserves shared text positions',
      (tester) async {
        await tester.pumpWidget(_app(const BottomBarBadge.count(9)));
        await tester.pumpAndSettle();
        await tester.pumpWidget(_app(const BottomBarBadge.count(10)));
        await tester.pump(const Duration(milliseconds: 16));
        final incoming = _textOffset(tester, '10');
        final outgoing = _textOffset(tester, '9');
        final width = _pillSize(tester).width;
        expect(incoming, greaterThan(_pillSize(tester).height / 2));

        await tester.pumpWidget(_app(BottomBarBadge.count(next)));

        expect(_textOffset(tester, '9'), closeTo(outgoing, 0.0001));
        expect(
          _textOffset(tester, next == 100 ? '99+' : '10'),
          closeTo(incoming, 0.0001),
        );
        expect(_pillSize(tester).width, closeTo(width, 0.0001));
        await tester.pumpAndSettle();
        expect(find.text(next > 99 ? '99+' : '$next'), findsOneWidget);
        expect(find.text('10'), findsNothing);
      },
    );
  }

  testWidgets('hidden text-scale updates snap to current size when shown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const BottomBarBadge.count(150, key: ValueKey('reference')),
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    final expected = _pillSize(tester);
    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(const BottomBarBadge.count(0)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(const BottomBarBadge.count(0), textScale: 2));
    expect(_pill, findsNothing);

    await tester.pumpWidget(
      _app(const BottomBarBadge.count(150), textScale: 2),
    );
    expect(_pillSize(tester), expected);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    expect(_pillSize(tester), expected);
    await tester.pumpAndSettle();
  });
}
