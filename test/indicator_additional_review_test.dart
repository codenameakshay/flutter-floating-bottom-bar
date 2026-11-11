import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _indicatorKey = Key('additional-indicator');
const _firstIconKey = Key('additional-first-icon');
const _lastIconKey = Key('additional-last-icon');
const _captureKey = Key('additional-capture');

Widget _app({
  required BottomBarIndicator indicator,
  int selectedIndex = 0,
  Widget? firstItem,
  double width = 300,
  bool? reducedMotion,
}) => MaterialApp(
  builder: (context, child) => reducedMotion == null
      ? child!
      : MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: _captureKey,
        child: SizedBox(
          width: width,
          height: 64,
          child: BottomBarItems(
            selectedIndex: selectedIndex,
            indicator: indicator,
            indicatorMotion: const CupertinoMotion.snappy(
              duration: Duration(milliseconds: 450),
            ),
            children: [
              firstItem ??
                  const BottomBarItem(
                    icon: SizedBox(key: _firstIconKey, width: 24, height: 24),
                  ),
              const BottomBarItem(icon: SizedBox(width: 24, height: 24)),
              const BottomBarItem(
                icon: SizedBox(key: _lastIconKey, width: 24, height: 24),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

Future<Color> _pixelAt(WidgetTester tester, Offset global) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final point = global - tester.getTopLeft(find.byKey(_captureKey));
  return (await tester.runAsync<Color>(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final index = (point.dy.floor() * image.width + point.dx.floor()) * 4;
      return Color.fromARGB(
        bytes.getUint8(index + 3),
        bytes.getUint8(index),
        bytes.getUint8(index + 1),
        bytes.getUint8(index + 2),
      );
    } finally {
      image.dispose();
    }
  }))!;
}

Widget _translatedItem(ValueNotifier<Offset> offset) =>
    ValueListenableBuilder<Offset>(
      valueListenable: offset,
      child: const BottomBarItem(
        icon: SizedBox(key: _firstIconKey, width: 24, height: 24),
      ),
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
    );

void _expectPillAtFirstIcon(WidgetTester tester) {
  final content = tester.getRect(find.byKey(_firstIconKey));
  final origin = tester.getTopLeft(find.byType(BottomBarItems));
  expect(
    find.byType(BottomBarItems),
    paints..rrect(
      rrect: RRect.fromRectAndRadius(
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ).inflateRect(content).shift(-origin),
        const Radius.circular(16),
      ),
    ),
  );
}

void main() {
  testWidgets('builder follows a locally translated item in the first frame', (
    tester,
  ) async {
    final offset = ValueNotifier<Offset>(Offset.zero);
    addTearDown(offset.dispose);
    await tester.pumpWidget(
      _app(
        firstItem: _translatedItem(offset),
        indicator: BottomBarIndicator.builder(
          (_, rect, settled) =>
              const ColoredBox(key: _indicatorKey, color: Colors.red),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initial = tester.getRect(find.byKey(_firstIconKey));
    expect(tester.getRect(find.byKey(_indicatorKey)), initial);

    offset.value = const Offset(20, 8);
    await tester.pump();
    final translated = tester.getRect(find.byKey(_firstIconKey));
    expect(translated, initial.shift(const Offset(20, 8)));
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      translated,
      reason:
          'The builder must track a paint-only transform on its first frame.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'builder follows a local translation inside a repaint boundary in the first frame',
    (tester) async {
      final offset = ValueNotifier<Offset>(Offset.zero);
      addTearDown(offset.dispose);
      await tester.pumpWidget(
        _app(
          firstItem: RepaintBoundary(child: _translatedItem(offset)),
          indicator: BottomBarIndicator.builder(
            (_, rect, settled) =>
                const ColoredBox(key: _indicatorKey, color: Colors.red),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initial = tester.getRect(find.byKey(_firstIconKey));
      expect(tester.getRect(find.byKey(_indicatorKey)), initial);

      offset.value = const Offset(20, 8);
      await tester.pump();
      final translated = tester.getRect(find.byKey(_firstIconKey));
      expect(translated, initial.shift(const Offset(20, 8)));
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        translated,
        reason:
            'A repaint boundary must not delay first-frame builder geometry.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pill follows a local translation inside a repaint boundary', (
    tester,
  ) async {
    final offset = ValueNotifier<Offset>(Offset.zero);
    addTearDown(offset.dispose);
    await tester.pumpWidget(
      _app(
        firstItem: RepaintBoundary(child: _translatedItem(offset)),
        indicator: const BottomBarIndicator.pill(color: Colors.red),
      ),
    );
    await tester.pumpAndSettle();
    final initial = tester.getRect(find.byKey(_firstIconKey));
    expect(
      (await _pixelAt(tester, initial.center)).toARGB32(),
      Colors.red.toARGB32(),
    );
    final newlyCoveredPoint = Offset(initial.right + 27, initial.center.dy + 8);
    expect(
      (await _pixelAt(tester, newlyCoveredPoint)).toARGB32(),
      isNot(Colors.red.toARGB32()),
    );

    offset.value = const Offset(20, 8);
    await tester.pump();
    expect(
      tester.getRect(find.byKey(_firstIconKey)),
      initial.shift(const Offset(20, 8)),
    );
    expect(
      (await _pixelAt(tester, newlyCoveredPoint)).toARGB32(),
      Colors.red.toARGB32(),
      reason: 'The retained layer must contain the translated pill too.',
    );
    _expectPillAtFirstIcon(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected item remains visible when a wide row becomes narrow', (
    tester,
  ) async {
    const indicator = BottomBarIndicator.pill();
    await tester.pumpWidget(_app(indicator: indicator, selectedIndex: 2));
    await tester.pumpAndSettle();
    final wide = tester.getRect(find.byType(BottomBarItems));
    final initiallySelected = tester.getRect(find.byKey(_lastIconKey));
    expect(initiallySelected.left, greaterThanOrEqualTo(wide.left));
    expect(initiallySelected.right, lessThanOrEqualTo(wide.right));

    await tester.pumpWidget(
      _app(indicator: indicator, selectedIndex: 2, width: 80),
    );
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final selected = tester.getRect(find.byKey(_lastIconKey));
    expect(selected.left, greaterThanOrEqualTo(viewport.left));
    expect(selected.right, lessThanOrEqualTo(viewport.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'platform reduced motion stops an active spring and cleans observer',
    (tester) async {
      final dispatcher = tester.binding.platformDispatcher;
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      var settled = false;
      final indicator = BottomBarIndicator.builder((_, rect, isSettled) {
        settled = isSettled;
        return const ColoredBox(key: _indicatorKey, color: Colors.red);
      });
      await tester.pumpWidget(_app(indicator: indicator));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        tester.getRect(find.byKey(_firstIconKey)),
      );
      expect(settled, isTrue);
      final observer =
          tester
                  .stateList<State>(
                    find.descendant(
                      of: find.byType(BottomBarItems),
                      matching: find.byWidgetPredicate(
                        (widget) => widget is StatefulWidget,
                      ),
                    ),
                  )
                  .whereType<WidgetsBindingObserver>()
                  .whereType<TickerProvider>()
                  .single
              as WidgetsBindingObserver;

      await tester.pumpWidget(_app(indicator: indicator, selectedIndex: 2));
      await tester.pump(const Duration(milliseconds: 60));
      final target = tester.getRect(find.byKey(_lastIconKey));
      expect(tester.getRect(find.byKey(_indicatorKey)), isNot(target));
      expect(settled, isFalse);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pump();
      expect(tester.getRect(find.byKey(_indicatorKey)), target);
      expect(settled, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(_app(indicator: indicator));
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        tester.getRect(find.byKey(_firstIconKey)),
      );
      expect(settled, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);

      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      await tester.pump();
      await tester.pumpWidget(_app(indicator: indicator, selectedIndex: 2));
      await tester.pump(const Duration(milliseconds: 60));
      expect(settled, isFalse);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.removeObserver(observer), isFalse);
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reenabling motion with a selection change starts a spring', (
    tester,
  ) async {
    var settled = false;
    final indicator = BottomBarIndicator.builder((_, rect, isSettled) {
      settled = isSettled;
      return const ColoredBox(key: _indicatorKey, color: Colors.red);
    });
    await tester.pumpWidget(_app(indicator: indicator, reducedMotion: true));
    await tester.pumpAndSettle();
    final initial = tester.getRect(find.byKey(_firstIconKey));
    expect(tester.getRect(find.byKey(_indicatorKey)), initial);
    expect(settled, isTrue);

    await tester.pumpWidget(
      _app(indicator: indicator, selectedIndex: 2, reducedMotion: false),
    );
    final target = tester.getRect(find.byKey(_lastIconKey));
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      isNot(target),
      reason: 'The new MediaQuery permits animation in this selection update.',
    );
    expect(settled, isFalse);
    await tester.pump(const Duration(milliseconds: 60));
    final moving = tester.getRect(find.byKey(_indicatorKey));
    expect(moving.left, greaterThan(initial.left));
    expect(moving.left, lessThan(target.left));
    expect(settled, isFalse);

    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_indicatorKey)), target);
    expect(settled, isTrue);
  });

  testWidgets('indicator type switches and disposal leave no idle frames', (
    tester,
  ) async {
    final builder = BottomBarIndicator.builder(
      (_, rect, settled) =>
          const ColoredBox(key: _indicatorKey, color: Colors.red),
    );
    await tester.pumpWidget(_app(indicator: builder));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_firstIconKey)),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(_app(indicator: const BottomBarIndicator.pill()));
    await tester.pumpAndSettle();
    expect(find.byKey(_indicatorKey), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(_app(indicator: builder));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_firstIconKey)),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
