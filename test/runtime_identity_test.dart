import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/semantics.dart';
import 'helpers/tooltip_finder.dart';

void main() {
  testWidgets('scroll hiding keeps the custom hidden-action subtree mounted', (
    tester,
  ) async {
    await _withSemantics(tester, () async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              body: ListView(children: const [SizedBox(height: 2000)]),
              icon: (_, _) => const _StatefulIcon(),
              child: const SizedBox(height: 56),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mountedIcon = tester.state<_StatefulIconState>(
        find.byType(_StatefulIcon),
      );
      mountedIcon.increment();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(semanticsLabels(tester), isNot(contains('Scroll to top')));

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(controller.isVisible, isFalse);
      expect(semanticsLabels(tester), contains('Scroll to top'));
      final tooltip = tester.state<TooltipState>(
        findByTooltip('Scroll to top'),
      );
      expect(tooltip.ensureTooltipVisible(), isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Scroll to top'), findsOneWidget);

      controller.show();
      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.isVisible, isTrue);
      expect(semanticsLabels(tester), isNot(contains('Scroll to top')));
      expect(find.text('Scroll to top'), findsNothing);
      expect(
        tester.state<_StatefulIconState>(find.byType(_StatefulIcon)),
        same(mountedIcon),
      );

      controller.hide();
      await tester.pumpAndSettle();
      expect(controller.isVisible, isFalse);
      expect(find.text('1'), findsOneWidget);
      expect(semanticsLabels(tester), contains('Scroll to top'));
      expect(
        tester.state<_StatefulIconState>(find.byType(_StatefulIcon)),
        same(mountedIcon),
      );
    });
  });

  testWidgets('visible bar excludes the disabled hidden action from focus', (
    tester,
  ) async {
    final controller = BottomBarController();
    final focusNode = FocusNode();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            body: const SizedBox.expand(),
            icon: (_, _) => _StatefulIcon(focusNode: focusNode),
            child: const SizedBox(height: 56),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);

    controller.hide();
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    controller.show();
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isFalse);
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    controller.hide();
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets('hidden action respects inherited tooltip visibility', (
    tester,
  ) async {
    await _withSemantics(tester, () async {
      final controller = BottomBarController();
      final icon = GlobalKey<_StatefulIconState>();
      var tooltipsVisible = true;
      addTearDown(controller.dispose);

      Future<void> pumpHarness() async {
        await tester.pumpWidget(
          TooltipVisibility(
            visible: tooltipsVisible,
            child: MaterialApp(
              home: Scaffold(
                body: BottomBar(
                  controller: controller,
                  body: const SizedBox.expand(),
                  icon: (_, _) => _StatefulIcon(key: icon),
                  child: const SizedBox(height: 56),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await pumpHarness();
      controller.hide();
      await tester.pumpAndSettle();
      final mountedIcon = icon.currentState!;
      final tooltip = tester.state<TooltipState>(
        findByTooltip('Scroll to top'),
      );
      expect(tooltip.ensureTooltipVisible(), isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Scroll to top'), findsOneWidget);

      tooltipsVisible = false;
      await pumpHarness();
      expect(find.text('Scroll to top'), findsNothing);
      expect(
        tester.state<_StatefulIconState>(find.byType(_StatefulIcon)),
        same(mountedIcon),
      );
      expect(tooltip.ensureTooltipVisible(), isFalse);

      tooltipsVisible = true;
      await pumpHarness();
      expect(tooltip.ensureTooltipVisible(), isTrue);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Scroll to top'), findsOneWidget);
      expect(
        tester.state<_StatefulIconState>(find.byType(_StatefulIcon)),
        same(mountedIcon),
      );
    });
  });

  testWidgets('keyboard inset keeps the mounted bar subtree and footprint', (
    tester,
  ) async {
    const childHeight = 56.0;
    final reportedHeights = <double>[];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    Future<void> pumpWithInset(
      double inset, {
      Size size = const Size(400, 800),
    }) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            viewInsets: EdgeInsets.only(bottom: inset),
          ),
          child: MaterialApp(
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              body: BottomBar(
                layout: const BottomBarLayout(
                  offset: 0,
                  respectSafeArea: false,
                ),
                body: Builder(
                  builder: (context) {
                    final height = BottomBarScope.of(context).barHeight;
                    return ValueListenableBuilder<double>(
                      valueListenable: height,
                      builder: (_, value, _) {
                        if (value > 0) reportedHeights.add(value);
                        return const SizedBox.expand();
                      },
                    );
                  },
                ),
                child: const _StatefulBarChild(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpWithInset(0);
    final mountedChild = tester.state<_StatefulBarChildState>(
      find.byType(_StatefulBarChild),
    );
    mountedChild.setValue('Typed search');
    await tester.pump();
    expect(find.text('Typed search'), findsOneWidget);
    final baseline = tester
        .getBottomLeft(find.byKey(const Key('bar-content')))
        .dy;

    await pumpWithInset(300);

    expect(
      tester.state<_StatefulBarChildState>(find.byType(_StatefulBarChild)),
      same(mountedChild),
    );
    expect(find.text('Typed search'), findsOneWidget);
    expect(reportedHeights.last, childHeight);
    expect(
      tester.getBottomLeft(find.byKey(const Key('bar-content'))).dy,
      closeTo(baseline - 300, 0.5),
    );

    await pumpWithInset(0);
    expect(
      tester.state<_StatefulBarChildState>(find.byType(_StatefulBarChild)),
      same(mountedChild),
    );
    expect(find.text('Typed search'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byKey(const Key('bar-content'))).dy,
      closeTo(baseline, 0.5),
    );

    await pumpWithInset(0, size: const Size(800, 400));
    expect(
      tester.state<_StatefulBarChildState>(find.byType(_StatefulBarChild)),
      same(mountedChild),
    );
    expect(find.text('Typed search'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byKey(const Key('bar-content'))).dy,
      closeTo(400, 0.5),
    );
    expect(reportedHeights.last, childHeight);
  });

  testWidgets('keyboard-lifted hidden action keeps hit testing and semantics', (
    tester,
  ) async {
    await _withSemantics(tester, () async {
      final controller = BottomBarController();
      final scrollController = ScrollController();
      addTearDown(() {
        controller.dispose();
        scrollController.dispose();
        tester.view.reset();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 800);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
          ),
          child: MaterialApp(
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              body: BottomBar(
                controller: controller,
                layout: const BottomBarLayout(respectSafeArea: false),
                body: ListView(
                  controller: scrollController,
                  children: const [SizedBox(height: 2000)],
                ),
                child: const SizedBox(height: 56),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(controller.isVisible, isFalse);
      expect(semanticsLabels(tester), contains('Scroll to top'));

      final action = findByTooltip('Scroll to top');
      final actionRect = tester.getRect(action);
      expect(actionRect.bottom, lessThanOrEqualTo(500.5));
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(scrollController.offset, closeTo(0, 0.5));
      expect(controller.isVisible, isTrue);
      expect(semanticsLabels(tester), isNot(contains('Scroll to top')));
    });
  });
}

Future<void> _withSemantics(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final semantics = tester.ensureSemantics();
  try {
    await body();
  } finally {
    semantics.dispose();
  }
}

class _StatefulBarChild extends StatefulWidget {
  const _StatefulBarChild();

  @override
  State<_StatefulBarChild> createState() => _StatefulBarChildState();
}

class _StatefulBarChildState extends State<_StatefulBarChild> {
  var value = 'Search';

  void setValue(String next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('bar-content'),
      height: 56,
      child: Text(value),
    );
  }
}

class _StatefulIcon extends StatefulWidget {
  const _StatefulIcon({this.focusNode, super.key});

  final FocusNode? focusNode;

  @override
  State<_StatefulIcon> createState() => _StatefulIconState();
}

class _StatefulIconState extends State<_StatefulIcon> {
  var value = 0;

  void increment() => setState(() => value++);

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      child: SizedBox.expand(child: Text('$value')),
    );
  }
}
