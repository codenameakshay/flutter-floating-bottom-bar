import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/focus_ring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';

void main() {
  testWidgets('hidden action name replaces semantics from a custom icon', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          controller: controller,
          iconSemanticLabel: 'Back to start',
          iconTooltip: 'Go up',
          icon: (_, _) =>
              const Icon(Icons.arrow_upward, semanticLabel: 'Decorative arrow'),
          body: const SizedBox.expand(),
          child: const SizedBox(width: 200, height: 56),
        ),
      ),
    );
    controller.hide();
    await tester.pumpAndSettle();
    expect(semanticsLabels(tester), ['Back to start']);
    final node = tester.getSemantics(find.bySemanticsLabel('Back to start'));
    expect(node, isSemantics(isButton: true, hasTapAction: true));
    semantics.dispose();
  });

  testWidgets('focus ring tracks touch mode and detaches its listener', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    addTearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FocusRing(
            shape: const CircleBorder(),
            child: InkWell(
              focusNode: focus,
              onTap: () {},
              child: const SizedBox.square(dimension: 48),
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    Decoration decoration() => tester
        .widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(FocusRing),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .decoration;
    expect(decoration(), isA<ShapeDecoration>());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(decoration(), isA<BoxDecoration>());
    await tester.pumpWidget(const SizedBox.shrink());
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(tester.takeException(), isNull);
  });
}
