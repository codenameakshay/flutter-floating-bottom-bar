import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class AccessibilityDemoPage extends StatefulWidget {
  const AccessibilityDemoPage({super.key});

  @override
  State<AccessibilityDemoPage> createState() => _AccessibilityDemoPageState();
}

class _AccessibilityDemoPageState extends State<AccessibilityDemoPage> {
  double? _scale;
  bool _highContrast = false;
  bool _rtl = false;
  bool _germanStrings = false;
  int _index = 0;
  int _unread = 3;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = _scale;
    final page = MediaQuery(
      data: media.copyWith(
        textScaler: scale == null ? media.textScaler : TextScaler.linear(scale),
        highContrast: _highContrast || media.highContrast,
      ),
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: _buildScaffold(),
      ),
    );
    if (!_germanStrings) return page;
    return Localizations.override(
      context: context,
      locale: const Locale('de'),
      delegates: [
        BottomBarLocalizationsDelegate(_german),
        ...GlobalMaterialLocalizations.delegates,
      ],
      child: page,
    );
  }

  Widget _buildScaffold() {
    final german = _germanStrings;
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: BottomBar(
        theme: BottomBarThemeData.glass(),
        scrollBehavior: BottomBarScrollBehavior(
          minimizeBehavior: BottomBarMinimizeBehavior.onScrollDown,
        ),
        body: BottomBarBodyPadding(
          child: ListView(
            children: [
              _buildControls(),
              for (var i = 1; i <= 40; i++) ListTile(title: Text('Row $i')),
            ],
          ),
        ),
        child: BottomBarItems(
          selectedIndex: _index,
          onSelected: (i) => setState(() => _index = i),
          centerAction: BottomBarCenterAction(
            icon: const Icon(Icons.add),
            tooltip: german ? 'Verfassen' : 'Compose',
            style: BottomBarCenterActionStyle.notched,
            onPressed: () => setState(() => _unread++),
          ),
          children: [
            BottomBarItem(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: Text(german ? 'Start' : 'Home'),
            ),
            BottomBarItem(
              icon: const Icon(Icons.inbox_outlined),
              selectedIcon: const Icon(Icons.inbox),
              label: Text(german ? 'Posteingang' : 'Inbox'),
              badge: BottomBarBadge.count(_unread),
            ),
            BottomBarItem(
              icon: const Icon(Icons.bookmark_border),
              selectedIcon: const Icon(Icons.bookmark),
              label: Text(german ? 'Gemerkt' : 'Saved'),
              badge: const BottomBarBadge.dot(),
            ),
            BottomBarItem(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: Text(german ? 'Profil' : 'Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    final textTheme = Theme.of(context).textTheme;
    final scale = (_scale ?? MediaQuery.textScalerOf(context).scale(10) / 10)
        .clamp(1.0, 3.0);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Text scale', style: textTheme.titleSmall),
            Slider(
              value: scale,
              min: 1,
              max: 3,
              divisions: 8,
              label: '${scale.toStringAsFixed(1)}x',
              semanticFormatterCallback: (value) =>
                  'Text scale ${value.toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _scale = value),
            ),
            SwitchListTile(
              title: const Text('High contrast'),
              value: _highContrast,
              onChanged: (value) => setState(() => _highContrast = value),
            ),
            SwitchListTile(
              title: const Text('Right to left'),
              value: _rtl,
              onChanged: (value) => setState(() => _rtl = value),
            ),
            SwitchListTile(
              title: const Text('German strings'),
              value: _germanStrings,
              onChanged: (value) => setState(() => _germanStrings = value),
            ),
          ],
        ),
      ),
    );
  }
}

BottomBarLocalizations _german(Locale locale) =>
    const _GermanBottomBarLocalizations();

class _GermanBottomBarLocalizations extends BottomBarLocalizations {
  const _GermanBottomBarLocalizations();

  @override
  String get scrollToTop => 'Nach oben scrollen';

  @override
  String get scrollToBottom => 'Nach unten scrollen';

  @override
  String badgeCount(int count) => '$count neu';

  @override
  String badgeCountOverflow(int max) => 'Mehr als $max neu';

  @override
  String get badgeDot => 'Neu';
}
