import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

const _bar = Key('bar');
const _body = Key('body');

void main() {
  testWidgets('bar without MediaQuery treats absent insets as zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      RawView(
        view: tester.view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: ThemeData(),
            child: BottomBar(
              theme: const BottomBarThemeData(
                surface: BottomBarSurface.glass(),
              ),
              showIcon: false,
              body: const SizedBox.expand(key: _body),
              child: const SizedBox(key: _bar, height: 56),
            ),
          ),
        ),
      ),
      wrapWithView: false,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      BottomBarScope.of(tester.element(find.byKey(_body))).barHeight.value,
      76,
    );
  });

  testWidgets(
    'floating and docked runtime switch updates footprint and inset together',
    (tester) async {
      var docked = false;
      var keyboard = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQueryData(
                  padding: EdgeInsets.only(bottom: keyboard ? 0 : 34),
                  viewPadding: const EdgeInsets.only(bottom: 34),
                  viewInsets: EdgeInsets.only(bottom: keyboard ? 300 : 0),
                ),
                child: BottomBar(
                  layout: docked
                      ? const BottomBarLayout.docked()
                      : const BottomBarLayout(),
                  showIcon: false,
                  body: const SizedBox.expand(key: _body),
                  child: const _StatefulBar(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        BottomBarScope.of(tester.element(find.byKey(_body))).barHeight.value,
        110,
      );
      final originalState = tester.state(find.byType(_StatefulBar));
      update(() {
        docked = true;
        keyboard = true;
      });
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(_StatefulBar)), same(originalState));
      expect(
        BottomBarScope.of(tester.element(find.byKey(_body))).barHeight.value,
        56,
      );
      expect(
        BottomBarScope.of(tester.element(find.byKey(_body))).bottomInset,
        0,
      );
      expect(tester.getRect(find.byKey(_bar)).bottom, 300);
      update(() {
        docked = false;
        keyboard = false;
      });
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(_StatefulBar)), same(originalState));
      expect(
        BottomBarScope.of(tester.element(find.byKey(_body))).barHeight.value,
        110,
      );
      expect(
        BottomBarScope.of(tester.element(find.byKey(_body))).bottomInset,
        34,
      );
    },
  );
  for (final (index, layout) in [
    const BottomBarLayout.adaptive(
      maxWidth: 900,
      directionalAlignment: AlignmentDirectional.bottomStart,
    ),
    const BottomBarLayout(
      width: double.infinity,
      directionalAlignment: AlignmentDirectional.bottomStart,
    ),
    const BottomBarLayout.docked(),
  ].indexed) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'landscape hidden action avoids asymmetric inset layout $index $direction',
        (tester) async {
          tester.view.physicalSize = const Size(800, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final controller = BottomBarController();
          addTearDown(controller.dispose);
          const actionKey = Key('hidden-action');
          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: MediaQuery(
                  data: const MediaQueryData(
                    padding: EdgeInsets.fromLTRB(47, 0, 48, 21),
                  ),
                  child: BottomBar(
                    controller: controller,
                    layout: layout,
                    icon: (width, height) =>
                        SizedBox(key: actionKey, width: width, height: height),
                    body: const SizedBox.expand(),
                    child: const SizedBox(key: _bar, height: 56),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final barRect = tester.getRect(find.byKey(_bar));
          expect(barRect.left, greaterThanOrEqualTo(47));
          expect(barRect.right, lessThanOrEqualTo(752));
          controller.hide();
          await tester.pumpAndSettle();
          final actionRect = tester.getRect(find.byKey(actionKey));
          expect(actionRect.left, greaterThanOrEqualTo(47));
          expect(actionRect.right, lessThanOrEqualTo(752));
          expect(actionRect.bottom, lessThanOrEqualTo(379));
          expect(
            tester.getRect(find.byKey(_bar)).top,
            greaterThanOrEqualTo(400),
          );
        },
      );
    }
  }
}

class _StatefulBar extends StatefulWidget {
  const _StatefulBar();
  @override
  State<_StatefulBar> createState() => _StatefulBarState();
}

class _StatefulBarState extends State<_StatefulBar> {
  @override
  Widget build(BuildContext context) => const SizedBox(key: _bar, height: 56);
}
