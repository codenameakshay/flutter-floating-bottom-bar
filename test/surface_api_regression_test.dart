import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'solid fade preserves the ancestor clip around its opacity layer',
    (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: ClipRect(
              child: BarSurface(
                surface: BottomBarSurface.solid(),
                fades: true,
                visibility: AlwaysStoppedAnimation(0.5),
                child: SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        ),
      );
      expect(tester.layers.whereType<OpacityLayer>(), hasLength(1));
      expect(tester.layers.whereType<ClipRectLayer>(), hasLength(1));
      expect(
        tester
            .renderObject<RenderBarSurface>(find.byType(BarSurface))
            .needsCompositing,
        isTrue,
      );
    },
  );
}
