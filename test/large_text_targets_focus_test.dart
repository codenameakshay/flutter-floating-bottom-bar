import 'dart:math' as math;

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bar_surface.dart';
import 'package:flutter_floating_bottom_bar/src/internal/bottom_bar_action.dart';
import 'package:flutter_floating_bottom_bar/src/internal/focus_ring.dart';
import 'package:flutter_floating_bottom_bar/src/internal/minimize.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _padChildKey = ValueKey('body-pad-child');
const _labels = ['Home', 'Inbox', 'Saved', 'Profile'];
const _narrowLabels = [
  'Home',
  'Search',
  'Inbox',
  'Saved',
  'Alerts',
  'Chat',
  'Music',
  'Profile',
];

class _Probe {
  BuildContext? context;
}

List<(String, BottomBarThemeData?)> _themeCases() => [
  ('default', null),
  ('glass', BottomBarThemeData.glass()),
  ('material3', BottomBarThemeData.material3()),
  ('pill', BottomBarThemeData.pill()),
  ('minimal', BottomBarThemeData.minimal()),
];

BottomBarItems _rowItems({BottomBarCenterAction? centerAction}) =>
    BottomBarItems(
      selectedIndex: 0,
      onSelected: (_) {},
      centerAction: centerAction,
      children: [
        const BottomBarItem(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        BottomBarItem(
          icon: const Icon(Icons.inbox_outlined),
          label: const Text('Inbox'),
          badge: BottomBarBadge.count(120),
        ),
        const BottomBarItem(
          icon: Icon(Icons.bookmark_border),
          label: Text('Saved'),
          badge: BottomBarBadge.dot(),
        ),
        const BottomBarItem(
          icon: Icon(Icons.person_outline),
          label: Text('Profile'),
        ),
      ],
    );

BottomBarItems _narrowItems() => BottomBarItems(
  selectedIndex: 0,
  onSelected: (_) {},
  children: [
    for (final label in _narrowLabels)
      BottomBarItem(
        icon: const Icon(Icons.circle_outlined),
        label: Text(label),
      ),
  ],
);

BottomBarCenterAction _centre(BottomBarCenterActionStyle style) =>
    BottomBarCenterAction(
      icon: const Icon(Icons.add),
      semanticLabel: 'Create',
      style: style,
      onPressed: () {},
    );

Widget _probeBody(_Probe probe, Widget child) => Builder(
  builder: (context) {
    probe.context = context;
    return child;
  },
);

Widget _wrap(double scale, Widget home, {TextDirection? direction}) =>
    MaterialApp(
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: page!,
      ),
      home: Directionality(
        textDirection: direction ?? TextDirection.ltr,
        child: home,
      ),
    );

Future<_Probe> _pump(
  WidgetTester tester, {
  required double scale,
  BottomBarThemeData? theme,
  BottomBarController? controller,
  Widget? accessory,
  Widget? child,
  Widget? body,
  BottomBarScrollBehavior? scrollBehavior,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final probe = _Probe();
  await tester.pumpWidget(
    _wrap(
      scale,
      Scaffold(
        body: BottomBar(
          controller: controller,
          theme: theme,
          accessory: accessory,
          scrollBehavior: scrollBehavior ?? const BottomBarScrollBehavior(),
          body: _probeBody(probe, body ?? const SizedBox.expand()),
          child: child ?? _rowItems(),
        ),
      ),
      direction: direction,
    ),
  );
  await tester.pumpAndSettle();
  return probe;
}

double _footprint(_Probe probe) =>
    BottomBarScope.of(probe.context!).barHeight.value;

Future<double> _footprintAt(
  WidgetTester tester,
  double scale,
  BottomBarThemeData? theme,
) async {
  final probe = await _pump(tester, scale: scale, theme: theme);
  return _footprint(probe);
}

List<RenderParagraph> _textParagraphs(WidgetTester tester, Finder root) =>
    tester
        .renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.descendant(of: root, matching: find.byType(Text)),
            matching: find.byType(RichText),
          ),
        )
        .where((p) => p.text.toPlainText().isNotEmpty)
        .toList();

void _expectNoTruncation(WidgetTester tester, Finder root) {
  expect(tester.takeException(), isNull);
  for (final p in _textParagraphs(tester, root)) {
    expect(p.didExceedMaxLines, isFalse, reason: p.text.toPlainText());
  }
}

