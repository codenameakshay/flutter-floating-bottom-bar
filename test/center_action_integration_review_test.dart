import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/semantics.dart';

void main() {
  for (final style in [
    BottomBarCenterActionStyle.raised,
    BottomBarCenterActionStyle.notched,
  ]) {
    for (final transition in [...BottomBarTransition.values, null]) {
      testWidgets('$style excludes hidden action for $transition', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        final focus = FocusNode();
        addTearDown(focus.dispose);
        final scopeKey = GlobalKey();
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BottomBar(
                controller: controller,
                motion: BottomBarMotion.curved(
                  transition: transition ?? BottomBarTransition.fade,
                  transitionBuilder: transition == null
                      ? (context, animation, child) => child
                      : null,
                  slideStart: const Offset(0, 1),
                ),
                layout: const BottomBarLayout(width: 320, offset: 0),
                body: BottomBarBodyPadding(
                  key: scopeKey,
                  child: const SizedBox.expand(),
                ),
                child: BottomBarItems(
                  centerAction: BottomBarCenterAction(
                    style: style,
                    icon: Focus(focusNode: focus, child: const Icon(Icons.add)),
                    semanticLabel: 'Create',
                    onPressed: () => taps++,
                  ),
                  children: const [
                    BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
                    BottomBarItem(
                      icon: Icon(Icons.person),
                      label: Text('Profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final actionInk = find.descendant(
          of: find.byType(BottomBarCenterAction),
          matching: find.byType(InkWell),
        );
        final actionRect = tester.getRect(actionInk);
        final point = Offset(actionRect.center.dx, actionRect.top + 5);
        final scope = BottomBarScope.of(tester.element(find.byKey(scopeKey)));
        final height = scope.barHeight.value;
        expect(height, tester.getSize(find.byType(BarSurface)).height);
        final padding = tester.widget<Padding>(
          find
              .descendant(
                of: find.byKey(scopeKey),
                matching: find.byType(Padding),
              )
              .first,
        );
        expect((padding.padding as EdgeInsets).bottom, height);
        expect(semanticsLabels(tester), contains('Create'));
        focus.requestFocus();
        await tester.pump();
        expect(focus.hasFocus, isTrue);
        await tester.tapAt(point);
        await tester.pumpAndSettle();
        expect(taps, 1);

        controller.hide();
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isFalse);
        expect(focus.canRequestFocus, isFalse);
        expect(semanticsLabels(tester), isNot(contains('Create')));
        expect(scope.barHeight.value, height);
        await tester.tapAt(point);
        await tester.pumpAndSettle();
        expect(taps, 1);
        if (transition == BottomBarTransition.slide) {
          expect(tester.getRect(actionInk).top, greaterThanOrEqualTo(600));
        }

        controller.show();
        await tester.pumpAndSettle();
        expect(semanticsLabels(tester), contains('Create'));
        expect(focus.canRequestFocus, isTrue);
        expect(tester.getRect(actionInk), actionRect);
        await tester.tapAt(point);
        await tester.pumpAndSettle();
        expect(taps, 2);
        semantics.dispose();
      });
    }
  }

  testWidgets('raised action is included in body clearance', (tester) async {
    final scopeKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          layout: const BottomBarLayout(width: 320, offset: 0),
          body: Builder(
            key: scopeKey,
            builder: (context) {
              final height = BottomBarScope.of(context).barHeight.value;
              return BottomBarBodyPadding(child: SizedBox(height: height));
            },
          ),
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            centerAction: BottomBarCenterAction(
              icon: Icon(Icons.add),
              tooltip: 'Create',
              onPressed: () {},
              style: BottomBarCenterActionStyle.raised,
            ),
            children: [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scope = tester.element(find.byKey(scopeKey));
    expect(BottomBarScope.of(scope).barHeight.value, greaterThan(48));
  });

  testWidgets('bar without a center action keeps its child footprint', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BottomBar(
          layout: const BottomBarLayout(width: 320, offset: 0),
          body: const SizedBox.shrink(),
          child: SizedBox(width: 320, height: 52),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(BarSurface)).height, 52);
  });
}
