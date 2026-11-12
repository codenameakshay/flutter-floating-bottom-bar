import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  int? index, {
  BottomBarIndicator indicator = const BottomBarIndicator.underline(),
  bool empty = false,
  bool reduced = false,
  bool widePadding = false,
}) => MaterialApp(
  themeAnimationDuration: Duration.zero,
  theme: ThemeData(
    extensions: [
      BottomBarThemeData(
        items: BottomBarItemThemeData(
          motion: const CupertinoMotion.smooth(duration: Duration(seconds: 1)),
          padding: widePadding
              ? const EdgeInsets.symmetric(horizontal: 20)
              : null,
        ),
      ),
    ],
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 100,
        height: 80,
        child: BottomBarItems(
          selectedIndex: index,
          labelBehavior: BottomBarLabelBehavior.onlySelected,
          indicator: indicator,
          children: empty
              ? const []
              : const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(
                    icon: Icon(Icons.search),
                    label: Text('Search'),
                  ),
                  BottomBarItem(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'reduced motion geometry changes reveal without a scroll ticker',
    (tester) async {
      await tester.pumpWidget(_app(2, reduced: true));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(2, reduced: true, widePadding: true));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 1);
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );

  testWidgets('reduced motion selection has no ticker in a narrow row', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0, reduced: true));
    await tester.pumpWidget(_app(2, reduced: true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion stops narrow row label reveal mid-growth', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(2));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(_app(2, reduced: true));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 1);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('selection resumes after an empty row and indicator opt-out', (
    tester,
  ) async {
    await tester.pumpWidget(_app(null, empty: true));
    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(2));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(
      _app(2, indicator: const BottomBarIndicator.none()),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(_app(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final label = tester.getRect(find.text('Settings').first);
    expect(label.right, lessThanOrEqualTo(viewport.right));
    expect(label.left, greaterThanOrEqualTo(viewport.left));
  });

  testWidgets('narrow rows reveal the selected item after its label grows', (
    tester,
  ) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(2));
    await tester.pumpAndSettle();
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final label = tester.getRect(find.text('Settings').first);
    expect(label.left, greaterThanOrEqualTo(viewport.left));
    expect(label.right, lessThanOrEqualTo(viewport.right));

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    await tester.drag(find.byType(SingleChildScrollView), const Offset(70, 0));
    await tester.pumpAndSettle();
    final userOffset = position.pixels;
    expect(userOffset, lessThan(position.maxScrollExtent));
    await tester.pump(const Duration(seconds: 1));
    expect(position.pixels, userOffset);
  });
}
