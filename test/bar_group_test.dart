import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/tooltip_finder.dart';

int _pillInitCount = 0;

class _CountingPill extends StatefulWidget {
  const _CountingPill();

  @override
  State<_CountingPill> createState() => _CountingPillState();
}

class _CountingPillState extends State<_CountingPill> {
  @override
  void initState() {
    super.initState();
    _pillInitCount++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 200, height: 50);
}

List<BottomBarItem> _tabs(int count) {
  const tabs = <(IconData, String)>[
    (Icons.home, 'Home'),
    (Icons.inbox, 'Inbox'),
    (Icons.search, 'Search'),
    (Icons.person, 'Profile'),
  ];
  return [
    for (final tab in tabs.take(count))
      BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
  ];
}

Widget _pillRow({int count = 2, BottomBarCenterAction? centerAction}) {
  return BottomBarItems(
    key: const Key('pill-items'),
    selectedIndex: 0,
    onSelected: (_) {},
    centerAction: centerAction,
    children: _tabs(count),
  );
}

Rect _slotRect(WidgetTester tester, String slot) {
  return tester.getRect(find.byKey(ValueKey(slot)));
}

Iterable<String> _traversalTexts(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .expand((node) => [node.label, node.tooltip])
      .where((text) => text.isNotEmpty);
}

Key? _slotOf(FocusNode? node) {
  return node?.context?.findAncestorWidgetOfExactType<BarSurface>()?.key;
}

