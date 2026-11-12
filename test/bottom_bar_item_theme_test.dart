import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(
  Widget body, {
  List<ThemeExtension<dynamic>> extensions = const [],
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, extensions: extensions),
    home: Scaffold(body: body),
  );
}

Widget _barWith({required Widget child, BottomBarThemeData? theme}) {
  return BottomBar(theme: theme, body: const SizedBox(), child: child);
}

/// The colour of the last icon in the item keyed [key]. A pill, tint or
/// underline item paints the plain copy first and the selected copy last.
Color? _lastIconColor(WidgetTester tester, Key key) {
  final icons = find.descendant(
    of: find.byKey(key),
    matching: find.byType(Icon),
  );
  return IconTheme.of(tester.element(icons.last)).color;
}

Color? _homeIconColor(WidgetTester tester) {
  return IconTheme.of(tester.element(find.byIcon(Icons.home))).color;
}

void main() {
  group('BottomBarItemThemeData', () {
    group('copyWith', () {
      test('replaces only the given fields', () {
        const original = BottomBarItemThemeData(
          color: Colors.red,
          iconSize: 20,
          pressedScale: 0.9,
          iconLabelGap: 2,
        );
        final copy = original.copyWith(
          color: Colors.blue,
          iconSize: 30,
          iconLabelGap: 6,
        );

        expect(copy.color, isSameColorAs(Colors.blue));
        expect(copy.iconSize, 30);
        expect(copy.iconLabelGap, 6);
        expect(copy.pressedScale, original.pressedScale);
        expect(copy.selectedColor, original.selectedColor);
        expect(copy.padding, original.padding);
      });
    });

    group('merge', () {
      test('non-null fields of other win, null fields keep this', () {
        const base = BottomBarItemThemeData(
          color: Colors.red,
          iconSize: 20,
          pressedScale: 0.9,
        );
        const override = BottomBarItemThemeData(
          color: Colors.blue,
          iconSize: null,
        );
        final merged = base.merge(override);

        expect(merged.color, isSameColorAs(Colors.blue));
        expect(merged.iconSize, 20);
        expect(merged.pressedScale, 0.9);
      });

      test('merge(null) returns the identical instance', () {
        const base = BottomBarItemThemeData(color: Colors.red);
        expect(identical(base.merge(null), base), isTrue);
      });
    });

    group('equality', () {
      BottomBarItemThemeData build({double pressedScale = 0.9}) {
        return BottomBarItemThemeData(
          labelStyle: const TextStyle(fontSize: 12),
          color: Colors.red,
          padding: const EdgeInsets.all(4),
          pressedScale: pressedScale,
          splashFactory: NoSplash.splashFactory,
          motion: const CupertinoMotion.smooth(),
        );
      }

      test('equal fields give equal instances with equal hash codes', () {
        final a = build();
        final b = build();

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('changing one field makes the instances unequal', () {
        expect(build(), isNot(build(pressedScale: 0.8)));
      });
    });

    group('static lerp', () {
      test('interpolates colour, sizes, scale, padding, weight and gap', () {
        const a = BottomBarItemThemeData(
          color: Colors.black,
          iconSize: 20,
          pressedScale: 1,
          padding: EdgeInsets.all(0),
          labelStyle: TextStyle(fontWeight: FontWeight.w400),
          iconLabelGap: 2,
        );
        const b = BottomBarItemThemeData(
          color: Colors.white,
          iconSize: 30,
          pressedScale: 0.8,
          padding: EdgeInsets.all(10),
          labelStyle: TextStyle(fontWeight: FontWeight.w800),
          iconLabelGap: 6,
        );
        final mid = BottomBarItemThemeData.lerp(a, b, 0.5)!;

        expect(mid.color, Color.lerp(Colors.black, Colors.white, 0.5));
        expect(mid.iconSize, 25);
        expect(mid.pressedScale, closeTo(0.9, 1e-9));
        expect(mid.padding, const EdgeInsets.all(5));
        expect(mid.labelStyle?.fontWeight, FontWeight.w600);
        expect(mid.iconLabelGap, 4);
      });

      test('steps splashFactory, motion and indicator at t == 0.5', () {
        final a = BottomBarItemThemeData(
          splashFactory: NoSplash.splashFactory,
          motion: const CupertinoMotion.smooth(),
          indicator: const BottomBarIndicator.pill(),
        );
        final b = BottomBarItemThemeData(
          splashFactory: InkRipple.splashFactory,
          motion: const CupertinoMotion.snappy(),
          indicator: const BottomBarIndicator.tint(),
        );

        final early = BottomBarItemThemeData.lerp(a, b, 0.4)!;
        expect(early.splashFactory, NoSplash.splashFactory);
        expect(early.motion, const CupertinoMotion.smooth());
        expect(early.indicator, const BottomBarIndicator.pill());

        final late = BottomBarItemThemeData.lerp(a, b, 0.6)!;
        expect(late.splashFactory, InkRipple.splashFactory);
        expect(late.motion, const CupertinoMotion.snappy());
        expect(late.indicator, const BottomBarIndicator.tint());
      });

      test('lerp(null, null, t) is null', () {
        expect(BottomBarItemThemeData.lerp(null, null, 0.5), isNull);
      });
    });
  });

  group('BottomBarThemeData.items', () {
    test('merge deep-merges items field by field', () {
      const base = BottomBarThemeData(
        items: BottomBarItemThemeData(color: Colors.red, pressedScale: 0.9),
      );
      const override = BottomBarThemeData(
        items: BottomBarItemThemeData(color: Colors.blue),
      );
      final merged = base.merge(override);

      expect(merged.items?.color, isSameColorAs(Colors.blue));
      expect(merged.items?.pressedScale, 0.9);
    });

    test('copyWith(items: ...) sets items', () {
      const items = BottomBarItemThemeData(iconSize: 26);
      final copy = const BottomBarThemeData().copyWith(items: items);

      expect(copy.items, items);
    });

    test('lerp lerps items and does not step them', () {
      const a = BottomBarThemeData(items: BottomBarItemThemeData(iconSize: 20));
      const b = BottomBarThemeData(items: BottomBarItemThemeData(iconSize: 30));
      final mid = a.lerp(b, 0.5);

      expect(mid.items?.iconSize, 25);
    });
  });

  group('unselected colour precedence', () {
    testWidgets('no theme anywhere uses colorScheme.onSurfaceVariant', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _barWith(
            child: const BottomBarItems(
              children: [BottomBarItem(icon: Icon(Icons.home))],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scheme = Theme.of(
        tester.element(find.byIcon(Icons.home)),
      ).colorScheme;
      expect(_homeIconColor(tester), scheme.onSurfaceVariant);
    });

    testWidgets('ThemeData extension colour applies', (tester) async {
      await tester.pumpWidget(
        _app(
          _barWith(
            child: const BottomBarItems(
              children: [BottomBarItem(icon: Icon(Icons.home))],
            ),
          ),
          extensions: const [
            BottomBarThemeData(
              items: BottomBarItemThemeData(color: Colors.red),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_homeIconColor(tester), isSameColorAs(Colors.red));
    });

    testWidgets('BottomBar theme beats the extension colour', (tester) async {
      await tester.pumpWidget(
        _app(
          _barWith(
            theme: const BottomBarThemeData(
              items: BottomBarItemThemeData(color: Colors.green),
            ),
            child: const BottomBarItems(
              children: [BottomBarItem(icon: Icon(Icons.home))],
            ),
          ),
          extensions: const [
            BottomBarThemeData(
              items: BottomBarItemThemeData(color: Colors.red),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_homeIconColor(tester), isSameColorAs(Colors.green));
    });

    testWidgets('BottomBarItem colour beats the BottomBar theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _barWith(
            theme: const BottomBarThemeData(
              items: BottomBarItemThemeData(color: Colors.green),
            ),
            child: const BottomBarItems(
              children: [
                BottomBarItem(icon: Icon(Icons.home), color: Colors.blue),
              ],
            ),
          ),
          extensions: const [
            BottomBarThemeData(
              items: BottomBarItemThemeData(color: Colors.red),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_homeIconColor(tester), isSameColorAs(Colors.blue));
    });

    testWidgets(
      'selected colour: indicator foreground beats theme, item selectedColor beats indicator',
      (tester) async {
        await tester.pumpWidget(
          _app(
            _barWith(
              child: BottomBarItems(
                selectedIndex: 0,
                indicator: const BottomBarIndicator.pill(
                  foregroundColor: Colors.orange,
                ),
                children: const [
                  BottomBarItem(key: ValueKey('plain'), icon: Icon(Icons.home)),
                  BottomBarItem(
                    key: ValueKey('purple'),
                    icon: Icon(Icons.search),
                    selectedColor: Colors.purple,
                  ),
                ],
              ),
            ),
            extensions: const [
              BottomBarThemeData(
                items: BottomBarItemThemeData(selectedColor: Colors.green),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _lastIconColor(tester, const ValueKey('plain')),
          isSameColorAs(Colors.orange),
        );
        expect(
          _lastIconColor(tester, const ValueKey('purple')),
          isSameColorAs(Colors.purple),
        );
      },
    );

    testWidgets('item outside a BottomBar reads the extension colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Center(child: BottomBarItem(icon: Icon(Icons.home))),
          extensions: const [
            BottomBarThemeData(
              items: BottomBarItemThemeData(color: Colors.red),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(_homeIconColor(tester), isSameColorAs(Colors.red));
    });

    testWidgets(
      'item inside a BottomBar with theme colour reads it, not the extension',
      (tester) async {
        await tester.pumpWidget(
          _app(
            _barWith(
              theme: const BottomBarThemeData(
                items: BottomBarItemThemeData(color: Colors.green),
              ),
              child: const BottomBarItems(
                children: [BottomBarItem(icon: Icon(Icons.home))],
              ),
            ),
            extensions: const [
              BottomBarThemeData(
                items: BottomBarItemThemeData(color: Colors.red),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(_homeIconColor(tester), isSameColorAs(Colors.green));
      },
    );
  });

  group('indicator from theme', () {
    testWidgets('extension pill indicator paints an rrect', (tester) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            height: 64,
            child: BottomBarItems(
              selectedIndex: 0,
              children: const [
                BottomBarItem(icon: Icon(Icons.home)),
                BottomBarItem(icon: Icon(Icons.search)),
                BottomBarItem(icon: Icon(Icons.inbox)),
              ],
            ),
          ),
          extensions: [
            BottomBarThemeData(
              items: BottomBarItemThemeData(
                indicator: const BottomBarIndicator.pill(),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomBarItems), paints..rrect());
    });

    testWidgets('BottomBarIndicator.none argument paints no rrect', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            height: 64,
            child: BottomBarItems(
              selectedIndex: 0,
              indicator: const BottomBarIndicator.none(),
              children: const [
                BottomBarItem(icon: Icon(Icons.home)),
                BottomBarItem(icon: Icon(Icons.search)),
                BottomBarItem(icon: Icon(Icons.inbox)),
              ],
            ),
          ),
          extensions: [
            BottomBarThemeData(
              items: BottomBarItemThemeData(
                indicator: const BottomBarIndicator.pill(),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomBarItems), isNot(paints..rrect()));
    });
  });

  group('theme fields reach InkWell', () {
    testWidgets('padding, ink radius and splash factory are applied', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const BottomBarItem(icon: Icon(Icons.home)),
          extensions: [
            BottomBarThemeData(
              items: BottomBarItemThemeData(
                padding: const EdgeInsets.all(12),
                inkBorderRadius: BorderRadius.circular(20),
                splashFactory: NoSplash.splashFactory,
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final ink = tester.widget<InkWell>(find.byType(InkWell));
      expect(ink.borderRadius, BorderRadius.circular(20));
      expect(ink.splashFactory, NoSplash.splashFactory);

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(InkWell),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, const EdgeInsets.all(12));
    });
  });

  group('null theme keeps today\'s look', () {
    testWidgets('ink radius is 8 and label uses labelSmall font size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          _barWith(
            child: const BottomBarItems(
              children: [
                BottomBarItem(
                  key: ValueKey('home'),
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ink = tester.widget<InkWell>(
        find.descendant(
          of: find.byKey(const ValueKey('home')),
          matching: find.byType(InkWell),
        ),
      );
      expect(ink.borderRadius, BorderRadius.circular(8));

      final labelSmall = Theme.of(
        tester.element(find.byType(BottomBarItems)),
      ).textTheme.labelSmall;
      expect(
        DefaultTextStyle.of(tester.element(find.text('Home'))).style.fontSize,
        labelSmall?.fontSize,
      );
    });
  });
}
