import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/widgets/bottom_bar_switcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _linear = BottomBarMotion.curved(
  duration: Duration(milliseconds: 400),
  curve: Curves.linear,
);

enum _Mode { nav, actions, composer }

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: TextButton(
      onPressed: () => setState(() => count++),
      child: Text('Count $count'),
    ),
  );
}

Widget _nav({Key key = const ValueKey('nav'), VoidCallback? onTap}) => SizedBox(
  key: key,
  height: 64,
  child: Row(
    children: [
      Expanded(
        child: TextButton(onPressed: onTap ?? () {}, child: const Text('Home')),
      ),
      Expanded(
        child: TextButton(onPressed: () {}, child: const Text('Search')),
      ),
    ],
  ),
);

Widget _actions({FocusNode? first}) => SizedBox(
  key: const ValueKey('actions'),
  height: 80,
  child: Row(
    children: [
      Expanded(
        child: TextButton(
          focusNode: first,
          onPressed: () {},
          child: const Text('Share'),
        ),
      ),
      Expanded(
        child: TextButton(onPressed: () {}, child: const Text('Delete')),
      ),
    ],
  ),
);

Widget _composer({FocusNode? field, bool autofocus = false}) => SizedBox(
  key: const ValueKey('composer'),
  height: 120,
  child: Row(
    children: [
      IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
      Expanded(
        child: TextField(
          focusNode: field,
          autofocus: autofocus,
          decoration: const InputDecoration(hintText: 'Message'),
        ),
      ),
    ],
  ),
);

class _Harness extends StatefulWidget {
  const _Harness({
    required this.builder,
    this.layout,
    this.motion = _linear,
    this.surface,
    this.controller,
    this.compactChild,
    this.body,
  });

  final Widget Function(_Mode mode) builder;
  final BottomBarLayout? layout;
  final BottomBarMotion? motion;
  final BottomBarSurface? surface;
  final BottomBarController? controller;
  final Widget? compactChild;
  final Widget? body;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  _Mode mode = _Mode.nav;

  void go(_Mode next) => setState(() => mode = next);

  @override
  Widget build(BuildContext context) => BottomBar(
    layout: widget.layout,
    motion: widget.motion,
    controller: widget.controller,
    compactChild: widget.compactChild,
    theme: widget.surface == null
        ? null
        : BottomBarThemeData(surface: widget.surface),
    body:
        widget.body ??
        ListView.builder(
          itemCount: 60,
          itemBuilder: (_, i) => SizedBox(height: 50, child: Text('Row $i')),
        ),
    child: BottomBarSwitcher(child: widget.builder(mode)),
  );
}

Widget _byMode(_Mode mode) => switch (mode) {
  _Mode.nav => _nav(),
  _Mode.actions => _actions(),
  _Mode.composer => _composer(),
};

