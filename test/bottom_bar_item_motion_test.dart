import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_indicator.dart';
import 'package:flutter_test/flutter_test.dart';

const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);

const _tabs = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home, 'Home'),
  (Icons.search, Icons.saved_search, 'Search'),
  (Icons.inbox_outlined, Icons.inbox, 'Inbox'),
];

Widget _app(
  Widget child, {
  BottomBarItemThemeData items = const BottomBarItemThemeData(),
  bool reducedMotion = false,
}) => MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    extensions: [BottomBarThemeData(items: items)],
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: child!,
  ),
  home: Scaffold(body: Center(child: child)),
);

Widget _row({
  required int selectedIndex,
  BottomBarIndicator? indicator,
  BottomBarLabelBehavior labelBehavior = BottomBarLabelBehavior.alwaysShow,
  Motion? indicatorMotion,
}) => SizedBox(
  width: 360,
  height: 72,
  child: BottomBarItems(
    selectedIndex: selectedIndex,
    indicator: indicator,
    indicatorMotion: indicatorMotion,
    labelBehavior: labelBehavior,
    onSelected: (_) {},
    children: [
      for (final (i, tab) in _tabs.indexed)
        BottomBarItem(
          key: ValueKey(i),
          icon: Icon(tab.$1),
          selectedIcon: Icon(tab.$2),
          label: Text(tab.$3),
        ),
    ],
  ),
);

Widget _single({required bool selected}) => BottomBarItem(
  icon: const Icon(Icons.home_outlined),
  selectedIcon: const Icon(Icons.home),
  label: const Text('Home'),
  selected: selected,
  onTap: () {},
);

const _blackWhite = BottomBarItemThemeData(
  color: _black,
  selectedColor: _white,
  labelStyle: TextStyle(fontWeight: FontWeight.w400),
  selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
);

/// Progress of a black-to-white colour: 0 unselected, 1 selected.
double _progress(Color? color) => color!.r;

Color? _labelColor(WidgetTester tester, String label) =>
    DefaultTextStyle.of(tester.element(find.text(label).first)).style.color;

Color? _iconColor(WidgetTester tester, IconData icon) =>
    IconTheme.of(tester.element(find.byIcon(icon).first)).color;

