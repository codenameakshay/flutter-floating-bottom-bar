import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  for (final style in BottomBarCenterActionStyle.values) {
    testWidgets('standalone $style uses inline defaults', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BottomBarItems(
                centerAction: BottomBarCenterAction(
                  style: style,
                  semanticLabel: 'Create',
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
                children: const [
                  BottomBarItem(icon: Icon(Icons.home)),
                  BottomBarItem(icon: Icon(Icons.search)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ink = find.descendant(
        of: find.byType(BottomBarCenterAction),
        matching: find.byType(InkWell),
      );
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(BottomBarCenterAction),
          matching: find.byType(Material),
        ),
      );
      expect(tester.getSize(ink), const Size(48, 48));
      expect(material.elevation, 0);
      expect(material.shape, isA<RoundedRectangleBorder>());
      expect(
        tester.widget<CenterActionSlot>(find.byType(CenterActionSlot)).width,
        64,
      );
    });
  }
}
