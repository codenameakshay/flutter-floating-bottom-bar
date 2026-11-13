import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

const _childKey = Key('bar-child');
const _innerKey = Key('inner-child');
const _firstKey = Key('first-child');

Future<void> _pump(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(400, 800),
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets? viewPadding,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        viewPadding: viewPadding ?? padding,
        viewInsets: viewInsets,
      ),
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

BottomBar _bar({BottomBarLayout? layout, Widget? body, Widget? child}) {
  return BottomBar(
    layout: layout,
    showIcon: false,
    body: body ?? const SizedBox.expand(),
    child: child ?? const SizedBox(key: _childKey, height: 56),
  );
}

Widget _probe(void Function(BuildContext) capture) {
  return Builder(
    builder: (context) {
      capture(context);
      return const SizedBox.expand();
    },
  );
}

EdgeInsetsGeometry _paddingInBodyPadding(WidgetTester tester) {
  return tester
      .widget<Padding>(
        find.descendant(
          of: find.byType(BottomBarBodyPadding),
          matching: find.byType(Padding),
        ),
      )
      .padding;
}

void main() {
  testWidgets(
    'gesture inset lifts a bottom bar above the 24px home indicator',
    (tester) async {
      await _pump(
        tester,
        padding: const EdgeInsets.only(bottom: 24),
        home: _bar(),
      );

      expect(tester.getRect(find.byKey(_childKey)).bottom, 800 - 24 - 10);
    },
  );

  testWidgets(
    '3-button navigation inset lifts a bottom bar above the 48px bar',
    (tester) async {
      await _pump(
        tester,
        padding: const EdgeInsets.only(bottom: 48),
        home: _bar(),
      );

      expect(tester.getRect(find.byKey(_childKey)).bottom, 800 - 48 - 10);
    },
  );

  testWidgets('a bottom-aligned bar ignores the top inset', (tester) async {
    late BuildContext bodyContext;
    await _pump(
      tester,
      padding: const EdgeInsets.fromLTRB(0, 47, 0, 34),
      home: _bar(body: _probe((c) => bodyContext = c)),
    );

    expect(BottomBarScope.of(bodyContext).barHeight.value, 56 + 20 + 34);
    expect(tester.getRect(find.byKey(_childKey)).bottom, 800 - 34 - 10);
  });

  testWidgets(
    'a top-aligned bar ignores the bottom inset and reserves the top one',
    (tester) async {
      late BuildContext bodyContext;
      await _pump(
        tester,
        padding: const EdgeInsets.fromLTRB(0, 47, 0, 34),
        home: _bar(
          layout: const BottomBarLayout(alignment: Alignment.topCenter),
          body: _probe((c) => bodyContext = c),
        ),
      );

      expect(tester.getRect(find.byKey(_childKey)).top, 47 + 10);
      expect(BottomBarScope.of(bodyContext).barHeight.value, 56 + 20 + 47);
      expect(BottomBarScope.of(bodyContext).bottomInset, 0);
    },
  );

  testWidgets(
    'body padding reserves the bottom inset exactly once with a plain list',
    (tester) async {
      await _pump(
        tester,
        padding: const EdgeInsets.only(bottom: 34),
        home: _bar(
          body: BottomBarBodyPadding(
            child: ListView(
              children: const [SizedBox(key: _firstKey, height: 2000)],
            ),
          ),
        ),
      );

      expect(
        tester
            .widget<SliverPadding>(find.byType(SliverPadding).first)
            .padding
            .resolve(TextDirection.ltr)
            .bottom,
        0,
      );
      expect(
        tester.getTopLeft(find.byKey(_firstKey)).dy,
        tester.getTopLeft(find.byType(ListView)).dy,
      );
      expect(
        _paddingInBodyPadding(tester).resolve(TextDirection.ltr).bottom,
        56 + 20 + 34,
      );
    },
  );

  testWidgets(
    'a SafeArea above the bar leaves the body padding at the bar footprint',
    (tester) async {
      late BuildContext bodyContext;
      await _pump(
        tester,
        padding: const EdgeInsets.only(bottom: 34),
        home: SafeArea(
          child: _bar(
            body: Stack(
              children: [
                _probe((c) => bodyContext = c),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomBarBodyPadding(
                    child: const SizedBox(
                      key: _innerKey,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        _paddingInBodyPadding(tester).resolve(TextDirection.ltr).bottom,
        76,
      );
      expect(BottomBarScope.of(bodyContext).bottomInset, 0);
      expect(tester.getRect(find.byKey(_childKey)).bottom, 800 - 34 - 10);
    },
  );

  testWidgets(
    'a SafeArea inside the body counts the inset once, 110 from the screen bottom',
    (tester) async {
      await _pump(
        tester,
        padding: const EdgeInsets.only(bottom: 34),
        home: _bar(
          body: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: BottomBarBodyPadding(
                child: const SizedBox(key: _innerKey, width: 20, height: 20),
              ),
            ),
          ),
        ),
      );

      expect(
        _paddingInBodyPadding(tester).resolve(TextDirection.ltr).bottom,
        76,
      );
      expect(tester.getRect(find.byKey(_innerKey)).bottom, 800 - 110);
    },
  );

  testWidgets(
    'landscape side insets inset a full-width bar by 47 on each side',
    (tester) async {
      await _pump(
        tester,
        size: const Size(800, 400),
        padding: const EdgeInsets.fromLTRB(47, 0, 47, 21),
        home: _bar(
          layout: const BottomBarLayout(width: double.infinity),
          child: const SizedBox(key: _childKey, height: 56),
        ),
      );

      final rect = tester.getRect(find.byKey(_childKey));
      expect(rect.left, 57);
      expect(rect.right, 800 - 57);
    },
  );

  testWidgets(
    'an asymmetric 3-button landscape inset only moves the right edge',
    (tester) async {
      await _pump(
        tester,
        size: const Size(800, 400),
        padding: const EdgeInsets.only(right: 48),
        home: _bar(
          layout: const BottomBarLayout(width: double.infinity),
          child: const SizedBox(key: _childKey, height: 56),
        ),
      );

      final rect = tester.getRect(find.byKey(_childKey));
      expect(rect.right, 800 - 58);
      expect(rect.left, 10);
    },
  );

  testWidgets('the keyboard lifts the bar and the nav inset never drops out', (
    tester,
  ) async {
    await _pump(
      tester,
      padding: const EdgeInsets.only(bottom: 48),
      viewPadding: const EdgeInsets.only(bottom: 48),
      home: _bar(),
    );
    expect(tester.getRect(find.byKey(_childKey)).bottom, 742);

    await _pump(
      tester,
      padding: EdgeInsets.zero,
      viewPadding: const EdgeInsets.only(bottom: 48),
      viewInsets: const EdgeInsets.only(bottom: 300),
      home: _bar(),
    );
    expect(tester.getRect(find.byKey(_childKey)).bottom, 800 - 300 - 10);

    await _pump(
      tester,
      padding: const EdgeInsets.only(bottom: 18),
      viewPadding: const EdgeInsets.only(bottom: 48),
      viewInsets: const EdgeInsets.only(bottom: 30),
      home: _bar(),
    );
    expect(tester.getRect(find.byKey(_childKey)).bottom, 800 - 48 - 10);
  });
}
