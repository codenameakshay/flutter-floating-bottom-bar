import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/src/internal/scroll_notification_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

class _Pages {
  _Pages({double fraction = 1})
    : pages = PageController(viewportFraction: fraction);

  final PageController pages;
  final lists = List.generate(3, (_) => ScrollController());
  final hidden = <bool>[];
  late final dispatcher = ScrollNotificationDispatcher(
    onShouldHide: hidden.add,
  );

  Widget list(int index) => NotificationListener<ScrollMetricsNotification>(
    onNotification: (notification) {
      dispatcher.track(notification);
      return false;
    },
    child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        dispatcher.handle(notification);
        return false;
      },
      child: ListView.builder(
        key: ValueKey(index),
        controller: lists[index],
        itemExtent: 50,
        itemCount: 60,
        itemBuilder: (_, row) => Text('$index:$row'),
      ),
    ),
  );

  Widget app({Axis axis = Axis.horizontal}) => MaterialApp(
    home: Center(
      child: SizedBox(
        width: 400,
        height: 400,
        child: PageView(
          controller: pages,
          scrollDirection: axis,
          children: List.generate(3, list),
        ),
      ),
    ),
  );

  Future<void> pump(WidgetTester tester, Duration elapsed) async {
    tester.binding.addPostFrameCallback((_) => dispatcher.resolve());
    tester.binding.scheduleFrame();
    await tester.pump(elapsed);
  }

  void dispose() {
    pages.dispose();
    for (final controller in lists) {
      controller.dispose();
    }
  }
}

void main() {
  for (final axis in Axis.values) {
    for (final fraction in [1.0, 0.5]) {
      testWidgets(
        '$axis fraction $fraction selects and scrolls the landing list',
        (tester) async {
          final fixture = _Pages(fraction: fraction);
          addTearDown(fixture.dispose);
          await tester.pumpWidget(fixture.app(axis: axis));
          await tester.pumpAndSettle();
          fixture.pages.animateToPage(
            1,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
          );
          var landed = false;
          for (var i = 0; i < 70; i++) {
            await fixture.pump(tester, const Duration(milliseconds: 16));
            final active = fixture.dispatcher.resolve().active;
            if (fixture.lists[1].hasClients &&
                active?.position == fixture.lists[1].position &&
                fixture.pages.position.isScrollingNotifier.value) {
              expect(active!.tab!.$2, 1);
              expect(
                (fixture.pages.position.pixels - 400 * fraction).abs(),
                lessThanOrEqualTo(8),
              );
              fixture.hidden.clear();
              fixture.lists[1].animateTo(
                100,
                duration: const Duration(milliseconds: 64),
                curve: Curves.linear,
              );
              await tester.pump();
              await fixture.pump(tester, const Duration(milliseconds: 16));
              expect(fixture.pages.position.isScrollingNotifier.value, isTrue);
              expect(fixture.hidden, contains(true));
              landed = true;
              break;
            }
          }
          expect(landed, isTrue);
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets('a vertical page host still drives the bar like a list', (
    tester,
  ) async {
    final fixture = _Pages();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          fixture.dispatcher.handle(notification);
          return false;
        },
        child: fixture.app(axis: Axis.vertical),
      ),
    );
    await tester.pumpAndSettle();
    fixture.hidden.clear();
    fixture.pages.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    expect(fixture.hidden, contains(true), reason: 'paging down hides');
  });

  testWidgets('a tab tap warp does not follow the skipped middle list', (
    tester,
  ) async {
    final fixture = _Pages();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'A'),
                  Tab(text: 'B'),
                  Tab(text: 'C'),
                ],
              ),
            ),
            body: TabBarView(children: List.generate(3, fixture.list)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('C'));
    for (var i = 0; i < 30; i++) {
      await fixture.pump(tester, const Duration(milliseconds: 16));
      final active = fixture.dispatcher.resolve().active;
      if (fixture.lists[1].hasClients) {
        expect(active?.position, isNot(fixture.lists[1].position));
      }
      if (active != null) {
        final index = fixture.lists.indexWhere(
          (list) =>
              list.hasClients && identical(list.position, active.position),
        );
        expect(active.tab?.$2, index);
      }
    }
    await tester.pumpAndSettle();
    expect(
      fixture.dispatcher.resolve().active?.position,
      fixture.lists[2].position,
    );
    expect(fixture.dispatcher.resolve().active?.tab?.$2, 2);
  });

  testWidgets('a slow finger held near a boundary currently counts as landed', (
    tester,
  ) async {
    final fixture = _Pages();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(fixture.app());
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(590, 300));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-390, 0));
    await fixture.pump(tester, const Duration(milliseconds: 16));
    fixture.dispatcher.resolve();
    for (var i = 0; i < 30; i++) {
      await gesture.moveBy(const Offset(-1, 0));
      await fixture.pump(tester, const Duration(milliseconds: 20));
      fixture.dispatcher.resolve();
      if ((fixture.pages.position.pixels - 400).abs() <= 6) break;
    }
    expect(fixture.pages.position.isScrollingNotifier.value, isTrue);
    expect((fixture.pages.position.pixels - 400).abs(), lessThanOrEqualTo(8));
    expect(fixture.dispatcher.resolve().active?.tab?.$2, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
