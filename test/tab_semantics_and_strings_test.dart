import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';
import 'helpers/tooltip_finder.dart';

class _Test extends BottomBarLocalizations {
  const _Test();

  @override
  String get scrollToTop => 'T-top';

  @override
  String get scrollToBottom => 'T-bottom';

  @override
  String badgeCount(int count) => 'T-$count';

  @override
  String badgeCountOverflow(int max) => 'T-over-$max';

  @override
  String get badgeDot => 'T-dot';
}

final _delegates = <LocalizationsDelegate<dynamic>>[
  BottomBarLocalizationsDelegate((_) => const _Test()),
  DefaultMaterialLocalizations.delegate,
  DefaultWidgetsLocalizations.delegate,
];

List<BottomBarItem> _items({
  bool inboxSelected = false,
  VoidCallback? onTap,
  BottomBarBadge? inboxBadge,
}) => [
  BottomBarItem(
    icon: const Icon(Icons.home_outlined),
    selectedIcon: const Icon(Icons.home),
    label: const Text('Home'),
    onTap: onTap,
  ),
  BottomBarItem(
    icon: const Icon(Icons.inbox_outlined),
    selectedIcon: const Icon(Icons.inbox),
    label: const Text('Inbox'),
    badge: inboxBadge ?? BottomBarBadge.count(3),
    selected: inboxSelected,
    onTap: onTap,
  ),
  BottomBarItem(
    icon: const Icon(Icons.bookmark_border),
    selectedIcon: const Icon(Icons.bookmark),
    label: const Text('Saved'),
    onTap: onTap,
  ),
  BottomBarItem(
    icon: const Icon(Icons.person_outline),
    selectedIcon: const Icon(Icons.person),
    label: const Text('Profile'),
    onTap: onTap,
  ),
];

BottomBarItems _row({
  int? selectedIndex,
  ValueChanged<int>? onSelected,
  BottomBarIndicator? indicator,
  BottomBarLabelBehavior? labelBehavior,
  BottomBarCenterAction? centerAction,
  List<BottomBarItem>? items,
}) => BottomBarItems(
  selectedIndex: selectedIndex,
  onSelected: onSelected,
  indicator: indicator,
  labelBehavior: labelBehavior,
  centerAction: centerAction,
  children: items ?? _items(),
);

Widget _wrap(Widget child, {List<LocalizationsDelegate<dynamic>>? delegates}) =>
    MaterialApp(
      localizationsDelegates: delegates,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(width: 400, child: child),
        ),
      ),
    );

Widget _barApp(
  BottomBar bar, {
  List<LocalizationsDelegate<dynamic>>? delegates,
}) => MaterialApp(
  localizationsDelegates: delegates,
  home: Scaffold(body: bar),
);

BottomBar _bar({
  required Widget child,
  BottomBarController? controller,
  BottomBarScrollBehavior? scrollBehavior,
  String? iconSemanticLabel,
  String? iconTooltip,
}) => BottomBar(
  controller: controller,
  scrollBehavior: scrollBehavior ?? const BottomBarScrollBehavior(),
  iconSemanticLabel: iconSemanticLabel,
  iconTooltip: iconTooltip,
  body: const SizedBox.expand(),
  child: child,
);

List<String> _labels(WidgetTester tester) => semanticsLabels(tester).toList();

