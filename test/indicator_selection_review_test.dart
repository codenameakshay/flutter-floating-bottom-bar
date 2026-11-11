import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

const _indicatorKey = Key('review-indicator');

Widget _builder(BuildContext context, Rect rect, bool settled) =>
    const ColoredBox(key: _indicatorKey, color: Colors.red);

const _indicator = BottomBarIndicator.builder(_builder);

const _children = <Widget>[
  BottomBarItem(key: Key('home'), icon: Icon(Icons.home), label: Text('Home')),
  BottomBarItem(
    key: Key('search'),
    icon: Icon(Icons.search),
    label: Text('Search'),
  ),
  BottomBarItem(
    key: Key('inbox'),
    icon: Icon(Icons.inbox),
    label: Text('Inbox'),
  ),
  BottomBarItem(
    key: Key('person'),
    icon: Icon(Icons.person),
    label: Text('Person'),
  ),
];

Widget _app({
  int? selectedIndex = 0,
  bool reducedMotion = false,
  double width = 400,
  BottomBarIndicator? indicator = _indicator,
  ValueChanged<int>? onSelected,
  List<Widget> children = _children,
  BottomBarLabelBehavior labels = BottomBarLabelBehavior.alwaysShow,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: width,
          height: 64,
          child: BottomBarItems(
            selectedIndex: selectedIndex,
            indicator: indicator,
            onSelected: onSelected,
            labelBehavior: labels,
            children: children,
          ),
        ),
      ),
    ),
  ),
);

Rect _content(WidgetTester tester, String key, String label) => tester
    .getRect(
      find
          .descendant(of: find.byKey(Key(key)), matching: find.byType(Icon))
          .first,
    )
    .expandToInclude(tester.getRect(find.text(label).first));

/// The pill's slot-based rect inset by its default 2px, at item [key].
Rect _pillTarget(WidgetTester tester, String key) =>
    const EdgeInsets.all(2).deflateRect(tester.getRect(find.byKey(Key(key))));

Rect _paintedPill(WidgetTester tester) {
  late Rect rect;
  expect(
    find.byType(BottomBarItems),
    paints..something((method, arguments) {
      if (method != #drawRRect) return false;
      rect = (arguments.first as RRect).outerRect;
      return true;
    }),
  );
  return rect;
}

class _Counter extends StatefulWidget {
  const _Counter(this.label, {super.key});
  final String label;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => count++),
    child: SizedBox(
      width: 48,
      height: 48,
      child: Text('${widget.label} $count'),
    ),
  );
}

