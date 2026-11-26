import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

class LongLabelsRecipe extends StatefulWidget {
  const LongLabelsRecipe({super.key});

  @override
  State<LongLabelsRecipe> createState() => _LongLabelsRecipeState();
}

class _LongLabelsRecipeState extends State<LongLabelsRecipe> {
  static const _tabs = [
    (Icons.home_outlined, 'Home overview'),
    (Icons.bookmark_outline, 'Saved recipes'),
    (Icons.insights_outlined, 'Weekly progress'),
    (Icons.notifications_none, 'Notifications center'),
    (Icons.settings_outlined, 'Account settings'),
  ];

  int _index = 0;
  bool _largeText = false;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: _largeText
          ? media.copyWith(textScaler: const TextScaler.linear(2))
          : media,
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_tabs[_index].$2),
            actions: [
              IconButton(
                tooltip: 'Text size 2x',
                isSelected: _largeText,
                onPressed: () => setState(() => _largeText = !_largeText),
                icon: const Icon(Icons.format_size),
              ),
              IconButton(
                tooltip: 'Right to left',
                isSelected: _rtl,
                onPressed: () => setState(() => _rtl = !_rtl),
                icon: const Icon(Icons.format_textdirection_r_to_l),
              ),
            ],
          ),
          body: BottomBar(
            layout: const BottomBarLayout.adaptive(maxWidth: 480),
            body: BottomBarBodyPadding(
              child: ListView.builder(
                itemCount: 30,
                itemBuilder: (context, i) =>
                    ListTile(title: Text('${_tabs[_index].$2} ${i + 1}')),
              ),
            ),
            child: BottomBarItems(
              selectedIndex: _index,
              onSelected: (i) => setState(() => _index = i),
              indicator: const BottomBarIndicator.pill(),
              children: [
                for (final (icon, label) in _tabs)
                  BottomBarItem(icon: Icon(icon), label: Text(label)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
