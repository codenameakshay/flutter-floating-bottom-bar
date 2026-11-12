import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';

const branchRoots = ['/home', '/search', '/inbox', '/profile'];

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ScaffoldWithBottomBar(
        location: state.uri.path,
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const HomePage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      DetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/search', builder: (_, _) => const SearchPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (_, _) => const InboxPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) =>
                      DetailPage(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithBottomBar extends StatefulWidget {
  const ScaffoldWithBottomBar({
    required this.location,
    required this.navigationShell,
    super.key,
  });

  final String location;
  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithBottomBar> createState() => _ScaffoldWithBottomBarState();
}

class _ScaffoldWithBottomBarState extends State<ScaffoldWithBottomBar> {
  final _bar = BottomBarController();

  @override
  void didUpdateWidget(ScaffoldWithBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell.currentIndex !=
        oldWidget.navigationShell.currentIndex) {
      _bar.show();
    }
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final atRoot = widget.location == branchRoots[shell.currentIndex];
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: BottomBar(
          controller: _bar,
          layout: const BottomBarLayout.adaptive(maxWidth: 420, offset: 16),
          body: shell,
          child: BottomBarItems(
            selectedIndex: shell.currentIndex,
            indicator: const BottomBarIndicator.pill(),
            scrollToStartOnReselect: atRoot,
            onReselected: (i) {
              if (!atRoot) shell.goBranch(i, initialLocation: true);
            },
            onSelected: (i) {
              if (i != shell.currentIndex) shell.goBranch(i);
            },
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
              BottomBarItem(
                icon: Icon(Icons.inbox),
                label: Text('Inbox'),
                badge: BottomBarBadge.count(3),
              ),
              BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
        ),
      ),
    );
  }
}

// Stub pages for the recipe compile test.
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Recipe Home'));
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Recipe Search'));
}

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Recipe Inbox'));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Recipe Profile'));
}

class DetailPage extends StatelessWidget {
  const DetailPage({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('Recipe detail $id'));
}