void main() {
  testWidgets('review callback replacement reaches reused const item', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(_app(onSelected: (_) => calls.add('old')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(onSelected: (_) => calls.add('new')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search')));
    expect(calls, ['new']);
  });

  testWidgets('review enabling reduced motion snaps active indicator', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(selectedIndex: 3));
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      isNot(_content(tester, 'person', 'Person')),
    );
    await tester.pumpWidget(_app(selectedIndex: 3, reducedMotion: true));
    expect(
      tester.getRect(find.byKey(_indicatorKey)),
      _content(tester, 'person', 'Person'),
    );
  });

  testWidgets('review pill reveals newly selected icon-only item', (
    tester,
  ) async {
    const pill = BottomBarIndicator.pill();
    await tester.pumpWidget(
      _app(
        width: 100,
        indicator: pill,
        labels: BottomBarLabelBehavior.alwaysHide,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(
        width: 100,
        selectedIndex: 3,
        indicator: pill,
        labels: BottomBarLabelBehavior.alwaysHide,
      ),
    );
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final item = tester.getRect(find.byKey(const Key('person')));
    expect(item.left, greaterThanOrEqualTo(viewport.left));
    expect(item.right, lessThanOrEqualTo(viewport.right));
  });

  testWidgets(
    'review reduced motion selection jumps without scheduling frames',
    (tester) async {
      await tester.pumpWidget(_app(reducedMotion: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(selectedIndex: 3, reducedMotion: true));
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        _content(tester, 'person', 'Person'),
      );
      await tester.pump();
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        _content(tester, 'person', 'Person'),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets(
    'review selected null toggle disposes active ticker and resets selection',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(selectedIndex: 3));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(_app(selectedIndex: null));
      await tester.pumpAndSettle();
      expect(find.byKey(_indicatorKey), findsNothing);
      expect(find.byType(BottomBarItemSelectionScope), findsNothing);
      expect(tester.binding.transientCallbackCount, 0);
      await tester.pumpWidget(_app(selectedIndex: 1));
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        _content(tester, 'search', 'Search'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets('review selected semantics follow effective selection', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(selectedIndex: 1, onSelected: (_) {}));
    await tester.pumpAndSettle();
    for (final key in ['home', 'search', 'inbox', 'person']) {
      final node = tester.getSemantics(find.byKey(Key(key)));
      expect(
        node.getSemanticsData().flagsCollection.isSelected,
        key == 'search' ? ui.Tristate.isTrue : ui.Tristate.isFalse,
      );
    }
    handle.dispose();
  });

  testWidgets('review indicator cannot capture taps or contribute semantics', (
    tester,
  ) async {
    final calls = <String>[];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        onSelected: (_) => calls.add('item'),
        indicator: BottomBarIndicator.builder(
          (context, rect, settled) => GestureDetector(
            key: _indicatorKey,
            onTap: () => calls.add('indicator'),
            child: Semantics(
              label: 'decorative-indicator',
              child: const ColoredBox(color: Colors.red),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('decorative-indicator'), findsNothing);
    await tester.tapAt(tester.getCenter(find.byKey(_indicatorKey)));
    expect(calls, ['item']);
    handle.dispose();
  });

  testWidgets(
    'review item callback precedes selection and null own callback still selects',
    (tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          children: [
            BottomBarItem(
              key: const Key('first'),
              icon: const Icon(Icons.home),
              onTap: () => calls.add('own'),
            ),
            const BottomBarItem(key: Key('second'), icon: Icon(Icons.search)),
          ],
          onSelected: (index) => calls.add('select$index'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('first')));
      expect(calls, ['own', 'select0']);
      calls.clear();
      await tester.tap(find.byKey(const Key('second')));
      expect(calls, ['select1']);
    },
  );

  testWidgets(
    'review item insertion and removal jump to current valid selection',
    (tester) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _app(
          selectedIndex: 1,
          children: [
            const BottomBarItem(
              key: Key('settings'),
              icon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
            ..._children,
          ],
        ),
      );
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        _content(tester, 'home', 'Home'),
      );
      await tester.pumpWidget(
        _app(selectedIndex: 1, children: _children.sublist(0, 2)),
      );
      expect(
        tester.getRect(find.byKey(_indicatorKey)),
        _content(tester, 'search', 'Search'),
      );
    },
  );

  testWidgets('review empty children without selectedIndex remains valid', (
    tester,
  ) async {
    await tester.pumpWidget(_app(selectedIndex: null, children: const []));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets('review invalid selectedIndex asserts in debug', (tester) async {
    await tester.pumpWidget(_app(selectedIndex: -1));
    expect(tester.takeException(), isAssertionError);
  });

  for (final selection in <int?>[null, 0]) {
    testWidgets(
      'review keyed custom child retains state on narrow reorder selection=$selection',
      (tester) async {
        const a = _Counter('A', key: Key('counter-a'));
        const b = _Counter('B', key: Key('counter-b'));
        const c = _Counter('C', key: Key('counter-c'));
        await tester.pumpWidget(
          _app(width: 100, selectedIndex: selection, children: const [a, b, c]),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('counter-a')));
        await tester.pump();
        expect(find.text('A 1'), findsOneWidget);
        await tester.pumpWidget(
          _app(width: 100, selectedIndex: selection, children: const [b, a, c]),
        );
        await tester.pumpAndSettle();
        expect(find.text('A 1'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'review enabling stretch while changing selection uses trailing edge',
    (tester) async {
      await tester.pumpWidget(_app(indicator: const BottomBarIndicator.pill()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _app(
          selectedIndex: 3,
          indicator: const BottomBarIndicator.pill(stretch: true),
        ),
      );
      var widest = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final width = _paintedPill(tester).width;
        if (width > widest) widest = width;
      }
      final targetWidth = _pillTarget(tester, 'person').width;
      expect(widest, greaterThan(targetWidth + 40));
    },
  );

  testWidgets(
    'review disabling stretch while changing selection removes trailing edge',
    (tester) async {
      await tester.pumpWidget(
        _app(indicator: const BottomBarIndicator.pill(stretch: true)),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _app(selectedIndex: 3, indicator: const BottomBarIndicator.pill()),
      );
      var widest = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final width = _paintedPill(tester).width;
        if (width > widest) widest = width;
      }
      final targetWidth = _pillTarget(tester, 'person').width;
      expect(widest, lessThan(targetWidth + 5));
    },
  );
}
