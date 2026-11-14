import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('ink label uses indicator label foreground', (tester) async {
    const selected = Color(0xffe53935);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const BottomBarItemSelectionScope(
            index: 0,
            selected: true,
            ink: true,
            selectedForegroundColor: Color(0xff123456),
            selectedLabelColor: selected,
            child: BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
          ),
        ),
      ),
    );

    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.text('Home'),
    );
    expect(
      paragraphs.any((paragraph) => paragraph.text.style?.color == selected),
      isTrue,
    );
    final iconColors = tester
        .widgetList<IconTheme>(find.byType(IconTheme))
        .map((theme) => theme.data.color);
    expect(iconColors, contains(const Color(0xff123456)));
  });

  for (final indicator in [
    const BottomBarIndicator.pill(),
    const BottomBarIndicator.tint(),
    const BottomBarIndicator.underline(),
  ]) {
    testWidgets('ink $indicator respects item selectedColor', (tester) async {
      const selected = Color(0xffe53935);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BottomBarItems(
              selectedIndex: 0,
              indicator: indicator,
              children: const [
                BottomBarItem(
                  icon: Icon(Icons.home),
                  label: Text('Home'),
                  selectedColor: selected,
                ),
              ],
            ),
          ),
        ),
      );
      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.text('Home'),
      );
      expect(
        paragraphs.any((paragraph) => paragraph.text.style?.color == selected),
        isTrue,
      );
      expect(
        tester
            .widgetList<IconTheme>(find.byType(IconTheme))
            .any((theme) => theme.data.color == selected),
        isTrue,
      );
    });
  }

  testWidgets(
    'non-ink label interpolates selected color and resets unselected',
    (tester) async {
      const plain = Color(0xffc62828);
      const selectedForeground = Color(0xff1565c0);
      const selectedLabel = Color(0xff2e7d32);
      Widget app(bool isSelected) => MaterialApp(
        theme: ThemeData(
          extensions: [
            BottomBarThemeData(
              items: BottomBarItemThemeData(
                motion: const CurvedMotion(
                  Duration(milliseconds: 200),
                  Curves.linear,
                ),
              ),
            ),
          ],
        ),
        home: Scaffold(
          body: BottomBarItemSelectionScope(
            index: 0,
            selected: isSelected,
            selectedForegroundColor: selectedForeground,
            selectedLabelColor: selectedLabel,
            child: const BottomBarItem(
              icon: Icon(Icons.home),
              label: Text('Home'),
              color: plain,
            ),
          ),
        ),
      );

      await tester.pumpWidget(app(false));
      Color labelColor() => tester
          .renderObjectList<RenderParagraph>(find.text('Home'))
          .first
          .text
          .style!
          .color!;
      expect(labelColor(), plain);
      await tester.pumpWidget(app(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(labelColor(), Color.lerp(plain, selectedLabel, 0.5));
      expect(labelColor(), isNot(Color.lerp(plain, selectedForeground, 0.5)));
      await tester.pumpAndSettle();
      expect(labelColor(), selectedLabel);
      await tester.pumpWidget(app(false));
      await tester.pumpAndSettle();
      expect(labelColor(), plain);
    },
  );

  testWidgets('non-ink selected label uses indicator label foreground', (
    tester,
  ) async {
    const labelForeground = Color(0xff00a86b);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.light(onSurface: labelForeground),
        ),
        home: Scaffold(
          body: BottomBarItems(
            selectedIndex: 0,
            indicator: const BottomBarIndicator.container(),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
            ],
          ),
        ),
      ),
    );

    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.text('Home'),
    );
    expect(
      paragraphs.any(
        (paragraph) => paragraph.text.style?.color == labelForeground,
      ),
      isTrue,
    );
  });
}
