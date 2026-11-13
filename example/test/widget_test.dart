import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';

void main() {
  const demoNames = <String>[
    'Indicators',
    'Issues dock',
    'AI prompt dock',
    'Basic TabBar',
    'Minimal API',
    'Nested scroll',
    'Badged nav',
    'Custom transition',
    'go_router shell',
    'Centre action',
    'Glass surface',
    'Groups',
  ];

  testWidgets('demo picker lists and opens every registered demo', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Demos'), findsOneWidget);

    for (final demoName in demoNames) {
      await tester.scrollUntilVisible(
        find.text(demoName),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(demoName));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'opening $demoName');

      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'returning from $demoName',
      );
      expect(find.text('Demos'), findsOneWidget);
    }
  });

  testWidgets('go_router demo disposes and reopens at Home', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    final outerNavigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );

    outerNavigator.pushNamed('/go-router-shell');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home row 1'));
    await tester.pumpAndSettle();
    expect(find.text('Home item 1'), findsOneWidget);

    outerNavigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('Demos'), findsOneWidget);
    expect(tester.takeException(), isNull);

    outerNavigator.pushNamed('/go-router-shell');
    await tester.pumpAndSettle();
    expect(find.text('Home row 0'), findsOneWidget);
    expect(find.text('Home item 1'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a deep link opens its demo on top of the picker', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/nested-scroll';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Nested scroll'), findsWidgets);
    expect(find.text('Demos'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Demos'), findsOneWidget);
  });

  testWidgets('an unknown pushed route leaves the demo picker usable', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.binding.handlePushRoute('/not-a-demo');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Demos'), findsOneWidget);
    await tester.tap(find.text('Issues dock'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('issues-content')), findsOneWidget);
  });

  testWidgets('a pushed registered route opens its demo above the picker', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    await tester.binding.handlePushRoute('/minimal-api');
    await tester.pumpAndSettle();

    expect(find.text('Demos'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Demos'), findsOneWidget);
  });

  testWidgets('an unknown initial deep link falls back to the demo picker', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/not-a-demo';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(
      tester.takeException(),
      contains('Could not navigate to initial route'),
    );
    expect(find.text('Demos'), findsOneWidget);
    await tester.tap(find.text('Issues dock'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('issues-content')), findsOneWidget);
  });

  testWidgets('wide screens show the app in a 430px phone frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());

    expect(tester.getSize(find.byKey(const Key('device-frame'))).width, 430);
    expect(tester.getSize(find.byType(Navigator)).width, 430);
  });

  testWidgets('phones show the app full screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());

    expect(find.byKey(const Key('device-frame')), findsNothing);
    expect(tester.getSize(find.byType(Navigator)).width, 390);
  });

  testWidgets('600px is the first viewport width that uses a device frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(599, 844));
    await tester.pumpWidget(const ExampleApp());
    expect(find.byKey(const Key('device-frame')), findsNothing);

    await tester.binding.setSurfaceSize(const Size(600, 844));
    await tester.pump();
    expect(find.byKey(const Key('device-frame')), findsOneWidget);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('desktop keyboard insets are mapped into the device frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetViewInsets();
      return tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const ExampleApp());

    final appMedia = tester.widget<MediaQuery>(
      find
          .descendant(
            of: find.byKey(const Key('device-frame')),
            matching: find.byType(MediaQuery),
          )
          .first,
    );
    expect(appMedia.data.size, const Size(430, 932));
    expect(appMedia.data.viewInsets.bottom, 66);
    expect(appMedia.data.viewPadding.bottom, 12);
    expect(appMedia.data.padding.bottom, 0);

    tester.view.viewInsets = const FakeViewPadding();
    await tester.pump();
    final restoredMedia = tester.widget<MediaQuery>(
      find
          .descendant(
            of: find.byKey(const Key('device-frame')),
            matching: find.byType(MediaQuery),
          )
          .first,
    );
    expect(restoredMedia.data.viewInsets.bottom, 0);
    expect(restoredMedia.data.padding.bottom, 12);
  });

  testWidgets('desktop keyboard inset below the frame margin stays outside', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    tester.view.viewInsets = const FakeViewPadding(bottom: 30);
    addTearDown(() {
      tester.view.resetViewInsets();
      return tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const ExampleApp());
    final appMedia = tester.widget<MediaQuery>(
      find
          .descendant(
            of: find.byKey(const Key('device-frame')),
            matching: find.byType(MediaQuery),
          )
          .first,
    );
    expect(appMedia.data.viewInsets.bottom, 0);
    expect(appMedia.data.padding.bottom, 12);
  });

  testWidgets('phone keyboard insets pass through unchanged', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(() {
      tester.view.resetViewInsets();
      return tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const ExampleApp());
    final appMedia = tester.widget<MediaQuery>(
      find
          .ancestor(
            of: find.byType(Navigator),
            matching: find.byType(MediaQuery),
          )
          .first,
    );
    expect(appMedia.data.viewInsets.bottom, 100);
  });

  testWidgets('short desktop windows keep every demo free of layout errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());

    for (final demoName in demoNames) {
      await tester.scrollUntilVisible(
        find.text(demoName),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(demoName));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'opening $demoName');
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'returning from $demoName',
      );
    }
  });

  testWidgets('issues demo keeps its content readable on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('Issues dock'));
    await tester.pumpAndSettle();

    final content = find.byKey(const Key('issues-content'));
    expect(content, findsOneWidget);
    expect(tester.getSize(content).width, lessThanOrEqualTo(760));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI prompt demo explains its empty state on phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleApp());
    await tester.tap(find.text('AI prompt dock'));
    await tester.pumpAndSettle();

    expect(find.text('Start with a prompt'), findsOneWidget);
    expect(
      find.text('Ask a question or imagine something new.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
