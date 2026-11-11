import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

enum _Style {
  pill('Pill'),
  stretch('Stretch'),
  tint('Tint'),
  underline('Underline'),
  dot('Dot'),
  tubelight('Tubelight');

  const _Style(this.label);
  final String label;
}

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
    _Style.tint => const BottomBarIndicator.tint(stretch: true),
    _Style.underline => const BottomBarIndicator.underline(),
    _Style.dot => const BottomBarIndicator.dot(),
    _Style.tubelight => BottomBarIndicator.builder(
      (context, rect, settled) =>
          _Tubelight(rect: rect, color: Theme.of(context).colorScheme.primary),
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
              child: Wrap(
                key: const Key('indicator-style'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in _Style.values)
                    ChoiceChip(
                      label: Text(style.label),
                      selected: style == _style,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _style = style),
                    ),
                ],
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

/// A lit bar on the bar's top edge that casts a soft beam down onto the
/// selected item.
class _Tubelight extends StatelessWidget {
  const _Tubelight({required this.rect, required this.color});

  /// Reach above the content, up to the bar's top edge.
  static const _rise = 12.0;

  final Rect rect;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.bottomCenter,
      minWidth: 0,
      minHeight: 0,
      maxWidth: rect.width + 12,
      maxHeight: rect.height + _rise,
      child: CustomPaint(
        size: Size(rect.width + 12, rect.height + _rise),
        painter: _TubelightPainter(color),
      ),
    );
  }
}

class _TubelightPainter extends CustomPainter {
  const _TubelightPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const lampWidth = 32.0;
    final left = (size.width - lampWidth) / 2;
    final beam = Path()
      ..moveTo(left, 2)
      ..lineTo(left + lampWidth, 2)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    final lamp = RRect.fromLTRBR(
      left,
      0,
      left + lampWidth,
      4,
      const Radius.circular(2),
    );
    canvas.drawRRect(
      lamp.inflate(3),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(lamp, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TubelightPainter oldDelegate) =>
      oldDelegate.color != color;
}
