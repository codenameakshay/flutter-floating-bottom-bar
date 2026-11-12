import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  BottomBarItem item, {
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  BottomBarLabelBehavior labels = BottomBarLabelBehavior.alwaysShow,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          child: BottomBarItems(
            labelBehavior: labels,
            indicator: const BottomBarIndicator.none(),
            children: [item],
          ),
        ),
      ),
    ),
  ),
);

Finder _pill() => find.descendant(
  of: find.byType(BottomBarBadge),
  matching: find.byType(Container),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('raw badge keeps legacy corner placement in $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const BottomBarItem(
            icon: SizedBox(key: ValueKey('icon'), width: 24, height: 24),
            label: Text('Inbox'),
            badge: SizedBox(key: ValueKey('raw'), width: 19, height: 11),
          ),
          direction: direction,
        ),
      );
      final icon = tester.getRect(find.byKey(const ValueKey('icon')));
      final badge = tester.getRect(find.byKey(const ValueKey('raw')));
      expect(badge.top, icon.top - 4);
      expect(
        direction == TextDirection.ltr ? badge.right : badge.left,
        direction == TextDirection.ltr ? icon.right + 4 : icon.left - 4,
      );
    });

    for (final dot in [false, true]) {
      testWidgets('appearance fixes the ${dot ? 'dot' : 'text'} badge anchor '
          'to the icon corner in $direction', (tester) async {
        Future<void> pumpBadge(bool show) => tester.pumpWidget(
          _app(
            BottomBarItem(
              icon: const SizedBox(
                key: ValueKey('icon'),
                width: 40,
                height: 40,
              ),
              badge: dot
                  ? BottomBarBadge.dot(show: show)
                  : BottomBarBadge.label('New', show: show),
            ),
            direction: direction,
            textScale: 3,
          ),
        );
        await pumpBadge(false);
        await pumpBadge(true);
        await tester.pump(const Duration(milliseconds: 40));
        final transform = tester.widget<Transform>(
          find.descendant(
            of: find.byType(BottomBarBadge),
            matching: find.byWidgetPredicate(
              (widget) => widget is Transform && widget.origin != null,
            ),
          ),
        );
        expect(transform.transform.entry(0, 0), inExclusiveRange(0, 1));
        final box = tester.renderObject<RenderBox>(_pill());
        final anchor = Offset(
          direction == TextDirection.ltr
              ? (dot ? box.size.width : 12)
              : (dot ? 0 : box.size.width - 12),
          dot ? 0 : box.size.height / 2 - 4,
        );
        final icon = tester.getRect(find.byKey(const ValueKey('icon')));
        final corner = direction == TextDirection.ltr
            ? icon.topRight
            : icon.topLeft;
        expect((box.localToGlobal(anchor) - corner).distance, lessThan(0.001));
      });
    }

    testWidgets('large text badge keeps its M3 anchor in $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const BottomBarItem(
            icon: SizedBox(key: ValueKey('icon'), width: 40, height: 40),
            badge: BottomBarBadge.label('New', offset: Offset(7, 3)),
          ),
          direction: direction,
          textScale: 3,
        ),
      );
      await tester.pumpAndSettle();
      final icon = tester.getRect(find.byKey(const ValueKey('icon')));
      final badge = tester.getRect(_pill());
      expect(badge.height, greaterThan(16));
      expect(badge.center.dy, icon.top + 4 + 3);
      expect(
        direction == TextDirection.ltr ? badge.left : badge.right,
        direction == TextDirection.ltr
            ? icon.right - 12 + 7
            : icon.left + 12 - 7,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final labels in BottomBarLabelBehavior.values) {
    testWidgets('badge retains item name and semantic tap with $labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        var taps = 0;
        await tester.pumpWidget(
          _app(
            BottomBarItem(
              icon: const Icon(Icons.inbox, semanticLabel: 'Decorative icon'),
              label: const Text('Mail', semanticsLabel: 'Inbox'),
              badge: const BottomBarBadge.count(4, semanticLabel: '4 unread'),
              onTap: () => taps++,
            ),
            labels: labels,
          ),
        );
        final node = tester.getSemantics(find.byType(BottomBarItem));
        final data = node.getSemanticsData();
        expect(data.label, 'Inbox, 4 unread');
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        expect(taps, 1);
        await tester.tap(find.byType(BottomBarItem));
        expect(taps, 2);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('explicit name wins over tooltip and disabled item has no tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(
          const BottomBarItem(
            icon: Icon(Icons.inbox, semanticLabel: 'Icon'),
            label: Text('Visible mail'),
            semanticLabel: 'Inbox',
            tooltip: 'Open mail',
            badge: BottomBarBadge.count(3),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(BottomBarItem))
          .getSemanticsData();
      expect(data.label, 'Inbox, 3');
      expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      await tester.pumpWidget(
        _app(
          BottomBarItem(
            icon: const Icon(Icons.inbox),
            tooltip: 'Open mail',
            badge: const BottomBarBadge.count(3),
            onTap: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(BottomBarItem)).label,
        'Open mail, 3',
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('badge name changes preserve unkeyed icon state and active tap', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      Future<void> pumpBadge(
        Widget? badge, {
        BottomBarLabelBehavior labels = BottomBarLabelBehavior.alwaysShow,
      }) => tester.pumpWidget(
        _app(
          BottomBarItem(
            icon: _StatefulIcon(),
            label: const Text('Inbox'),
            badge: badge,
            onTap: () => taps++,
          ),
          labels: labels,
        ),
      );

      await pumpBadge(const BottomBarBadge.count(0));
      final mounted = tester.state(find.byType(_StatefulIcon));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(BottomBarItem)),
      );
      await pumpBadge(const BottomBarBadge.count(3));
      expect(tester.state(find.byType(_StatefulIcon)), same(mounted));
      expect(tester.getSemantics(find.byType(BottomBarItem)).label, 'Inbox, 3');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(taps, 1);

      await pumpBadge(const BottomBarBadge.count(0));
      await tester.pump(const Duration(milliseconds: 30));
      expect(tester.state(find.byType(_StatefulIcon)), same(mounted));
      expect(tester.getSemantics(find.byType(BottomBarItem)).label, 'Inbox');
      await pumpBadge(null);
      expect(tester.state(find.byType(_StatefulIcon)), same(mounted));
      await pumpBadge(null, labels: BottomBarLabelBehavior.alwaysHide);
      expect(tester.state(find.byType(_StatefulIcon)), same(mounted));
      expect(tester.getSemantics(find.byType(BottomBarItem)).label, 'Inbox');
      await pumpBadge(null);
      expect(tester.state(find.byType(_StatefulIcon)), same(mounted));
    } finally {
      semantics.dispose();
    }
  });
}

class _StatefulIcon extends StatefulWidget {
  @override
  State<_StatefulIcon> createState() => _StatefulIconState();
}

class _StatefulIconState extends State<_StatefulIcon> {
  @override
  Widget build(BuildContext context) => const Icon(Icons.inbox);
}
