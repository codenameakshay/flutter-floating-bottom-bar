import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class MiniPlayerRecipe extends StatefulWidget {
  const MiniPlayerRecipe({super.key});

  @override
  State<MiniPlayerRecipe> createState() => _MiniPlayerRecipeState();
}

class _MiniPlayerRecipeState extends State<MiniPlayerRecipe> {
  int _index = 0;
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini player')),
      body: BottomBar(
        theme: BottomBarThemeData.glass(),
        scrollBehavior: const BottomBarScrollBehavior(
          minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
        ),
        accessory: NowPlaying(
          playing: _playing,
          onToggle: () => setState(() => _playing = !_playing),
        ),
        body: BottomBarBodyPadding(
          child: ListView.builder(
            itemCount: 40,
            itemBuilder: (context, i) => ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: Text('Track ${i + 1}'),
            ),
          ),
        ),
        child: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          children: const [
            BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
            BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
            BottomBarItem(
              icon: Icon(Icons.library_music),
              label: Text('Library'),
            ),
          ],
        ),
      ),
    );
  }
}

class NowPlaying extends StatelessWidget {
  const NowPlaying({required this.playing, required this.onToggle, super.key});

  final bool playing;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final expanded =
        BottomBarAccessoryPlacement.of(context) ==
        BottomBarAccessoryPlacement.expanded;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Row(
        children: [
          Icon(Icons.album, size: expanded ? 40 : 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expanded ? 'Midnight Drive · The Lanterns' : 'Midnight Drive',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: playing ? 'Pause' : 'Play',
            onPressed: onToggle,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          ),
          if (expanded)
            IconButton(
              tooltip: 'Next',
              onPressed: () {},
              icon: const Icon(Icons.skip_next),
            ),
        ],
      ),
    );
  }
}
