import 'package:flutter_floating_bottom_bar_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<NavigatorState> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    return tester.state<NavigatorState>(find.byType(Navigator).first);
  }

  testWidgets('removing a covered route keeps the adaptive demo frameless', (
    tester,
  ) async {
    final navigator = await open(tester);
    final covered = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/covered'),
      builder: (_) => const Scaffold(body: Text('Covered')),
    );
    navigator.push(covered);
    await tester.pumpAndSettle();
    navigator.pushNamed('/adaptive-rail');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsNothing);
    navigator.removeRoute(covered);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing a covered route keeps the adaptive demo frameless', (
    tester,
  ) async {
    final navigator = await open(tester);
    final covered = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/covered'),
      builder: (_) => const Scaffold(body: Text('Covered')),
    );
    navigator.push(covered);
    await tester.pumpAndSettle();
    navigator.pushNamed('/adaptive-rail');
    await tester.pumpAndSettle();
    navigator.replace(
      oldRoute: covered,
      newRoute: MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/replacement'),
        builder: (_) => const Scaffold(body: Text('Replacement')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adaptive deep links stay frameless until popped', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/adaptive-rail';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await open(tester);
    expect(find.byKey(const Key('device-frame')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('device-frame')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
