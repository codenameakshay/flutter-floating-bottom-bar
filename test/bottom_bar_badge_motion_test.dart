import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget badge, {bool reducedMotion = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: child!,
  ),
  home: Directionality(
    textDirection: TextDirection.ltr,
    child: Scaffold(
      body: Center(
        child: BottomBarItem(
          icon: const Icon(Icons.inbox, key: ValueKey('icon')),
          label: const Text('Inbox'),
          badge: badge,
        ),
      ),
    ),
  ),
);

Finder get _pill => find.descendant(
  of: find.byType(BottomBarBadge),
  matching: find.byType(Container),
);

Finder get _texts => find.descendant(
  of: find.byType(BottomBarBadge),
  matching: find.byType(Text),
);

Rect _pillRect(WidgetTester tester) => tester.getRect(_pill);

double _pillWidth(WidgetTester tester) => _pillRect(tester).width;

/// Each text layer of the badge with its rect.
List<(String, Rect)> layers(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(_texts))
    (text.data!, tester.getRect(find.byWidget(text))),
];

/// The scale of the badge's presence transform, 1 when it is not scaled.
double scale(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.descendant(
      of: find.byType(BottomBarBadge),
      matching: find.byType(Transform),
    ),
  );
  for (final transform in transforms) {
    final m = transform.transform;
    if (m[0] != 1 || m[5] != 1) return m[0];
  }
  return 1.0;
}

/// Hides [shown] and checks that the pill leaves within one second.
Future<void> _expectOutAnimation(
  WidgetTester tester, {
  required BottomBarBadge shown,
  required BottomBarBadge hidden,
}) async {
  await tester.pumpWidget(_app(shown));
  await tester.pumpAndSettle();

  await tester.pumpWidget(_app(hidden));
  await tester.pump(const Duration(milliseconds: 30));

  expect(_pill, findsOneWidget);
  expect(scale(tester), lessThan(1));
  expect(scale(tester), greaterThan(0));

  var present = 1;
  var elapsed = 30;
  while (_pill.evaluate().isNotEmpty) {
    await tester.pump(const Duration(milliseconds: 16));
    elapsed += 16;
    if (_pill.evaluate().isNotEmpty) present++;
    expect(
      elapsed,
      lessThanOrEqualTo(1000),
      reason: 'pill still mounted after 1s',
    );
  }
  expect(present, greaterThanOrEqualTo(2));
}

