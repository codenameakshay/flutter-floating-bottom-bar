import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _fullKey = Key('full');
const _pillKey = Key('pill');

Rect _globalSemanticsRect(SemanticsNode node) {
  var transform = Matrix4.identity();
  SemanticsNode? current = node;
  while (current?.parent != null) {
    transform = (current!.transform ?? Matrix4.identity()) * transform;
    current = current.parent;
  }
  return MatrixUtils.transformRect(transform, node.rect);
}

Widget _host(Animation<double> progress, {required bool minimized, Key? key}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: MinimizeHost(
          key: key,
          progress: progress,
          minimized: minimized,
          full: Semantics(
            key: _fullKey,
            container: true,
            label: 'Full bar',
            child: const SizedBox(width: 300, height: 64),
          ),
          compact: Semantics(
            key: _pillKey,
            container: true,
            label: 'Compact bar',
            child: const SizedBox.square(dimension: 48),
          ),
        ),
      ),
    );

void _expectSemanticsFollowsPaint(WidgetTester tester, Key key) {
  final finder = find.byKey(key);
  final box = tester.renderObject<RenderBox>(finder);
  final expected = MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
  final actual = _globalSemanticsRect(tester.getSemantics(finder));
  expect(actual.left, closeTo(expected.left, 0.001));
  expect(actual.top, closeTo(expected.top, 0.001));
  expect(actual.width, closeTo(expected.width, 0.001));
  expect(actual.height, closeTo(expected.height, 0.001));
}

void main() {
  testWidgets('custom pill updates its merged label while minimized', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final title = ValueNotifier('First track');
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ValueListenableBuilder(
            valueListenable: title,
            builder: (context, value, child) => CompactPillButton(
              onTap: () {},
              label: null,
              child: Text(value),
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .getSemantics(find.byType(CompactPillButton))
          .getSemanticsData()
          .label,
      'First track',
    );
    expect(
      tester.getSemantics(find.byType(CompactPillButton)),
      isSemantics(hasExpandedState: true, isExpanded: false),
    );
    title.value = 'Second track';
    await tester.pump();
    expect(
      tester
          .getSemantics(find.byType(CompactPillButton))
          .getSemanticsData()
          .label,
      'Second track',
    );
    expect(
      tester.getSemantics(find.byType(CompactPillButton)),
      isSemantics(hasExpandedState: true, isExpanded: false),
    );
    semantics.dispose();
    title.dispose();
  });
  testWidgets('partial morph detaches and reattaches without stale layers', (
    tester,
  ) async {
    final progress = AnimationController(vsync: tester, value: 0.4);
    addTearDown(progress.dispose);
    final key = GlobalKey();
    Widget tree(bool left) => Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: left
                ? _host(progress, minimized: false, key: key)
                : const SizedBox(),
          ),
          Expanded(
            child: left
                ? const SizedBox()
                : _host(progress, minimized: false, key: key),
          ),
        ],
      ),
    );
    await tester.pumpWidget(tree(true));
    final before = tester.renderObject<RenderMinimizeHost>(find.byKey(key));
    await tester.pumpWidget(tree(false));
    expect(tester.renderObject(find.byKey(key)), same(before));
    progress.value = 0.7;
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    progress.value = 1;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  for (final minimized in [false, true]) {
    testWidgets(
      '${minimized ? 'Pill' : 'Full bar'} semantics follows interrupted morph',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final progress = AnimationController(
          vsync: tester,
          value: minimized ? 1 : 0,
        );
        addTearDown(progress.dispose);
        await tester.pumpWidget(_host(progress, minimized: minimized));
        final key = minimized ? _pillKey : _fullKey;
        _expectSemanticsFollowsPaint(tester, key);
        progress.value = 0.4;
        await tester.pump();
        _expectSemanticsFollowsPaint(tester, key);
        progress.value = 0.7;
        await tester.pump();
        _expectSemanticsFollowsPaint(tester, key);
        progress.value = minimized ? 1 : 0;
        await tester.pump();
        _expectSemanticsFollowsPaint(tester, key);
        semantics.dispose();
      },
    );
  }
}
