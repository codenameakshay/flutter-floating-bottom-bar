import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _icon = ValueKey('icon');

Widget _badgeApp(
  Widget badge, {
  TextDirection dir = TextDirection.ltr,
  List<ThemeExtension<dynamic>> extensions = const [],
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, extensions: extensions),
    home: Directionality(
      textDirection: dir,
      child: Scaffold(
        body: Center(
          child: BottomBarItem(
            icon: const Icon(Icons.inbox, key: _icon),
            label: const Text('Inbox'),
            badge: badge,
          ),
        ),
      ),
    ),
  );
}

Finder _pill() => find.descendant(
  of: find.byType(BottomBarBadge),
  matching: find.byType(Container),
);

Rect _iconRect(WidgetTester tester) => tester.getRect(find.byKey(_icon));

ShapeDecoration _decoration(WidgetTester tester, Finder pill) =>
    tester.widget<Container>(pill).decoration! as ShapeDecoration;

Widget _barApp({
  required Widget child,
  BottomBarThemeData? theme,
  List<ThemeExtension<dynamic>> extensions = const [],
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true, extensions: extensions),
    home: Scaffold(
      body: BottomBar(
        theme: theme,
        body: const SizedBox(),
        child: SizedBox(height: 40, child: child),
      ),
    ),
  );
}

String? _semanticsLabel(WidgetTester tester) =>
    tester.getSemantics(find.byType(BottomBarItem)).label;

