import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class GlassSurfaceDemoPage extends StatefulWidget {
  const GlassSurfaceDemoPage({super.key});

  @override
  State<GlassSurfaceDemoPage> createState() => _GlassSurfaceDemoPageState();
}

class _GlassSurfaceDemoPageState extends State<GlassSurfaceDemoPage> {
  int _index = 0;
  double _blur = 16;
  double _opacity = 0.8;
  bool _glass = true;
  bool _highlight = true;
  bool _notched = false;
  bool _highContrast = false;
  bool _scrollEdge = false;
  bool _shortList = false;

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Blur ${_blur.round()}'),
            Slider(
              min: 0,
              max: 40,
              value: _blur,
              onChanged: (value) => setState(() => _blur = value),
            ),
            Text('Tint opacity ${(_opacity * 100).round()}%'),
            Slider(
              value: _opacity,
              onChanged: (value) => setState(() => _opacity = value),
            ),
            SwitchListTile(
              title: const Text('Edge highlight'),
              value: _highlight,
              onChanged: (value) => setState(() => _highlight = value),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Glass')),
                  ButtonSegment(value: false, label: Text('Solid')),
                ],
                selected: {_glass},
                onSelectionChanged: (selection) =>
                    setState(() => _glass = selection.first),
              ),
            ),
            SwitchListTile(
              title: const Text('Notched centre action'),
              value: _notched,
              onChanged: (value) => setState(() => _notched = value),
            ),
            SwitchListTile(
              title: const Text('High contrast'),
              value: _highContrast,
              onChanged: (value) => setState(() => _highContrast = value),
            ),
            SwitchListTile(
              title: const Text('Clear at scroll end'),
              value: _scrollEdge,
              onChanged: (value) => setState(() => _scrollEdge = value),
            ),
            SwitchListTile(
              title: const Text('Short list'),
              value: _shortList,
              onChanged: (value) => setState(() => _shortList = value),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = _glass
        ? BottomBarSurface.glass(
            blur: _blur,
            fillOpacity: _opacity,
            edgeHighlight: _highlight ? const Color(0x59FFFFFF) : null,
          )
        : const BottomBarSurface.solid();

    return Scaffold(
      appBar: AppBar(title: const Text('Glass surface')),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: _highContrast),
        child: BottomBar(
          layout: const BottomBarLayout(
            width: 360,
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          // A bar that hides on scroll is gone by the time the list ends.
          scrollBehavior: BottomBarScrollBehavior(hideOnScroll: !_scrollEdge),
          theme: BottomBarThemeData(
            surface: surface,
            scrollEdgeSurface: _scrollEdge
                ? const BottomBarSurface(fillOpacity: 0)
                : null,
          ),
          // The feed scrolls under the bar, so only its end is padded.
          body: Builder(
            builder: (context) => ValueListenableBuilder<double>(
              valueListenable: BottomBarScope.of(context).barHeight,
              builder: (context, barHeight, _) => ListView.builder(
                padding: EdgeInsets.only(bottom: barHeight),
                itemCount: _shortList ? 1 : 61,
                itemBuilder: (context, index) =>
                    index == 0 ? _buildControls() : _FeedTile(index: index - 1),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: BottomBarItems(
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
              indicator: const BottomBarIndicator.pill(),
              centerAction: _notched
                  ? BottomBarCenterAction(
                      icon: const Icon(Icons.add),
                      tooltip: 'Create',
                      style: BottomBarCenterActionStyle.notched,
                      onPressed: () {},
                    )
                  : null,
              children: const [
                BottomBarItem(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                BottomBarItem(icon: Icon(Icons.search), label: Text('Search')),
                BottomBarItem(
                  icon: Icon(Icons.inbox_outlined),
                  selectedIcon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final isWhite = index % 5 == 0;
    final isBlack = !isWhite && index % 7 == 0;
    final plain = isWhite || isBlack;
    final textColor = isWhite ? Colors.black : Colors.white;
    final hueA = ((index * 37) % 360).toDouble();
    final hueB = ((index * 37 + 60) % 360).toDouble();

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white
            : isBlack
            ? Colors.black
            : null,
        gradient: plain
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HSLColor.fromAHSL(1, hueA, 0.75, 0.55).toColor(),
                  HSLColor.fromAHSL(1, hueB, 0.75, 0.55).toColor(),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: Text(
              'Card $index',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
