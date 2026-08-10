import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarLayout', () {
    test('default values match the documented defaults', () {
      const layout = BottomBarLayout();
      expect(layout.width, 300);
      expect(layout.maxWidth, null);
      expect(layout.offset, 10);
      expect(layout.borderRadius, BorderRadius.zero);
      expect(layout.iconOffset, Offset.zero);
      expect(layout.alignment, Alignment.bottomCenter);
      expect(layout.fit, StackFit.loose);
      expect(layout.clip, Clip.hardEdge);
      expect(layout.respectSafeArea, true);
    });

    test('adaptive constructor uses infinity width and preserves defaults', () {
      const layout = BottomBarLayout.adaptive(maxWidth: 360);

      expect(layout.width, double.infinity);
      expect(layout.maxWidth, 360);
      expect(layout.offset, 10);
      expect(layout.borderRadius, BorderRadius.zero);
      expect(layout.iconOffset, Offset.zero);
      expect(layout.alignment, Alignment.bottomCenter);
      expect(layout.fit, StackFit.loose);
      expect(layout.clip, Clip.hardEdge);
      expect(layout.respectSafeArea, true);
    });

    test('copyWith preserves untouched fields', () {
      const layout = BottomBarLayout();
      final updated = layout.copyWith(width: 200, maxWidth: 240);
      expect(updated.width, 200);
      expect(updated.maxWidth, 240);
      expect(updated.offset, 10);
      expect(updated.iconOffset, Offset.zero);
      expect(updated.respectSafeArea, true);
    });

    test('copyWith can explicitly clear maxWidth', () {
      const layout = BottomBarLayout(width: 280, maxWidth: 320, offset: 20);

      final updated = layout.copyWith(clearMaxWidth: true);

      expect(updated.width, 280);
      expect(updated.maxWidth, isNull);
      expect(updated.offset, 20);
    });

    test('equality and hashCode are value-based', () {
      const a = BottomBarLayout(width: 250, maxWidth: 320);
      const b = BottomBarLayout(width: 250, maxWidth: 320);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('negative, infinite, and NaN maxWidth values are rejected', () {
      expect(
        () => BottomBarLayout(maxWidth: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BottomBarLayout.adaptive(maxWidth: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BottomBarLayout(maxWidth: double.infinity),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BottomBarLayout.adaptive(maxWidth: double.infinity),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BottomBarLayout(maxWidth: double.nan),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BottomBarLayout.adaptive(maxWidth: double.nan),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  testWidgets('layout borderRadius shapes the visible default decoration',
      (tester) async {
    final radius = BorderRadius.circular(40);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          layout: BottomBarLayout(borderRadius: radius),
          body: const SizedBox.shrink(),
          child: const SizedBox(
            key: Key('bar-child'),
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
        ),
      ),
    ));

    final containers = find.ancestor(
      of: find.byKey(const Key('bar-child')),
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && widget.decoration is BoxDecoration,
      ),
    );
    final container = containers.evaluate().single.widget as Container;
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.borderRadius, radius);
  });

  testWidgets(
      'widget layout with explicit BorderRadius.zero overrides rounded decoration',
      (tester) async {
    const roundedDecoration = BorderRadius.all(Radius.circular(28));

    await _pumpBottomBar(
      tester,
      theme: const BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: roundedDecoration,
        ),
      ),
      layout: const BottomBarLayout(borderRadius: BorderRadius.zero),
    );

    expect(_barDecoration(tester).borderRadius, BorderRadius.zero);
    expect(_barMaterial(tester).borderRadius, BorderRadius.zero);
  });

  testWidgets(
      'theme layout with explicit BorderRadius.zero overrides rounded decoration',
      (tester) async {
    const roundedDecoration = BorderRadius.all(Radius.circular(28));

    await _pumpBottomBar(
      tester,
      theme: const BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: roundedDecoration,
        ),
        layout: BottomBarLayout(borderRadius: BorderRadius.zero),
      ),
    );

    expect(_barDecoration(tester).borderRadius, BorderRadius.zero);
    expect(_barMaterial(tester).borderRadius, BorderRadius.zero);
  });

  testWidgets('decoration radius remains when no layout override exists',
      (tester) async {
    const roundedDecoration = BorderRadius.all(Radius.circular(18));

    await _pumpBottomBar(
      tester,
      theme: const BottomBarThemeData(
        barDecoration: BoxDecoration(
          color: Colors.white,
          borderRadius: roundedDecoration,
        ),
      ),
    );

    expect(_barDecoration(tester).borderRadius, roundedDecoration);
  });

  testWidgets(
      'adaptive layout uses available width on narrow viewports after offset padding',
      (tester) async {
    await _pumpBottomBar(
      tester,
      viewport: const Size(320, 800),
      layout: const BottomBarLayout.adaptive(
        maxWidth: 420,
        offset: 20,
        respectSafeArea: false,
      ),
    );

    expect(_barSize(tester).width, 280);
  });

  testWidgets('adaptive layout caps width at maxWidth on wide viewports',
      (tester) async {
    await _pumpBottomBar(
      tester,
      viewport: const Size(800, 800),
      layout: const BottomBarLayout.adaptive(
        maxWidth: 360,
        offset: 20,
        respectSafeArea: false,
      ),
    );

    expect(_barSize(tester).width, 360);
  });

  testWidgets('regular layout width is capped by maxWidth', (tester) async {
    await _pumpBottomBar(
      tester,
      viewport: const Size(800, 800),
      layout: const BottomBarLayout(
        width: 520,
        maxWidth: 300,
        offset: 20,
        respectSafeArea: false,
      ),
    );

    expect(_barSize(tester).width, 300);
  });

  testWidgets('iconOffset translates only the back-to-top icon',
      (tester) async {
    const iconOffset = Offset(0, 10);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          layout: const BottomBarLayout(iconOffset: iconOffset),
          body: ListView.builder(
            itemBuilder: (context, index) => Text('Row $index'),
          ),
          child: const SizedBox(
            key: Key('bar-child'),
            height: 56,
            child: Text('Bottom Bar Child'),
          ),
        ),
      ),
    ));

    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final iconTransform = tester.widget<Transform>(
      find.ancestor(
        of: find.byTooltip('Scroll to top'),
        matching: find.byType(Transform),
      ),
    );

    expect(iconTransform.transform.getTranslation().y, iconOffset.dy);
  });
}

Future<void> _pumpBottomBar(
  WidgetTester tester, {
  BottomBarLayout? layout,
  BottomBarThemeData? theme,
  Size viewport = const Size(800, 600),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BottomBar(
          layout: layout,
          theme: theme,
          body: const SizedBox.expand(),
          child: const SizedBox(
            key: Key('bar-child'),
            height: 56,
            child: Center(child: Text('Bottom Bar Child')),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _barDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(_barContainerFinder());
  return container.decoration! as BoxDecoration;
}

Material _barMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.ancestor(
      of: find.byKey(const Key('bar-child')),
      matching: find.byWidgetPredicate(
        (widget) => widget is Material && widget.borderRadius != null,
      ),
    ),
  );
}

Size _barSize(WidgetTester tester) {
  return tester.getSize(_barContainerFinder());
}

Finder _barContainerFinder() {
  return find.ancestor(
    of: find.byKey(const Key('bar-child')),
    matching: find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    ),
  );
}
