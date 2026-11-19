import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_code.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_config.dart';
import 'package:flutter_floating_bottom_bar_example/configurator/bar_preview.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _phone = Size(390, 844);
const _wide = Size(1400, 900);

Future<void> _open(WidgetTester tester, String route, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.platformDispatcher.defaultRouteNameTestValue = route;
  addTearDown(tester.binding.platformDispatcher.clearDefaultRouteNameTestValue);

  await tester.pumpWidget(const ExampleApp());
  await tester.pumpAndSettle();
}

void _mockClipboard(WidgetTester tester, void Function(String?) onCopy) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        onCopy((call.arguments as Map)['text'] as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapKnob(WidgetTester tester, Finder finder) async {
  await tester.dragUntilVisible(
    finder,
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
  await _tap(tester, finder);
}

Future<void> _scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
  await tester.pumpAndSettle();
}

BarConfig _previewConfig(WidgetTester tester) =>
    tester.widget<BarPreview>(find.byType(BarPreview)).config;

String? _codeText(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('configurator-code')))
    .data;

void main() {
  test('the configurator is the last demo', () {
    expect(demos.last.slug, 'configurator');
  });

  testWidgets('home lists the configurator first and opens it', (tester) async {
    await _open(tester, '/', _phone);

    expect(
      find.descendant(
        of: find.byType(ListTile).first,
        matching: find.text('Build your bar'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Build your bar'));
    await tester.pumpAndSettle();

    expect(find.text('Configurator'), findsWidgets);
    expect(find.byType(BarPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a share link opens its bar without the device frame', (
    tester,
  ) async {
    await _open(tester, '/configurator?c=lay:floating,rtl:1,items:5', _phone);

    expect(
      _previewConfig(tester),
      BarConfig.decode('lay:floating,rtl:1,items:5'),
    );
    expect(find.byKey(const Key('device-frame')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final route in const [
    '/configurator?c=%E0%A4%A',
    '/configurator?c=garbage',
    '/configurator?c=blur:999',
    '/configurator?c=',
  ]) {
    testWidgets('a bad link opens the defaults: $route', (tester) async {
      await _open(tester, route, _phone);

      expect(_previewConfig(tester), BarConfig.defaults);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (route, expected) in [
    ('/configurator?c=items:5,blur:%FF', BarConfig.defaults),
    ('/configurator?c=items%3A5%2Cblur%3A%FF', BarConfig.defaults),
    ('/configurator?c=items:5&future=%FF', BarConfig.defaults),
    ('/configurator?c=items:5,blur:%', BarConfig.defaults.set(Knob.items, 5)),
    ('/configurator?c=items:5,blur:%G0', BarConfig.defaults.set(Knob.items, 5)),
  ]) {
    testWidgets('a bad escape never throws: $route', (tester) async {
      await _open(tester, route, _phone);

      expect(_previewConfig(tester), expected);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wide layout shows the code panel and copies it', (tester) async {
    String? copied;
    _mockClipboard(tester, (text) => copied = text);
    await _open(tester, '/configurator', _wide);

    expect(find.byKey(const Key('configurator-frame')), findsOneWidget);
    expect(find.byKey(const Key('configurator-code')), findsOneWidget);
    expect(_codeText(tester), generateCode(BarConfig.defaults));

    final solid = BarConfig.defaults.set(Knob.surface, SurfaceStyle.solid);
    await _tapKnob(tester, find.widgetWithText(ChoiceChip, 'Solid'));

    expect(find.text('Blur needs the glass surface.'), findsOneWidget);
    expect(_codeText(tester), generateCode(solid));

    await _scrollToTop(tester);
    await _tap(tester, find.widgetWithText(FilledButton, 'Copy code'));

    expect(copied, generateCode(solid));
    expect(find.text('Code copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone sheet and preview stay aligned after resizing', (
    tester,
  ) async {
    await _open(tester, '/configurator', _phone);
    await tester.dragFrom(const Offset(195, 600), const Offset(0, -400));
    await tester.pumpAndSettle();

    tester.view.physicalSize = _wide;
    await tester.pumpAndSettle();
    tester.view.physicalSize = _phone;
    await tester.pumpAndSettle();

    final sheet = find
        .descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(Material),
        )
        .first;
    expect(
      tester.getBottomLeft(find.byType(BarPreview)).dy,
      closeTo(tester.getTopLeft(sheet).dy, 1),
    );
    final preset = find.descendant(
      of: find.byKey(const ValueKey('knob-preset')),
      matching: find.widgetWithText(ChoiceChip, 'None'),
    );
    await _tap(tester, preset);
    expect(_previewConfig(tester).preset, BarPreset.none);
    expect(
      tester.getBottomLeft(find.byType(BarPreview)).dy,
      closeTo(tester.getTopLeft(sheet).dy, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone copy shows the code in a dialog', (tester) async {
    String? copied;
    _mockClipboard(tester, (text) => copied = text);
    await _open(tester, '/configurator', _phone);

    await _tap(tester, find.widgetWithText(FilledButton, 'Copy code'));

    expect(find.byType(Dialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byKey(const Key('configurator-code')),
      ),
      findsOneWidget,
    );
    expect(copied, generateCode(BarConfig.defaults));

    await _tap(tester, find.byTooltip('Close'));

    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('share copies a link to the playground', (tester) async {
    String? copied;
    _mockClipboard(tester, (text) => copied = text);
    await _open(tester, '/configurator?c=rtl:1', _wide);

    await _tap(tester, find.widgetWithText(OutlinedButton, 'Share'));

    expect(
      copied,
      kIsWeb
          ? Uri.base.replace(fragment: '/configurator?c=rtl:1').toString()
          : 'https://codenameakshay.github.io/flutter-floating-bottom-bar/'
                '#/configurator?c=rtl:1',
    );
    expect(find.text('Link copied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web knob updates and reset replace the current URL', (
    tester,
  ) async {
    final updates = <Map<Object?, Object?>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      (call) async {
        if (call.method == 'routeInformationUpdated') {
          updates.add(Map<Object?, Object?>.from(call.arguments as Map));
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.navigation,
        null,
      ),
    );
    await _open(tester, '/configurator', _wide);
    updates.clear();

    await _tapKnob(tester, find.widgetWithText(ChoiceChip, 'Docked'));
    expect(updates.last, {
      'uri': _previewConfig(tester).location,
      'state': null,
      'replace': true,
    });

    await _scrollToTop(tester);
    await _tap(tester, find.byTooltip('Reset'));
    expect(updates.last, {
      'uri': BarConfig.defaults.location,
      'state': null,
      'replace': true,
    });
    expect(tester.takeException(), isNull);
  }, skip: !kIsWeb);

  testWidgets('a knob updates the preview and reset restores it', (
    tester,
  ) async {
    await _open(tester, '/configurator', _wide);

    await _tapKnob(tester, find.widgetWithText(ChoiceChip, 'Docked'));

    expect(_previewConfig(tester).get(Knob.layout), LayoutStyle.docked);
    expect(find.text('A docked bar sits on the bottom edge.'), findsOneWidget);

    await _scrollToTop(tester);
    await _tap(tester, find.byTooltip('Reset'));

    expect(_previewConfig(tester), BarConfig.defaults);
    expect(tester.takeException(), isNull);
  });
}
