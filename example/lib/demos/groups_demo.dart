import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class GroupsDemoPage extends StatefulWidget {
  const GroupsDemoPage({super.key});

  @override
  State<GroupsDemoPage> createState() => _GroupsDemoPageState();
}

class _GroupsDemoPageState extends State<GroupsDemoPage> {
  int _index = 0;
  bool _leading = true;
  bool _trailing = true;
  bool _glass = true;
  bool _rtl = false;

  void _openSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const _SearchPage()));
  }

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Leading profile button'),
            value: _leading,
            onChanged: (value) => setState(() => _leading = value),
          ),
          SwitchListTile(
            title: const Text('Trailing search button'),
            value: _trailing,
            onChanged: (value) => setState(() => _trailing = value),
          ),
          SwitchListTile(
            title: const Text('Glass surface'),
            value: _glass,
            onChanged: (value) => setState(() => _glass = value),
          ),
          SwitchListTile(
            title: const Text('Right to left'),
            value: _rtl,
            onChanged: (value) => setState(() => _rtl = value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: BottomBar(
          layout: const BottomBarLayout.adaptive(
            maxWidth: 480,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          theme: BottomBarThemeData(
            surface: _glass
                ? const BottomBarSurface.glass()
                : const BottomBarSurface.solid(),
          ),
          body: BottomBarBodyPadding(
            child: ListView.builder(
              itemCount: 61,
              itemBuilder: (context, index) =>
                  index == 0 ? _buildControls() : _FeedTile(index: index - 1),
            ),
          ),
          leading: _leading
              ? IconButton(
                  tooltip: 'Profile',
                  icon: const CircleAvatar(
                    radius: 16,
                    child: Text(
                      'JD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onPressed: () {},
                )
              : null,
          trailing: _trailing
              ? IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                  onPressed: _openSearch,
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: BottomBarItems(
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
              indicator: const BottomBarIndicator.pill(),
              children: const [
                BottomBarItem(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.inbox_outlined),
                  selectedIcon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.photo_library_outlined),
                  selectedIcon: Icon(Icons.photo_library),
                  label: Text('Library'),
                ),
                BottomBarItem(
                  icon: Icon(Icons.bookmark_outline),
                  selectedIcon: Icon(Icons.bookmark),
                  label: Text('Saved'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage();

  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  static const _names = [
    'Architecture notes',
    'Budget 2026',
    'Camera roll',
    'Design review',
    'Flight tickets',
    'Groceries',
    'Hiking trip',
    'Music',
    'Recipes',
    'Reading list',
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final results = [
      for (final name in _names)
        if (name.toLowerCase().contains(query)) name,
    ];

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
          ),
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
      ),
      body: ListView(
        children: [for (final name in results) ListTile(title: Text(name))],
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
