import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(BottomBarItem item) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 200,
        child: BottomBarItems(
          selectedIndex: 0,
          indicator: const BottomBarIndicator.pill(),
          children: [item],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('ink mounts a badge only once, including keyed badges', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      harness(
        BottomBarItem(
          icon: const Icon(Icons.home),
          badge: SizedBox(key: key, width: 8, height: 8),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(key), findsOneWidget);
  });

  testWidgets('selected ink copy cannot intercept input', (tester) async {
    var plainTaps = 0;
    var selectedTaps = 0;
    await tester.pumpWidget(
      harness(
        BottomBarItem(
          icon: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => plainTaps++,
            child: const SizedBox(width: 24, height: 24),
          ),
          selectedIcon: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => selectedTaps++,
            child: const SizedBox(width: 24, height: 24),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(BottomBarItem));
    expect(plainTaps, 1);
    expect(selectedTaps, 0);
  });

  testWidgets('selected ink copy does not add a focus target', (tester) async {
    final plain = FocusNode();
    final selected = FocusNode();
    addTearDown(plain.dispose);
    addTearDown(selected.dispose);
    await tester.pumpWidget(
      harness(
        BottomBarItem(
          icon: Focus(focusNode: plain, child: const Icon(Icons.home)),
          selectedIcon: Focus(
            focusNode: selected,
            child: const Icon(Icons.home),
          ),
        ),
      ),
    );
    expect(plain.canRequestFocus, isTrue);
    expect(selected.canRequestFocus, isFalse);
  });
  testWidgets('ink preserves the natural width of a selected icon', (
    tester,
  ) async {
    const key = Key('selected icon');
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: harness(
          const BottomBarItem(
            icon: SizedBox(width: 24, height: 24),
            selectedIcon: SizedBox(
              key: key,
              width: 40,
              height: 24,
              child: ColoredBox(color: Color(0xFFFF0000)),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(key)), const Size(40, 24));
    final image = await tester.runAsync(
      () =>
          (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(),
    );
    addTearDown(image!.dispose);
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final point = tester.getCenter(find.byKey(key)) + const Offset(18, 0);
    final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
    expect(bytes!.buffer.asUint8List().sublist(offset, offset + 4), [
      255,
      0,
      0,
      255,
    ]);
  });

  for (final part in ['icon', 'label']) {
    testWidgets('ink supports a GlobalKey on a custom $part', (tester) async {
      final key = GlobalKey();
      final keyed = SizedBox(key: key, width: 24, height: 24);
      await tester.pumpWidget(
        harness(
          BottomBarItem(
            icon: part == 'icon' ? keyed : const Icon(Icons.home),
            label: part == 'label' ? keyed : null,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