/// Labels that fit their slot at 1.0x stay whole at [scale]; a label too
/// long even at 1.0x keeps its ellipsis. Every label stays inside its slot.
void _expectItemText(WidgetTester tester, double scale) {
  expect(tester.takeException(), isNull);
  final paragraphs = _textParagraphs(tester, find.byType(BottomBarItem));
  expect(paragraphs, isNotEmpty);
  final capped = math.min(scale, 1.3);
  var whole = 0;
  for (final p in paragraphs) {
    final text = p.text.toPlainText();
    expect(p.textScaler.scale(10) / 10, closeTo(capped, 0.001), reason: text);
    final slot = (p.parent! as RenderBox).constraints.maxWidth;
    final widthAtOne = p.getMaxIntrinsicWidth(double.infinity) / capped;
    expect(
      p.didExceedMaxLines,
      widthAtOne > slot + 0.5,
      reason: '$text: ${widthAtOne.toStringAsFixed(1)} at 1.0x in $slot',
    );
    expect(
      MatrixUtils.transformRect(
        p.getTransformTo(null),
        Offset.zero & p.size,
      ).width,
      lessThanOrEqualTo(slot + 0.5),
      reason: text,
    );
    if (!p.didExceedMaxLines) whole++;
  }
  expect(whole, greaterThan(0));
}

void _expectFootprintMatchesSurface(WidgetTester tester, _Probe probe) {
  final surface = tester.getRect(find.byType(BarSurface));
  final bottomGap =
      tester.getSize(find.byType(Scaffold)).height - surface.bottom;
  expect(_footprint(probe), closeTo(surface.height + 2 * bottomGap, 0.5));
}

Future<void> _expectPastCapTooltip(WidgetTester tester) async {
  await tester.longPress(find.text('Home'));
  await tester.pump();
  expect(
    find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == 'Home',
    ),
    findsOneWidget,
  );
  expect(find.bySemanticsLabel(RegExp('^Home')), findsWidgets);
  await tester.pump(const Duration(seconds: 3));
}

Size _ink(WidgetTester tester, Finder root) => tester.getSize(
  find.descendant(of: root, matching: find.byType(InkWell)).first,
);

void _expectTarget(Size size, {String? reason}) {
  expect(size.width, greaterThanOrEqualTo(48), reason: reason);
  expect(size.height, greaterThanOrEqualTo(48), reason: reason);
}

Future<void> _expectGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  handle.dispose();
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

({String name, double x}) _focused(WidgetTester tester) {
  final context = FocusManager.instance.primaryFocus!.context!;
  final item = context.findAncestorWidgetOfExactType<BottomBarItem>();
  if (item != null) {
    return (
      name: (item.label! as Text).data!,
      x: tester.getCenter(find.byWidget(item)).dx,
    );
  }
  final centre = context
      .findAncestorWidgetOfExactType<BottomBarCenterAction>()!;
  return (name: 'Create', x: tester.getCenter(find.byWidget(centre)).dx);
}

FocusRing _focusRing(WidgetTester tester) => FocusManager
    .instance
    .primaryFocus!
    .context!
    .findAncestorWidgetOfExactType<FocusRing>()!;

Decoration _ringDecoration(WidgetTester tester, FocusRing ring) => tester
    .widget<DecoratedBox>(
      find
          .descendant(
            of: find.byWidget(ring),
            matching: find.byType(DecoratedBox),
          )
          .first,
    )
    .decoration;

void _expectRingVisible(WidgetTester tester, FocusRing ring) {
  final decoration = _ringDecoration(tester, ring);
  expect(decoration, isA<ShapeDecoration>());
  final side = ((decoration as ShapeDecoration).shape as OutlinedBorder).side;
  expect(side.width, 2);
  expect(
    side.color,
    Theme.of(tester.element(find.byType(BottomBar))).colorScheme.primary,
  );
}

void _expectRingHidden(WidgetTester tester, FocusRing ring) {
  expect(_ringDecoration(tester, ring), isNot(isA<ShapeDecoration>()));
}

