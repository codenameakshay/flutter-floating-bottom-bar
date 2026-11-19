import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final scale in [1.3, 2.0, 3.0]) {
    testWidgets('material3 paragraph and body padding fit at ${scale}x', (
      tester,
    ) async {
      BuildContext? bodyContext;
      const bodyKey = ValueKey('padded-body');
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: BottomBar(
              theme: BottomBarThemeData.material3(),
              body: Builder(
                builder: (context) {
                  bodyContext = context;
                  return const BottomBarBodyPadding(
                    child: SizedBox.expand(key: bodyKey),
                  );
                },
              ),
              child: BottomBarItems(
                selectedIndex: 0,
                onSelected: (_) {},
                children: const [
                  BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                  BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final item in tester.widgetList<BottomBarItem>(
        find.byType(BottomBarItem),
      )) {
        final itemFinder = find.byWidget(item);
        final target = tester.getRect(
          find.descendant(of: itemFinder, matching: find.byType(InkWell)),
        );
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          find.descendant(of: itemFinder, matching: find.byType(RichText)),
        )) {
          final rect = MatrixUtils.transformRect(
            paragraph.getTransformTo(null),
            Offset.zero & paragraph.size,
          );
          expect(rect.top, greaterThanOrEqualTo(target.top));
          expect(rect.bottom, lessThanOrEqualTo(target.bottom));
          expect(rect.left, greaterThanOrEqualTo(target.left));
          expect(rect.right, lessThanOrEqualTo(target.right));
        }
      }
      final footprint = BottomBarScope.of(bodyContext!).barHeight.value;
      expect(
        tester.getRect(find.byKey(bodyKey)).bottom,
        closeTo(tester.getSize(find.byType(Scaffold)).height - footprint, 0.01),
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final rich in [false, true]) {
    testWidgets(
      'explicit ${rich ? 'rich' : 'plain'} label scaler stays within the accessibility cap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BottomBar(
                theme: BottomBarThemeData.material3(),
                body: const SizedBox.expand(),
                child: BottomBarItems(
                  selectedIndex: 0,
                  onSelected: (_) {},
                  children: [
                    BottomBarItem(
                      icon: const Icon(Icons.home),
                      label: rich
                          ? const Text.rich(
                              TextSpan(text: 'Home'),
                              textScaler: TextScaler.linear(3),
                            )
                          : const Text(
                              'Home',
                              textScaler: TextScaler.linear(3),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final paragraphs = tester
            .renderObjectList<RenderParagraph>(
              find.descendant(
                of: find.byType(BottomBarItem),
                matching: find.byType(RichText),
              ),
            )
            .where((paragraph) => paragraph.text.toPlainText() == 'Home');
        expect(paragraphs, isNotEmpty);
        for (final paragraph in paragraphs) {
          expect(paragraph.textScaler.scale(12), lessThanOrEqualTo(12 * 1.3));
        }
        expect(tester.takeException(), isNull);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == 'Home',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('minimized rich label retains its name with a badge', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BottomBar(
            controller: controller,
            body: const SizedBox.expand(),
            child: BottomBarItems(
              selectedIndex: 0,
              onSelected: (_) {},
              children: [
                BottomBarItem(
                  icon: const Icon(Icons.home),
                  label: const Text.rich(TextSpan(text: 'Home')),
                  badge: BottomBarBadge.count(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.minimize();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Home, 3 new'), findsOneWidget);
    expect(find.bySemanticsLabel('3 new'), findsNothing);
    semantics.dispose();
  });
}
