import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _branches = [('/a', 'A'), ('/b', 'B'), ('/c', 'C')];

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/a',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(
          body: BottomBarAdaptive(
            items: BottomBarItems(
              selectedIndex: shell.currentIndex,
              onSelected: shell.goBranch,
              children: const [
                BottomBarItem(
                  icon: Icon(Icons.circle_outlined),
                  label: Text('A'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.circle_outlined),
                  label: Text('B'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.circle_outlined),
                  label: Text('C'),
                ),
              ],
            ),
            body: shell,
          ),
        ),
        branches: [
          for (final (path, label) in _branches)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: path,
                  builder: (_, _) => ListView.builder(
                    key: PageStorageKey<String>(path),
                    itemCount: 50,
                    itemBuilder: (context, i) =>
                        ListTile(title: Text('$label row $i')),
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(of: find.byType(BottomBarItems), matching: find.text(label))
        .hitTestable(),
  );
  await tester.pumpAndSettle();
}

double _offset(WidgetTester tester, String path) {
  return tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(PageStorageKey<String>(path)),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position
      .pixels;
}

void main() {
  testWidgets('branch state and selection survive the bar-to-rail switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = _buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await _tapTab(tester, 'B');
    expect(find.text('B row 0'), findsOneWidget);

    await tester.drag(
      find.byKey(PageStorageKey<String>('/b')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    final offset = _offset(tester, '/b');
    expect(offset, greaterThan(0));

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();
    expect(find.byType(BottomBar), findsNothing);
    expect(find.byKey(PageStorageKey<String>('/b')), findsOneWidget);
    expect(_offset(tester, '/b'), offset);

    await _tapTab(tester, 'C');
    expect(find.byKey(PageStorageKey<String>('/c')), findsOneWidget);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(find.byType(BottomBar), findsOneWidget);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).selectedIndex,
      2,
    );
  });
}
