import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/demos/ai_prompt_dock_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('enters and submits a local prompt', (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Plan a small garden');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Plan a small garden'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('whitespace prompts stay in the draft', (tester) async {
    await _pumpPage(tester);

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '  \n  ');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump();

    expect(find.text('Start with a prompt'), findsOneWidget);
    expect(find.text('  \n  '), findsOneWidget);
  });

  testWidgets('draft and focus survive scrolling', (tester) async {
    await _pumpPage(tester);
    final field = find.byType(TextField);

    for (var index = 0; index < 8; index++) {
      await tester.tap(field);
      await tester.enterText(field, 'Message $index');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Message 7'), findsOneWidget);
    await tester.enterText(field, 'Keep this draft');
    await tester.pump();
    final scrollable = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
    expect(tester.widget<TextField>(field).controller!.text, 'Keep this draft');
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(
      tester.widget<BottomBar>(find.byType(BottomBar)).controller!.isVisible,
      isTrue,
    );
  });

  testWidgets('composer actions expose labels and dismiss the keyboard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpPage(tester);

    expect(find.text('Ask'), findsOneWidget);
    expect(find.text('Imagine'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    final sendSemantics = tester
        .getSemantics(find.widgetWithText(FilledButton, 'Send'))
        .getSemanticsData();
    expect(sendSemantics.flagsCollection.isButton, isTrue);
    expect(find.byTooltip('Back to demos'), findsOneWidget);
    final backSemantics = tester
        .getSemantics(find.byTooltip('Back to demos'))
        .getSemanticsData();
    expect(backSemantics.flagsCollection.isButton, isTrue);
    expect(backSemantics.tooltip, 'Back to demos');

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.byTooltip('Dismiss keyboard'), findsOneWidget);
    final dismissSemantics = tester
        .getSemantics(find.byTooltip('Dismiss keyboard'))
        .getSemanticsData();
    expect(dismissSemantics.flagsCollection.isButton, isTrue);
    expect(dismissSemantics.tooltip, 'Dismiss keyboard');
    await tester.tap(find.byTooltip('Dismiss keyboard'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('composer fits a narrow, large-text viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2),
            viewInsets: const EdgeInsets.only(bottom: 280),
          ),
          child: child!,
        ),
        home: const AiPromptDockDemoPage(),
      ),
    );
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(MediaQuery.textScalerOf(tester.element(field)).scale(10), 20);
    await tester.tap(field);
    await tester.enterText(field, 'one\ntwo\nthree\nfour');
    await tester.pump();

    final sendButton = find.widgetWithText(FilledButton, 'Send');
    expect(sendButton, findsOneWidget);
    expect(tester.getRect(sendButton).bottom, lessThanOrEqualTo(360));
    expect(find.byTooltip('Dismiss keyboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPage(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: AiPromptDockDemoPage()));
  await tester.pumpAndSettle();
}
