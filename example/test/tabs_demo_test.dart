import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _openTabs(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue = '/tabs';
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();

  expect(find.text('Demos'), findsNothing, reason: 'deep link skips picker');
  expect(find.text('Inbox row 0'), findsOneWidget, reason: 'Inbox shown');
}

Future<void> _tapHost(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

Future<void> _drag(WidgetTester tester, String title, double dy) async {
  await tester.drag(find.byKey(PageStorageKey<String>(title)), Offset(0, dy));
  await tester.pumpAndSettle();
}

bool _barVisible(WidgetTester tester) {
  return tester.widget<BottomBar>(find.byType(BottomBar)).controller!.isVisible;
}

void _selectTab(WidgetTester tester, int index) {
  tester.widget<BottomBarItems>(find.byType(BottomBarItems)).onSelected!(index);
}

void main() {
  testWidgets('every host hides on scroll and shows on tab select', (
    tester,
  ) async {
    await _openTabs(tester);

    for (final host in ['IndexedStack', 'PageView', 'TabBarView']) {
      await _tapHost(tester, host);
      await _drag(tester, 'Inbox', -600);
      expect(_barVisible(tester), isFalse, reason: '$host hides on scroll');

      _selectTab(tester, 2);
      await tester.pumpAndSettle();
      expect(_barVisible(tester), isTrue, reason: '$host shows on tab change');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('restore mode keeps a tab hidden when returning to it', (
    tester,
  ) async {
    await _openTabs(tester);

    await tester.tap(find.byKey(const ValueKey('restore-switch')));
    await tester.pumpAndSettle();
    await _tapHost(tester, 'PageView');

    await _drag(tester, 'Inbox', -600);
    expect(_barVisible(tester), isFalse);

    _selectTab(tester, 2);
    await tester.pumpAndSettle();
    expect(_barVisible(tester), isTrue, reason: 'Archive never seen shows');

    _selectTab(tester, 0);
    await tester.pumpAndSettle();
    expect(_barVisible(tester), isFalse, reason: 'Inbox restores hidden');
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping PageView lands on the next tab', (tester) async {
    await _openTabs(tester);
    await _tapHost(tester, 'PageView');

    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Starred row 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
