import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class AccessoryDemoPage extends StatefulWidget {
  const AccessoryDemoPage({super.key});

  @override
  State<AccessoryDemoPage> createState() => _AccessoryDemoPageState();
}

class _AccessoryDemoPageState extends State<AccessoryDemoPage> {
  final _controller = BottomBarController();
  BottomBarMinimizeBehavior _mode = BottomBarMinimizeBehavior.onScrollDown;
  bool _docked = false;
  bool _playing = true;
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              title: const Text('Docked'),
              value: _docked,
              onChanged: (value) => setState(() => _docked = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessory'),
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
        layout: _docked ? const BottomBarLayout.docked() : null,
        accessory: _NowPlaying(
          playing: _playing,
          onToggle: () => setState(() => _playing = !_playing),
        ),
        trailing: IconButton(
          tooltip: 'Search',
          onPressed: () {},
          icon: const Icon(Icons.search_rounded),
        ),
        body: BottomBarBodyPadding(
          child: ListView(
            children: [
              _buildControls(),
              for (var i = 0; i < 60; i++)
                ListTile(
                  leading: const Icon(Icons.music_note_outlined),
                  title: Text('Track ${i + 1}'),
                  subtitle: const Text('Artist'),
                ),
            ],
          ),
        ),
        child: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          children: const [
            BottomBarItem(icon: Icon(Icons.home_rounded), label: Text('Home')),
            BottomBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: Text('New'),
            ),
            BottomBarItem(
              icon: Icon(Icons.radio_rounded),
              label: Text('Radio'),
            ),
            BottomBarItem(
              icon: Icon(Icons.library_music_rounded),
              label: Text('Library'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.playing, required this.onToggle});

  final bool playing;
  final VoidCallback onToggle;

  Widget _artwork(ColorScheme colorScheme, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: size / 2,
            ),
          ),
        ),
      ),
    );
  }

  IconButton _playButton() {
    return IconButton(
      tooltip: playing ? 'Pause' : 'Play',
      onPressed: onToggle,
      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placement = BottomBarAccessoryPlacement.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return switch (placement) {
      BottomBarAccessoryPlacement.expanded => SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
          child: Row(
            children: [
              _artwork(colorScheme, 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Midnight City',
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'M83',
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _playButton(),
              IconButton(
                tooltip: 'Next',
                onPressed: () {},
                icon: const Icon(Icons.fast_forward_rounded),
              ),
            ],
          ),
        ),
      ),
      BottomBarAccessoryPlacement.inline => Padding(
        padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
        child: Row(
          children: [_artwork(colorScheme, 32), const Spacer(), _playButton()],
        ),
      ),
    };
  }
}
