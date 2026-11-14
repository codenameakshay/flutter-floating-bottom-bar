import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar_example/demos/adaptive_rail_demo.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

Future<void> _resize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  await tester.pumpAndSettle();
}

Future<void> _openDemo(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MaterialApp(home: AdaptiveRailDemoPage()));
  await tester.pumpAndSettle();
}

double _offset(WidgetTester tester) {
  return tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position
      .pixels;
}

Future<void> _tapRailItem(WidgetTester tester, String label) async {
  await tester.tap(
    find
        .descendant(of: find.byType(BottomBarItems), matching: find.text(label))
        .hitTestable(),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bar below 600 wide, rail at 1000 wide', (tester) async {
    await _openDemo(tester, 400);
    expect(find.byType(BottomBar), findsOneWidget);

    await _resize(tester, 1000);
    expect(find.byType(BottomBar), findsNothing);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).direction,
      Axis.vertical,
    );
  });

  testWidgets(
    'text, scroll and selection survive a resize across the breakpoint',
    (tester) async {
      await _openDemo(tester, 400);

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      final offset = _offset(tester);
      expect(offset, greaterThan(0));

      await _resize(tester, 1000);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'hello',
      );
      expect(_offset(tester), offset);

      await _tapRailItem(tester, 'Inbox');
      await _resize(tester, 400);
      expect(
        tester
            .widget<BottomBarItems>(find.byType(BottomBarItems))
            .selectedIndex,
        1,
      );
    },
  );

  testWidgets('Material 3 attaches the body at 80, glass at 112', (
    tester,
  ) async {
    await _openDemo(tester, 1000);

    await tester.tap(find.text('Material 3'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(CustomScrollView)).dx, 80);

    await tester.tap(find.text('Glass'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byType(CustomScrollView)).dx, 112);
  });

  testWidgets('the demo route fills the window; the picker stays framed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsOneWidget);

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed('/adaptive-rail');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsOneWidget);
  });
}
