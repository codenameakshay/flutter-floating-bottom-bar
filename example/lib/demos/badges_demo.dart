import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class BadgesDemoPage extends StatefulWidget {
  const BadgesDemoPage({super.key});

  @override
  State<BadgesDemoPage> createState() => _BadgesDemoPageState();
}

class _BadgesDemoPageState extends State<BadgesDemoPage> {
  int _index = 0;
  int _unread = 3;
  bool _homeDot = true;
  bool _profileNew = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges demo')),
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: 420,
          offset: 16,
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.bouncy,
          extraBounce: 0.02,
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
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inbox count: $_unread',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => setState(() => _unread += 1),
                          child: const Text('Add 1'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => setState(() => _unread += 50),
                          child: const Text('Add 50'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => setState(() => _unread = 0),
                          child: const Text('Clear'),
                        ),
                        FilledButton.tonal(
                          onPressed: () => setState(() => _homeDot = !_homeDot),
                          child: const Text('Toggle dot'),
                        ),
                        FilledButton.tonal(
                          onPressed: () =>
                              setState(() => _profileNew = !_profileNew),
                          child: const Text('Toggle New'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < 40; i++) ListTile(title: Text('Message $i')),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomBarItems(
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            indicator: const BottomBarIndicator.pill(),
            children: [
              BottomBarItem(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: const Text('Home'),
                badge: BottomBarBadge.dot(show: _homeDot),
              ),
              BottomBarItem(
                icon: const Icon(Icons.inbox_outlined),
                selectedIcon: const Icon(Icons.inbox),
                label: const Text('Inbox'),
                badge: BottomBarBadge.count(
                  _unread,
                  semanticLabel: '$_unread new',
                ),
              ),
              BottomBarItem(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: const Text('Profile'),
                badge: BottomBarBadge.label('New', show: _profileNew),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
