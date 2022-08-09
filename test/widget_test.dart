// // This is a basic Flutter widget test.
// //
// // To perform an interaction with a widget in your test, use the WidgetTester
// // utility in the flutter_test package. For example, you can send tap and scroll
// // gestures. You can also use WidgetTester to find child widgets in the widget
// // tree, read text, and verify that the values of widget properties are correct.

// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:floating_bottom_bar/main.dart';

// void main() {
//   testWidgets('App scroll smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget(MyApp());

//     // Verify that our list starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('100'), findsNothing);

//     // Tap the '+' icon and trigger a frame, and the tabs should scroll to 3rd tab.
//     // await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();

//     final listFinder = find.byKey(ValueKey('infinite_list_key#${Colors.green.toString()}'));
//     final itemFinder = find.text('100');

//     // Scroll until the item to be found appears.
//     await tester.scrollUntilVisible(
//       itemFinder,
//       500.0,
//       scrollable: listFinder,
//     );

//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('100'), findsOneWidget);
//   });
// }
