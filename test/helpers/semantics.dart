import 'package:flutter_test/flutter_test.dart';

Iterable<String> semanticsLabels(WidgetTester tester) {
  return tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty);
}
