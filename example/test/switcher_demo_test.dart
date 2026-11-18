import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openSwitcher(
  WidgetTester tester, {
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = FakeViewPadding(bottom: bottomInset);
  tester.view.padding = FakeViewPadding(bottom: bottomInset);
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/switcher';
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();
}

final _viewport = find.byType(Viewport);
final _dock = find.byType(BottomBarSwitcher);
final _tiles = find.descendant(
  of: _viewport,
  matching: find.byType(GestureDetector),
);

Finder _tile(int index) => _tiles.at(index);

Future<void> _expectLastRowAboveDock(WidgetTester tester) async {
  final position = Scrollable.of(tester.element(_tiles.first)).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();

  final dockTop = tester.getTopLeft(_dock).dy;
  final count = _tiles.evaluate().length;
  for (var index = count - 3; index < count; index++) {
    final tile = _tile(index);
    expect(tester.getBottomLeft(tile).dy, closeTo(dockTop - 10, 0.01));
    expect(tile.hitTestable(), findsOneWidget);
  }
}

void main() {
  testWidgets('switcher demo starts on the nav dock', (tester) async {
    await _openSwitcher(tester);

    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('long press selects a tile and shows the selection dock', (
    tester,
  ) async {
    await _openSwitcher(tester);

    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();

    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Library'), findsNothing);
  });

  testWidgets('tapping another tile in selection mode adds it', (tester) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();

    await tester.tap(_tile(1));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('compose opens the composer and close returns to selection', (
    tester,
  ) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();
    await tester.tap(_tile(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Compose'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('2 selected'), findsOneWidget);
  });

  testWidgets('cancel clears the selection and restores the nav dock', (
    tester,
  ) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('deselecting the last photo while composing returns to nav', (
    tester,
  ) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Compose'));
    await tester.pumpAndSettle();

    await tester.tap(_tile(0));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('photos scroll under the dock and the last row clears it', (
    tester,
  ) async {
    await _openSwitcher(tester, bottomInset: 34);

    expect(tester.getBottomLeft(_dock).dy, closeTo(800, 0.01));
    final dockCenter = tester.getCenter(_dock);
    expect(tester.getRect(_viewport).contains(dockCenter), isTrue);
    expect(
      _tiles.evaluate().any(
        (tile) =>
            tester.getRect(find.byWidget(tile.widget)).contains(dockCenter),
      ),
      isTrue,
    );
    await _expectLastRowAboveDock(tester);

    await tester.longPress(_tiles.last);
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await _expectLastRowAboveDock(tester);

    await tester.tap(find.byTooltip('Compose'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await _expectLastRowAboveDock(tester);

    tester.view.padding = const FakeViewPadding();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.focusNode.hasFocus, isTrue);
    expect(field.hitTestable(), findsOneWidget);
    await tester.enterText(field, 'One\nTwo\nThree\nFour');
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(_viewport).dy, 544);
    expect(tester.getBottomLeft(_dock).dy, closeTo(534, 0.01));
    expect(
      tester.getTopLeft(field).dy,
      greaterThan(tester.getTopLeft(_viewport).dy),
    );
    expect(tester.getBottomLeft(field).dy, lessThan(544));
    expect(field.hitTestable(), findsOneWidget);
    await _expectLastRowAboveDock(tester);
  });

  testWidgets('composer morph does not rebuild the mounted photo tiles', (
    tester,
  ) async {
    await _openSwitcher(tester);
    await tester.longPress(_tile(0));
    await tester.pumpAndSettle();
    final selectionHeight = tester.getSize(_dock).height;

    await tester.tap(find.byTooltip('Compose'));
    await tester.pump();

    final photos = _tiles.evaluate().toSet();
    var rebuilds = 0;
    final previousCallback = debugOnRebuildDirtyWidget;
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      if (photos.contains(element)) rebuilds++;
      previousCallback?.call(element, builtOnce);
    };
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
    } finally {
      debugOnRebuildDirtyWidget = previousCallback;
    }

    expect(tester.getSize(_dock).height, greaterThan(selectionHeight));
    expect(rebuilds, 0);
  });
}
