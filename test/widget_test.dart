import 'package:flutter_test/flutter_test.dart';

import 'package:floating_bottom_bar/main.dart';

void main() {
  testWidgets('demo app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flutter Floating Bottom Bar Demo'), findsOneWidget);
  });
}