void main() {
  testWidgets('appear overshoots and settles at scale 1', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(0)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    final samples = <double>[];
    for (var t = 0; t < 600; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(scale(tester));
    }

    expect(samples.first, lessThan(0.5));
    expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(1.0));

    await tester.pumpAndSettle();
    expect(scale(tester), 1.0);
  });

  testWidgets('disappearing count stays mounted and shrinks', (tester) async {
    await _expectOutAnimation(
      tester,
      shown: const BottomBarBadge.count(3),
      hidden: const BottomBarBadge.count(0),
    );
  });

  testWidgets('disappearing dot stays mounted and shrinks', (tester) async {
    await _expectOutAnimation(
      tester,
      shown: const BottomBarBadge.dot(),
      hidden: const BottomBarBadge.dot(show: false),
    );
  });

  testWidgets('disappearing label stays mounted and shrinks', (tester) async {
    await _expectOutAnimation(
      tester,
      shown: const BottomBarBadge.label('New'),
      hidden: const BottomBarBadge.label('New', show: false),
    );
  });

  testWidgets('out animation keeps the last shown text', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const BottomBarBadge.count(0)));
    await tester.pump(const Duration(milliseconds: 30));

    expect(layers(tester).map((layer) => layer.$1).toList(), ['3']);
  });

  testWidgets('count rolls up when it grows', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    await tester.pumpAndSettle();
    final settledTop = layers(tester).single.$2.top;

    await tester.pumpWidget(_app(const BottomBarBadge.count(4)));
    await tester.pump(const Duration(milliseconds: 4));
    await tester.pump(const Duration(milliseconds: 60));

    final mid = {for (final (text, rect) in layers(tester)) text: rect};
    expect(mid.keys.toSet(), {'3', '4'});
    expect(mid['3']!.top, lessThan(settledTop));
    expect(mid['4']!.top, greaterThan(settledTop));

    await tester.pumpAndSettle();
    final settled = layers(tester);
    expect(settled.map((layer) => layer.$1).toList(), ['4']);
    expect(settled.single.$2.top, closeTo(settledTop, 0.01));
  });

  testWidgets('count rolls down when it shrinks', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(4)));
    await tester.pumpAndSettle();
    final settledTop = layers(tester).single.$2.top;

    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    await tester.pump(const Duration(milliseconds: 3));
    await tester.pump(const Duration(milliseconds: 60));

    final mid = {for (final (text, rect) in layers(tester)) text: rect};
    expect(mid.keys.toSet(), {'3', '4'});
    expect(mid['4']!.top, greaterThan(settledTop));
    expect(mid['3']!.top, lessThan(settledTop));
  });

  testWidgets('width animates between 9 and 10', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(9)));
    await tester.pumpAndSettle();
    final w9 = _pillWidth(tester);

    await tester.pumpWidget(_app(const BottomBarBadge.count(10)));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 30));
    final mid = _pillWidth(tester);

    await tester.pumpAndSettle();
    final w10 = _pillWidth(tester);

    expect(w10, greaterThan(w9));
    expect(mid, greaterThan(w9));
    expect(mid, lessThan(w10));
  });

  testWidgets('width animates between 10 and 99+', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(10)));
    await tester.pumpAndSettle();
    final w10 = _pillWidth(tester);

    await tester.pumpWidget(_app(const BottomBarBadge.count(150)));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 30));
    final mid = _pillWidth(tester);

    await tester.pumpAndSettle();
    final w99 = _pillWidth(tester);

    expect(w99, greaterThan(w10));
    expect(mid, greaterThan(w10));
    expect(mid, lessThan(w99));
  });

  testWidgets('fast retarget changes without jumps', (tester) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(1)));
    await tester.pumpAndSettle();

    final frames = <(double, List<(String, Rect)>)>[];
    void record() => frames.add((_pillWidth(tester), layers(tester)));

    await tester.pumpWidget(_app(const BottomBarBadge.count(2)));
    record();
    await tester.pump(const Duration(milliseconds: 40));
    record();
    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    record();
    await tester.pump(const Duration(milliseconds: 40));
    record();
    await tester.pumpWidget(_app(const BottomBarBadge.count(2)));
    record();
    for (var t = 0; t < 800; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      record();
    }

    for (var i = 1; i < frames.length; i++) {
      final (prevWidth, prevLayers) = frames[i - 1];
      final (width, currentLayers) = frames[i];
      expect(
        (width - prevWidth).abs(),
        lessThan(6),
        reason: 'width jump at frame $i',
      );
      for (final (text, rect) in currentLayers) {
        for (final (prevText, prevRect) in prevLayers) {
          if (prevText == text) {
            expect(
              (rect.top - prevRect.top).abs(),
              lessThan(10),
              reason: '"$text" jumped at frame $i',
            );
          }
        }
      }
    }

    await tester.pumpAndSettle();
    expect(layers(tester).map((layer) => layer.$1).toList(), ['2']);
  });

  testWidgets('reduced motion snaps every change', (tester) async {
    await tester.pumpWidget(
      _app(const BottomBarBadge.count(3), reducedMotion: true),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _app(const BottomBarBadge.count(150), reducedMotion: true),
    );
    await tester.pump();
    expect(layers(tester).map((layer) => layer.$1).toList(), ['99+']);
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(
      _app(const BottomBarBadge.count(0), reducedMotion: true),
    );
    await tester.pump();
    expect(_pill, findsNothing);

    await tester.pumpWidget(
      _app(const BottomBarBadge.count(5), reducedMotion: true),
    );
    await tester.pump();
    expect(_pill, findsOneWidget);
    expect(scale(tester), 1.0);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('showing again while hiding keeps the pill and settles', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(const BottomBarBadge.count(0)));
    await tester.pump(const Duration(milliseconds: 30));

    await tester.pumpWidget(_app(const BottomBarBadge.count(3)));
    expect(_pill, findsOneWidget);

    await tester.pumpAndSettle();
    expect(_pill, findsOneWidget);
    expect(scale(tester), 1.0);
    expect(layers(tester).map((layer) => layer.$1).toList(), ['3']);
  });
}
