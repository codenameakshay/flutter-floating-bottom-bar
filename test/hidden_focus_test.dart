import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hiding the bar removes focus from its descendants', (
    tester,
  ) async {
    final controller = BottomBarController();
    final focusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      controller.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            body: const SizedBox.shrink(),
            child: TextField(focusNode: focusNode),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    controller.hide();
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    controller.show();
    await tester.pumpAndSettle();
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });
}