Future<_HarnessState> _pump(
  WidgetTester tester, {
  Widget Function(_Mode)? builder,
  BottomBarLayout? layout,
  BottomBarMotion? motion = _linear,
  BottomBarSurface? surface,
  BottomBarController? controller,
  Widget? compactChild,
  Widget? body,
  TextDirection direction = TextDirection.ltr,
  bool reduceMotion = false,
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Directionality(
        textDirection: direction,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: Scaffold(
              body: _Harness(
                builder: builder ?? _byMode,
                layout: layout,
                motion: motion,
                surface: surface,
                controller: controller,
                compactChild: compactChild,
                body: body,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return tester.state<_HarnessState>(find.byType(_Harness));
}

RenderBottomBarSwitcher _switcher(WidgetTester tester) =>
    tester.renderObject<RenderBottomBarSwitcher>(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SwitcherBox'),
    );

RenderBarSurface _surface(WidgetTester tester) =>
    tester.renderObject<RenderBarSurface>(find.byType(BarSurface));

List<double> _opacities(WidgetTester tester) {
  final switcher = _switcher(tester);
  final opacities = <double>[];
  switcher.visitChildren((child) {
    opacities.add(switcher.opacityOf(child as RenderBox));
  });
  return opacities;
}

List<String> _labels(WidgetTester tester) {
  final labels = <String>[];
  bool visit(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren(visit);
    return true;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return labels;
}

void main() {
  group('size', () {
    testWidgets('springs the height at 0, 0.5 and 1 of a linear morph', (
      tester,
    ) async {
      final state = await _pump(tester);
      expect(_switcher(tester).size.height, 64);

      state.go(_Mode.composer);
      await tester.pump();
      expect(_switcher(tester).size.height, 64);
      expect(_switcher(tester).targetSize!.height, 120);

      await tester.pump(const Duration(milliseconds: 200));
      expect(_switcher(tester).size.height, moreOrLessEquals(92, epsilon: 0.5));

      await tester.pumpAndSettle();
      expect(_switcher(tester).size.height, 120);
      expect(_switcher(tester).isMorphing, isFalse);
    });

    testWidgets('keeps the bar width: only the height morphs inside a bar', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        layout: const BottomBarLayout(width: 320),
      );
      expect(_switcher(tester).size.width, 320);
      state.go(_Mode.composer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_switcher(tester).size.width, 320);
    });

    testWidgets('morphs the width too where the constraints leave it loose', (
      tester,
    ) async {
      var wide = false;
      late StateSetter set;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return BottomBarSwitcher(
                  motion: const LinearMotion(Duration(milliseconds: 400)),
                  child: wide
                      ? const SizedBox(
                          key: ValueKey('w'),
                          width: 300,
                          height: 40,
                        )
                      : const SizedBox(
                          key: ValueKey('n'),
                          width: 100,
                          height: 60,
                        ),
                );
              },
            ),
          ),
        ),
      );
      set(() => wide = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_switcher(tester).size, const Size(200, 50));
      await tester.pumpAndSettle();
      expect(_switcher(tester).size, const Size(300, 40));
    });

    testWidgets('retargets mid-flight from the current height and velocity', (
      tester,
    ) async {
      final state = await _pump(tester, motion: const BottomBarMotion());
      state.go(_Mode.composer);
      await tester.pump();
      final heights = <double>[];
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        heights.add(_switcher(tester).size.height);
      }
      final before = heights.last;
      final speed = heights.last - heights[heights.length - 2];
      expect(speed, greaterThan(0));

      state.go(_Mode.nav);
      await tester.pump();
      expect(_switcher(tester).size.height, before);
      expect(_switcher(tester).targetSize!.height, 64);
      await tester.pump(const Duration(milliseconds: 1));
      final after = _switcher(tester).size.height;
      expect(after, greaterThan(before));
      expect(after - before, lessThan(speed));

      var last = after;
      var maxStep = 0.0;
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final h = _switcher(tester).size.height;
        maxStep = (h - last).abs() > maxStep ? (h - last).abs() : maxStep;
        last = h;
      }
      expect(maxStep, lessThan(12));
      await tester.pumpAndSettle();
      expect(_switcher(tester).size.height, 64);
    });

    testWidgets('reduced motion swaps at once with no size animation', (
      tester,
    ) async {
      final state = await _pump(tester, reduceMotion: true);
      state.go(_Mode.composer);
      await tester.pump();
      expect(_switcher(tester).size.height, 120);
      expect(_switcher(tester).isMorphing, isFalse);
      expect(find.text('Home'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('enabling reduced motion finishes an in-flight swap', (
      tester,
    ) async {
      var disableAnimations = false;
      var tall = false;
      late StateSetter set;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: disableAnimations),
                child: Center(
                  child: BottomBarSwitcher(
                    motion: _linear.resolveMotion(),
                    child: tall ? _actions() : _nav(),
                  ),
                ),
              );
            },
          ),
        ),
      );
      set(() => tall = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_switcher(tester).size.height, 72);

      set(() => disableAnimations = true);
      await tester.pump();
      expect(_switcher(tester).size.height, 80);
      expect(_opacities(tester), [1.0]);
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('animates again when platform reduced motion turns off', (
      tester,
    ) async {
      final dispatcher = tester.binding.platformDispatcher;
      dispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
      var height = 40.0;
      late StateSetter resize;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: BottomBarSwitcher(
              motion: _linear.resolveMotion(),
              child: StatefulBuilder(
                builder: (context, setState) {
                  resize = setState;
                  return SizedBox(width: 100, height: height);
                },
              ),
            ),
          ),
        ),
      );
      resize(() => height = 60);
      await tester.pump();
      expect(_switcher(tester).size.height, 60);

      dispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump();
      resize(() => height = 100);
      await tester.pump();
      expect(_switcher(tester).size.height, 60);
      await tester.pump(const Duration(milliseconds: 200));
      expect(_switcher(tester).size.height, 80);
    });

    testWidgets('morphs through a zero-height child and back', (tester) async {
      final state = await _pump(
        tester,
        builder: (mode) => mode == _Mode.nav
            ? _nav()
            : const SizedBox.shrink(key: ValueKey('empty')),
      );
      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      expect(_switcher(tester).size.height, 0);
      expect(find.text('Home'), findsNothing);

      state.go(_Mode.nav);
      await tester.pumpAndSettle();
      expect(_switcher(tester).size.height, 64);
      expect(find.text('Home'), findsOneWidget);
      expect(_opacities(tester), [1.0]);
    });
  });

  group('outline', () {
    testWidgets('the bar outline and glass follow the size every frame', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        surface: const BottomBarSurface.glass(),
      );
      state.go(_Mode.composer);
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 80));
        final switcher = _switcher(tester);
        final outline = _surface(tester).outlineRect;
        expect(outline.height, switcher.size.height);
        expect(outline.width, switcher.size.width);
      }
    });

    testWidgets('a capsule stays a capsule as the height changes', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        layout: const BottomBarLayout(
          borderRadius: BorderRadius.all(Radius.circular(999)),
        ),
      );
      state.go(_Mode.composer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final surface = _surface(tester);
      final rect = surface.outlineRect;
      final path = surface.outline.getOuterPath(rect);
      final r = rect.height / 2;
      expect(path.contains(Offset(rect.left + r, rect.center.dy)), isTrue);
      expect(path.contains(rect.topLeft + Offset(r * 0.25, r * 0.25)), isFalse);
      expect(path.contains(Offset(rect.left + 1, rect.center.dy)), isTrue);
    });
  });

  group('outgoing child', () {
    testWidgets('is out of pointer, focus and semantics from the first frame', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      final homeFocus = FocusNode();
      addTearDown(homeFocus.dispose);
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => SizedBox(
            key: const ValueKey('nav'),
            height: 64,
            child: TextButton(
              focusNode: homeFocus,
              onPressed: () => taps++,
              child: const Text('Home'),
            ),
          ),
          _ => _composer(),
        },
      );
      expect(_labels(tester), contains('Home'));
      final homeCenter = tester.getCenter(find.text('Home'));

      state.go(_Mode.composer);
      await tester.pump();
      expect(find.text('Home'), findsOneWidget);
      expect(homeFocus.canRequestFocus, isFalse);
      expect(_labels(tester), isNot(contains('Home')));
      await tester.tapAt(homeCenter);
      await tester.pump();
      expect(taps, 0);

      await tester.pumpAndSettle();
      expect(find.text('Home'), findsNothing);
      handle.dispose();
    });

    testWidgets('cancels a press that started on the outgoing child', (
      tester,
    ) async {
      var taps = 0;
      final state = await _pump(
        tester,
        builder: (mode) =>
            mode == _Mode.nav ? _nav(onTap: () => taps++) : _actions(),
      );
      final home = find.text('Home');
      await tester.tap(home);
      expect(taps, 1);

      final press = await tester.startGesture(tester.getCenter(home));
      state.go(_Mode.actions);
      await tester.pump();
      expect(home, findsOneWidget);
      await press.up();
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('paints with no gap: the bar is never empty mid-morph', (
      tester,
    ) async {
      final state = await _pump(tester);
      state.go(_Mode.composer);
      await tester.pump();
      for (var i = 0; i <= 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final switcher = _switcher(tester);
        var total = 0.0;
        switcher.visitChildren((child) {
          total += switcher.opacityOf(child as RenderBox);
        });
        expect(total, greaterThan(0.99), reason: 'frame $i');
      }
    });

    testWidgets('keeps content visible through a three-way retarget', (
      tester,
    ) async {
      final state = await _pump(tester);
      state.go(_Mode.actions);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final before = _switcher(tester).size;

      state.go(_Mode.composer);
      await tester.pump();
      expect(_switcher(tester).size, before);
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          _opacities(tester),
          contains(greaterThan(0)),
          reason: 'frame $i',
        );
      }
      await tester.pumpAndSettle();
      expect(_switcher(tester).size.height, 120);
      expect(_opacities(tester), [1.0]);
    });

    testWidgets('clips opacity layers and releases them when an exit ends', (
      tester,
    ) async {
      var tall = false;
      late StateSetter set;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return BottomBarSwitcher(
                  motion: _linear.resolveMotion(),
                  child: tall
                      ? const ColoredBox(
                          key: ValueKey('tall'),
                          color: Color(0xFF0000FF),
                          child: SizedBox(width: 100, height: 120),
                        )
                      : const ColoredBox(
                          key: ValueKey('short'),
                          color: Color(0xFFFF0000),
                          child: SizedBox(width: 100, height: 40),
                        ),
                );
              },
            ),
          ),
        ),
      );
      set(() => tall = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.layers.whereType<ClipRectLayer>(), hasLength(1));
      await tester.pump(const Duration(milliseconds: 100));
      final layers = tester.layers.whereType<OpacityLayer>().toList();
      expect(layers, hasLength(2));
      final outgoing = layers.first;
      final incoming = layers.last;
      final parent = incoming.parent;

      await tester.pump(const Duration(milliseconds: 220));
      expect(outgoing.debugHandleCount, 0);
      expect(parent, isA<ClipRectLayer>());
    });
  });

  group('state', () {
    testWidgets('a GlobalKey child keeps its state across a full round trip', (
      tester,
    ) async {
      final key = GlobalKey<_CounterState>();
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => _Counter(key: key),
          _ => _actions(),
        },
      );
      await tester.tap(find.text('Count 0'));
      await tester.pump();
      expect(find.text('Count 1'), findsOneWidget);

      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsNothing);
      expect(find.text('Count 1', skipOffstage: false), findsOneWidget);

      state.go(_Mode.nav);
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);
      expect(key.currentState!.count, 1);
    });

    testWidgets('a local key keeps state only when it returns mid-exit', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => const _Counter(key: ValueKey('nav')),
          _ => _actions(),
        },
      );
      await tester.tap(find.text('Count 0'));
      await tester.pump();

      state.go(_Mode.actions);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      state.go(_Mode.nav);
      await tester.pumpAndSettle();
      expect(find.text('Count 1'), findsOneWidget);

      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      state.go(_Mode.nav);
      await tester.pumpAndSettle();
      expect(find.text('Count 0'), findsOneWidget);
    });

    testWidgets('reverses before the first tick without losing the child', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        builder: (mode) => mode == _Mode.nav
            ? const _Counter(key: ValueKey('nav'))
            : _actions(),
      );
      await tester.tap(find.text('Count 0'));
      await tester.pump();
      final original = tester.state(find.byType(_Counter));

      state.go(_Mode.actions);
      await tester.pump();
      state.go(_Mode.nav);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.state(find.byType(_Counter)), same(original));
      expect(find.text('Count 1'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
      expect(_opacities(tester), [1.0]);
    });

    testWidgets('removes an unpainted intermediate child on a rapid switch', (
      tester,
    ) async {
      final state = await _pump(tester);
      state.go(_Mode.actions);
      await tester.pump();
      state.go(_Mode.composer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_opacities(tester).where((opacity) => opacity > 0), [1.0]);
      await tester.pumpAndSettle();
      expect(find.text('Share', skipOffstage: false), findsNothing);
      expect(_opacities(tester), [1.0]);
    });

    testWidgets('later switches do not restart unrelated exits', (
      tester,
    ) async {
      final state = await _pump(tester);
      state.go(_Mode.actions);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      state.go(_Mode.composer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      state.go(_Mode.actions);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.text('Home', skipOffstage: false), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      await tester.pumpAndSettle();
      expect(_opacities(tester), [1.0]);
    });

    testWidgets('unmounts live and parked children during a retarget', (
      tester,
    ) async {
      final parkedKey = GlobalKey<_CounterState>();
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => _Counter(key: parkedKey),
          _Mode.actions => const _Counter(key: ValueKey('actions')),
          _Mode.composer => const _Counter(key: ValueKey('composer')),
        },
      );
      final parked = parkedKey.currentState!;
      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      final outgoing = tester.state(find.byKey(const ValueKey('actions')));
      state.go(_Mode.composer);
      await tester.pump();
      final incoming = tester.state(find.byKey(const ValueKey('composer')));

      await tester.pumpWidget(const SizedBox());
      expect(parked.mounted, isFalse);
      expect(outgoing.mounted, isFalse);
      expect(incoming.mounted, isFalse);
      expect(parkedKey.currentState, isNull);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('replaces a parked GlobalKey child with a different type', (
      tester,
    ) async {
      final key = GlobalKey();
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => _Counter(key: key),
          _Mode.actions => _actions(),
          _Mode.composer => Padding(
            key: key,
            padding: EdgeInsets.zero,
            child: const SizedBox(height: 120, child: Text('Replacement')),
          ),
        },
      );
      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      expect(key.currentWidget, isA<_Counter>());

      state.go(_Mode.composer);
      await tester.pumpAndSettle();
      expect(key.currentWidget, isA<Padding>());
      expect(find.text('Replacement'), findsOneWidget);
      expect(find.byType(_Counter, skipOffstage: false), findsNothing);
    });

    testWidgets('BottomBarItems comes back on the app-held selection', (
      tester,
    ) async {
      var selected = 2;
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => BottomBarItems(
            key: const ValueKey('items'),
            selectedIndex: selected,
            onSelected: (i) => selected = i,
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
            ],
          ),
          _ => _actions(),
        },
      );
      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      state.go(_Mode.nav);
      await tester.pumpAndSettle();
      final items = tester.widget<BottomBarItems>(find.byType(BottomBarItems));
      expect(items.selectedIndex, 2);
    });
  });

  group('focus', () {
    testWidgets('moves from the old child to the new child first focusable', (
      tester,
    ) async {
      final homeFocus = FocusNode();
      final share = FocusNode();
      addTearDown(homeFocus.dispose);
      addTearDown(share.dispose);
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => SizedBox(
            key: const ValueKey('nav'),
            height: 64,
            child: TextButton(
              focusNode: homeFocus,
              onPressed: () {},
              child: const Text('Home'),
            ),
          ),
          _ => _actions(first: share),
        },
      );
      homeFocus.requestFocus();
      await tester.pump();
      expect(homeFocus.hasPrimaryFocus, isTrue);

      state.go(_Mode.actions);
      await tester.pump();
      await tester.pump();
      expect(share.hasPrimaryFocus, isTrue);
    });

    testWidgets('leaves focus where the app puts it in the new child', (
      tester,
    ) async {
      final homeFocus = FocusNode();
      final field = FocusNode();
      addTearDown(homeFocus.dispose);
      addTearDown(field.dispose);
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.nav => SizedBox(
            key: const ValueKey('nav'),
            height: 64,
            child: TextButton(
              focusNode: homeFocus,
              onPressed: () {},
              child: const Text('Home'),
            ),
          ),
          _ => _composer(field: field),
        },
      );
      homeFocus.requestFocus();
      await tester.pump();

      state.go(_Mode.composer);
      field.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('an autofocus text field gets focus after a touch switch', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        builder: (mode) => switch (mode) {
          _Mode.composer => _composer(autofocus: true),
          _ => _nav(),
        },
      );
      state.go(_Mode.composer);
      await tester.pump();
      await tester.pump();
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.widget.focusNode.hasPrimaryFocus, isTrue);
    });

    testWidgets('does not take focus when it was elsewhere', (tester) async {
      final outside = FocusNode();
      addTearDown(outside.dispose);
      final state = await _pump(
        tester,
        body: Focus(focusNode: outside, child: const SizedBox.expand()),
      );
      outside.requestFocus();
      await tester.pump();
      state.go(_Mode.actions);
      await tester.pump();
      await tester.pump();
      expect(outside.hasPrimaryFocus, isTrue);
    });

    testWidgets('does not override an app focus request outside the bar', (
      tester,
    ) async {
      final home = FocusNode();
      final share = FocusNode();
      final outside = FocusNode();
      addTearDown(home.dispose);
      addTearDown(share.dispose);
      addTearDown(outside.dispose);
      final state = await _pump(
        tester,
        body: Focus(focusNode: outside, child: const SizedBox.expand()),
        builder: (mode) => mode == _Mode.nav
            ? Focus(key: const ValueKey('home'), focusNode: home, child: _nav())
            : _actions(first: share),
      );
      home.requestFocus();
      await tester.pump();
      expect(home.hasPrimaryFocus, isTrue);

      state.go(_Mode.actions);
      tester.binding.addPostFrameCallback((_) => outside.requestFocus());
      await tester.pump();
      await tester.pumpAndSettle();
      expect(outside.hasPrimaryFocus, isTrue);
    });

    testWidgets('keeps an already focused body field over new autofocus', (
      tester,
    ) async {
      final outside = FocusNode();
      final field = FocusNode();
      addTearDown(outside.dispose);
      addTearDown(field.dispose);
      final state = await _pump(
        tester,
        body: Focus(focusNode: outside, child: const SizedBox.expand()),
        builder: (mode) => mode == _Mode.nav
            ? _nav()
            : _composer(field: field, autofocus: true),
      );
      outside.requestFocus();
      await tester.pump();
      state.go(_Mode.composer);
      await tester.pumpAndSettle();
      expect(outside.hasPrimaryFocus, isTrue);
      expect(field.hasPrimaryFocus, isFalse);
    });

    testWidgets('tab traversal can enter and leave the switcher', (
      tester,
    ) async {
      final outside = FocusNode();
      final inside = FocusNode();
      addTearDown(outside.dispose);
      addTearDown(inside.dispose);
      await _pump(
        tester,
        body: Align(
          alignment: Alignment.topCenter,
          child: TextButton(
            focusNode: outside,
            onPressed: () {},
            child: const Text('Outside'),
          ),
        ),
        builder: (_) => TextButton(
          focusNode: inside,
          onPressed: () {},
          child: const Text('Inside'),
        ),
      );
      outside.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(inside.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(outside.hasPrimaryFocus, isTrue);
    });

    testWidgets('a parked GlobalKey child cannot take focus or semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final key = GlobalKey();
      final home = FocusNode();
      final share = FocusNode();
      addTearDown(home.dispose);
      addTearDown(share.dispose);
      final state = await _pump(
        tester,
        builder: (mode) => mode == _Mode.nav
            ? SizedBox(
                key: key,
                height: 64,
                child: TextButton(
                  focusNode: home,
                  onPressed: () {},
                  child: const Text('Parkable'),
                ),
              )
            : _actions(first: share),
      );
      home.requestFocus();
      await tester.pump();
      expect(home.hasPrimaryFocus, isTrue);
      expect(_labels(tester), contains('Parkable'));

      state.go(_Mode.actions);
      await tester.pumpAndSettle();
      home.requestFocus();
      await tester.pump();
      expect(key.currentContext, isNotNull);
      expect(home.canRequestFocus, isFalse);
      expect(share.hasPrimaryFocus, isTrue);
      expect(_labels(tester), isNot(contains('Parkable')));

      state.go(_Mode.nav);
      await tester.pumpAndSettle();
      expect(home.hasPrimaryFocus, isTrue);
      expect(_labels(tester), contains('Parkable'));
      semantics.dispose();
    });
  });

  testWidgets('keyboard: the composer rides the keyboard with avoidKeyboard', (
    tester,
  ) async {
    final field = FocusNode();
    addTearDown(field.dispose);
    final state = await _pump(
      tester,
      builder: (mode) => switch (mode) {
        _Mode.composer => _composer(field: field),
        _ => _nav(),
      },
    );
    state.go(_Mode.composer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    final editable = tester.state<EditableTextState>(find.byType(EditableText));
    expect(_switcher(tester).isMorphing, isTrue);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    double barBottom() {
      final surface = _surface(tester);
      return surface.localToGlobal(surface.size.bottomLeft(Offset.zero)).dy;
    }

    final restBottom = barBottom();

    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    expect(
      restBottom - barBottom(),
      moreOrLessEquals(900 / tester.view.devicePixelRatio, epsilon: 1),
    );
    expect(field.hasPrimaryFocus, isTrue);
    expect(tester.state(find.byType(EditableText)), same(editable));
    expect(_switcher(tester).isMorphing, isTrue);

    tester.view.resetViewInsets();
    await tester.pump();
    expect(barBottom(), moreOrLessEquals(restBottom, epsilon: 1));
    expect(field.hasPrimaryFocus, isTrue);
    expect(tester.state(find.byType(EditableText)), same(editable));
    await tester.pumpAndSettle();
    expect(find.text('hello'), findsOneWidget);
    expect(_switcher(tester).size.height, 120);
  });

  testWidgets('docked: the docked bar morphs its height at full width', (
    tester,
  ) async {
    final state = await _pump(tester, layout: const BottomBarLayout.docked());
    final width = tester.getSize(find.byType(Scaffold)).width;
    expect(_switcher(tester).size.width, width);
    state.go(_Mode.composer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_switcher(tester).size.height, moreOrLessEquals(92, epsilon: 0.5));
    expect(_surface(tester).outlineRect.width, width);
  });

  testWidgets('RTL: focus lands on the first focusable in reading order', (
    tester,
  ) async {
    final homeFocus = FocusNode();
    final share = FocusNode();
    addTearDown(homeFocus.dispose);
    addTearDown(share.dispose);
    final state = await _pump(
      tester,
      direction: TextDirection.rtl,
      builder: (mode) => switch (mode) {
        _Mode.nav => SizedBox(
          key: const ValueKey('nav'),
          height: 64,
          child: TextButton(
            focusNode: homeFocus,
            onPressed: () {},
            child: const Text('Home'),
          ),
        ),
        _ => SizedBox(
          key: const ValueKey('actions'),
          height: 80,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Delete'),
                ),
              ),
              Positioned(
                right: 0,
                child: TextButton(
                  focusNode: share,
                  onPressed: () {},
                  child: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      },
    );
    homeFocus.requestFocus();
    await tester.pump();
    state.go(_Mode.actions);
    await tester.pump();
    await tester.pump();
    expect(share.hasPrimaryFocus, isTrue);
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('Share')).dx,
      greaterThan(tester.getCenter(find.text('Delete')).dx),
    );
  });

  testWidgets('RTL: a start alignment sits the children on the right', (
    tester,
  ) async {
    var wide = false;
    late StateSetter set;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              set = setState;
              return BottomBarSwitcher(
                alignment: AlignmentDirectional.centerStart,
                motion: const LinearMotion(Duration(milliseconds: 400)),
                child: wide
                    ? const SizedBox(key: ValueKey('w'), width: 300, height: 40)
                    : const SizedBox(
                        key: ValueKey('n'),
                        width: 100,
                        height: 40,
                      ),
              );
            },
          ),
        ),
      ),
    );
    set(() => wide = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final box = tester.getRect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_SwitcherBox'),
    );
    final narrow = tester.getRect(find.byKey(const ValueKey('n')));
    expect(narrow.right, moreOrLessEquals(box.right, epsilon: 0.01));
  });

  group('minimize', () {
    testWidgets('a switch while minimized lands at once, shown on expand', (
      tester,
    ) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final state = await _pump(
        tester,
        controller: controller,
        compactChild: const Icon(Icons.home),
      );
      controller.minimize();
      await tester.pumpAndSettle();

      state.go(_Mode.composer);
      await tester.pump();
      expect(_switcher(tester).size.height, 120);
      expect(_switcher(tester).isMorphing, isFalse);
      await tester.pump();
      expect(find.text('Home'), findsNothing);

      controller.show();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(_switcher(tester).size.height, 120);
    });

    testWidgets('a switcher in the visible pill still morphs', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      var big = false;
      late StateSetter set;
      await _pump(
        tester,
        controller: controller,
        compactChild: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return BottomBarSwitcher(
              child: big
                  ? const SizedBox(key: ValueKey('big'), width: 48, height: 60)
                  : const SizedBox(
                      key: ValueKey('small'),
                      width: 48,
                      height: 40,
                    ),
            );
          },
        ),
      );
      controller.minimize();
      await tester.pumpAndSettle();
      set(() => big = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final pill = tester.renderObject<RenderBottomBarSwitcher>(
        find
            .byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_SwitcherBox',
            )
            .last,
      );
      expect(pill.isMorphing, isTrue);
    });

    testWidgets('a switch while expanding still morphs', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      final state = await _pump(
        tester,
        controller: controller,
        compactChild: const Icon(Icons.home),
      );
      controller.minimize();
      await tester.pumpAndSettle();
      controller.show();
      await tester.pump();
      state.go(_Mode.composer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_switcher(tester).isMorphing, isTrue);
    });
  });

  testWidgets('body padding follows the morph one frame behind, as is', (
    tester,
  ) async {
    final state = await _pump(
      tester,
      body: const BottomBarBodyPadding(child: SizedBox.expand()),
    );
    await tester.pump();
    double padding() => tester
        .widget<Padding>(
          find
              .descendant(
                of: find.byType(BottomBarBodyPadding),
                matching: find.byType(Padding),
              )
              .first,
        )
        .padding
        .resolve(TextDirection.ltr)
        .bottom;
    final rest = padding();

    state.go(_Mode.composer);
    await tester.pump();
    final seen = <double>[];
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      seen.add(padding());
    }
    await tester.pumpAndSettle();
    expect(seen.toSet().length, greaterThan(10));
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
    }
    expect(padding(), rest + 56);
  });

  testWidgets('inherits the bar motion, then the item theme outside a bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            BottomBarThemeData(
              items: BottomBarItemThemeData(
                indicatorMotion: LinearMotion(Duration(milliseconds: 400)),
              ),
            ),
          ],
        ),
        home: const Center(
          child: BottomBarSwitcher(
            child: SizedBox(key: ValueKey('a'), width: 100, height: 40),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            BottomBarThemeData(
              items: BottomBarItemThemeData(
                indicatorMotion: LinearMotion(Duration(milliseconds: 400)),
              ),
            ),
          ],
        ),
        home: const Center(
          child: BottomBarSwitcher(
            child: SizedBox(key: ValueKey('b'), width: 100, height: 80),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_switcher(tester).size.height, moreOrLessEquals(60, epsilon: 0.5));
  });

  testWidgets('updates an explicit motion while a switch is in flight', (
    tester,
  ) async {
    var switcher = BottomBarSwitcher(child: _nav());
    late StateSetter set;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return BottomBar(
              motion: _linear,
              body: const SizedBox.expand(),
              child: switcher,
            );
          },
        ),
      ),
    );
    set(() => switcher = BottomBarSwitcher(child: _composer()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_switcher(tester).size.height, 78);

    set(
      () => switcher = BottomBarSwitcher(
        motion: const LinearMotion(Duration(milliseconds: 50)),
        child: switcher.child,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(_switcher(tester).size.height, 120);
    expect(_opacities(tester), [1.0]);
  });
}
