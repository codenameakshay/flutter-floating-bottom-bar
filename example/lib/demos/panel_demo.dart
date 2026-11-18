import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class PanelDemoPage extends StatefulWidget {
  const PanelDemoPage({super.key});

  @override
  State<PanelDemoPage> createState() => _PanelDemoPageState();
}

class _PanelDemoPageState extends State<PanelDemoPage> {
  int _index = 0;

  Future<void> _openCreate() async {
    final value = await showBottomBarPanel<String>(
      context,
      semanticLabel: 'Create',
      builder: (_) => const _CreatePanel(),
    );
    if (value == null || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Created $value')));
  }

  void _openMore(BuildContext context) {
    showBottomBarPanel<void>(
      context,
      semanticLabel: 'More',
      maxHeight: 0.85,
      builder: (_) => const _MorePanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Colors.primaries;
    return Scaffold(
      appBar: AppBar(title: const Text('Expand into a panel')),
      body: BottomBar(
        theme: BottomBarThemeData.glass(),
        trailing: Builder(
          builder: (context) => IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _openMore(context),
          ),
        ),
        body: BottomBarBodyPadding(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: 40,
            itemBuilder: (context, i) => DecoratedBox(
              decoration: BoxDecoration(
                color: colors[i % colors.length].shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomBarItems(
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            indicator: const BottomBarIndicator.pill(),
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              semanticLabel: 'Create',
              onPressed: _openCreate,
            ),
            children: const [
              BottomBarItem(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              BottomBarItem(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: Text('Explore'),
              ),
              BottomBarItem(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: Text('Inbox'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _CreateAction = ({String label, IconData icon});

const _createActions = <_CreateAction>[
  (label: 'Photo', icon: Icons.photo_camera_outlined),
  (label: 'Note', icon: Icons.edit_note),
  (label: 'Event', icon: Icons.event),
  (label: 'Link', icon: Icons.link),
];

class _CreatePanel extends StatefulWidget {
  const _CreatePanel();

  @override
  State<_CreatePanel> createState() => _CreatePanelState();
}

class _CreatePanelState extends State<_CreatePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _action(BuildContext context, int i, _CreateAction action) {
    final begin = i * 0.12;
    final end = (0.6 + i * 0.12).clamp(0.0, 1.0);
    final t = Interval(
      begin,
      end,
      curve: Curves.easeOutBack,
    ).transform(_controller.value);
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - t)),
        child: Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.filledTonal(
                iconSize: 28,
                icon: Icon(action.icon),
                onPressed: () => Navigator.of(context).pop(action.label),
              ),
              const SizedBox(height: 8),
              Text(action.label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (var i = 0; i < _createActions.length; i++)
              _action(context, i, _createActions[i]),
          ],
        ),
      ),
    );
  }
}

class _MorePanel extends StatefulWidget {
  const _MorePanel();

  @override
  State<_MorePanel> createState() => _MorePanelState();
}

class _MorePanelState extends State<_MorePanel> {
  static const _items = [
    'Settings',
    'Downloads',
    'Favourites',
    'History',
    'Shared with you',
    'Archive',
    'Trash',
    'Help',
    'Feedback',
    'About',
    'Privacy',
    'Accounts',
    'Storage',
    'Notifications',
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final item in _items)
        if (item.toLowerCase().contains(query)) item,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'More',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              for (final item in shown)
                ListTile(
                  title: Text(item),
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