void main() {
  group('large text', () {
    for (final scale in [1.3, 2.0, 3.0]) {
      group('at ${scale}x', () {
        for (final (name, theme) in _themeCases()) {
          testWidgets('rows keep whole labels with the $name theme', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            final reference = await _footprintAt(tester, 1.0, theme);
            final probe = await _pump(tester, scale: scale, theme: theme);
            _expectItemText(tester, scale);
            _expectFootprintMatchesSurface(tester, probe);
            expect(_footprint(probe), greaterThanOrEqualTo(reference - 0.5));
            handle.dispose();
          });
        }

        if (scale > 1.3) {
          testWidgets('past 1.3x long-press shows the label as a tooltip', (
            tester,
          ) async {
            final handle = tester.ensureSemantics();
            await _pump(tester, scale: scale);
            await _expectPastCapTooltip(tester);
            handle.dispose();
          });
        }

        testWidgets('narrow scrolling row keeps every label whole', (
          tester,
        ) async {
          final probe = await _pump(
            tester,
            scale: scale,
            child: SizedBox(width: 200, child: _narrowItems()),
          );
          _expectItemText(tester, scale);
          _expectFootprintMatchesSurface(tester, probe);
        });

        testWidgets('rail keeps whole labels', (tester) async {
          tester.view.physicalSize = const Size(1200, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _wrap(
              scale,
              Scaffold(
                body: BottomBarAdaptive(
                  items: _rowItems(),
                  body: const SizedBox.expand(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(BottomBar), findsNothing);
          _expectItemText(tester, scale);
        });

        testWidgets('badge text fits its badge', (tester) async {
          await _pump(tester, scale: scale);
          final paragraphs = tester.renderObjectList<RenderParagraph>(
            find.descendant(
              of: find.byType(BottomBarBadge),
              matching: find.byType(RichText),
            ),
          );
          expect(paragraphs, isNotEmpty);
          for (final p in paragraphs) {
            final text = p.text.toPlainText();
            expect(text, isNotEmpty);
            expect(p.didExceedMaxLines, isFalse, reason: text);
            expect(
              p.textScaler.scale(10) / 10,
              closeTo(math.min(scale, 1.3), 0.001),
              reason: text,
            );
            expect(
              p.size.width,
              greaterThanOrEqualTo(
                p.getMaxIntrinsicWidth(double.infinity) - 0.5,
              ),
              reason: text,
            );
          }
        });

        testWidgets('minimized pill holds its label scale', (tester) async {
          final controller = BottomBarController();
          addTearDown(controller.dispose);
          await _pump(tester, scale: scale, controller: controller);
          controller.minimize();
          await tester.pumpAndSettle();
          expect(find.byType(CompactPillButton), findsOneWidget);
          _expectNoTruncation(tester, find.byType(CompactPillButton));
        });

        testWidgets('accessory keeps whole labels', (tester) async {
          await _pump(
            tester,
            scale: scale,
            accessory: const ListTile(
              title: Text('Now playing'),
              subtitle: Text('Artist'),
            ),
          );
          _expectItemText(tester, scale);
        });

        testWidgets('body padding reserves the bar height', (tester) async {
          final probe = await _pump(
            tester,
            scale: scale,
            body: const BottomBarBodyPadding(
              child: SizedBox.expand(key: _padChildKey),
            ),
          );
          final footprint = _footprint(probe);
          _expectFootprintMatchesSurface(tester, probe);
          final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
          expect(
            tester.getRect(find.byKey(_padChildKey)).bottom,
            closeTo(scaffoldHeight - footprint, 0.5),
          );
        });
      });
    }
  });

  group('tap targets', () {
    for (final scale in [1.0, 3.0]) {
      group('at ${scale}x', () {
        testWidgets('every item is at least 48 by 48', (tester) async {
          await _pump(tester, scale: scale);
          for (final label in _labels) {
            _expectTarget(
              _ink(
                tester,
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(BottomBarItem),
                ),
              ),
              reason: label,
            );
          }
          await _expectGuidelines(tester);
        });

        for (final style in BottomBarCenterActionStyle.values) {
          testWidgets('centre action ${style.name} is at least 48 by 48', (
            tester,
          ) async {
            await _pump(
              tester,
              scale: scale,
              child: _rowItems(centerAction: _centre(style)),
            );
            _expectTarget(_ink(tester, find.byType(BottomBarCenterAction)));
            await _expectGuidelines(tester);
          });
        }

        testWidgets('minimized pill is at least 48 by 48', (tester) async {
          final controller = BottomBarController();
          addTearDown(controller.dispose);
          await _pump(tester, scale: scale, controller: controller);
          controller.minimize();
          await tester.pumpAndSettle();
          _expectTarget(_ink(tester, find.byType(CompactPillButton)));
          await _expectGuidelines(tester);
        });

        testWidgets('hidden scroll-to-top is at least 48 by 48', (
          tester,
        ) async {
          await _pump(
            tester,
            scale: scale,
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (_, i) =>
                  SizedBox(height: 60, child: Text('Row $i')),
            ),
          );
          await tester.drag(find.byType(ListView), const Offset(0, -300));
          await tester.pumpAndSettle();
          _expectTarget(_ink(tester, find.byType(BottomBarAction)));
          await _expectGuidelines(tester);
        });

        testWidgets('items in a narrow scrolling row are at least 48 by 48', (
          tester,
        ) async {
          await _pump(
            tester,
            scale: scale,
            child: SizedBox(width: 200, child: _narrowItems()),
          );
          for (final label in _narrowLabels) {
            _expectTarget(
              _ink(
                tester,
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(BottomBarItem),
                ),
              ),
              reason: label,
            );
          }
          await _expectGuidelines(tester);
        });
      });
    }
  });

  group('keyboard and focus', () {
    setUp(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });

    tearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('tab walks Home, Inbox, centre action, Saved, Profile', (
      tester,
    ) async {
      await _pump(
        tester,
        scale: 1.0,
        child: _rowItems(
          centerAction: _centre(BottomBarCenterActionStyle.inline),
        ),
      );
      final names = <String>[];
      final xs = <double>[];
      for (var i = 0; i < 5; i++) {
        await _tab(tester);
        final focused = _focused(tester);
        names.add(focused.name);
        xs.add(focused.x);
      }
      expect(names, ['Home', 'Inbox', 'Create', 'Saved', 'Profile']);
      for (var i = 0; i < xs.length - 1; i++) {
        expect(xs[i], lessThan(xs[i + 1]));
      }
    });

    testWidgets('in RTL, tab follows reading order and runs right to left', (
      tester,
    ) async {
      await _pump(
        tester,
        scale: 1.0,
        direction: TextDirection.rtl,
        child: _rowItems(
          centerAction: _centre(BottomBarCenterActionStyle.inline),
        ),
      );
      final names = <String>[];
      final xs = <double>[];
      for (var i = 0; i < 5; i++) {
        await _tab(tester);
        final focused = _focused(tester);
        names.add(focused.name);
        xs.add(focused.x);
      }
      expect(names, ['Home', 'Inbox', 'Create', 'Saved', 'Profile']);
      for (var i = 0; i < xs.length - 1; i++) {
        expect(xs[i], greaterThan(xs[i + 1]));
      }
    });

    testWidgets('arrow right from Home moves focus to Inbox', (tester) async {
      await _pump(tester, scale: 1.0);
      await _tab(tester);
      expect(_focused(tester).name, 'Home');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_focused(tester).name, 'Inbox');
    });

    testWidgets('focused item shows a 2px primary ring until focus leaves', (
      tester,
    ) async {
      await _pump(tester, scale: 1.0);
      await _tab(tester);
      final home = _focusRing(tester);
      _expectRingVisible(tester, home);

      await _tab(tester);
      expect(_focused(tester).name, 'Inbox');
      _expectRingHidden(tester, home);
      _expectRingVisible(tester, _focusRing(tester));
    });

    testWidgets('focused centre action shows the ring', (tester) async {
      await _pump(
        tester,
        scale: 1.0,
        child: _rowItems(
          centerAction: _centre(BottomBarCenterActionStyle.inline),
        ),
      );
      await _tab(tester);
      await _tab(tester);
      await _tab(tester);
      expect(_focused(tester).name, 'Create');
      _expectRingVisible(tester, _focusRing(tester));
    });

    testWidgets('focused minimized pill shows the ring', (tester) async {
      final controller = BottomBarController();
      addTearDown(controller.dispose);
      await _pump(tester, scale: 1.0, controller: controller);
      controller.minimize();
      await tester.pumpAndSettle();
      await _tab(tester);
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<CompactPillButton>(),
        isNotNull,
      );
      _expectRingVisible(tester, _focusRing(tester));
    });

    testWidgets('focused hidden scroll-to-top shows the ring', (tester) async {
      await _pump(
        tester,
        scale: 1.0,
        body: ListView.builder(
          itemCount: 100,
          itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Row $i')),
        ),
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await _tab(tester);
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<BottomBarAction>(),
        isNotNull,
      );
      _expectRingVisible(tester, _focusRing(tester));
    });

    testWidgets('alwaysTouch strategy shows no ring on keyboard focus', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      await _pump(tester, scale: 1.0);
      await _tab(tester);
      expect(_focused(tester).name, 'Home');
      _expectRingHidden(tester, _focusRing(tester));
    });
  });
}
