import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class AdaptiveNavigationDemoPage extends StatefulWidget {
  const AdaptiveNavigationDemoPage({super.key});

  @override
  State<AdaptiveNavigationDemoPage> createState() =>
      _AdaptiveNavigationDemoPageState();
}

class _AdaptiveNavigationDemoPageState
    extends State<AdaptiveNavigationDemoPage> {
  static const _destinations = [
    _Destination(
      label: 'Home overview',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      description: 'A quick view of today and the activity that needs you.',
    ),
    _Destination(
      label: 'Saved recipes',
      icon: Icons.bookmark_outline,
      selectedIcon: Icons.bookmark,
      description: 'Recipes you saved to come back to later.',
    ),
    _Destination(
      label: 'Weekly progress',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      description: 'Your progress across the current week.',
    ),
    _Destination(
      label: 'Notifications center',
      icon: Icons.notifications_none,
      selectedIcon: Icons.notifications,
      description: 'Updates and reminders that are ready for your attention.',
    ),
    _Destination(
      label: 'Account settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      description: 'Preferences, profile details, and account controls.',
    ),
  ];

  int _selectedIndex = 0;
  bool _isRtl = false;
  bool _largeText = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaler = _largeText && mediaQuery.textScaler.scale(1) < 2
        ? const TextScaler.linear(2)
        : mediaQuery.textScaler;

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: textScaler),
      child: Directionality(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Adaptive navigation'),
            actions: [
              IconButton(
                tooltip: 'Toggle right-to-left layout',
                icon: Icon(
                  _isRtl
                      ? Icons.format_textdirection_r_to_l
                      : Icons.format_textdirection_l_to_r,
                ),
                onPressed: () => setState(() => _isRtl = !_isRtl),
              ),
              IconButton(
                tooltip: 'Toggle large text preview',
                icon: Icon(
                  _largeText ? Icons.text_increase : Icons.text_fields,
                ),
                onPressed: () => setState(() => _largeText = !_largeText),
              ),
            ],
          ),
          body: BottomBar(
            layout: const BottomBarLayout.adaptive(
              maxWidth: 420,
              offset: 8,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            theme: BottomBarThemeData(
              barDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                Text(
                  'Five destinations stay reachable as labels wrap at narrow widths.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _DestinationContent(destination: _destinations[_selectedIndex]),
                const SizedBox(height: 24),
                const BottomBarBodyPadding(child: SizedBox(height: 8)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale = MediaQuery.of(context).textScaler.scale(1);
                  final itemWidth = (72 * textScale)
                      .clamp(88.0, constraints.maxWidth)
                      .toDouble();

                  if (textScale >= 1.5) {
                    final maxNavigationHeight = constraints.hasBoundedHeight
                        ? constraints.maxHeight
                        : MediaQuery.sizeOf(context).height;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxNavigationHeight,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var index = 0;
                              index < _destinations.length;
                              index++
                            ) ...[
                              _LargeTextNavigationItem(
                                destination: _destinations[index],
                                selected: _selectedIndex == index,
                                onTap: () =>
                                    setState(() => _selectedIndex = index),
                              ),
                              if (index != _destinations.length - 1)
                                const SizedBox(height: 4),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (var index = 0; index < _destinations.length; index++)
                        SizedBox(
                          width: itemWidth,
                          child: BottomBarItem(
                            icon: Icon(_destinations[index].icon),
                            selectedIcon: Icon(
                              _destinations[index].selectedIcon,
                            ),
                            label: Text(
                              _destinations[index].label,
                              textAlign: TextAlign.center,
                            ),
                            semanticLabel: _destinations[index].label,
                            selected: _selectedIndex == index,
                            onTap: () => setState(() => _selectedIndex = index),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LargeTextNavigationItem extends StatelessWidget {
  const _LargeTextNavigationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = selected ? destination.selectedIcon : destination.icon;

    return ListTile(
      key: ValueKey('adaptive-navigation-${destination.label}'),
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      minTileHeight: 48,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon),
      title: Text(destination.label),
      onTap: onTap,
    );
  }
}

class _DestinationContent extends StatelessWidget {
  const _DestinationContent({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(destination.label),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(destination.selectedIcon, size: 40),
            const SizedBox(height: 16),
            Text(
              destination.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(destination.description),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.description,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String description;
}