void main() {
  group('tab semantics', () {
    testWidgets('selected row reads position and selected state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(_row(selectedIndex: 1, onSelected: (_) {})),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), [
          'Home, Tab 1 of 4',
          'Inbox, 3 new, Tab 2 of 4',
          'Saved, Tab 3 of 4',
          'Profile, Tab 4 of 4',
        ]);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Inbox, 3 new, Tab 2 of 4'),
          ),
          isSemantics(
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
          ),
        );
        for (final label in [
          'Home, Tab 1 of 4',
          'Saved, Tab 3 of 4',
          'Profile, Tab 4 of 4',
        ]) {
          expect(
            tester.getSemantics(find.bySemanticsLabel(label)),
            isSemantics(
              isButton: true,
              hasSelectedState: true,
              isSelected: false,
              hasTapAction: true,
            ),
            reason: label,
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('items with their own selected flag read the same positions', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(_row(items: _items(inboxSelected: true, onTap: () {}))),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), [
          'Home, Tab 1 of 4',
          'Inbox, 3 new, Tab 2 of 4',
          'Saved, Tab 3 of 4',
          'Profile, Tab 4 of 4',
        ]);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Inbox, 3 new, Tab 2 of 4'),
          ),
          isSemantics(
            isButton: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Saved, Tab 3 of 4')),
          isSemantics(
            hasSelectedState: true,
            isSelected: false,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    for (final (name, indicator, behavior) in [
      ('pill indicator', const BottomBarIndicator.pill(), null),
      ('tint indicator', const BottomBarIndicator.tint(), null),
      (
        'pill indicator with onlySelected labels',
        const BottomBarIndicator.pill(),
        BottomBarLabelBehavior.onlySelected,
      ),
      (
        'pill indicator with hidden labels',
        const BottomBarIndicator.pill(),
        BottomBarLabelBehavior.alwaysHide,
      ),
    ]) {
      testWidgets('one node per item with $name', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _wrap(
              _row(
                selectedIndex: 1,
                onSelected: (_) {},
                indicator: indicator,
                labelBehavior: behavior,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(_labels(tester), [
            'Home, Tab 1 of 4',
            'Inbox, 3 new, Tab 2 of 4',
            'Saved, Tab 3 of 4',
            'Profile, Tab 4 of 4',
          ]);
          expect(_labels(tester), isNot(contains('Home')));
          expect(_labels(tester), isNot(contains('Inbox')));
        } finally {
          semantics.dispose();
        }
      });
    }

    testWidgets('centre action is not counted as a tab', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 1,
              onSelected: (_) {},
              centerAction: BottomBarCenterAction(
                icon: const Icon(Icons.add),
                tooltip: 'Compose',
                onPressed: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), [
          'Home, Tab 1 of 4',
          'Inbox, 3 new, Tab 2 of 4',
          'Compose',
          'Saved, Tab 3 of 4',
          'Profile, Tab 4 of 4',
        ]);
        expect(_labels(tester).where((l) => l.contains('Tab')), hasLength(4));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('rail items carry the same positions and selected flag', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      addTearDown(tester.view.reset);
      try {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(1200, 800);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BottomBarAdaptive(
                items: _row(selectedIndex: 1, onSelected: (_) {}),
                body: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), [
          'Home, Tab 1 of 4',
          'Inbox, 3 new, Tab 2 of 4',
          'Saved, Tab 3 of 4',
          'Profile, Tab 4 of 4',
        ]);
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Inbox, 3 new, Tab 2 of 4'),
          ),
          isSemantics(isButton: true, hasSelectedState: true, isSelected: true),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Home, Tab 1 of 4')),
          isSemantics(hasSelectedState: true, isSelected: false),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('selecting a tab moves the selected flag without announcing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final messages = <Object?>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            messages.add(message);
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      try {
        var index = 1;
        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => _wrap(
              _row(
                selectedIndex: index,
                onSelected: (i) => setState(() => index = i),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        messages.clear();

        await tester.tap(find.text('Saved'));
        await tester.pumpAndSettle();

        expect(index, 2);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Saved, Tab 3 of 4')),
          isSemantics(hasSelectedState: true, isSelected: true),
        );
        expect(
          tester.getSemantics(
            find.bySemanticsLabel('Inbox, 3 new, Tab 2 of 4'),
          ),
          isSemantics(hasSelectedState: true, isSelected: false),
        );
        expect(
          messages.whereType<Map>().where((m) => m['type'] == 'announce'),
          isEmpty,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a custom rich label is one node with its position', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 0,
              onSelected: (_) {},
              items: [
                const BottomBarItem(
                  icon: Icon(Icons.home),
                  label: Text.rich(TextSpan(text: 'Rich')),
                ),
                const BottomBarItem(
                  icon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final rich = _labels(tester).where((l) => l.contains('Rich')).toList();
        expect(rich, hasLength(1));
        expect(rich.single, contains('Tab 1 of 2'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('semanticLabel wins over the visible label', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 0,
              onSelected: (_) {},
              items: [
                const BottomBarItem(
                  icon: Icon(Icons.mail),
                  label: Text('Inbox'),
                  semanticLabel: 'Mail',
                ),
                const BottomBarItem(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), ['Mail, Tab 1 of 2', 'Home, Tab 2 of 2']);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('strings', () {
    testWidgets('hidden action reads Scroll to top by default', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(_bar(controller: controller, child: _row(selectedIndex: 1))),
        );
        await tester.pumpAndSettle();
        controller.hide();
        await tester.pumpAndSettle();

        expect(findByTooltip('Scroll to top'), findsOneWidget);
        expect(_labels(tester), contains('Scroll to top'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('hidden action reads Scroll to bottom with scrollOpposite', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(
            _bar(
              controller: controller,
              scrollBehavior: const BottomBarScrollBehavior(
                scrollOpposite: true,
              ),
              child: _row(selectedIndex: 1),
            ),
          ),
        );
        await tester.pumpAndSettle();
        controller.hide();
        await tester.pumpAndSettle();

        expect(findByTooltip('Scroll to bottom'), findsOneWidget);
        expect(_labels(tester), contains('Scroll to bottom'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a dot badge announces New', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 1,
              onSelected: (_) {},
              items: _items(inboxBadge: BottomBarBadge.dot()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), contains('Inbox, New, Tab 2 of 4'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a count above max announces More than 99 new', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 1,
              onSelected: (_) {},
              items: _items(inboxBadge: BottomBarBadge.count(150)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _labels(tester),
          contains('Inbox, More than 99 new, Tab 2 of 4'),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('the minimized pill keeps the English Expand hint', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(_bar(controller: controller, child: _row(selectedIndex: 1))),
        );
        await tester.pumpAndSettle();
        controller.minimize();
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.byType(CompactPillButton)),
          isSemantics(
            label: 'Inbox, 3 new',
            hint: 'Expand',
            isButton: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a translated count badge joins the item name', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(selectedIndex: 1, onSelected: (_) {}),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), contains('Inbox, T-3, Tab 2 of 4'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('translated overflow and dot strings join the item name', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 1,
              onSelected: (_) {},
              items: _items(inboxBadge: BottomBarBadge.count(150)),
            ),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();
        expect(_labels(tester), contains('Inbox, T-over-99, Tab 2 of 4'));

        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 1,
              onSelected: (_) {},
              items: _items(inboxBadge: BottomBarBadge.dot()),
            ),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();
        expect(_labels(tester), contains('Inbox, T-dot, Tab 2 of 4'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('translated hidden action label and tooltip', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(
            _bar(controller: controller, child: _row(selectedIndex: 1)),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();
        controller.hide();
        await tester.pumpAndSettle();

        expect(findByTooltip('T-top'), findsOneWidget);
        expect(_labels(tester), contains('T-top'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('translated scrollOpposite label', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(
            _bar(
              controller: controller,
              scrollBehavior: const BottomBarScrollBehavior(
                scrollOpposite: true,
              ),
              child: _row(selectedIndex: 1),
            ),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();
        controller.hide();
        await tester.pumpAndSettle();

        expect(findByTooltip('T-bottom'), findsOneWidget);
        expect(_labels(tester), contains('T-bottom'));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('translated count keeps the English pill hint', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(
            _bar(controller: controller, child: _row(selectedIndex: 1)),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();
        controller.minimize();
        await tester.pumpAndSettle();

        expect(
          tester.getSemantics(find.byType(CompactPillButton)),
          isSemantics(
            label: 'Inbox, T-3',
            hint: 'Expand',
            isButton: true,
            hasTapAction: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('per-widget icon label and tooltip win over the delegate', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      try {
        await tester.pumpWidget(
          _barApp(
            _bar(
              controller: controller,
              iconSemanticLabel: 'Up',
              iconTooltip: 'Up tip',
              child: _row(selectedIndex: 1),
            ),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();
        controller.hide();
        await tester.pumpAndSettle();

        expect(findByTooltip('Up tip'), findsOneWidget);
        expect(_labels(tester), contains('Up'));
        expect(_labels(tester), isNot(contains('T-top')));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('per-badge semanticLabel wins over the delegate', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _wrap(
            _row(
              selectedIndex: 0,
              onSelected: (_) {},
              items: _items(
                inboxBadge: BottomBarBadge.count(3, semanticLabel: 'three'),
              ),
            ),
            delegates: _delegates,
          ),
        );
        await tester.pumpAndSettle();

        expect(_labels(tester), contains('Inbox, three, Tab 2 of 4'));
      } finally {
        semantics.dispose();
      }
    });

    test('every member of BottomBarLocalizations is overridable', () {
      const strings = _Test();

      expect(strings.scrollToTop, 'T-top');
      expect(strings.scrollToBottom, 'T-bottom');
      expect(strings.badgeCount(3), 'T-3');
      expect(strings.badgeCountOverflow(99), 'T-over-99');
      expect(strings.badgeDot, 'T-dot');
    });
  });
}