Future<void> pumpBar(
  WidgetTester tester, {
  double viewWidth = 400,
  TextDirection direction = TextDirection.ltr,
  bool withLeading = true,
  bool withTrailing = true,
  BottomBarLayout layout = const BottomBarLayout(width: 360),
  BottomBarMotion? motion,
  BottomBarController? controller,
  BottomBarThemeData? theme,
  bool showIcon = false,
  bool highContrast = false,
  Widget? body,
  Widget? child,
  VoidCallback? onLeadingPressed,
  VoidCallback? onTrailingPressed,
  FocusNode? leadingFocusNode,
  FocusNode? trailingFocusNode,
}) async {
  tester.view.physicalSize = Size(viewWidth, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: app!,
      ),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            layout: layout,
            motion: motion,
            controller: controller,
            theme: theme,
            showIcon: showIcon,
            body: body ?? const SizedBox.expand(),
            leading: withLeading
                ? IconButton(
                    key: const Key('leading-button'),
                    tooltip: 'Profile',
                    icon: const Icon(Icons.person),
                    focusNode: leadingFocusNode,
                    onPressed: onLeadingPressed ?? () {},
                  )
                : null,
            trailing: withTrailing
                ? IconButton(
                    key: const Key('trailing-button'),
                    tooltip: 'Search',
                    icon: const Icon(Icons.search),
                    focusNode: trailingFocusNode,
                    onPressed: onTrailingPressed ?? () {},
                  )
                : null,
            child: child ?? _pillRow(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('both slots sit either side of the pill in LTR', (tester) async {
    await pumpBar(tester);

    expect(_slotRect(tester, 'leading'), const Rect.fromLTRB(20, 240, 70, 290));
    expect(_slotRect(tester, 'pill'), const Rect.fromLTRB(78, 240, 322, 290));
    expect(
      _slotRect(tester, 'trailing'),
      const Rect.fromLTRB(330, 240, 380, 290),
    );
  });

  testWidgets('a single slot or no slot gives the pill the full row', (
    tester,
  ) async {
    await pumpBar(tester, withTrailing: false);
    expect(_slotRect(tester, 'pill'), const Rect.fromLTRB(78, 240, 380, 290));

    await pumpBar(tester, withLeading: false);
    expect(_slotRect(tester, 'pill'), const Rect.fromLTRB(20, 240, 322, 290));

    await pumpBar(tester, withLeading: false, withTrailing: false);
    expect(_slotRect(tester, 'pill'), const Rect.fromLTRB(20, 240, 380, 290));
  });

  testWidgets('maxWidth caps the row and centres it', (tester) async {
    await pumpBar(
      tester,
      layout: const BottomBarLayout(width: 1000, maxWidth: 300),
    );

    expect(
      _slotRect(tester, 'leading'),
      const Rect.fromLTRB(50, 240, 100, 290),
    );
    expect(
      _slotRect(tester, 'trailing'),
      const Rect.fromLTRB(300, 240, 350, 290),
    );

    await pumpBar(
      tester,
      layout: const BottomBarLayout.adaptive(maxWidth: 300),
    );

    expect(
      _slotRect(tester, 'leading'),
      const Rect.fromLTRB(50, 240, 100, 290),
    );
    expect(
      _slotRect(tester, 'trailing'),
      const Rect.fromLTRB(300, 240, 350, 290),
    );
  });

  testWidgets('both slots mirror in RTL', (tester) async {
    await pumpBar(tester, direction: TextDirection.rtl);

    expect(
      _slotRect(tester, 'leading'),
      const Rect.fromLTRB(330, 240, 380, 290),
    );
    expect(_slotRect(tester, 'pill'), const Rect.fromLTRB(78, 240, 322, 290));
    expect(
      _slotRect(tester, 'trailing'),
      const Rect.fromLTRB(20, 240, 70, 290),
    );
  });

  testWidgets('groupSpacing sets the gap between each slot and the pill', (
    tester,
  ) async {
    await pumpBar(
      tester,
      layout: const BottomBarLayout(width: 360, groupSpacing: 20),
    );

    final leading = _slotRect(tester, 'leading');
    final pill = _slotRect(tester, 'pill');
    final trailing = _slotRect(tester, 'trailing');
    expect(pill.left, leading.right + 20);
    expect(trailing.left, pill.right + 20);
  });

  testWidgets(
    'a row too narrow for the slots narrows the bar and scrolls the pill',
    (tester) async {
      await pumpBar(tester, viewWidth: 200, child: _pillRow(count: 4));

      expect(
        _slotRect(tester, 'leading'),
        const Rect.fromLTRB(10, 240, 60, 290),
      );
      expect(_slotRect(tester, 'pill'), const Rect.fromLTRB(68, 240, 132, 290));
      expect(
        _slotRect(tester, 'trailing'),
        const Rect.fromLTRB(140, 240, 190, 290),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pill')),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'taps in the gaps reach the body and taps on slots stay on the slots',
    (tester) async {
      var bodyTaps = 0;
      var leadingPresses = 0;
      await pumpBar(
        tester,
        onLeadingPressed: () => leadingPresses++,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => bodyTaps++,
          child: const SizedBox.expand(),
        ),
      );

      await tester.tapAt(const Offset(74, 265));
      await tester.pump();
      expect(bodyTaps, 1);
      expect(leadingPresses, 0);

      await tester.tapAt(const Offset(45, 265));
      await tester.pump();
      expect(leadingPresses, 1);
      expect(bodyTaps, 1);

      await tester.tapAt(const Offset(326, 265));
      await tester.pump();
      expect(bodyTaps, 2);
      expect(leadingPresses, 1);
    },
  );

  testWidgets('a hidden bar ignores taps, focus and semantics on its slots', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    final leadingFocus = FocusNode();
    final trailingFocus = FocusNode();
    addTearDown(leadingFocus.dispose);
    addTearDown(trailingFocus.dispose);
    final semantics = tester.ensureSemantics();
    var leadingPresses = 0;
    var trailingPresses = 0;

    await pumpBar(
      tester,
      controller: controller,
      motion: const BottomBarMotion(transition: BottomBarTransition.fade),
      leadingFocusNode: leadingFocus,
      trailingFocusNode: trailingFocus,
      onLeadingPressed: () => leadingPresses++,
      onTrailingPressed: () => trailingPresses++,
    );

    controller.hide();
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(45, 265));
    await tester.tapAt(const Offset(355, 265));
    await tester.pump();
    expect(leadingPresses, 0);
    expect(trailingPresses, 0);

    for (final node in [leadingFocus, trailingFocus]) {
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isFalse);
    }

    expect(_traversalTexts(tester), isNot(contains('Profile')));
    expect(_traversalTexts(tester), isNot(contains('Search')));

    controller.show();
    await tester.pumpAndSettle();
    expect(_traversalTexts(tester), containsAll(['Profile', 'Search']));
    await tester.tapAt(const Offset(45, 265));
    await tester.pump();
    expect(leadingPresses, 1);
    semantics.dispose();
  });

  testWidgets(
    'Tab moves through the leading button, the pill, then the trailing button',
    (tester) async {
      for (final direction in TextDirection.values) {
        await pumpBar(tester, direction: direction);

        final visited = <FocusNode?>[];
        for (var i = 0; i < 4; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          visited.add(FocusManager.instance.primaryFocus);
        }

        final slots = visited.map(_slotOf).toList();
        const pill = ValueKey('pill');
        final trailingAt = slots.indexOf(const ValueKey('trailing'));
        expect(slots.first, const ValueKey('leading'));
        expect(trailingAt, greaterThan(0));
        expect(slots.indexOf(pill), isNonNegative);
        expect(slots.indexOf(pill), lessThan(trailingAt));
        expect(slots.lastIndexOf(pill), lessThan(trailingAt));
      }
    },
  );

  testWidgets(
    'semantics read the leading button, the pill, then the trailing button in LTR',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester);

      final texts = _traversalTexts(tester).toList();
      expect(texts, containsAll(['Profile', 'Home', 'Inbox', 'Search']));
      expect(texts.indexOf('Profile'), lessThan(texts.indexOf('Home')));
      expect(texts.indexOf('Home'), lessThan(texts.indexOf('Inbox')));
      expect(texts.indexOf('Inbox'), lessThan(texts.indexOf('Search')));
      semantics.dispose();
    },
  );

  testWidgets(
    'semantics read the leading button, the pill, then the trailing button in RTL',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester, direction: TextDirection.rtl);

      final texts = _traversalTexts(tester).toList();
      expect(texts, containsAll(['Profile', 'Home', 'Inbox', 'Search']));
      expect(texts.indexOf('Profile'), lessThan(texts.indexOf('Home')));
      expect(texts.indexOf('Home'), lessThan(texts.indexOf('Inbox')));
      expect(texts.indexOf('Inbox'), lessThan(texts.indexOf('Search')));
      semantics.dispose();
    },
  );

  testWidgets(
    'every piece and the body share one scroll-edge surface, edge and backdrop',
    (tester) async {
      await pumpBar(
        tester,
        theme: const BottomBarThemeData(
          surface: BottomBarSurface.glass(),
          scrollEdgeSurface: BottomBarSurface(fillOpacity: 0),
        ),
        body: ListView(
          children: const [
            ListTile(title: Text('One')),
            ListTile(title: Text('Two')),
            ListTile(title: Text('Three')),
          ],
        ),
      );

      final surfaces = tester
          .widgetList<BarSurface>(find.byType(BarSurface))
          .toList();
      expect(surfaces, hasLength(3));
      final first = surfaces.first;
      expect(first.backdropKey, isNotNull);
      expect(first.edge!.value, 1);
      for (final piece in surfaces) {
        expect(identical(piece.surface, first.surface), isTrue);
        expect(identical(piece.edgeSurface, first.edgeSurface), isTrue);
        expect(identical(piece.edge, first.edge), isTrue);
        expect(identical(piece.visibility, first.visibility), isTrue);
        expect(identical(piece.backdropKey, first.backdropKey), isTrue);
      }
    },
  );

  testWidgets(
    'high contrast paints every piece as an opaque, unblurred surface',
    (tester) async {
      await pumpBar(
        tester,
        highContrast: true,
        theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
      );

      final surfaces = tester
          .widgetList<BarSurface>(find.byType(BarSurface))
          .toList();
      expect(surfaces, hasLength(3));
      for (final piece in surfaces) {
        expect(piece.surface!.blur, 0);
        expect(piece.surface!.tint!.a, 1);
      }
    },
  );

  testWidgets('the three glass pieces read one shared backdrop', (
    tester,
  ) async {
    await pumpBar(
      tester,
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
    );

    final layers = tester.layers.whereType<BackdropFilterLayer>().toList();
    expect(layers, hasLength(3));
    final key = layers.first.backdropKey;
    expect(key, isNotNull);
    for (final layer in layers) {
      expect(identical(layer.backdropKey, key), isTrue);
    }
  });

  testWidgets(
    'the gaps between slots are clear and the slots paint their surface',
    (tester) async {
      await pumpBar(
        tester,
        body: const ColoredBox(color: Colors.white, child: SizedBox.expand()),
        theme: const BottomBarThemeData(
          surface: BottomBarSurface.solid(color: Color(0xFFFF0000)),
        ),
      );

      final image = (await tester.runAsync(
        () => captureImage(find.byType(BottomBar).evaluate().single),
      ))!;
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      ))!;
      List<int> pixel(int x, int y) {
        final i = (y * image.width + x) * 4;
        return [for (var c = 0; c < 4; c++) bytes.getUint8(i + c)];
      }

      expect(pixel(74, 265), [255, 255, 255, 255]);
      expect(pixel(25, 265), [255, 0, 0, 255]);
      image.dispose();
    },
  );

  testWidgets(
    'barHeight is the bar footprint and includes a raised centre action',
    (tester) async {
      late BuildContext bodyContext;
      final paddingKey = GlobalKey();
      Widget body() => Builder(
        builder: (context) {
          bodyContext = context;
          return BottomBarBodyPadding(
            key: paddingKey,
            child: const SizedBox.expand(),
          );
        },
      );
      BottomBarCenterAction raised() => BottomBarCenterAction(
        icon: const Icon(Icons.add),
        tooltip: 'Create',
        style: BottomBarCenterActionStyle.raised,
        onPressed: () {},
      );

      await pumpBar(tester, body: body());
      expect(BottomBarScope.of(bodyContext).barHeight.value, 70);

      await pumpBar(
        tester,
        child: _pillRow(centerAction: raised()),
        body: body(),
      );
      final grouped = BottomBarScope.of(bodyContext).barHeight.value;
      final groupedPadding = tester
          .widget<Padding>(
            find.descendant(
              of: find.byKey(paddingKey),
              matching: find.byType(Padding),
            ),
          )
          .padding
          .resolve(TextDirection.ltr);
      expect(groupedPadding.bottom, grouped);

      await pumpBar(
        tester,
        withLeading: false,
        withTrailing: false,
        child: _pillRow(centerAction: raised()),
        body: body(),
      );
      final ungrouped = BottomBarScope.of(bodyContext).barHeight.value;
      expect(grouped, ungrouped);
      expect(grouped, greaterThan(70));
    },
  );

  testWidgets('a raised centre action still receives taps in a grouped bar', (
    tester,
  ) async {
    var presses = 0;
    await pumpBar(
      tester,
      child: _pillRow(
        centerAction: BottomBarCenterAction(
          icon: const Icon(Icons.add),
          tooltip: 'Create',
          style: BottomBarCenterActionStyle.raised,
          onPressed: () => presses++,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(presses, 1);
  });

  testWidgets(
    'the back-to-top action still scrolls to the start and reveals a grouped bar',
    (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await pumpBar(
        tester,
        controller: controller,
        showIcon: true,
        body: ListView.builder(
          controller: scrollController,
          itemCount: 100,
          itemBuilder: (_, i) => ListTile(title: Text('Item $i')),
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(scrollController.offset, greaterThan(0));
      expect(controller.isVisible, isFalse);

      await tester.tap(findByTooltip('Scroll to top'));
      await tester.pumpAndSettle();
      expect(scrollController.offset, 0);
      expect(controller.isVisible, isTrue);
    },
  );

  testWidgets('the pill keeps its state when a slot is added and removed', (
    tester,
  ) async {
    _pillInitCount = 0;
    await pumpBar(
      tester,
      withLeading: false,
      withTrailing: false,
      child: const _CountingPill(),
    );
    await pumpBar(tester, withTrailing: false, child: const _CountingPill());
    await pumpBar(
      tester,
      withLeading: false,
      withTrailing: false,
      child: const _CountingPill(),
    );

    expect(_pillInitCount, 1);
  });

  testWidgets('slot icons take the item colour and size from the bar theme', (
    tester,
  ) async {
    await pumpBar(
      tester,
      theme: const BottomBarThemeData(
        items: BottomBarItemThemeData(color: Color(0xFF00AA00), iconSize: 30),
      ),
    );

    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.search))).color,
      const Color(0xFF00AA00),
    );
    expect(tester.getSize(find.byIcon(Icons.search)), const Size(30, 30));

    await pumpBar(tester);

    final element = tester.element(find.byIcon(Icons.search));
    expect(
      IconTheme.of(element).color,
      Theme.of(element).colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('a slot button fills its 50 by 50 piece', (tester) async {
    await pumpBar(tester);

    expect(
      tester.getSize(find.byKey(const Key('trailing-button'))),
      const Size(50, 50),
    );
  });

  testWidgets('side pieces match a pill whose height follows its width', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 300)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          showIcon: false,
          layout: const BottomBarLayout(width: 360),
          body: const SizedBox.expand(),
          leading: const SizedBox(width: 10, height: 10),
          trailing: const SizedBox(width: 10, height: 10),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                SizedBox(height: constraints.maxWidth < 300 ? 60 : 40),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('pill'))).height, 60);
    expect(tester.getSize(find.byKey(const ValueKey('leading'))).height, 60);
    expect(tester.getSize(find.byKey(const ValueKey('trailing'))).height, 60);
  });
}
