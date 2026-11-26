import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

final badgesFeature = GoldenFeature(
  'Badges',
  readme: 'badges',
  demo: 'badged-nav',
  cases: [
    GoldenCase(
      'badge',
      caption: 'Dot, count, label and outlined count badges on the tabs',
      shots: const [Shot.light, Shot.dark, Shot.rtl, Shot.text2x],
      build: (shot) => goldenApp(
        shot,
        Scaffold(
          body: Builder(
            builder: (context) => BottomBar(
              body: const SizedBox.shrink(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BottomBarItems(
                  selectedIndex: 0,
                  children: [
                    BottomBarItem(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home),
                      label: const Text('Home'),
                      badge: const BottomBarBadge.dot(),
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                      badge: const BottomBarBadge.count(3),
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.inbox_outlined),
                      selectedIcon: const Icon(Icons.inbox),
                      label: const Text('Inbox'),
                      badge: const BottomBarBadge.count(150),
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Updates'),
                      badge: const BottomBarBadge.label('New'),
                    ),
                    BottomBarItem(
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Profile'),
                      badge: BottomBarBadge.count(
                        7,
                        outline: BorderSide(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);
