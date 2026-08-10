import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'BottomBarBodyPadding reserves bar footprint plus caller padding while hidden',
      (tester) async {
    final controller = BottomBarController();
    const barHeight = 56.0;
    const barOffset = 12.0;
    const safeAreaBottom = 18.0;
    const callerPadding = EdgeInsetsDirectional.only(
      start: 11,
      top: 7,
      end: 13,
      bottom: 5,
    );
    final bodyPaddingKey = GlobalKey();
    final bodyChildKey = GlobalKey();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: safeAreaBottom),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: BottomBar(
                controller: controller,
                layout: const BottomBarLayout(offset: barOffset),
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomBarBodyPadding(
                    key: bodyPaddingKey,
                    padding: callerPadding,
                    child: SizedBox(
                      key: bodyChildKey,
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
                child: const SizedBox(height: barHeight, width: 200),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialPadding = _bodyPadding(tester, bodyPaddingKey);
    final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
    final expectedTop = scaffoldHeight - 20 - 103;
    expect(initialPadding.resolve(TextDirection.rtl),
        const EdgeInsets.fromLTRB(13, 7, 11, 103));
    expect(tester.getTopLeft(find.byKey(bodyChildKey)).dy,
        closeTo(expectedTop, 0.01));

    controller.hide();
    await tester.pumpAndSettle();

    final hiddenPadding = _bodyPadding(tester, bodyPaddingKey);
    expect(hiddenPadding.resolve(TextDirection.rtl),
        const EdgeInsets.fromLTRB(13, 7, 11, 103));
    expect(tester.getTopLeft(find.byKey(bodyChildKey)).dy,
        closeTo(expectedTop, 0.01));
  });

  testWidgets(
      'paint-only custom transition keeps reported and reserved footprint stable when hidden',
      (tester) async {
    final controller = BottomBarController();
    const barHeight = 56.0;
    const barOffset = 12.0;
    const safeAreaBottom = 18.0;
    const footprint = barHeight + (barOffset * 2) + safeAreaBottom;
    final observedHeights = <double>[];
    final bodyPaddingKey = GlobalKey();
    final bodyChildKey = GlobalKey();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: safeAreaBottom),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: BottomBar(
              controller: controller,
              layout: const BottomBarLayout(offset: barOffset),
              motion: BottomBarMotion(
                transitionBuilder: (context, animation, child) {
                  final value = animation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + (0.1 * value),
                      child: child,
                    ),
                  );
                },
              ),
              body: Builder(
                builder: (context) {
                  final scope = BottomBarScope.of(context);
                  return ValueListenableBuilder<double>(
                    valueListenable: scope.barHeight,
                    builder: (context, value, _) {
                      observedHeights.add(value);
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: BottomBarBodyPadding(
                          key: bodyPaddingKey,
                          child: SizedBox(
                            key: bodyChildKey,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              child: const SizedBox(height: barHeight, width: 200),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
    final expectedTop = scaffoldHeight - 20 - footprint;
    final initialPadding = _bodyPadding(tester, bodyPaddingKey);
    expect(initialPadding.resolve(TextDirection.ltr),
        const EdgeInsets.only(bottom: footprint));
    expect(observedHeights.last, closeTo(footprint, 0.01));
    expect(tester.getTopLeft(find.byKey(bodyChildKey)).dy,
        closeTo(expectedTop, 0.01));

    controller.hide();
    await tester.pumpAndSettle();

    final hiddenPadding = _bodyPadding(tester, bodyPaddingKey);
    expect(hiddenPadding.resolve(TextDirection.ltr),
        const EdgeInsets.only(bottom: footprint));
    expect(observedHeights.last, closeTo(footprint, 0.01));
    expect(tester.getTopLeft(find.byKey(bodyChildKey)).dy,
        closeTo(expectedTop, 0.01));
  });
}

EdgeInsetsGeometry _bodyPadding(WidgetTester tester, GlobalKey key) {
  return tester
      .widget<Padding>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(Padding),
        ),
      )
      .padding;
}
