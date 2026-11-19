import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _tabs = <(IconData, String)>[
  (Icons.home, 'Home'),
  (Icons.inbox, 'Inbox'),
  (Icons.person, 'Profile'),
];

List<BottomBarItem> _items() => [
  for (final tab in _tabs)
    BottomBarItem(icon: Icon(tab.$1), label: Text(tab.$2)),
];

Widget _playRow({VoidCallback? onPlay, bool withText = false}) => SizedBox(
  height: 56,
  child: Row(
    children: [
      if (withText) const Text('Midnight City'),
      IconButton(
        key: const Key('play'),
        tooltip: 'Play',
        onPressed: onPlay ?? () {},
        icon: const Icon(Icons.play_arrow),
      ),
    ],
  ),
);

String? _focusedName() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return null;
  String? name;
  ctx.visitAncestorElements((element) {
    final widget = element.widget;
    if (widget.key == const Key('play')) {
      name = 'play';
      return false;
    }
    if (widget.key == const Key('search')) {
      name = 'search';
      return false;
    }
    if (widget is BottomBarItem) {
      final label = widget.label;
      name = label is Text ? label.data : null;
      return false;
    }
    if (widget is CompactPillButton) {
      name = 'pill';
      return false;
    }
    return true;
  });
  return name;
}

Future<List<String>> _tabOrder(WidgetTester tester, int presses) async {
  final order = <String>[];
  for (var i = 0; i < presses; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final name = _focusedName();
    if (name != null && !order.contains(name)) order.add(name);
  }
  return order;
}

Future<BottomBarController> _pumpBar(
  WidgetTester tester, {
  Widget? accessory,
  BottomBarThemeData? theme,
  bool highContrast = false,
  String? trailingTooltip = 'Search',
  bool leading = false,
}) async {
  tester.view
    ..physicalSize = const Size(400, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = BottomBarController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(highContrast: highContrast),
        child: app!,
      ),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: BottomBar(
            layout: const BottomBarLayout(width: 360),
            controller: controller,
            theme:
                theme ??
                const BottomBarThemeData(surface: BottomBarSurface.glass()),
            accessory: accessory,
            leading: leading
                ? IconButton(
                    key: const Key('profile'),
                    tooltip: 'Profile',
                    onPressed: () {},
                    icon: const Icon(Icons.person),
                  )
                : null,
            trailing: IconButton(
              key: const Key('search'),
              tooltip: trailingTooltip,
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            body: const SizedBox.expand(),
            child: BottomBarItems(
              selectedIndex: 0,
              onSelected: (_) {},
              children: _items(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Iterable<String> _spoken(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .expand((node) => [node.label, node.tooltip])
      .where((text) => text.isNotEmpty);
}

int _indexWhere(List<String> labels, bool Function(String) test) {
  return labels.indexWhere(test);
}

void main() {
  testWidgets('an inline tap runs the accessory control and does not expand', (
    tester,
  ) async {
    var taps = 0;
    final controller = await _pumpBar(
      tester,
      accessory: _playRow(onPlay: () => taps++),
    );

    controller.minimize();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('play')));
    await tester.pumpAndSettle();

    expect(taps, 1, reason: 'the inline play button runs once per tap');
    expect(
      controller.visibility.value,
      BottomBarVisibility.minimized,
      reason: 'tapping the inline accessory must not expand the bar',
    );
  });

  testWidgets('expanded Tab order is accessory, then items, then trailing', (
    tester,
  ) async {
    await _pumpBar(tester, accessory: _playRow());

    final order = await _tabOrder(tester, 8);
    expect(order, const [
      'play',
      'Home',
      'Inbox',
      'Profile',
      'search',
    ], reason: 'expanded focus order must follow the visual reading order');
  });

  testWidgets('minimized Tab order is pill, then accessory, then trailing', (
    tester,
  ) async {
    final controller = await _pumpBar(tester, accessory: _playRow());

    controller.minimize();
    await tester.pumpAndSettle();

    final order = await _tabOrder(tester, 8);
    expect(order, const [
      'pill',
      'play',
      'search',
    ], reason: 'the full bar items must never take focus while minimized');
  });

  testWidgets('semantics read the accessory between the items and trailing', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = await _pumpBar(
      tester,
      accessory: _playRow(withText: true),
    );

    var labels = _spoken(tester).toList();
    final track = _indexWhere(labels, (l) => l == 'Midnight City');
    final home = _indexWhere(labels, (l) => l == 'Home, Tab 1 of 3');
    final search = _indexWhere(labels, (l) => l == 'Search');
    expect(track, greaterThanOrEqualTo(0), reason: 'expanded: $labels');
    expect(home, greaterThanOrEqualTo(0), reason: 'expanded: $labels');
    expect(search, greaterThanOrEqualTo(0), reason: 'expanded: $labels');
    expect(
      track < home && home < search,
      isTrue,
      reason: 'expanded order must be accessory, items, trailing: $labels',
    );

    controller.minimize();
    await tester.pumpAndSettle();

    labels = _spoken(tester).toList();
    final pill = _indexWhere(labels, (l) => l.contains('Home'));
    final minimizedTrack = _indexWhere(labels, (l) => l == 'Midnight City');
    final minimizedSearch = _indexWhere(labels, (l) => l == 'Search');
    expect(pill, greaterThanOrEqualTo(0), reason: 'minimized: $labels');
    expect(
      minimizedTrack,
      greaterThanOrEqualTo(0),
      reason: 'minimized: $labels',
    );
    expect(
      minimizedSearch,
      greaterThanOrEqualTo(0),
      reason: 'minimized: $labels',
    );
    expect(
      pill < minimizedTrack && minimizedTrack < minimizedSearch,
      isTrue,
      reason: 'minimized order must be pill, accessory, trailing: $labels',
    );
    handle.dispose();
  });

  testWidgets('hidden accessory has no semantics and takes no focus', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = await _pumpBar(
      tester,
      accessory: _playRow(withText: true),
    );

    controller.hide();
    await tester.pumpAndSettle();

    expect(
      _spoken(tester).where((l) => l.contains('Midnight City')),
      isEmpty,
      reason: 'a hidden bar must not expose the accessory to semantics',
    );
    final order = await _tabOrder(tester, 8);
    expect(
      order,
      isNot(contains('play')),
      reason: 'a hidden accessory must not take focus',
    );
    handle.dispose();
  });

  testWidgets('glass accessory shares the one backdrop read with the pieces', (
    tester,
  ) async {
    await _pumpBar(tester, accessory: _playRow(), leading: true);

    final layers = tester.layers.whereType<BackdropFilterLayer>().toList();
    expect(
      layers,
      hasLength(4),
      reason: 'leading, pill, trailing and accessory each paint one blur',
    );
    final key = layers.first.backdropKey;
    expect(key, isNotNull);
    for (final layer in layers) {
      expect(
        identical(layer.backdropKey, key),
        isTrue,
        reason: 'every piece must read the same backdrop',
      );
    }
  });

  testWidgets('high contrast paints the accessory as an opaque surface', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      accessory: _playRow(),
      leading: true,
      highContrast: true,
      theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
    );

    expect(
      tester.layers.whereType<BackdropFilterLayer>(),
      isEmpty,
      reason: 'high contrast must not blur any piece',
    );
    final surface = tester.widget<BarSurface>(find.byType(BarSurface).last);
    expect(surface.surface!.blur, 0);
    expect(surface.surface!.tint!.a, 1);
  });
}
