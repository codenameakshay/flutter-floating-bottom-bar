import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('every item theme field participates in copy, merge and equality', () {
    const empty = BottomBarItemThemeData();
    final variants = <BottomBarItemThemeData>[
      empty.copyWith(color: Colors.red),
      empty.copyWith(selectedColor: Colors.blue),
      empty.copyWith(iconSize: 20),
      empty.copyWith(selectedIconSize: 26),
      empty.copyWith(labelStyle: const TextStyle(fontSize: 10)),
      empty.copyWith(selectedLabelStyle: const TextStyle(fontSize: 12)),
      empty.copyWith(padding: const EdgeInsets.all(9)),
      empty.copyWith(iconLabelGap: 4),
      empty.copyWith(inkBorderRadius: BorderRadius.circular(3)),
      empty.copyWith(overlayColor: const WidgetStatePropertyAll(Colors.red)),
      empty.copyWith(splashFactory: NoSplash.splashFactory),
      empty.copyWith(pressedScale: 0.9),
      empty.copyWith(motion: const CupertinoMotion.smooth()),
      empty.copyWith(indicator: const BottomBarIndicator.none()),
      empty.copyWith(indicatorMotion: const CupertinoMotion.snappy()),
    ];
    for (var i = 0; i < variants.length; i++) {
      final variant = variants[i];
      expect(variant, isNot(empty), reason: 'field $i');
      expect(empty.merge(variant), variant, reason: 'field $i');
      expect(variant.merge(empty), variant, reason: 'field $i');
      expect(variant.copyWith(), variant, reason: 'field $i');
      expect(variant.copyWith().hashCode, variant.hashCode, reason: 'field $i');
    }
  });

  testWidgets('bar theme updates inherited items without replacing the item', (
    tester,
  ) async {
    const item = BottomBarItem(icon: Icon(Icons.home));
    Widget app(BottomBarItemThemeData? local) => MaterialApp(
      theme: ThemeData(
        extensions: const [
          BottomBarThemeData(
            items: BottomBarItemThemeData(color: Colors.red, iconSize: 31),
          ),
        ],
      ),
      home: Scaffold(
        body: BottomBar(
          theme: BottomBarThemeData(items: local),
          body: const SizedBox(),
          child: const BottomBarItems(children: [item]),
        ),
      ),
    );
    IconThemeData iconTheme() =>
        IconTheme.of(tester.element(find.byIcon(Icons.home)));

    await tester.pumpWidget(
      app(const BottomBarItemThemeData(color: Colors.green)),
    );
    await tester.pumpAndSettle();
    expect(iconTheme().color, isSameColorAs(Colors.green));
    expect(iconTheme().size, 31);
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();
    expect(iconTheme().color, isSameColorAs(Colors.red));
    expect(iconTheme().size, 31);
    expect(tester.takeException(), isNull);
  });
}
