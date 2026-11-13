import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _branches = <({String path, String label, IconData icon, bool detail})>[
  (path: '/home', label: 'Home', icon: Icons.home_outlined, detail: true),
  (path: '/search', label: 'Search', icon: Icons.search, detail: false),
  (path: '/inbox', label: 'Inbox', icon: Icons.inbox_outlined, detail: true),
  (
    path: '/profile',
    label: 'Profile',
    icon: Icons.person_outline,
    detail: false,
  ),
];

/// go_router's [StatefulShellRoute.indexedStack] hosted in a [BottomBar].
///
/// The example app already owns the URL and back button, so this demo mounts
/// go_router as a nested [Router]. See [_LocalRouteInformation] and the
/// [PopScope] in [build] for how it stays out of the app's way.
class GoRouterShellDemoPage extends StatefulWidget {
  const GoRouterShellDemoPage({super.key});

  @override
  State<GoRouterShellDemoPage> createState() => _GoRouterShellDemoPageState();
}

class _GoRouterShellDemoPageState extends State<GoRouterShellDemoPage> {
  // Without overridePlatformDefaultLocation go_router starts at the platform's
  // route, which is the outer deep link `/go-router-shell`.
  late final _router = GoRouter(
    initialLocation: _branches.first.path,
    overridePlatformDefaultLocation: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ScaffoldWithBottomBar(
          location: state.uri.path,
          navigationShell: navigationShell,
        ),
        branches: [
          for (final branch in _branches)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: branch.path,
                  builder: (_, _) => _ListPage(
                    title: branch.label,
                    root: true,
                    onOpen: branch.detail
                        ? (context, i) => context.go('${branch.path}/$i')
                        : null,
                  ),
                  routes: [
                    if (branch.detail)
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => _ListPage(
                          title:
                              '${branch.label} item ${state.pathParameters['id']}',
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
  late final _routeInformation = _LocalRouteInformation(
    _router.routeInformationProvider,
  );

  // The Router reports its first route while it builds, so this only notifies
  // on a change; it starts true because initialLocation is Home.
  final _atHomeRoot = ValueNotifier(true);

  void _syncAtHomeRoot() => _atHomeRoot.value =
      _router.routerDelegate.currentConfiguration.uri.path ==
      _branches.first.path;

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_syncAtHomeRoot);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_syncAtHomeRoot);
    _router.dispose();
    _atHomeRoot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Back reaches the example app's Navigator first, never the nested
    // Router, so this route hands it to go_router until Home is at its root.
    return ValueListenableBuilder(
      valueListenable: _atHomeRoot,
      builder: (context, atHomeRoot, child) => PopScope(
        canPop: atHomeRoot,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _router.routerDelegate.popRoute();
        },
        child: child!,
      ),
      child: Router(
        routerDelegate: _router.routerDelegate,
        routeInformationParser: _router.routeInformationParser,
        routeInformationProvider: _routeInformation,
      ),
    );
  }
}

/// Feeds go_router's own location to the nested [Router] but drops what the
/// Router reports back, which go_router would send to the platform as the
/// browser URL and history entries.
class _LocalRouteInformation extends RouteInformationProvider {
  _LocalRouteInformation(this._goRouter);

  final RouteInformationProvider _goRouter;

  @override
  RouteInformation get value => _goRouter.value;

  @override
  void addListener(VoidCallback listener) => _goRouter.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _goRouter.removeListener(listener);
}

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
    final atRoot = widget.location == _branches[shell.currentIndex].path;
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: Scaffold(
        body: BottomBar(
          controller: _bar,
          layout: const BottomBarLayout.adaptive(
            maxWidth: 420,
            offset: 16,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          theme: BottomBarThemeData(
            barDecoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            scrollEdgeSurface: shell.currentIndex == 0
                ? const BottomBarSurface(fillOpacity: 0)
                : null,
          ),
          body: shell,
          child: Padding(
            padding: const EdgeInsets.all(8),
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
              children: [
                for (final branch in _branches)
                  BottomBarItem(
                    icon: Icon(branch.icon),
                    label: Text(branch.label),
                    badge: branch.label == 'Inbox'
                        ? const BottomBarBadge.count(3)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListPage extends StatelessWidget {
  const _ListPage({required this.title, this.root = false, this.onOpen});

  final String title;
  final bool root;
  final void Function(BuildContext context, int index)? onOpen;

  @override
  Widget build(BuildContext context) {
    final open = onOpen;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: root
            ? CloseButton(
                onPressed: Navigator.of(context, rootNavigator: true).pop,
              )
            : null,
      ),
      body: BottomBarBodyPadding(
        child: ListView.builder(
          key: PageStorageKey(title),
          itemCount: 60,
          itemBuilder: (context, i) => ListTile(
            title: Text('$title row $i'),
            trailing: open == null ? null : const Icon(Icons.chevron_right),
            onTap: open == null ? null : () => open(context, i),
          ),
        ),
      ),
    );
  }
}
