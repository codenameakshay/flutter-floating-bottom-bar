import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'cases/transitions.dart';
import 'golden_case.dart';

void main() {
  testWidgets('pins physical size and device pixel ratio for a golden', (
    tester,
  ) async {
    const physicalSize = Size(480, 320);
    tester.view.devicePixelRatio = 3;

    pinGoldenView(tester, physicalSize);

    expect(tester.view.physicalSize, physicalSize);
    expect(tester.view.devicePixelRatio, 1);
  });

  for (final c in transitionsFeature.cases) {
    testWidgets('${c.id} reaches a visible midpoint', (tester) async {
      pinGoldenView(tester, c.size);
      await c.run!(tester, c.shots.single);
    });
  }
}
