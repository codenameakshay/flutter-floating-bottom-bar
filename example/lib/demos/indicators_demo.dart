import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

enum _Style { pill, stretch, underline, dot, blob }

class IndicatorsDemoPage extends StatefulWidget {
  const IndicatorsDemoPage({super.key});

  @override
  State<IndicatorsDemoPage> createState() => _IndicatorsDemoPageState();
}

class _IndicatorsDemoPageState extends State<IndicatorsDemoPage> {
  int _index = 0;
  _Style _style = _Style.pill;

  BottomBarIndicator get _indicator => switch (_style) {
    _Style.pill => const BottomBarIndicator.pill(),
    _Style.stretch => const BottomBarIndicator.pill(stretch: true),
    _Style.underline => const BottomBarIndicator.underline(),
    _Style.dot => const BottomBarIndicator.dot(),
    _Style.blob => BottomBarIndicator.builder(
      (context, rect, settled) => OverflowBox(
        maxWidth: rect.width + 12,
        maxHeight: rect.height + 12,
        child: SizedBox(
          width: rect.width + 12,
          height: rect.height + 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC2E0), Color(0xFFC7D2FE)],
              ),
            ),
          ),
        ),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indicators')),
      body: BottomBar(
        layout: const BottomBarLayout.adaptive(
          maxWidth: 420,
          offset: 16,
          borderRadius: BorderRadius.all(Radius.circular(28)),
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<_Style>(
                key: const Key('indicator-style'),
                segments: const [
                  ButtonSegment(value: _Style.pill, label: Text('Pill')),
                  ButtonSegment(value: _Style.stretch, label: Text('Stretch')),
                  ButtonSegment(
                    value: _Style.underline,
                    label: Text('Underline'),
                  ),
                  ButtonSegment(value: _Style.dot, label: Text('Dot')),
                  ButtonSegment(value: _Style.blob, label: Text('Blob')),
                ],
                selected: {_style},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _style = s.first),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 200,
                itemBuilder: (_, i) => ListTile(title: Text('Row $i')),
              ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomBarItems(
            selectedIndex: _index,
            onSelected: (i) => setState(() => _index = i),
            indicator: _indicator,
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
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: Text('Saved'),
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
    );
  }
}
