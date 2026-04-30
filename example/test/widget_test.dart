import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

void main() {
  testWidgets('demo picker renders', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Demos'), findsOneWidget);
    expect(find.text('Tab bar'), findsOneWidget);
  });
}
