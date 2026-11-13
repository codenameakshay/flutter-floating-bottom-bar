import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_group.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'bar_group_test.dart' show pumpBar;

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'raised group leaves gaps and space above sides clear $direction',
      (tester) async {
        var bodyTaps = 0;
        var actionTaps = 0;
        await pumpBar(
          tester,
          direction: direction,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => bodyTaps++,
            child: const SizedBox.expand(),
          ),
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Create',
              style: BottomBarCenterActionStyle.raised,
              onPressed: () => actionTaps++,
            ),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
            ],
          ),
        );
        final leading = tester.getRect(find.byKey(const ValueKey('leading')));
        final pill = tester.getRect(find.byKey(const ValueKey('pill')));
        final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
        for (final side in [leading, trailing]) {
          await tester.tapAt(Offset(side.center.dx, pill.top + 1));
          final gapX = side.center.dx < pill.center.dx
              ? (side.right + pill.left) / 2
              : (pill.right + side.left) / 2;
          await tester.tapAt(Offset(gapX, side.center.dy));
        }
        await tester.pump();
        expect(bodyTaps, 4);
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
        expect(actionTaps, 1);
      },
    );
  }

  testWidgets('ungrouped pill preserves incoming minimum height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: BarGroup(
            pillIndex: 0,
            spacing: 8,
            children: [SizedBox(key: Key('pill'), height: 50)],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('pill'))), const Size(800, 600));
  });

  testWidgets('group supports dry layout and intrinsic measurement', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            child: BarGroup(
              pillIndex: 1,
              spacing: 8,
              children: [
                SizedBox(width: 40, height: 30),
                SizedBox(width: 200, height: 50),
                SizedBox(width: 60, height: 30),
              ],
            ),
          ),
        ),
      ),
    );
    final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
    expect(group.getDryLayout(const BoxConstraints(maxWidth: 300)), group.size);
    expect(group.getMinIntrinsicHeight(300), 50);
    expect(group.getMaxIntrinsicHeight(300), 50);
    expect(group.getMinIntrinsicHeight(double.infinity), 50);
    expect(group.getMaxIntrinsicHeight(double.infinity), 50);
    expect(group.getDryLayout(const BoxConstraints()), const Size(326, 50));
    expect(group.getMinIntrinsicWidth(50), 326);
    expect(group.getMaxIntrinsicWidth(50), 326);
  });
  testWidgets('side pieces follow runtime pill height including zero', (
    tester,
  ) async {
    for (final height in [50.0, 80.0, 0.0]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 300,
              child: BarGroup(
                pillIndex: 1,
                spacing: 8,
                children: [
                  const SizedBox(key: Key('side'), width: 40),
                  SizedBox(key: const Key('main'), height: height),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('side'))).height, height);
      expect(tester.getSize(find.byKey(const Key('main'))).height, height);
      expect(tester.takeException(), isNull);
    }
  });
  for (final height in [100.0, 10.0, 0.0]) {
    testWidgets('raised surface has nonnegative side height at $height', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: height,
              child: BarGroup(
                pillIndex: 1,
                spacing: 8,
                children: [
                  const BarSurface(
                    key: Key('side'),
                    child: SizedBox(width: 40),
                  ),
                  BarSurface(
                    key: const Key('main'),
                    child: BottomBarCenterAction(
                      tooltip: 'Create',
                      icon: const Icon(Icons.add),
                      style: BottomBarCenterActionStyle.raised,
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
      final pill = tester.renderObject<RenderBarSurface>(
        find.byKey(const Key('main')),
      );
      expect(pill.barHeight, greaterThanOrEqualTo(0));
      expect(
        tester.getSize(find.byKey(const Key('side'))).height,
        pill.barHeight,
      );
      expect(
        group.getDryLayout(BoxConstraints.tightFor(width: 300, height: height)),
        group.size,
      );
    });
  }
  testWidgets('an empty group occupies only its minimum constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 300,
            child: BarGroup(pillIndex: 0, spacing: 8, children: []),
          ),
        ),
      ),
    );
    final group = tester.renderObject<RenderBarGroup>(find.byType(BarGroup));
    expect(group.size, const Size(300, 0));
    expect(group.getDryLayout(const BoxConstraints()), Size.zero);
    expect(group.getMinIntrinsicWidth(0), 0);
    expect(group.getMaxIntrinsicWidth(0), 0);
    expect(group.getMinIntrinsicHeight(0), 0);
    expect(group.getMaxIntrinsicHeight(0), 0);
  });
}
