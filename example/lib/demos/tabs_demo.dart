import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

typedef _Section = ({String label, IconData icon, int rows});

const _sections = <_Section>[
  (label: 'Inbox', icon: Icons.inbox_outlined, rows: 60),
  (label: 'Starred', icon: Icons.star_outline, rows: 4),
  (label: 'Archive', icon: Icons.archive_outlined, rows: 30),
];

enum _Host {
  indexedStack('IndexedStack'),
  pageView('PageView'),
  tabBarView('TabBarView');

  const _Host(this.label);

  final String label;
}

class TabsDemoPage extends StatefulWidget {
  const TabsDemoPage({super.key});

  @override
  State<TabsDemoPage> createState() => _TabsDemoPageState();
}

class _TabsDemoPageState extends State<TabsDemoPage>
    with TickerProviderStateMixin {
  _Host _host = _Host.indexedStack;
  int _index = 0;
  bool _restore = false;
  final _pages = PageController();
  late final _tabs = TabController(length: _sections.length, vsync: this);
  final _bar = BottomBarController();

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_syncTabIndex);
  }

  @override
  void dispose() {
    _tabs.removeListener(_syncTabIndex);
    _tabs.dispose();
    _pages.dispose();
    _bar.dispose();
    super.dispose();
  }

  void _syncTabIndex() {
    if (_tabs.index != _index) setState(() => _index = _tabs.index);
  }

  void _setHost(Set<_Host> selection) {
    setState(() {
      _host = selection.single;
      _index = 0;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
    _tabs.index = 0;
  }

  void _select(int i) {
    switch (_host) {
      case _Host.indexedStack:
        setState(() => _index = i);
      case _Host.pageView:
        _pages.animateToPage(
          i,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        setState(() => _index = i);
      case _Host.tabBarView:
        _tabs.animateTo(i);
        setState(() => _index = i);
    }
  }

  List<Widget> _bodies({required bool keepAlive}) {
    return [
      for (final section in _sections)
        if (keepAlive)
          _KeepAlive(child: _sectionBody(section))
        else
          _sectionBody(section),
    ];
  }

  Widget _sectionBody(_Section section) {
    return BottomBarBodyPadding(
      child: ListView.builder(
        key: PageStorageKey(section.label),
        itemCount: section.rows,
        itemBuilder: (context, i) =>
            ListTile(title: Text('${section.label} row $i')),
      ),
    );
  }

  Widget _buildHost() {
    return switch (_host) {
      _Host.indexedStack => IndexedStack(
        index: _index,
        children: _bodies(keepAlive: false),
      ),
      _Host.pageView => PageView(
        controller: _pages,
        onPageChanged: (i) => setState(() => _index = i),
        children: _bodies(keepAlive: true),
      ),
      _Host.tabBarView => TabBarView(
        controller: _tabs,
        children: _bodies(keepAlive: true),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabs and pages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<_Host>(
                    segments: [
                      for (final host in _Host.values)
                        ButtonSegment<_Host>(
                          value: host,
                          label: Text(
                            host.label,
                            key: ValueKey('host-${host.name}'),
                          ),
                        ),
                    ],
                    selected: {_host},
                    onSelectionChanged: _setHost,
                  ),
                ),
                Row(
                  children: [
                    Switch(
                      key: const ValueKey('restore-switch'),
                      value: _restore,
                      onChanged: (value) => setState(() => _restore = value),
                    ),
                    const Text('Restore per tab'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: BottomBar(
        controller: _bar,
        layout: const BottomBarLayout.adaptive(
          maxWidth: 420,
          offset: 16,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        scrollBehavior: BottomBarScrollBehavior(
          visibilityOnTabChange: _restore
              ? BottomBarTabVisibility.restore
              : BottomBarTabVisibility.show,
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
          scrollEdgeSurface: const BottomBarSurface(fillOpacity: 0),
        ),
        body: KeyedSubtree(key: ValueKey(_host), child: _buildHost()),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: BottomBarItems(
            selectedIndex: _index,
            indicator: const BottomBarIndicator.pill(),
            scrollToStartOnReselect: true,
            onSelected: _select,
            children: [
              for (final section in _sections)
                BottomBarItem(
                  icon: Icon(section.icon),
                  label: Text(section.label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin<_KeepAlive> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
