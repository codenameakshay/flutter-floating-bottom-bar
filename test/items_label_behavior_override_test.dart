import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _AlwaysHideItems extends BottomBarItems {
  const _AlwaysHideItems({required super.children});

  @override
  BottomBarLabelBehavior get labelBehavior => BottomBarLabelBehavior.alwaysHide;
}

const _children = [BottomBarItem(icon: Icon(Icons.home), label: Text('Home'))];

void _expectHiddenLabel() {
  expect(find.byIcon(Icons.home), findsOneWidget);
  expect(find.text('Home'), findsNothing);
}

void main() {
  testWidgets('an external labelBehavior override hides row labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: _AlwaysHideItems(children: _children)),
      ),
    );

    _expectHiddenLabel();
  });

  testWidgets('an external labelBehavior override hides rail labels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BottomBarAdaptive(
            items: _AlwaysHideItems(children: _children),
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).direction,
      Axis.vertical,
    );
    _expectHiddenLabel();
  });
}
