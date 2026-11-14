import 'package:flutter/scheduler.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

bool _pillFocused() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<CompactPillButton>() !=
    null;

Future<void> _focusBar(
  WidgetTester tester,
  BottomBarController controller,
  FocusNode full, {
  bool reduced = false,
  bool keepVisible = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          scrollBehavior: BottomBarScrollBehavior(
            minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
            keepVisibleOnFocus: keepVisible,
          ),
          body: const SizedBox.expand(),
          compactChild: const SizedBox.square(dimension: 48),
          child: Focus(
            focusNode: full,
            child: const SizedBox(width: 300, height: 64),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  full.requestFocus();
  await tester.pump();
  expect(full.hasPrimaryFocus, isTrue);
}

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'rapid alternating scroll keeps focus on the active side, reduced=$reduced',
      (tester) async {
        final controller = BottomBarController();
        final full = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(full.dispose);
        await _focusBar(tester, controller, full, reduced: reduced);
        for (var i = 0; i < 4; i++) {
          controller.reportScroll(delta: 100);
          controller.reportScroll(delta: -100);
          await tester.pump();
          expect(full.hasPrimaryFocus, isTrue);
          controller.reportScroll(delta: 100);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(_pillFocused(), isTrue);
          controller.reportScroll(delta: -100);
          controller.reportScroll(delta: 100);
          await tester.pump();
          expect(_pillFocused(), isTrue);
          controller.reportScroll(delta: -100);
          await tester.pumpAndSettle();
          expect(full.hasPrimaryFocus, isTrue);
          expect(find.byType(CompactPillButton), findsNothing);
        }
      },
    );

    testWidgets('hide while minimized clears pill focus, reduced=$reduced', (
      tester,
    ) async {
      final controller = BottomBarController();
      final full = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(full.dispose);
      await _focusBar(tester, controller, full, reduced: reduced);
      controller.minimize();
      await tester.pumpAndSettle();
      expect(_pillFocused(), isTrue);
      controller.hide();
      await tester.pumpAndSettle();
      expect(_pillFocused(), isFalse);
      expect(full.hasFocus, isFalse);
      controller.show();
      await tester.pumpAndSettle();
      expect(_pillFocused(), isFalse);
      expect(find.byType(CompactPillButton), findsNothing);
    });
  }

  testWidgets('reentrant visibility listener cancels obsolete pill focus', (
    tester,
  ) async {
    final controller = BottomBarController();
    final full = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(full.dispose);
    await _focusBar(tester, controller, full);
    void expand() {
      if (controller.visibility.value == BottomBarVisibility.minimized) {
        controller.expand();
      }
    }

    controller.visibility.addListener(expand);
    addTearDown(() => controller.visibility.removeListener(expand));
    controller.minimize();
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(full.hasPrimaryFocus, isTrue);
    expect(find.byType(CompactPillButton), findsNothing);
  });

  testWidgets(
    'keepVisibleOnFocus protects the focused full bar after expansion',
    (tester) async {
      final controller = BottomBarController();
      final full = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(full.dispose);
      await _focusBar(tester, controller, full, keepVisible: true);
      controller.reportScroll(delta: 100);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.shown);
      controller.minimize();
      await tester.pumpAndSettle();
      expect(_pillFocused(), isTrue);
      controller.reportScroll(delta: 100);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.minimized);
      controller.reportScroll(delta: -100);
      await tester.pumpAndSettle();
      expect(full.hasPrimaryFocus, isTrue);
      controller.reportScroll(delta: 100);
      await tester.pumpAndSettle();
      expect(controller.visibility.value, BottomBarVisibility.shown);
    },
  );

  testWidgets('restoring tab visibility transfers focus to its active side', (
    tester,
  ) async {
    final controller = BottomBarController();
    final full = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(full.dispose);
    var tab = 0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Scaffold(
              body: BottomBar(
                controller: controller,
                scrollBehavior: const BottomBarScrollBehavior(
                  minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
                  visibilityOnTabChange: BottomBarTabVisibility.restore,
                  keepVisibleOnFocus: false,
                ),
                compactChild: const SizedBox.square(dimension: 48),
                body: IndexedStack(
                  index: tab,
                  children: [
                    for (var i = 0; i < 2; i++)
                      ListView.builder(
                        itemCount: 100,
                        itemBuilder: (_, index) =>
                            SizedBox(height: 60, child: Text('$index')),
                      ),
                  ],
                ),
                child: Focus(
                  focusNode: full,
                  child: const SizedBox(width: 300, height: 64),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    full.requestFocus();
    await tester.pump();
    controller.minimize();
    await tester.pumpAndSettle();
    expect(_pillFocused(), isTrue);
    update(() => tab = 1);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(full.hasPrimaryFocus, isTrue);
    expect(find.byType(CompactPillButton), findsNothing);
    update(() => tab = 0);
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.minimized);
    expect(_pillFocused(), isTrue);
    expect(full.hasFocus, isFalse);
  });

  testWidgets('removing the pill does not override a newer expansion', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    Widget build({required bool pill}) => MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: const SizedBox.expand(),
          compactChild: pill ? const SizedBox.square(dimension: 48) : null,
          child: const SizedBox(width: 300, height: 64),
        ),
      ),
    );
    await tester.pumpWidget(build(pill: true));
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    SchedulerBinding.instance.addPostFrameCallback((_) => controller.expand());
    await tester.pumpWidget(build(pill: false));
    await tester.pumpAndSettle();
    expect(controller.visibility.value, BottomBarVisibility.shown);
    expect(find.byType(CompactPillButton), findsNothing);
  });
}
