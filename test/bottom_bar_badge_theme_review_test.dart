import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('item-theme badge merge, copy, interpolation and value semantics', () {
    const low = BottomBarItemThemeData(
      color: Colors.black,
      badge: BottomBarBadgeThemeData(
        backgroundColor: Colors.red,
        textColor: Colors.white,
        dotSize: 5,
        textStyle: TextStyle(fontSize: 12, letterSpacing: 1),
      ),
    );
    const high = BottomBarItemThemeData(
      selectedColor: Colors.blue,
      badge: BottomBarBadgeThemeData(
        backgroundColor: Colors.green,
        height: 20,
        textStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );

    final merged = low.merge(high);
    expect(merged.color, Colors.black);
    expect(merged.selectedColor, Colors.blue);
    expect(
      merged.badge,
      const BottomBarBadgeThemeData(
        backgroundColor: Colors.green,
        textColor: Colors.white,
        dotSize: 5,
        height: 20,
        textStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );

    final copied = low.copyWith(badge: low.badge!.copyWith(outlineWidth: 2));
    expect(copied.badge!.outlineWidth, 2);
    expect(copied.badge!.backgroundColor, Colors.red);
    expect(copied, copied.copyWith());
    expect(copied.hashCode, copied.copyWith().hashCode);
    expect(copied, isNot(low));

    final halfway = BottomBarItemThemeData.lerp(low, high, 0.5)!;
    expect(
      halfway.badge!.backgroundColor,
      Color.lerp(Colors.red, Colors.green, 0.5),
    );
    expect(halfway.badge!.dotSize, 2.5);
    expect(halfway.badge!.height, 10);
    expect(BottomBarItemThemeData.lerp(low, low, 0.5), same(low));
  });

  testWidgets('per-badge, bar, extension and defaults resolve in order', (
    tester,
  ) async {
    Widget app({BottomBarThemeData? barTheme, BottomBarBadge? badge}) =>
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              BottomBarThemeData(
                items: BottomBarItemThemeData(
                  badge: BottomBarBadgeThemeData(
                    backgroundColor: Colors.red,
                    textStyle: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          home: Scaffold(
            body: BottomBar(
              theme: barTheme,
              body: const SizedBox(),
              child: SizedBox(
                height: 48,
                child: BottomBarItem(
                  icon: const Icon(Icons.inbox),
                  badge: badge ?? const BottomBarBadge.label('New'),
                ),
              ),
            ),
          ),
        );
    final pill = find.descendant(
      of: find.byType(BottomBarBadge),
      matching: find.byType(Container),
    );
    final text = find.text('New');
    Color pillColor() =>
        (tester.widget<Container>(pill).decoration! as ShapeDecoration).color!;
    TextStyle badgeStyle() => tester.widget<Text>(text).style!;

    await tester.pumpWidget(
      app(
        barTheme: const BottomBarThemeData(
          items: BottomBarItemThemeData(
            badge: BottomBarBadgeThemeData(
              backgroundColor: Colors.blue,
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        badge: const BottomBarBadge.label(
          'New',
          backgroundColor: Colors.green,
          textStyle: TextStyle(letterSpacing: 2),
        ),
      ),
    );
    expect(pillColor(), Colors.green);
    expect(badgeStyle().fontSize, 11);
    expect(badgeStyle().fontWeight, FontWeight.bold);
    expect(badgeStyle().letterSpacing, 2);

    await tester.pumpWidget(
      app(
        barTheme: const BottomBarThemeData(
          items: BottomBarItemThemeData(
            badge: BottomBarBadgeThemeData(
              backgroundColor: Colors.blue,
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
    expect(pillColor(), Colors.blue);
    expect(badgeStyle().fontSize, 11);
    expect(badgeStyle().fontWeight, FontWeight.bold);

    await tester.pumpWidget(app());
    expect(pillColor(), Colors.red);

    await tester.pumpWidget(
      MaterialApp(home: const Scaffold(body: BottomBarBadge.label('New'))),
    );
    expect(pillColor(), Colors.red);
    expect(tester.takeException(), isNull);
  });
}
