import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BottomBarLayout', () {
    test('default values match the documented defaults', () {
      const layout = BottomBarLayout();
      expect(layout.width, 300);
      expect(layout.offset, 10);
      expect(layout.borderRadius, BorderRadius.zero);
      expect(layout.alignment, Alignment.bottomCenter);
      expect(layout.fit, StackFit.loose);
      expect(layout.clip, Clip.hardEdge);
      expect(layout.respectSafeArea, true);
    });

    test('copyWith preserves untouched fields', () {
      const layout = BottomBarLayout();
      final updated = layout.copyWith(width: 200);
      expect(updated.width, 200);
      expect(updated.offset, 10);
      expect(updated.respectSafeArea, true);
    });

    test('equality and hashCode are value-based', () {
      const a = BottomBarLayout(width: 250);
      const b = BottomBarLayout(width: 250);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
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
}