Rect _paintedRect(WidgetTester tester) {
  late Rect rect;
  expect(
    find.byType(BottomBarItems),
    paints..something((method, arguments) {
      if (method != #drawRRect) return false;
      rect = (arguments.first as RRect).outerRect;
      return true;
    }),
  );
  return rect.shift(tester.getTopLeft(find.byType(BottomBarItems)));
}

Rect _anchorRect(WidgetTester tester, int item, IndicatorAnchorRole role) {
  final anchor = find.descendant(
    of: find.byKey(ValueKey(item)),
    matching: find.byWidgetPredicate(
      (widget) => widget is IndicatorAnchor && widget.role == role,
    ),
  );
  final box = tester.renderObject<RenderBox>(anchor);
  return box.localToGlobal(Offset.zero) & box.size;
}

double _scaleOf(WidgetTester tester, String label) {
  final transform = tester.widget<Transform>(
    find.ancestor(of: find.text(label), matching: find.byType(Transform)).first,
  );
  return transform.transform.storage[0];
}

void main() {
  group('non-reveal path', () {
    testWidgets('colour and label weight pass between their endpoints', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(_single(selected: false), items: _blackWhite),
      );
      expect(_labelColor(tester, 'Home'), _black);
      expect(
        DefaultTextStyle.of(tester.element(find.text('Home'))).style.fontWeight,
        FontWeight.w400,
      );

      await tester.pumpWidget(
        _app(_single(selected: true), items: _blackWhite),
      );
      await tester.pump(const Duration(milliseconds: 60));

      final mid = _progress(_labelColor(tester, 'Home'));
      expect(mid, greaterThan(0.05));
      expect(mid, lessThan(0.95));
      final weight = DefaultTextStyle.of(
        tester.element(find.text('Home')),
      ).style.fontWeight!.value;
      expect(weight, greaterThan(400));
      expect(weight, lessThan(800));

      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Home'), _white);
      expect(
        DefaultTextStyle.of(tester.element(find.text('Home'))).style.fontWeight,
        FontWeight.w800,
      );
    });

    testWidgets('icon cross-fades to selectedIcon', (tester) async {
      await tester.pumpWidget(
        _app(_single(selected: false), items: _blackWhite),
      );
      expect(find.byIcon(Icons.home), findsNothing);

      await tester.pumpWidget(
        _app(_single(selected: true), items: _blackWhite),
      );
      await tester.pump(const Duration(milliseconds: 60));
      double opacity(IconData icon) => tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byIcon(icon),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      final outgoing = opacity(Icons.home_outlined);
      final incoming = opacity(Icons.home);
      expect(incoming, greaterThan(0));
      expect(outgoing, greaterThan(0));
      expect(outgoing + incoming, closeTo(1, 1e-9));

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('icon size moves between iconSize and selectedIconSize', (
      tester,
    ) async {
      const items = BottomBarItemThemeData(iconSize: 20, selectedIconSize: 30);
      await tester.pumpWidget(_app(_single(selected: false), items: items));
      expect(tester.getSize(find.byIcon(Icons.home_outlined)).width, 20);

      await tester.pumpWidget(_app(_single(selected: true), items: items));
      await tester.pump(const Duration(milliseconds: 60));
      final size = IconTheme.of(tester.element(find.byIcon(Icons.home))).size!;
      expect(size, greaterThan(20));
      expect(size, lessThan(30));

      await tester.pumpAndSettle();
      expect(tester.getSize(find.byIcon(Icons.home)).width, 30);
    });

    testWidgets('fast retarget reverses from where the item is', (
      tester,
    ) async {
      Widget row(int index) => _app(
        _row(selectedIndex: index, indicator: const BottomBarIndicator.dot()),
        items: _blackWhite,
      );
      await tester.pumpWidget(row(0));
      await tester.pumpWidget(row(1));

      final samples = <double>[];
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(_progress(_labelColor(tester, 'Search')));
      }
      final peak = samples.last;
      expect(peak, greaterThan(0.05));
      expect(peak, lessThan(0.95));

      await tester.pumpWidget(row(2));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        samples.add(_progress(_labelColor(tester, 'Search')));
      }

      for (var i = 1; i < samples.length; i++) {
        expect(
          (samples[i] - samples[i - 1]).abs(),
          lessThan(0.2),
          reason: 'frame $i jumped from ${samples[i - 1]} to ${samples[i]}',
        );
      }
      expect(samples.last, lessThan(peak));
      await tester.pumpAndSettle();
      expect(_labelColor(tester, 'Search'), _black);
      expect(_labelColor(tester, 'Inbox'), _white);
    });
  });

  testWidgets('reveal path leaves item colour to the indicator', (
    tester,
  ) async {
    Widget row(int index) => _app(
      _row(selectedIndex: index, indicator: const BottomBarIndicator.pill()),
      items: _blackWhite,
    );
    await tester.pumpWidget(row(0));
    await tester.pumpWidget(row(1));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(_iconColor(tester, Icons.search), _black);
      expect(_labelColor(tester, 'Search'), _black);
    }
    await tester.pumpAndSettle();
    expect(_iconColor(tester, Icons.search), _black);
  });

  for (final reveal in [true, false]) {
    testWidgets('onlySelected label grows in and the indicator tracks it '
        '(${reveal ? 'underline' : 'dot'})', (tester) async {
      Widget row(int index) => _app(
        _row(
          selectedIndex: index,
          indicator: reveal
              ? const BottomBarIndicator.underline()
              : const BottomBarIndicator.dot(),
          labelBehavior: BottomBarLabelBehavior.onlySelected,
          indicatorMotion: const CupertinoMotion.snappy(
            duration: Duration(milliseconds: 100),
          ),
        ),
        items: const BottomBarItemThemeData(
          motion: CupertinoMotion.smooth(duration: Duration(seconds: 2)),
        ),
      );
      await tester.pumpWidget(row(0));
      expect(find.text('Inbox'), findsNothing);

      await tester.pumpWidget(row(2));
      await tester.pump(const Duration(milliseconds: 600));

      final widths = <double>[];
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final icon = _anchorRect(tester, 2, IndicatorAnchorRole.icon);
        final label = _anchorRect(tester, 2, IndicatorAnchorRole.label);
        final content = icon.expandToInclude(label);
        widths.add(label.width);
        final painted = _paintedRect(tester);
        if (reveal) {
          expect(painted.left, closeTo(content.left, 0.01));
          expect(painted.right, closeTo(content.right, 0.01));
          expect(painted.top, closeTo(content.bottom + 4, 0.01));
        } else {
          expect(painted.center.dx, closeTo(icon.center.dx, 0.01));
          expect(painted.top, closeTo(content.bottom + 4, 0.01));
        }
        final opacity = tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('Inbox').first,
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity;
        expect(opacity, greaterThan(0));
        expect(opacity, lessThan(1));
      }
      for (var i = 1; i < widths.length; i++) {
        expect(widths[i], greaterThan(widths[i - 1]));
      }

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      final label = _anchorRect(tester, 2, IndicatorAnchorRole.label);
      expect(label.width, tester.getSize(find.text('Inbox').first).width);
    });
  }

  testWidgets('pressedScale shrinks content, not the target or indicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _row(selectedIndex: 0, indicator: const BottomBarIndicator.underline()),
        items: const BottomBarItemThemeData(pressedScale: 0.8),
      ),
    );
    await tester.pumpAndSettle();
    final target = tester.getRect(
      find.descendant(
        of: find.byKey(const ValueKey(0)),
        matching: find.byType(InkWell),
      ),
    );
    final indicator = _paintedRect(tester);
    expect(_scaleOf(tester, 'Home'), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Home').first),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_scaleOf(tester, 'Home'), closeTo(0.8, 0.01));
    expect(
      tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey(0)),
          matching: find.byType(InkWell),
        ),
      ),
      target,
    );
    expect(_paintedRect(tester), indicator);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final releasing = _scaleOf(tester, 'Home');
    expect(releasing, greaterThan(0.8));
    expect(releasing, lessThan(1));
    expect(_paintedRect(tester), indicator);

    await tester.pumpAndSettle();
    expect(_scaleOf(tester, 'Home'), closeTo(1, 1e-6));
  });

  testWidgets('default theme adds no press transform', (tester) async {
    await tester.pumpWidget(_app(_single(selected: false)));
    expect(
      find.ancestor(of: find.text('Home'), matching: find.byType(Transform)),
      findsNothing,
    );
  });

  testWidgets('reduced motion snaps every item transition', (tester) async {
    final index = ValueNotifier(0);
    addTearDown(index.dispose);
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<int>(
          valueListenable: index,
          builder: (context, value, _) => _row(
            selectedIndex: value,
            indicator: const BottomBarIndicator.dot(),
            labelBehavior: BottomBarLabelBehavior.onlySelected,
          ),
        ),
        items: _blackWhite.copyWith(pressedScale: 0.8),
        reducedMotion: true,
      ),
    );
    index.value = 1;
    await tester.pump();
    expect(_labelColor(tester, 'Search'), _white);
    expect(_iconColor(tester, Icons.saved_search), _white);
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('Search'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.inbox_outlined)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    final icon = find.byIcon(Icons.inbox_outlined);
    final transform = tester.widget<Transform>(
      find.ancestor(of: icon, matching: find.byType(Transform)).first,
    );
    expect(transform.transform.storage[0], closeTo(0.8, 1e-6));
    await gesture.up();
    await tester.pump();
  });
}
