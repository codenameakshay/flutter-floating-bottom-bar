import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class MinimizeDemoPage extends StatefulWidget {
  const MinimizeDemoPage({super.key});

  @override
  State<MinimizeDemoPage> createState() => _MinimizeDemoPageState();
}

class _MinimizeDemoPageState extends State<MinimizeDemoPage> {
  final _controller = BottomBarController();
  BottomBarMinimizeBehavior _mode = BottomBarMinimizeBehavior.onScrollDown;
  bool _nowPlaying = false;
  bool _leading = false;
  bool _trailing = false;
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _nowPlayingPill(ColorScheme colorScheme) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, end: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.music_note_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Midnight City',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.pause_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<BottomBarMinimizeBehavior>(
              segments: const [
                ButtonSegment(
                  value: BottomBarMinimizeBehavior.never,
                  label: Text('Never'),
                ),
                ButtonSegment(
                  value: BottomBarMinimizeBehavior.onScrollDown,
                  label: Text('Scroll down'),
                ),
                ButtonSegment(
                  value: BottomBarMinimizeBehavior.onScrollUp,
                  label: Text('Scroll up'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            SwitchListTile(
              title: const Text('Now playing pill'),
              value: _nowPlaying,
              onChanged: (value) => setState(() => _nowPlaying = value),
            ),
            SwitchListTile(
              title: const Text('Leading piece'),
              value: _leading,
              onChanged: (value) => setState(() => _leading = value),
            ),
            SwitchListTile(
              title: const Text('Trailing search'),
              value: _trailing,
              onChanged: (value) => setState(() => _trailing = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimize on scroll'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ValueListenableBuilder<BottomBarVisibility>(
              valueListenable: _controller.visibility,
              builder: (_, v, _) => Text('State: ${v.name}'),
            ),
          ),
        ),
      ),
      body: BottomBar(
        controller: _controller,
        theme: BottomBarThemeData.glass(),
        scrollBehavior: BottomBarScrollBehavior(minimizeBehavior: _mode),
        compactChild: _nowPlaying ? _nowPlayingPill(colorScheme) : null,
        leading: _leading
            ? IconButton(
                tooltip: 'Account',
                onPressed: () {},
                icon: const Icon(Icons.account_circle_outlined),
              )
            : null,
        trailing: _trailing
            ? IconButton(
                tooltip: 'Search',
                onPressed: () {},
                icon: const Icon(Icons.search_rounded),
              )
            : null,
        body: BottomBarBodyPadding(
          child: ListView(
            children: [
              _buildControls(),
              for (var i = 0; i < 40; i++) _FeedCard(index: i),
            ],
          ),
        ),
        child: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          children: const [
            BottomBarItem(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: Text('Home'),
              badge: BottomBarBadge.dot(),
            ),
            BottomBarItem(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: Text('Explore'),
            ),
            BottomBarItem(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: Text('Inbox'),
              badge: BottomBarBadge.count(3),
            ),
            BottomBarItem(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: Text('Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final hue = ((index * 37) % 360).toDouble();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: HSLColor.fromAHSL(1, hue, 0.75, 0.55).toColor(),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        title: Text('Post $index'),
        subtitle: Text('A short line of text for post $index'),
      ),
    );
  }
}
