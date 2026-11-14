import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shell branch stacks survive both breakpoint directions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => Scaffold(
            body: BottomBarAdaptive(
              items: BottomBarItems(
                selectedIndex: shell.currentIndex,
                onSelected: shell.goBranch,
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('A')),
                  BottomBarItem(icon: Icon(Icons.search), label: Text('B')),
                ],
              ),
              body: shell,
            ),
          ),
          branches: [
            for (final path in ['a', 'b'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/$path',
                    builder: (_, _) => Text('$path root'),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (_, _) => Material(
                          child: TextField(key: ValueKey('$path field')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/a/detail');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('a field')), 'branch a');
    await tester.tap(
      find
          .descendant(of: find.byType(BottomBarItems), matching: find.text('B'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();
    router.push('/b/detail');
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('b field')), 'branch b');
    for (final width in [900.0, 400.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('branch b'), findsOneWidget);
      expect(
        tester
            .widget<BottomBarItems>(find.byType(BottomBarItems))
            .selectedIndex,
        1,
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(BottomBarItems),
              matching: find.text('A'),
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('branch a'), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(BottomBarItems),
              matching: find.text('B'),
            )
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('branch b'), findsOneWidget);
    }
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('b root'), findsOneWidget);
    await tester.tap(
      find
          .descendant(of: find.byType(BottomBarItems), matching: find.text('A'))
          .hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('branch a'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('a root'), findsOneWidget);
  });
}
