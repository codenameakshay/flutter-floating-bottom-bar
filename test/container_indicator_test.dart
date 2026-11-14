import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

final _shiftKey = GlobalKey<_ShiftedItemState>();
const _captureKey = Key('capture');
const _containerColor = Color(0xff00ff00);

class _ShiftedItem extends StatefulWidget {
  const _ShiftedItem({super.key});

  @override
  State<_ShiftedItem> createState() => _ShiftedItemState();
}

class _ShiftedItemState extends State<_ShiftedItem> {
  double shift = 0;

  void move() => setState(() => shift = 80);

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Transform.translate(
      offset: Offset(shift, 0),
      child: const BottomBarItem(
        icon: SizedBox(width: 24, height: 24),
        label: SizedBox.shrink(),
      ),
    ),
  );
}

Future<ui.Image> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  return boundary.toImage(pixelRatio: 1);
}

Future<Color> _pixel(ui.Image image, Offset localPosition) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final data = bytes!.buffer.asUint8List();
  final x = localPosition.dx.round();
  final y = localPosition.dy.round();
  final offset = (y * image.width + x) * 4;
  return Color.fromARGB(
    data[offset + 3],
    data[offset],
    data[offset + 1],
    data[offset + 2],
  );
}

void main() {
  testWidgets('container indicator tracks translated item pixels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: _captureKey,
              child: SizedBox(
                width: 240,
                height: 80,
                child: BottomBarItems(
                  selectedIndex: 0,
                  indicator: const BottomBarIndicator.container(
                    color: _containerColor,
                  ),
                  children: [
                    _ShiftedItem(key: _shiftKey),
                    const BottomBarItem(
                      icon: SizedBox(width: 24, height: 24),
                      label: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final captureRect = tester.getRect(find.byKey(_captureKey));
    final oldCenter = tester.getCenter(find.byKey(_shiftKey));
    final before = await tester.runAsync(() => _capture(tester));
    expect(
      await tester.runAsync(
        () => _pixel(before!, oldCenter - captureRect.topLeft),
      ),
      _containerColor,
    );
    before!.dispose();

    _shiftKey.currentState!.move();
    await tester.pump();
    await tester.pump();

    final movedCenter = oldCenter + const Offset(80, 0);
    final after = await tester.runAsync(() => _capture(tester));
    expect(
      await tester.runAsync(
        () => _pixel(after!, movedCenter - captureRect.topLeft),
      ),
      _containerColor,
    );
    expect(
      await tester.runAsync(
        () => _pixel(after!, oldCenter - captureRect.topLeft),
      ),
      isNot(_containerColor),
    );
    after!.dispose();
  });
}
