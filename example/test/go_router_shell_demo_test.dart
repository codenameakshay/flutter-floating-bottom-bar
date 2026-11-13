import 'package:flutter/services.dart';
import 'dart:io';
import 'fixtures/go_router_recipe.dart' as recipe;
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue =
      '/go-router-shell';
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();

  expect(find.text('Demos'), findsNothing, reason: 'deep link skips picker');
  expect(find.text('Home row 0'), findsOneWidget, reason: 'Home root shown');
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(of: find.byType(BottomBarItems), matching: find.text(label))
        .hitTestable(),
  );
  await tester.pumpAndSettle();
}

Future<void> _drag(WidgetTester tester, String title, double dy) async {
  await tester.drag(find.byKey(PageStorageKey<String>(title)), Offset(0, dy));
  await tester.pumpAndSettle();
}

double _offset(WidgetTester tester, String title) {
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byKey(PageStorageKey<String>(title)),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  return scrollable.position.pixels;
}

bool _barVisible(WidgetTester tester, String title) {
  return BottomBarScope.of(
    tester.element(find.byKey(PageStorageKey<String>(title))),
  ).isVisible.value;
}

void main() {
  test('recipe fixture matches the documented code', () {
    final examples = File('../EXAMPLES.md').readAsStringSync();
    final section = examples.split('## go_router (StatefulShellRoute)').last;
    final snippet = section.split('```dart')[1].split('```').first;
    final fixture = File('test/fixtures/go_router_recipe.dart')
        .readAsStringSync()
        .split('// Stub pages for the recipe compile test.')
        .first;
    String normalize(String value) =>
        value.replaceAll(RegExp(r'\s+'), ' ').trim();
    expect(normalize(fixture), normalize(snippet));
  });

  testWidgets('recipe compiles with stub pages and opens Inbox details', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: recipe.router));
    await tester.pumpAndSettle();
    expect(find.text('Recipe Home'), findsOneWidget);
    final bar = tester.widget<BottomBar>(find.byType(BottomBar)).controller!;
    bar.hide();
    await tester.pumpAndSettle();
    expect(bar.isVisible, isFalse);
    recipe.router.go('/inbox/2');
    await tester.pumpAndSettle();
    expect(find.text('Recipe detail 2'), findsOneWidget);
    expect(bar.isVisible, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    recipe.router.dispose();
  });

  testWidgets('root reselect leaves the inactive branch offset unchanged', (
    tester,
  ) async {
    await _openShell(tester);
    await _drag(tester, 'Home', -600);
    await _drag(tester, 'Home', 40);
    final homeOffset = _offset(tester, 'Home');
    await _tapTab(tester, 'Search');
    await _drag(tester, 'Search', -600);
    await _drag(tester, 'Search', 40);
    await _tapTab(tester, 'Search');
    expect(_offset(tester, 'Search'), 0);
    await _tapTab(tester, 'Home');
    expect(_offset(tester, 'Home'), homeOffset);
    await _tapTab(tester, 'Home');
    await _tapTab(tester, 'Home');
    expect(_offset(tester, 'Home'), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local navigation does not report browser URL changes', (
    tester,
  ) async {
    await _openShell(tester);
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      ),
    );
    await tester.tap(find.text('Home row 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _tapTab(tester, 'Inbox');
    expect(
      calls.where((call) => call.method == 'routeInformationUpdated'),
      isEmpty,
    );
  });

  testWidgets(
    'iOS detail swipe pops locally but branch root cannot swipe out',
    (tester) async {
      await _openShell(tester);
      await tester.tap(find.text('Home row 2'));
      await tester.pumpAndSettle();
      await tester.dragFrom(const Offset(1, 400), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Home row 0'), findsOneWidget);
      expect(find.text('Home item 2'), findsNothing);
      await _tapTab(tester, 'Search');
      await tester.dragFrom(const Offset(1, 400), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Search row 0'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Home row 0'), findsOneWidget);
      await tester.dragFrom(const Offset(1, 400), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Demos'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets('same-location go, restore and push still work after a pop', (
    tester,
  ) async {
    await _openShell(tester);
    final router = GoRouter.of(tester.element(find.text('Home row 0')));
    for (final navigate in <void Function()>[
      () => router.go('/home/2'),
      () =>
          router.restore(router.configuration.findMatch(Uri.parse('/home/2'))),
      () {
        router.push<void>('/home/2');
      },
    ]) {
      navigate();
      await tester.pumpAndSettle();
      expect(find.text('Home item 2'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Home row 0'), findsOneWidget);
      navigate();
      await tester.pumpAndSettle();
      expect(find.text('Home item 2'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('scrollToStart before any scroll scrolls the visible branch', (
    tester,
  ) async {
    await _openShell(tester);
    final bar = tester.widget<BottomBar>(find.byType(BottomBar)).controller!;
    bar.scrollToStart();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no list scrolled yet');

    await _tapTab(tester, 'Search');
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const PageStorageKey<String>('Search')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    position.jumpTo(400);
    bar.scrollToStart();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(position.pixels, 0);
  });

  testWidgets('programmatic branch navigation shows the hidden bar', (
    tester,
  ) async {
    await _openShell(tester);
    final router = GoRouter.of(tester.element(find.text('Home row 0')));
    await _drag(tester, 'Home', -600);
    expect(_barVisible(tester, 'Home'), isFalse);
    router.go('/search');
    await tester.pumpAndSettle();
    expect(find.text('Search row 0'), findsOneWidget);
    expect(_barVisible(tester, 'Search'), isTrue);
  });

  testWidgets(
    'tapping a tab switches branches and keeps each branch stack and scroll offset',
    (tester) async {
      await _openShell(tester);

      await _drag(tester, 'Home', -600);
      await _drag(tester, 'Home', 40);
      final homeOffset = _offset(tester, 'Home');
      expect(homeOffset, greaterThan(0), reason: 'Home list scrolled');

      await tester.tap(find.text('Home row 15'));
      await tester.pumpAndSettle();
      expect(find.text('Home item 15'), findsOneWidget);

      await _tapTab(tester, 'Search');
      expect(find.text('Search row 0'), findsOneWidget);
      expect(
        find.text('Home item 15'),
        findsNothing,
        reason: 'Search does not show the Home stack',
      );

      await _drag(tester, 'Search', -600);
      await _drag(tester, 'Search', 40);
      final searchOffset = _offset(tester, 'Search');
      expect(searchOffset, greaterThan(0), reason: 'Search list scrolled');

      await _tapTab(tester, 'Home');
      expect(
        find.text('Home item 15'),
        findsOneWidget,
        reason: 'Home detail kept across tab switch',
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Home item 15'), findsNothing);
      expect(find.text('Home row 15'), findsOneWidget);
      expect(
        _offset(tester, 'Home'),
        homeOffset,
        reason: 'Home root offset unchanged after detail back',
      );

      await _tapTab(tester, 'Search');
      expect(
        _offset(tester, 'Search'),
        searchOffset,
        reason: 'Search offset kept across tab switches',
      );
    },
  );

  testWidgets('reselect at depth returns to the root', (tester) async {
    await _openShell(tester);

    await _tapTab(tester, 'Inbox');
    await tester.tap(find.text('Inbox row 2'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox item 2'), findsOneWidget);

    await _tapTab(tester, 'Inbox');
    expect(find.text('Inbox item 2'), findsNothing);
    expect(find.text('Inbox row 2'), findsOneWidget);
  });

  testWidgets('reselect at root scrolls to the top and shows the bar', (
    tester,
  ) async {
    await _openShell(tester);

    await _drag(tester, 'Home', -600);
    expect(_offset(tester, 'Home'), greaterThan(0));
    expect(
      _barVisible(tester, 'Home'),
      isFalse,
      reason: 'scrolling down hides the bar',
    );

    await _drag(tester, 'Home', 40);
    expect(
      _barVisible(tester, 'Home'),
      isTrue,
      reason: 'a small upward drag shows the bar',
    );
    expect(
      _offset(tester, 'Home'),
      greaterThan(0),
      reason: 'list is still far from the top',
    );

    await _tapTab(tester, 'Home');
    expect(_offset(tester, 'Home'), 0.0, reason: 'reselect scrolls to top');
    expect(_barVisible(tester, 'Home'), isTrue, reason: 'bar visible');
  });

  testWidgets('back pops in the branch, then goes Home, then leaves the demo', (
    tester,
  ) async {
    await _openShell(tester);

    await _tapTab(tester, 'Inbox');
    await tester.tap(find.text('Inbox row 4'));
    await tester.pumpAndSettle();
    expect(find.text('Inbox item 4'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Inbox item 4'), findsNothing);
    expect(find.text('Inbox row 4'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text('Inbox row 4'),
      findsNothing,
      reason: 'Inbox root left for Home',
    );
    expect(find.text('Home row 0'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Demos'), findsOneWidget, reason: 'demo popped');
  });

  testWidgets('back from a hidden bar on Search shows the bar on Home', (
    tester,
  ) async {
    await _openShell(tester);

    await _tapTab(tester, 'Search');
    await _drag(tester, 'Search', -600);
    expect(_barVisible(tester, 'Search'), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Search row 0'), findsNothing);
    expect(find.text('Home row 0'), findsOneWidget);
    expect(_barVisible(tester, 'Home'), isTrue);
  });

  testWidgets('the hidden action scrolls only the visible branch', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _openShell(tester);

    await _drag(tester, 'Home', -600);
    await _drag(tester, 'Home', 40);
    final homeOffset = _offset(tester, 'Home');
    expect(homeOffset, greaterThan(0));

    await _tapTab(tester, 'Search');
    await _drag(tester, 'Search', -600);
    expect(_barVisible(tester, 'Search'), isFalse);
    expect(_offset(tester, 'Search'), greaterThan(0));

    await tester.tap(find.bySemanticsLabel('Scroll to top'));
    await tester.pumpAndSettle();
    expect(_offset(tester, 'Search'), 0.0, reason: 'Search scrolled to top');

    await _tapTab(tester, 'Home');
    expect(
      _offset(tester, 'Home'),
      homeOffset,
      reason: 'Home offset untouched by Search action',
    );
    semantics.dispose();
  });

  testWidgets('outer routes still push above the demo after a deep link', (
    tester,
  ) async {
    await _openShell(tester);

    await tester.binding.handlePushRoute('/indicators');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Indicators'),
      ),
      findsOneWidget,
    );
  });
}
