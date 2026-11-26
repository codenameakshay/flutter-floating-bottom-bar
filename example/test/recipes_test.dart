import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/composer.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/long_labels.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/mini_player.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/reader_controls.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/recipes_page.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/scroll_under.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/selection_dock.dart';
import 'package:flutter_floating_bottom_bar_example/recipes/split_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _phone = Size(390, 844);

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  Size size = _phone,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

ScrollPosition _scroll(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

void main() {
  testWidgets('composer submits, clears, grows and rides the keyboard', (
    tester,
  ) async {
    await _pump(tester, const ComposerRecipe());
    final field = find.byType(TextField);
    final oneLine = tester.getSize(field).height;

    await tester.enterText(field, 'one\ntwo\nthree');
    await tester.pump();
    expect(tester.getSize(field).height, greaterThan(oneLine));
    await tester.enterText(field, List.filled(5, 'line').join('\n'));
    await tester.pump();
    final fiveLines = tester.getSize(field).height;
    await tester.enterText(field, List.filled(9, 'line').join('\n'));
    await tester.pump();
    expect(tester.getSize(field).height, fiveLines, reason: 'caps at 5 lines');

    await tester.enterText(field, 'hello there');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('hello there'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    final focus = tester.widget<EditableText>(find.byType(EditableText));
    expect(focus.focusNode.hasFocus, isTrue);

    for (var i = 0; i < 20; i++) {
      await tester.enterText(field, 'message $i');
      await tester.tap(find.byTooltip('Send'));
    }
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(focus.focusNode.hasFocus, isTrue, reason: 'scrolling keeps focus');
    expect(find.byTooltip('Send').hitTestable(), findsOneWidget);

    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(field).bottom,
      lessThanOrEqualTo(_phone.height - 300),
    );
    expect(find.byTooltip('Send').hitTestable(), findsOneWidget);
  });

  testWidgets('selection dock morphs and returns to the same tab', (
    tester,
  ) async {
    await _pump(tester, const SelectionDockRecipe());
    await tester.tap(find.byType(BottomBarItem).at(1));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Message 2'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byType(BottomBarItems), findsNothing);
    await tester.tap(find.text('Message 4'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear selection'));
    await tester.pumpAndSettle();
    expect(find.text('2 selected'), findsNothing);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).selectedIndex,
      1,
    );
    expect(find.text('Message 2'), findsOneWidget);

    await tester.longPress(find.text('Message 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Message 3'), findsNothing);
    expect(
      tester.widget<BottomBarItems>(find.byType(BottomBarItems)).selectedIndex,
      1,
    );
  });

  testWidgets('reader tap shows the bar without moving the article', (
    tester,
  ) async {
    await _pump(tester, const ReaderControlsRecipe());
    final bookmark = find.byTooltip('Bookmark');
    expect(bookmark.hitTestable(), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(bookmark.hitTestable(), findsNothing, reason: 'hidden on scroll');
    final offset = _scroll(tester).pixels;
    expect(offset, greaterThan(0));

    await tester.tapAt(_phone.center(Offset.zero));
    await tester.pumpAndSettle();
    expect(bookmark.hitTestable(), findsOneWidget);
    expect(_scroll(tester).pixels, offset);

    double fontSize() => tester
        .widget<Text>(find.textContaining('Paragraph').first)
        .style!
        .fontSize!;
    final before = fontSize();
    await tester.tap(find.byTooltip('Larger text'));
    await tester.pump();
    expect(fontSize(), before + 2);
    await tester.tap(bookmark);
    await tester.pump();
    expect(find.byTooltip('Remove bookmark'), findsOneWidget);
  });

  testWidgets('scroll under: the last row clears the bar, grown or not', (
    tester,
  ) async {
    await _pump(tester, const ScrollUnderRecipe());
    final scope = BottomBarScope.of(
      tester.element(find.byType(CustomScrollView)),
    );
    final lastRow = find.ancestor(
      of: find.text('Row 40'),
      matching: find.byType(ListTile),
    );

    Future<void> expectLastRowClear() async {
      _scroll(tester).jumpTo(_scroll(tester).maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(lastRow).bottom,
        lessThanOrEqualTo(_phone.height - scope.barHeight.value + 0.01),
      );
    }

    await expectLastRowClear();
    final collapsed = scope.barHeight.value;

    await tester.tap(find.byTooltip('Show filters'));
    await tester.pumpAndSettle();
    expect(scope.barHeight.value, greaterThan(collapsed));
    await expectLastRowClear();
  });

  for (final (name, largeText, rtl) in [
    ('320 wide', false, false),
    ('320 wide at 2x text', true, false),
    ('320 wide at 2x text in RTL', true, true),
  ]) {
    testWidgets('long labels fit $name', (tester) async {
      await _pump(tester, const LongLabelsRecipe(), size: const Size(320, 640));
      if (largeText) await tester.tap(find.byTooltip('Text size 2x'));
      if (rtl) await tester.tap(find.byTooltip('Right to left'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final items = find.byType(BottomBarItem);
      expect(items, findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        final size = tester.getSize(items.at(i));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(tester.getRect(items.at(i)).right, lessThanOrEqualTo(320));
        expect(tester.getRect(items.at(i)).left, greaterThanOrEqualTo(0));
      }
      final first = tester.getCenter(items.first).dx;
      final last = tester.getCenter(items.last).dx;
      expect(rtl ? last < first : last > first, isTrue);

      await tester.tap(items.last);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Account settings'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mini player shows less inline and play toggles', (tester) async {
    await _pump(tester, const MiniPlayerRecipe());
    expect(find.text('Midnight Drive · The Lanterns'), findsOneWidget);
    expect(find.byTooltip('Next'), findsOneWidget);
    final expandedY = tester.getCenter(find.byTooltip('Play')).dy;

    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Midnight Drive'), findsOneWidget);
    expect(find.byTooltip('Next'), findsNothing);
    expect(
      tester.getCenter(find.byTooltip('Pause')).dy,
      greaterThan(expandedY),
    );

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('split bar gaps pass taps to the body', (tester) async {
    await _pump(tester, const SplitBarRecipe());
    final profile = tester.getRect(find.byTooltip('Profile'));
    final pill = tester.getRect(find.byType(BottomBarItems));
    final search = tester.getRect(find.byTooltip('Search'));

    for (final gap in [
      Offset((profile.right + pill.left) / 2, pill.center.dy),
      Offset((pill.right + search.left) / 2, pill.center.dy),
    ]) {
      final tile = find
          .descendant(
            of: find.byType(GridView),
            matching: find.byType(ColoredBox),
          )
          .evaluate()
          .firstWhere(
            (e) => tester
                .getRect(find.byElementPredicate((x) => x == e))
                .contains(gap),
          );
      final result = HitTestResult();
      tester.binding.hitTestInView(result, gap, tester.view.viewId);
      final targets = result.path.map((entry) => entry.target).toList();
      expect(targets, contains(tile.renderObject), reason: 'gap at $gap');
      expect(
        targets,
        isNot(contains(tester.renderObject(find.byTooltip('Search')))),
      );
    }
  });

  test('EXAMPLES.md quotes every recipe exactly', () {
    final docs = File('../EXAMPLES.md').readAsStringSync();
    final marker = RegExp(
      r'<!-- example/lib/recipes/(\w+)\.dart -->\n```dart\n([\s\S]*?)```',
    );
    final quoted = <String>{};
    for (final match in marker.allMatches(docs)) {
      final source = File('lib/recipes/${match[1]}.dart').readAsStringSync();
      final lines = match[2]!.split('\n');
      final found = [for (var k = 0; k <= 24; k += 2) k].any(
        (k) => source.contains(
          lines
              .map((l) => l.isEmpty ? l : '${' ' * k}$l')
              .join('\n')
              .trimRight(),
        ),
      );
      expect(
        found,
        isTrue,
        reason: '${match[1]} quote drifted from the source',
      );
      quoted.add(match[1]!);
    }
    final files = Directory('lib/recipes')
        .listSync()
        .map((f) => f.uri.pathSegments.last.replaceAll('.dart', ''))
        .where((name) => name != 'recipes_page')
        .toSet();
    expect(quoted, files);
    for (final recipe in recipes) {
      expect(docs, contains('#/${recipe.slug})'), reason: recipe.slug);
    }
  });
}
