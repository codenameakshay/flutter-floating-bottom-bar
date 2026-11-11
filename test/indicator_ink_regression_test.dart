import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _capture = Key('capture');

Widget _app(
  IndicatorMotion motion, {
  bool boundary = false,
  bool scale = false,
  bool rowBoundary = false,
  TextDirection direction = TextDirection.ltr,
  bool narrow = false,
  BottomBarIndicator indicator = const BottomBarIndicator.pill(
    color: Colors.green,
  ),
  ValueNotifier<double>? translation,
}) {
  Widget item() {
    Widget ink = const IndicatorInk(child: ColoredBox(color: Colors.red));
    if (boundary) ink = RepaintBoundary(child: ink);
    if (scale) ink = Transform.scale(scale: 0.8, child: ink);
    return IndicatorAnchor(
      role: IndicatorAnchorRole.slot,
      child: SizedBox(
        width: 100,
        height: 60,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.blue),
            ink,
          ],
        ),
      ),
    );
  }

  final first = item();
  Widget row = Row(
    children: [
      if (translation == null)
        first
      else
        ValueListenableBuilder<double>(
          valueListenable: translation,
          child: first,
          builder: (_, value, child) =>
              Transform.translate(offset: Offset(value, 0), child: child),
        ),
      item(),
    ],
  );
  if (rowBoundary) row = RepaintBoundary(child: row);
  Widget track = SizedBox(
    width: 200,
    height: 60,
    child: IndicatorTrack(
      motion: motion,
      indicator: indicator,
      reveal: false,
      row: row,
    ),
  );
  if (narrow) {
    track = SizedBox(
      width: 80,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: track,
      ),
    );
  }
  return MaterialApp(
    home: Center(
      child: RepaintBoundary(
        key: _capture,
        child: Directionality(textDirection: direction, child: track),
      ),
    ),
  );
}

Future<Color> _pixel(WidgetTester tester, int x) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final i = (30 * image.width + x) * 4;
    final color = Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
    image.dispose();
    return color;
  }))!;
}

void main() {
  testWidgets('ink supports RTL in a narrow scrolling row and ink off', (
    tester,
  ) async {
    final motion = IndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: const CupertinoMotion.snappy(),
    );
    await tester.pumpWidget(
      _app(motion, direction: TextDirection.rtl, narrow: true),
    );
    expect((await _pixel(tester, 40)).toARGB32(), Colors.red.toARGB32());
    await tester.pumpWidget(
      _app(
        motion,
        direction: TextDirection.rtl,
        narrow: true,
        indicator: const BottomBarIndicator.dot(),
      ),
    );
    expect((await _pixel(tester, 40)).toARGB32(), Colors.blue.toARGB32());
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    motion.dispose();
  });

  testWidgets('ink observes paint-only slot transforms behind a row boundary', (
    tester,
  ) async {
    final motion = IndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: const CupertinoMotion.snappy(),
    );
    final translation = ValueNotifier(0.0);
    await tester.pumpWidget(
      _app(motion, rowBoundary: true, translation: translation),
    );
    expect((await _pixel(tester, 50)).toARGB32(), Colors.red.toARGB32());
    translation.value = 100;
    await tester.pump();
    expect((await _pixel(tester, 150)).toARGB32(), Colors.red.toARGB32());
    expect(
      (await _pixel(tester, 50)).toARGB32(),
      0,
      reason: 'the green pill must leave the old slot in the same frame',
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.transientCallbackCount, 0);
    translation.dispose();
    motion.dispose();
  });
  for (final rowBoundary in [false, true]) {
    testWidgets(
      'ink refreshes across ${rowBoundary ? 'row' : 'item'} repaint boundary',
      (tester) async {
        final motion = IndicatorMotion(
          vsync: const TestVSync(),
          index: 0,
          motion: const CupertinoMotion.snappy(),
        );
        await tester.pumpWidget(
          _app(motion, boundary: !rowBoundary, rowBoundary: rowBoundary),
        );
        expect((await _pixel(tester, 50)).toARGB32(), Colors.red.toARGB32());
        motion.animateTo(1);
        await tester.pumpAndSettle();
        expect((await _pixel(tester, 50)).toARGB32(), Colors.blue.toARGB32());
        expect((await _pixel(tester, 150)).toARGB32(), Colors.red.toARGB32());
        await tester.pumpWidget(const SizedBox.shrink());
        motion.dispose();
      },
    );
  }
  testWidgets('ink supports a non-translation transform on first paint', (
    tester,
  ) async {
    final motion = IndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: const CupertinoMotion.snappy(),
    );
    await tester.pumpWidget(_app(motion, scale: true));
    expect((await _pixel(tester, 50)).toARGB32(), Colors.red.toARGB32());
    await tester.pumpWidget(const SizedBox.shrink());
    motion.dispose();
  });
}
