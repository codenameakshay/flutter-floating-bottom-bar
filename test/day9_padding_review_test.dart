import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('unmeasured footprint preserves the navigation inset', (
    tester,
  ) async {
    final height = ValueNotifier(0.0);
    final visible = ValueNotifier(true);
    addTearDown(height.dispose);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: BottomBarScope(
            barHeight: height,
            isVisible: visible,
            bottomInset: 34,
            child: const BottomBarBodyPadding(child: SizedBox.expand()),
          ),
        ),
      ),
    );

    expect(_reserved(tester), 34);
    height.value = 110;
    await tester.pump();
    expect(_reserved(tester), 110);
  });

  testWidgets('missing MediaQuery does not imply an inset was consumed', (
    tester,
  ) async {
    final height = ValueNotifier(110.0);
    final visible = ValueNotifier(true);
    addTearDown(height.dispose);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      RawView(
        view: tester.view,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: BottomBarScope(
            barHeight: height,
            isVisible: visible,
            bottomInset: 34,
            child: Builder(
              builder: (context) {
                expect(MediaQuery.maybeOf(context), isNull);
                return const BottomBarBodyPadding(child: SizedBox.expand());
              },
            ),
          ),
        ),
      ),
      wrapWithView: false,
    );
    expect(_reserved(tester), 110);
  });

  for (final safeArea in ['none', 'above bar', 'inside body']) {
    testWidgets(
      'keyboard and navigation change together with SafeArea $safeArea',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const body = Align(
          alignment: Alignment.bottomCenter,
          child: BottomBarBodyPadding(
            child: SizedBox(key: Key('body-child'), width: 20, height: 20),
          ),
        );
        final bar = BottomBar(
          showIcon: false,
          body: safeArea == 'inside body' ? const SafeArea(child: body) : body,
          child: const SizedBox(key: Key('bar-child'), height: 56),
        );
        for (final (navigation, keyboard) in [
          (34.0, 0.0),
          (48.0, 300.0),
          (21.0, 0.0),
        ]) {
          final bottom = keyboard > navigation ? 0.0 : navigation - keyboard;
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(400, 800),
                padding: EdgeInsets.only(bottom: bottom),
                viewPadding: EdgeInsets.only(bottom: navigation),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: MaterialApp(
                home: Scaffold(
                  extendBody: true,
                  body: safeArea == 'above bar' ? SafeArea(child: bar) : bar,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final boundary = 800 - keyboard - bottom;
          expect(
            tester.getRect(find.byKey(const Key('bar-child'))).bottom,
            boundary - 10,
          );
          expect(
            tester.getRect(find.byKey(const Key('body-child'))).bottom,
            boundary - 76,
          );
        }
      },
    );
  }

  testWidgets('Scaffold resized keyboard content and bar share one boundary', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          viewInsets: EdgeInsets.only(bottom: 300),
          viewPadding: EdgeInsets.only(bottom: 34),
        ),
        child: MaterialApp(
          home: Scaffold(
            extendBody: true,
            body: BottomBar(
              showIcon: false,
              body: const Align(
                alignment: Alignment.bottomCenter,
                child: BottomBarBodyPadding(
                  child: SizedBox(
                    key: Key('body-child'),
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              child: const SizedBox(key: Key('bar-child'), height: 56),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const Key('bar-child'))).bottom, 490);
    expect(tester.getRect(find.byKey(const Key('body-child'))).bottom, 424);
  });
}

double _reserved(WidgetTester tester) => tester
    .widget<Padding>(
      find
          .descendant(
            of: find.byType(BottomBarBodyPadding),
            matching: find.byType(Padding),
          )
          .first,
    )
    .padding
    .resolve(TextDirection.ltr)
    .bottom;