void main() {
  group('display', () {
    testWidgets('count above max shows max+', (tester) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.count(150)));
      expect(find.text('99+'), findsOneWidget);

      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.count(12, max: 9)),
      );
      await tester.pumpAndSettle();
      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('count 0 renders no pill, showZero renders 0', (tester) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.count(0)));
      await tester.pumpAndSettle();
      expect(_pill(), findsNothing);

      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.count(0, showZero: true)),
      );
      await tester.pumpAndSettle();
      expect(_pill(), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('label shows its text, empty or hidden renders no pill', (
      tester,
    ) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.label('New')));
      await tester.pumpAndSettle();
      expect(find.text('New'), findsOneWidget);

      await tester.pumpWidget(_badgeApp(const BottomBarBadge.label('')));
      await tester.pumpAndSettle();
      expect(_pill(), findsNothing);

      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.label('New', show: false)),
      );
      await tester.pumpAndSettle();
      expect(_pill(), findsNothing);
    });

    testWidgets('dot is a 6 by 6 pill with no text, show false hides it', (
      tester,
    ) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.dot()));
      await tester.pumpAndSettle();
      expect(tester.getSize(_pill()), const Size.square(6));
      expect(
        find.descendant(
          of: find.byType(BottomBarBadge),
          matching: find.byType(Text),
        ),
        findsNothing,
      );

      await tester.pumpWidget(_badgeApp(const BottomBarBadge.dot(show: false)));
      await tester.pumpAndSettle();
      expect(_pill(), findsNothing);
    });
  });

  group('placement', () {
    testWidgets('LTR count sits on the top-end corner', (tester) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.count(3)));
      await tester.pumpAndSettle();

      final iconRect = _iconRect(tester);
      expect(
        tester.getTopLeft(_pill()),
        Offset(iconRect.right - 12, iconRect.top - 4),
      );
      expect(tester.getSize(_pill()).height, 16);
    });

    testWidgets('LTR dot sits inside the top-end corner', (tester) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.dot()));
      await tester.pumpAndSettle();

      final iconRect = _iconRect(tester);
      expect(
        tester.getRect(_pill()),
        Rect.fromLTWH(iconRect.right - 6, iconRect.top, 6, 6),
      );
    });

    testWidgets('RTL count sits on the top-start corner', (tester) async {
      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.count(3), dir: TextDirection.rtl),
      );
      await tester.pumpAndSettle();

      final iconRect = _iconRect(tester);
      final pill = tester.getRect(_pill());
      expect(pill.right, iconRect.left + 12);
      expect(pill.top, iconRect.top - 4);
    });

    testWidgets('RTL dot sits inside the top-start corner', (tester) async {
      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.dot(), dir: TextDirection.rtl),
      );
      await tester.pumpAndSettle();

      final iconRect = _iconRect(tester);
      expect(
        tester.getRect(_pill()),
        Rect.fromLTWH(iconRect.left, iconRect.top, 6, 6),
      );
    });

    testWidgets('offset moves a dot by its vector, mirrored in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.dot()));
      await tester.pumpAndSettle();
      final base = tester.getTopLeft(_pill());

      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.dot(offset: Offset(2, 3))),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_pill()) - base, const Offset(2, 3));

      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.dot(), dir: TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      final rtlBase = tester.getTopLeft(_pill());

      await tester.pumpWidget(
        _badgeApp(
          const BottomBarBadge.dot(offset: Offset(2, 3)),
          dir: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(_pill()) - rtlBase, const Offset(-2, 3));
    });

    testWidgets('raw widget badge keeps the 4 pixel corner placement', (
      tester,
    ) async {
      await tester.pumpWidget(
        _badgeApp(const SizedBox(key: ValueKey('raw'), width: 10, height: 10)),
      );
      await tester.pumpAndSettle();

      final iconRect = _iconRect(tester);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('raw'))),
        Offset(iconRect.right + 4 - 10, iconRect.top - 4),
      );
    });

    for (final clip in Clip.values) {
      for (final scale in [1.0, 3.0]) {
        for (final height in [24.0, 40.0]) {
          testWidgets(
            'pills are not clipped by the bar with $clip at $height scale $scale',
            (tester) async {
              await tester.pumpWidget(
                MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: BottomBar(
                      layout: BottomBarLayout(clip: clip),
                      body: const SizedBox(),
                      child: SizedBox(
                        height: height,
                        child: BottomBarItems(
                          children: [
                            BottomBarItem(
                              icon: const Icon(Icons.inbox),
                              badge: const BottomBarBadge.count(150),
                            ),
                            BottomBarItem(
                              icon: const Icon(Icons.mail),
                              badge: const BottomBarBadge.dot(),
                            ),
                            BottomBarItem(icon: const Icon(Icons.send)),
                            BottomBarItem(
                              icon: const Icon(Icons.star),
                              badge: const BottomBarBadge.count(150),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();

              final pills = _pill();
              expect(pills, findsNWidgets(3));
              for (var i = 0; i < 3; i++) {
                final pill = pills.at(i);
                final pillRect = tester.getRect(pill);
                var node = tester.renderObject<RenderObject>(pill).parent;
                while (node != null) {
                  final clips =
                      node is RenderClipRect ||
                      node is RenderClipRRect ||
                      node is RenderClipPath ||
                      node is RenderViewportBase ||
                      (node is RenderStack && node.clipBehavior != Clip.none);
                  if (clips) {
                    final box = node as RenderBox;
                    final clipRect = MatrixUtils.transformRect(
                      box.getTransformTo(null),
                      Offset.zero & box.size,
                    );
                    expect(
                      pillRect.left,
                      greaterThanOrEqualTo(clipRect.left - 0.01),
                    );
                    expect(
                      pillRect.top,
                      greaterThanOrEqualTo(clipRect.top - 0.01),
                    );
                    expect(
                      pillRect.right,
                      lessThanOrEqualTo(clipRect.right + 0.01),
                    );
                    expect(
                      pillRect.bottom,
                      lessThanOrEqualTo(clipRect.bottom + 0.01),
                    );
                  }
                  node = node.parent;
                }
              }
            },
          );
        }
      }
    }
  });

  group('theme', () {
    testWidgets('item theme sets dot size and colour, bar theme merges, '
        'and the badge argument wins', (tester) async {
      const extension = BottomBarThemeData(
        items: BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(
            backgroundColor: Colors.red,
            dotSize: 10,
          ),
        ),
      );
      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.dot(), extensions: const [extension]),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(_pill()), const Size.square(10));
      expect(_decoration(tester, _pill()).color, isSameColorAs(Colors.red));

      await tester.pumpWidget(
        _barApp(
          extensions: const [extension],
          theme: const BottomBarThemeData(
            items: BottomBarItemThemeData(
              badge: BottomBarBadgeThemeData(backgroundColor: Colors.green),
            ),
          ),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: const Icon(Icons.inbox),
                badge: const BottomBarBadge.dot(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(_pill()), const Size.square(10));
      expect(_decoration(tester, _pill()).color, isSameColorAs(Colors.green));

      await tester.pumpWidget(
        _barApp(
          extensions: const [extension],
          theme: const BottomBarThemeData(
            items: BottomBarItemThemeData(
              badge: BottomBarBadgeThemeData(backgroundColor: Colors.green),
            ),
          ),
          child: BottomBarItems(
            children: [
              BottomBarItem(
                icon: const Icon(Icons.inbox),
                badge: const BottomBarBadge.dot(color: Colors.blue),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(_pill()), const Size.square(10));
      expect(_decoration(tester, _pill()).color, isSameColorAs(Colors.blue));
    });

    testWidgets('textColor sets the count colour, per-badge textStyle wins', (
      tester,
    ) async {
      const extension = BottomBarThemeData(
        items: BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(textColor: Colors.yellow),
        ),
      );
      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.count(3), extensions: const [extension]),
      );
      await tester.pumpAndSettle();
      final text = find.descendant(
        of: find.byType(BottomBarBadge),
        matching: find.byType(Text),
      );
      expect(
        tester.widget<Text>(text).style!.color,
        isSameColorAs(Colors.yellow),
      );

      await tester.pumpWidget(
        _badgeApp(
          const BottomBarBadge.count(
            3,
            textStyle: TextStyle(color: Colors.purple),
          ),
          extensions: const [extension],
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(text).style!.color,
        isSameColorAs(Colors.purple),
      );
    });

    testWidgets('outline width and colour come from the theme, per-badge wins, '
        'default has no outline', (tester) async {
      const extension = BottomBarThemeData(
        items: BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(
            outlineWidth: 2,
            outlineColor: Colors.black,
          ),
        ),
      );
      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.dot(), extensions: const [extension]),
      );
      await tester.pumpAndSettle();
      var side = (_decoration(tester, _pill()).shape as StadiumBorder).side;
      expect(side.width, 2);
      expect(side.color, isSameColorAs(Colors.black));

      await tester.pumpWidget(
        _badgeApp(
          const BottomBarBadge.dot(
            outline: BorderSide(color: Colors.white, width: 3),
          ),
          extensions: const [extension],
        ),
      );
      await tester.pumpAndSettle();
      side = (_decoration(tester, _pill()).shape as StadiumBorder).side;
      expect(side.width, 3);
      expect(side.color, isSameColorAs(Colors.white));

      await tester.pumpWidget(_badgeApp(const BottomBarBadge.dot()));
      await tester.pumpAndSettle();
      side = (_decoration(tester, _pill()).shape as StadiumBorder).side;
      expect(side.style, BorderStyle.none);
    });

    test('BottomBarBadgeThemeData merge keeps non-null fields of other', () {
      const base = BottomBarBadgeThemeData(
        backgroundColor: Colors.red,
        dotSize: 6,
        offset: Offset(1, 1),
      );
      const other = BottomBarBadgeThemeData(dotSize: 10, height: 20);
      final merged = base.merge(other);

      expect(merged.backgroundColor, isSameColorAs(Colors.red));
      expect(merged.dotSize, 10);
      expect(merged.height, 20);
      expect(merged.offset, const Offset(1, 1));
      expect(base.merge(null), same(base));
    });

    test('BottomBarBadgeThemeData copyWith replaces only given fields', () {
      const original = BottomBarBadgeThemeData(
        backgroundColor: Colors.red,
        dotSize: 6,
        outlineWidth: 1,
      );
      final copy = original.copyWith(dotSize: 8, height: 18);

      expect(copy.dotSize, 8);
      expect(copy.height, 18);
      expect(copy.backgroundColor, isSameColorAs(Colors.red));
      expect(copy.outlineWidth, 1);
    });

    test('BottomBarBadgeThemeData lerp interpolates at 0.5', () {
      const a = BottomBarBadgeThemeData(
        backgroundColor: Color(0xFF000000),
        dotSize: 6,
        height: 16,
        offset: Offset.zero,
        outlineWidth: 0,
      );
      const b = BottomBarBadgeThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        dotSize: 10,
        height: 24,
        offset: Offset(4, 8),
        outlineWidth: 2,
      );
      final mid = BottomBarBadgeThemeData.lerp(a, b, 0.5)!;

      expect(mid.backgroundColor, isSameColorAs(const Color(0xFF808080)));
      expect(mid.dotSize, 8);
      expect(mid.height, 20);
      expect(mid.offset, const Offset(2, 4));
      expect(mid.outlineWidth, 1);
    });

    test('BottomBarBadgeThemeData lerp of two nulls is null', () {
      expect(BottomBarBadgeThemeData.lerp(null, null, 0.5), isNull);
    });

    test('BottomBarBadgeThemeData equality follows its fields', () {
      const same = BottomBarBadgeThemeData(dotSize: 6, height: 16);
      const equal = BottomBarBadgeThemeData(dotSize: 6, height: 16);
      const differs = BottomBarBadgeThemeData(dotSize: 6, height: 17);

      expect(same, equal);
      expect(same.hashCode, equal.hashCode);
      expect(same, isNot(differs));
    });

    test('BottomBarItemThemeData merges, copies and lerps its badge', () {
      const a = BottomBarItemThemeData(
        badge: BottomBarBadgeThemeData(dotSize: 8),
      );
      const b = BottomBarItemThemeData(
        badge: BottomBarBadgeThemeData(height: 20),
      );
      final merged = a.merge(b).badge!;
      expect(merged.dotSize, 8);
      expect(merged.height, 20);

      final copy = const BottomBarItemThemeData(
        color: Colors.red,
      ).copyWith(badge: const BottomBarBadgeThemeData(dotSize: 8));
      expect(copy.badge!.dotSize, 8);
      expect(copy.color, isSameColorAs(Colors.red));

      const low = BottomBarItemThemeData(
        badge: BottomBarBadgeThemeData(dotSize: 6),
      );
      const high = BottomBarItemThemeData(
        badge: BottomBarBadgeThemeData(dotSize: 10),
      );
      expect(BottomBarItemThemeData.lerp(low, high, 0.5)!.badge!.dotSize, 8);

      expect(
        const BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(dotSize: 6),
        ),
        const BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(dotSize: 6),
        ),
      );
      expect(
        const BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(dotSize: 6),
        ).hashCode,
        const BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(dotSize: 6),
        ).hashCode,
      );
      expect(
        const BottomBarItemThemeData(
          badge: BottomBarBadgeThemeData(dotSize: 6),
        ),
        isNot(
          const BottomBarItemThemeData(
            badge: BottomBarBadgeThemeData(dotSize: 7),
          ),
        ),
      );
    });
  });

  group('semantics', () {
    testWidgets('icon-only item joins its accessible icon name and keeps tap', (
      tester,
    ) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottomBarItem(
                icon: const Icon(Icons.inbox, semanticLabel: 'Inbox'),
                badge: const BottomBarBadge.count(3),
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(BottomBarItem));
      expect(node.label, 'Inbox, 3');
      node.owner!.performAction(node.id, SemanticsAction.tap);
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('custom keyed label is mounted once during selection motion', (
      tester,
    ) async {
      final key = GlobalKey();
      Widget app(int selectedIndex) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: BottomBarItems(
              selectedIndex: selectedIndex,
              labelBehavior: BottomBarLabelBehavior.onlySelected,
              children: [
                BottomBarItem(
                  icon: const Icon(Icons.inbox),
                  label: Semantics(
                    key: key,
                    label: 'Inbox',
                    child: const SizedBox(width: 30, height: 10),
                  ),
                  badge: const BottomBarBadge.count(3),
                ),
                BottomBarItem(icon: const Icon(Icons.send)),
              ],
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(1));
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.takeException(), isNull);
      expect(find.byKey(key), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets(
      'custom badge naming keeps icon state across hide and removal',
      (tester) async {
        Widget app(Widget? badge) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottomBarItem(
                icon: const _StatefulIcon(),
                label: Semantics(
                  label: 'Inbox',
                  child: const SizedBox(width: 30, height: 10),
                ),
                badge: badge,
                onTap: () {},
              ),
            ),
          ),
        );
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(app(const BottomBarBadge.count(3)));
        final state = tester.state(find.byType(_StatefulIcon));
        for (final badge in [
          const BottomBarBadge.count(0),
          const BottomBarBadge.count(5),
          null,
        ]) {
          await tester.pumpWidget(app(badge));
          expect(tester.state(find.byType(_StatefulIcon)), same(state));
        }
        expect(_semanticsLabel(tester), 'Inbox');
        semantics.dispose();
      },
    );

    for (final behavior in BottomBarLabelBehavior.values) {
      testWidgets('custom label joins badge name with $behavior', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BottomBarItems(
                  labelBehavior: behavior,
                  children: [
                    BottomBarItem(
                      icon: const Icon(
                        Icons.inbox,
                        semanticLabel: 'Decorative icon',
                      ),
                      label: Semantics(
                        label: 'Inbox',
                        child: SizedBox(width: 30, height: 10),
                      ),
                      badge: const BottomBarBadge.count(
                        3,
                        semanticLabel: '3 new',
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_semanticsLabel(tester), 'Inbox, 3 new');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BottomBarItems(
                  labelBehavior: behavior,
                  children: [
                    BottomBarItem(
                      icon: const Icon(
                        Icons.inbox,
                        semanticLabel: 'Decorative icon',
                      ),
                      label: Semantics(
                        label: 'Inbox',
                        child: const SizedBox(width: 30, height: 10),
                      ),
                      badge: const BottomBarBadge.count(0),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(_semanticsLabel(tester), 'Inbox');
        semantics.dispose();
      });
    }

    testWidgets('count is announced after the item name', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.count(3, semanticLabel: '3 new')),
      );
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, 3 new');
      semantics.dispose();
    });

    testWidgets('semanticLabel on the item names it, badge is appended', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottomBarItem(
                icon: const Icon(Icons.inbox),
                semanticLabel: 'Inbox',
                label: const Text('Mail'),
                badge: const BottomBarBadge.count(3, semanticLabel: '3 new'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, 3 new');
      semantics.dispose();
    });

    testWidgets('tooltip names the item when there is no label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottomBarItem(
                icon: const Icon(Icons.inbox),
                tooltip: 'Inbox',
                badge: const BottomBarBadge.count(3, semanticLabel: '3 new'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, 3 new');
      semantics.dispose();
    });

    testWidgets('default count text is announced when no semanticLabel', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.count(150)));
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, 99+');
      semantics.dispose();
    });

    testWidgets('dot is silent unless it has a semanticLabel', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.dot()));
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox');

      await tester.pumpWidget(
        _badgeApp(const BottomBarBadge.dot(semanticLabel: 'new')),
      );
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, new');
      semantics.dispose();
    });

    testWidgets('hidden badge is silent, including during its out animation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_badgeApp(const BottomBarBadge.count(3)));
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, 3');

      await tester.pumpWidget(_badgeApp(const BottomBarBadge.count(0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(_semanticsLabel(tester), 'Inbox');
      semantics.dispose();
    });

    testWidgets('badge is announced when the item label is hidden', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottomBarItems(
                labelBehavior: BottomBarLabelBehavior.alwaysHide,
                children: [
                  BottomBarItem(
                    icon: const Icon(Icons.inbox),
                    label: const Text('Inbox'),
                    badge: const BottomBarBadge.count(
                      3,
                      semanticLabel: '3 new',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_semanticsLabel(tester), 'Inbox, 3 new');
      semantics.dispose();
    });
  });
}

class _StatefulIcon extends StatefulWidget {
  const _StatefulIcon();

  @override
  State<_StatefulIcon> createState() => _StatefulIconState();
}

class _StatefulIconState extends State<_StatefulIcon> {
  @override
  Widget build(BuildContext context) => const Icon(Icons.inbox);
}
