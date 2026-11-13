import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/tooltip_finder.dart';

const _childKey = Key('bar-child');
const _leadingKey = Key('leading-button');
const _itemsKey = Key('items');
const _badgeIconKey = Key('badge-icon');

const _icons = [Icons.home, Icons.inbox, Icons.search];

List<BottomBarItem> _tabs(int count) => [
  for (final icon in _icons.take(count))
    BottomBarItem(icon: Icon(icon), label: const Text('Tab')),
];

Future<void> _pumpBar(
  WidgetTester tester, {
  TextDirection direction = TextDirection.rtl,
  BottomBarLayout layout = const BottomBarLayout(width: 200),
  BottomBarMotion? motion,
  BottomBarController? controller,
  bool showIcon = false,
  Widget? leading,
  Widget? child,
  Widget? body,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: BottomBar(
            layout: layout,
            motion: motion,
            controller: controller,
            showIcon: showIcon,
            leading: leading,
            body: body ?? const SizedBox.expand(),
            child: child ?? const SizedBox(key: _childKey, height: 56),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<Offset> _actionCentre(
  WidgetTester tester, {
  required BottomBarLayout layout,
  TextDirection direction = TextDirection.rtl,
}) async {
  final controller = BottomBarController();
  addTearDown(controller.dispose);
  await _pumpBar(
    tester,
    direction: direction,
    layout: layout,
    controller: controller,
    showIcon: true,
  );
  controller.hide();
  await tester.pumpAndSettle();
  return tester.getCenter(findByTooltip('Scroll to top'));
}

void main() {
  testWidgets(
    'directionalAlignment bottomStart puts the bar on the right in RTL',
    (tester) async {
      await _pumpBar(
        tester,
        layout: const BottomBarLayout(
          width: 200,
          directionalAlignment: AlignmentDirectional.bottomStart,
        ),
      );

      expect(tester.getRect(find.byKey(_childKey)).right, 390);
    },
  );

  testWidgets(
    'directionalAlignment bottomStart puts the bar on the left in LTR',
    (tester) async {
      await _pumpBar(
        tester,
        direction: TextDirection.ltr,
        layout: const BottomBarLayout(
          width: 200,
          directionalAlignment: AlignmentDirectional.bottomStart,
        ),
      );

      expect(tester.getRect(find.byKey(_childKey)).left, 10);
    },
  );

  testWidgets('plain alignment bottomLeft stays on the left under RTL', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      layout: const BottomBarLayout(
        width: 200,
        alignment: Alignment.bottomLeft,
      ),
    );

    expect(tester.getRect(find.byKey(_childKey)).left, 10);
  });

  testWidgets('the back-to-top action follows directionalAlignment', (
    tester,
  ) async {
    final controller = BottomBarController();
    addTearDown(controller.dispose);
    await _pumpBar(
      tester,
      controller: controller,
      showIcon: true,
      layout: const BottomBarLayout(
        width: 200,
        directionalAlignment: AlignmentDirectional.bottomStart,
      ),
    );

    controller.hide();
    await tester.pumpAndSettle();

    expect(
      tester.getCenter(findByTooltip('Scroll to top')).dx,
      greaterThan(200),
    );
  });

  testWidgets('directionalIconOffset moves the action toward the end side', (
    tester,
  ) async {
    const base = BottomBarLayout(
      width: 200,
      directionalAlignment: AlignmentDirectional.bottomStart,
    );
    const shifted = BottomBarLayout(
      width: 200,
      directionalAlignment: AlignmentDirectional.bottomStart,
      directionalIconOffset: Offset(20, 0),
    );

    final rtlBase = await _actionCentre(tester, layout: base);
    final rtlShifted = await _actionCentre(tester, layout: shifted);
    expect(rtlShifted.dx, closeTo(rtlBase.dx - 20, 0.01));

    final ltrBase = await _actionCentre(
      tester,
      layout: base,
      direction: TextDirection.ltr,
    );
    final ltrShifted = await _actionCentre(
      tester,
      layout: shifted,
      direction: TextDirection.ltr,
    );
    expect(ltrShifted.dx, closeTo(ltrBase.dx + 20, 0.01));
  });

  testWidgets('iconOffset moves the action right under RTL', (tester) async {
    final base = await _actionCentre(
      tester,
      layout: const BottomBarLayout(
        width: 200,
        directionalAlignment: AlignmentDirectional.bottomStart,
      ),
    );
    final shifted = await _actionCentre(
      tester,
      layout: const BottomBarLayout(
        width: 200,
        directionalAlignment: AlignmentDirectional.bottomStart,
        iconOffset: Offset(20, 0),
      ),
    );

    expect(shifted.dx, closeTo(base.dx + 20, 0.01));
  });

  testWidgets(
    'offset under RTL keeps the bar 10 above the bottom with equal side gaps',
    (tester) async {
      await _pumpBar(tester, layout: const BottomBarLayout(width: 200));

      final rect = tester.getRect(find.byKey(_childKey));
      expect(rect.bottom, 790);
      expect(rect.left, 400 - rect.right);
      expect(rect.left, 100);
      expect(rect.right, 300);
    },
  );

  testWidgets(
    'directionalSlide moves the hidden bar toward the start side under RTL',
    (tester) async {
      Future<double> leftAfterHide({required bool directional}) async {
        final controller = BottomBarController();
        addTearDown(controller.dispose);
        await _pumpBar(
          tester,
          controller: controller,
          motion: BottomBarMotion.curved(
            duration: const Duration(milliseconds: 100),
            slideStart: const Offset(-2, 0),
            directionalSlide: directional,
          ),
        );
        controller.hide();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        return tester.getRect(find.byKey(_childKey)).left;
      }

      expect(await leftAfterHide(directional: true), greaterThan(100));
      expect(await leftAfterHide(directional: false), lessThan(100));
    },
  );

  test(
    'directionalBorderRadius resolves its topStart corner to topRight in RTL',
    () {
      const layout = BottomBarLayout(
        directionalBorderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(20),
        ),
      );

      expect(
        layout.effectiveBorderRadius.resolve(TextDirection.rtl),
        const BorderRadius.only(topRight: Radius.circular(20)),
      );
    },
  );

  testWidgets(
    'a directionalBorderRadius bar renders under RTL without exceptions',
    (tester) async {
      await _pumpBar(
        tester,
        layout: const BottomBarLayout(
          width: 200,
          directionalBorderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('item order mirrors under RTL with the first item on the right', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      child: BottomBarItems(
        selectedIndex: 0,
        onSelected: (_) {},
        indicator: const BottomBarIndicator.pill(),
        children: _tabs(3),
      ),
    );

    final first = tester.getRect(find.byType(BottomBarItem).first);
    final last = tester.getRect(find.byType(BottomBarItem).last);
    expect(first.left, greaterThan(last.left));
  });

  testWidgets('the leading button sits on the right of the pill under RTL', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      leading: IconButton(
        key: _leadingKey,
        tooltip: 'Lead',
        icon: const Icon(Icons.person),
        onPressed: () {},
      ),
    );

    final pill = tester.getRect(find.byKey(_childKey));
    final leading = tester.getRect(find.byKey(_leadingKey));
    expect(leading.left, greaterThan(pill.right));
  });

  testWidgets('a centre action sits in the middle of its row under RTL', (
    tester,
  ) async {
    await _pumpBar(
      tester,
      layout: const BottomBarLayout(width: 300),
      child: BottomBarItems(
        key: _itemsKey,
        selectedIndex: 0,
        onSelected: (_) {},
        centerAction: BottomBarCenterAction(
          icon: const Icon(Icons.add),
          tooltip: 'Create',
          onPressed: () {},
        ),
        children: _tabs(2),
      ),
    );

    final row = tester.getRect(find.byKey(_itemsKey));
    final action = tester.getRect(find.byIcon(Icons.add));
    expect(action.center.dx, closeTo(row.center.dx, 1));
  });

  testWidgets(
    'a count badge sits on the top-start corner, left of the icon under RTL',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: BottomBarItem(
                  icon: const Icon(Icons.inbox, key: _badgeIconKey),
                  label: const Text('Inbox'),
                  badge: const BottomBarBadge.count(3),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.getRect(find.byKey(_badgeIconKey));
      final badge = tester.getRect(
        find.descendant(
          of: find.byType(BottomBarBadge),
          matching: find.byType(Container),
        ),
      );
      expect(badge.center.dx, lessThan(icon.center.dx));
    },
  );
}
