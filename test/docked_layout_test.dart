import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

const _childKey = Key('bar-child');
const _innerKey = Key('inner-child');

Future<void> _pump(
  WidgetTester tester, {
  required Widget home,
  Size size = const Size(400, 800),
  EdgeInsets padding = const EdgeInsets.only(bottom: 34),
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool highContrast = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: padding,
        viewPadding: padding,
        viewInsets: viewInsets,
        highContrast: highContrast,
      ),
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

BottomBar _dockedBar({
  BottomBarLayout layout = const BottomBarLayout.docked(),
  BottomBarController? controller,
  BottomBarThemeData? theme,
  Widget? leading,
  Widget? child,
  Widget? body,
  void Function(BuildContext)? capture,
}) {
  return BottomBar(
    layout: layout,
    controller: controller,
    theme: theme,
    leading: leading,
    showIcon: false,
    body:
        body ??
        (capture == null
            ? const SizedBox.expand()
            : Builder(
                builder: (context) {
                  capture(context);
                  return const SizedBox.expand();
                },
              )),
    child: child ?? const SizedBox(key: _childKey, height: 64),
  );
}

void main() {
  testWidgets('a docked bar spans the width and reaches the bottom edge', (
    tester,
  ) async {
    late BuildContext bodyContext;
    await _pump(tester, home: _dockedBar(capture: (c) => bodyContext = c));

    final rect = tester.getRect(find.byKey(_childKey));
    expect(rect.left, 0);
    expect(rect.width, 400);
    expect(rect.bottom, 800 - 34);
    expect(BottomBarScope.of(bodyContext).barHeight.value, 64 + 34);
    expect(BottomBarScope.of(bodyContext).bottomInset, 34);
  });

  test(
    'the docked layout has no offset, infinite width and square corners',
    () {
      const layout = BottomBarLayout.docked();

      expect(layout.offset, 0);
      expect(layout.width, double.infinity);
      expect(layout.borderRadius, BorderRadius.zero);
    },
  );

  testWidgets(
    'respectSafeArea false lets a docked child reach the screen bottom',
    (tester) async {
      late BuildContext bodyContext;
      await _pump(
        tester,
        home: _dockedBar(
          layout: const BottomBarLayout.docked(respectSafeArea: false),
          capture: (c) => bodyContext = c,
        ),
      );

      expect(tester.getRect(find.byKey(_childKey)).bottom, 800);
      expect(BottomBarScope.of(bodyContext).barHeight.value, 64);
    },
  );

  testWidgets(
    'a docked bar in landscape keeps its child clear of the side and bottom insets',
    (tester) async {
      late BuildContext bodyContext;
      await _pump(
        tester,
        size: const Size(800, 400),
        padding: const EdgeInsets.fromLTRB(47, 0, 47, 21),
        home: _dockedBar(capture: (c) => bodyContext = c),
      );

      final rect = tester.getRect(find.byKey(_childKey));
      expect(rect.left, 47);
      expect(rect.right, 753);
      expect(rect.bottom, 379);
      expect(BottomBarScope.of(bodyContext).barHeight.value, 64 + 21);
    },
  );

  testWidgets('hiding a docked bar slides the whole surface off screen', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pump(tester, home: _dockedBar(controller: controller));

    controller.hide();
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(_childKey)).top,
      greaterThanOrEqualTo(800),
    );
  });

  testWidgets('the keyboard lifts a docked bar above it', (tester) async {
    await _pump(
      tester,
      padding: EdgeInsets.zero,
      viewInsets: const EdgeInsets.only(bottom: 300),
      home: _dockedBar(),
    );

    expect(tester.getRect(find.byKey(_childKey)).bottom, 500);
  });

  testWidgets('a docked bar ignores leading', (tester) async {
    await _pump(tester, home: _dockedBar(leading: const Text('L')));

    expect(find.text('L'), findsNothing);
  });

  final scenarios =
      <String, ({BottomBarThemeData? theme, bool highContrast, Widget child})>{
        'pill items': (
          theme: null,
          highContrast: false,
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            indicator: const BottomBarIndicator.pill(),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
            ],
          ),
        ),
        'raised centre action': (
          theme: null,
          highContrast: false,
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Create',
              style: BottomBarCenterActionStyle.raised,
              onPressed: () {},
            ),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
            ],
          ),
        ),
        'notched centre action': (
          theme: null,
          highContrast: false,
          child: BottomBarItems(
            selectedIndex: 0,
            onSelected: (_) {},
            centerAction: BottomBarCenterAction(
              icon: const Icon(Icons.add),
              tooltip: 'Create',
              style: BottomBarCenterActionStyle.notched,
              onPressed: () {},
            ),
            children: const [
              BottomBarItem(icon: Icon(Icons.home), label: Text('Home')),
              BottomBarItem(icon: Icon(Icons.inbox), label: Text('Inbox')),
            ],
          ),
        ),
        'glass surface with scroll-edge surface': (
          theme: const BottomBarThemeData(
            surface: BottomBarSurface.glass(),
            scrollEdgeSurface: BottomBarSurface.solid(),
          ),
          highContrast: false,
          child: const SizedBox(height: 64),
        ),
        'high contrast': (
          theme: const BottomBarThemeData(surface: BottomBarSurface.glass()),
          highContrast: true,
          child: const SizedBox(height: 64),
        ),
      };

  for (final entry in scenarios.entries) {
    testWidgets('docked feature renders without exception: ${entry.key}', (
      tester,
    ) async {
      final scenario = entry.value;
      await _pump(
        tester,
        highContrast: scenario.highContrast,
        home: _dockedBar(
          theme: scenario.theme,
          child: Padding(
            key: _childKey,
            padding: EdgeInsets.zero,
            child: scenario.child,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.byKey(_childKey)).bottom, 766);
    });
  }

  testWidgets(
    'BottomBarBodyPadding in a docked body pads the bar footprint and the inset',
    (tester) async {
      await _pump(
        tester,
        home: _dockedBar(
          body: BottomBarBodyPadding(
            child: const SizedBox(key: _innerKey, width: 20, height: 20),
          ),
        ),
      );

      final padding = tester
          .widget<Padding>(
            find.descendant(
              of: find.byType(BottomBarBodyPadding),
              matching: find.byType(Padding),
            ),
          )
          .padding
          .resolve(TextDirection.ltr);
      expect(padding.bottom, 64 + 34);
    },
  );
}
