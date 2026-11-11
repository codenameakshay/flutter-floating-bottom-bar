import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';

const _indicatorKey = Key('geometry-review-indicator');
const _iconKey = Key('geometry-review-icon');

class _ObservableIndicatorMotion extends IndicatorMotion {
  _ObservableIndicatorMotion({
    required super.vsync,
    required super.index,
    required super.motion,
  });

  bool get hasAttachedListeners => hasListeners;
}

Widget _builder(BuildContext context, Rect rect, bool settled) =>
    const ColoredBox(key: _indicatorKey, color: Colors.red);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Widget _bar({
  required Widget icon,
  BottomBarIndicator indicator = const BottomBarIndicator.builder(_builder),
  int selectedIndex = 0,
  double width = 300,
  bool transformItem = false,
}) => SizedBox(
  width: width,
  height: 64,
  child: BottomBarItems(
    selectedIndex: selectedIndex,
    indicator: indicator,
    children: [
      if (transformItem)
        Transform.scale(scale: 0.8, child: BottomBarItem(icon: icon))
      else
        BottomBarItem(icon: icon),
      const BottomBarItem(icon: Icon(Icons.search)),
      const BottomBarItem(icon: Icon(Icons.settings)),
    ],
  ),
);

void main() {
  for (final index in [-1, 4]) {
    testWidgets('invalid track index $index hides without reveal crash', (
      tester,
    ) async {
      final motion = IndicatorMotion(
        vsync: const TestVSync(),
        index: index,
        motion: const CupertinoMotion.snappy(),
      );
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 150,
            height: 64,
            child: IndicatorTrack(
              motion: motion,
              indicator: const BottomBarIndicator.builder(_builder),
              reveal: true,
              row: const Row(
                children: [
                  IndicatorAnchor(
                    role: IndicatorAnchorRole.slot,
                    child: SizedBox(width: 48, height: 48),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(_indicatorKey), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      motion.dispose();
    });
  }

  for (final indicator in [
    const BottomBarIndicator.pill(),
    const BottomBarIndicator.underline(),
    const BottomBarIndicator.dot(),
    const BottomBarIndicator.builder(_builder),
  ]) {
    testWidgets('${indicator.runtimeType} reveals selected narrow-row item', (
      tester,
    ) async {
      const icon = SizedBox(key: _iconKey, width: 24, height: 24);
      await tester.pumpWidget(
        _app(_bar(icon: icon, indicator: indicator, width: 80)),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _app(
          _bar(icon: icon, indicator: indicator, width: 80, selectedIndex: 2),
        ),
      );
      await tester.pumpAndSettle();
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      final selected = tester.getRect(find.byIcon(Icons.settings).first);
      expect(selected.left, greaterThanOrEqualTo(viewport.left));
      expect(selected.right, lessThanOrEqualTo(viewport.right));
    });
  }

  testWidgets('transformed item permits layout-time anchor transforms', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _bar(
          icon: const SizedBox(key: _iconKey, width: 24, height: 24),
          transformItem: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_iconKey)),
    );
  });

  testWidgets('builder tracks parent resize and type changes immediately', (
    tester,
  ) async {
    const icon = SizedBox(key: _iconKey, width: 24, height: 24);
    await tester.pumpWidget(_app(_bar(icon: icon)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(_bar(icon: icon, width: 210)));
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_iconKey)),
    );
    await tester.pumpWidget(
      _app(_bar(icon: icon, indicator: const BottomBarIndicator.pill())),
    );
    expect(find.byKey(_indicatorKey), findsNothing);
    await tester.pumpWidget(_app(_bar(icon: icon)));
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_iconKey)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('track swaps and detaches motion listeners', (tester) async {
    final first = _ObservableIndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: const CupertinoMotion.snappy(),
    );
    final second = _ObservableIndicatorMotion(
      vsync: const TestVSync(),
      index: 0,
      motion: const CupertinoMotion.snappy(),
    );
    Widget track(IndicatorMotion motion) => _app(
      SizedBox(
        width: 150,
        height: 64,
        child: IndicatorTrack(
          motion: motion,
          indicator: const BottomBarIndicator.builder(_builder),
          reveal: false,
          row: const Row(
            children: [
              IndicatorAnchor(
                role: IndicatorAnchorRole.slot,
                child: SizedBox(width: 48, height: 48),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(track(first));
    expect(first.hasAttachedListeners, isTrue);
    await tester.pumpWidget(track(second));
    expect(first.hasAttachedListeners, isFalse);
    expect(second.hasAttachedListeners, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(second.hasAttachedListeners, isFalse);
    first.jumpTo(0);
    second.jumpTo(0);
    await tester.pumpWidget(track(first));
    expect(first.hasAttachedListeners, isTrue);
    expect(tester.getSize(find.byKey(_indicatorKey)), const Size(48, 48));
    await tester.pumpWidget(const SizedBox.shrink());
    first.dispose();
    second.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('builder follows locally resized icon in the same frame', (
    tester,
  ) async {
    final iconSize = ValueNotifier<double>(24);
    addTearDown(iconSize.dispose);
    await tester.pumpWidget(
      _app(
        _bar(
          icon: ValueListenableBuilder<double>(
            valueListenable: iconSize,
            builder: (context, size, _) =>
                SizedBox(key: _iconKey, width: size, height: 24),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_iconKey)),
    );

    iconSize.value = 56;
    await tester.pump();
    final firstIndicator = tester.getRect(find.byKey(_indicatorKey));
    final firstIcon = tester.getRect(find.byKey(_iconKey));
    await tester.pump();
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      tester.getRect(find.byKey(_iconKey)),
      reason: 'The paint callback catches up only on the next frame.',
    );

    expect(
      firstIndicator,
      firstIcon,
      reason: 'The indicator must match the icon in the first resized frame.',
    );
  });

  testWidgets('underline follows locally resized icon in the same frame', (
    tester,
  ) async {
    final iconSize = ValueNotifier<double>(24);
    addTearDown(iconSize.dispose);
    await tester.pumpWidget(
      _app(
        _bar(
          indicator: const BottomBarIndicator.underline(),
          icon: ValueListenableBuilder<double>(
            valueListenable: iconSize,
            builder: (context, size, _) =>
                SizedBox(key: _iconKey, width: size, height: 24),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    iconSize.value = 56;
    await tester.pump();
    final content = tester.getRect(find.byKey(_iconKey).first);
    final origin = tester.getTopLeft(find.byType(BottomBarItems));
    expect(
      find.byType(BottomBarItems),
      paints..rrect(
        rrect: RRect.fromRectAndRadius(
          Rect.fromLTWH(
            content.center.dx - content.width / 2,
            content.bottom + 4,
            content.width,
            3,
          ).shift(-origin),
          const Radius.circular(1.5),
        ),
      ),
    );
  });
}
