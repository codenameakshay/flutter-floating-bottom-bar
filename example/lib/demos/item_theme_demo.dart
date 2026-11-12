import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

/// Muted M3 tones, a tint indicator and a tighter icon-label gap.
BottomBarItemThemeData quietItemTheme(ColorScheme cs) => BottomBarItemThemeData(
  color: cs.onSurfaceVariant,
  selectedColor: cs.onSecondaryContainer,
  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
  iconLabelGap: 4,
  indicator: BottomBarIndicator.tint(
    color: cs.secondaryContainer,
    foregroundColor: cs.onSecondaryContainer,
  ),
);

/// Heavier labels, larger selected icons, a press scale and a stretching pill.
BottomBarItemThemeData boldItemTheme(ColorScheme cs) => BottomBarItemThemeData(
  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  selectedLabelStyle: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
  ),
  iconSize: 22,
  selectedIconSize: 24,
  pressedScale: 0.9,
  indicator: BottomBarIndicator.pill(color: cs.tertiary, stretch: true),
);

/// Outline colours, larger icons, no ripple and a dot indicator.
BottomBarItemThemeData iconOnlyItemTheme(ColorScheme cs) =>
    BottomBarItemThemeData(
      color: cs.outline,
      selectedColor: cs.primary,
      iconSize: 26,
      selectedIconSize: 30,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      indicator: const BottomBarIndicator.dot(),
    );

const _tabs = <BottomBarItem>[
  BottomBarItem(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: Text('Home'),
  ),
  BottomBarItem(
    icon: Icon(Icons.search),
    selectedIcon: Icon(Icons.search),
    label: Text('Search'),
  ),
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
];

class ItemThemeDemoPage extends StatefulWidget {
  const ItemThemeDemoPage({super.key});

  @override
  State<ItemThemeDemoPage> createState() => _ItemThemeDemoPageState();
}

class _ItemThemeDemoPageState extends State<ItemThemeDemoPage> {
  int _quietIndex = 0;
  int _boldIndex = 0;
  int _iconOnlyIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Item theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ThemeCard(
            title: 'Quiet M3',
            description:
                'Sets muted M3 colours, a tint indicator and a 4 px icon-label gap.',
            child: _bar(
              theme: quietItemTheme(cs),
              labelBehavior: BottomBarLabelBehavior.alwaysShow,
              selectedIndex: _quietIndex,
              onSelected: (i) => setState(() => _quietIndex = i),
            ),
          ),
          _ThemeCard(
            title: 'Bold pill',
            description:
                'Sets heavier labels, larger selected icons, a press scale and a stretching pill.',
            child: _bar(
              theme: boldItemTheme(cs),
              labelBehavior: BottomBarLabelBehavior.onlySelected,
              selectedIndex: _boldIndex,
              onSelected: (i) => setState(() => _boldIndex = i),
            ),
          ),
          _ThemeCard(
            title: 'Icon only, no ripple',
            description:
                'Sets outline colours, larger icons, no ripple and a dot indicator. Labels stay for accessibility.',
            child: _bar(
              theme: iconOnlyItemTheme(cs),
              labelBehavior: BottomBarLabelBehavior.alwaysHide,
              selectedIndex: _iconOnlyIndex,
              onSelected: (i) => setState(() => _iconOnlyIndex = i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({
    required BottomBarItemThemeData theme,
    required BottomBarLabelBehavior labelBehavior,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return SizedBox(
      height: 96,
      child: BottomBar(
        theme: BottomBarThemeData(items: theme),
        body: const SizedBox.shrink(),
        child: BottomBarItems(
          selectedIndex: selectedIndex,
          onSelected: onSelected,
          labelBehavior: labelBehavior,
          children: _tabs,
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description, style: textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
