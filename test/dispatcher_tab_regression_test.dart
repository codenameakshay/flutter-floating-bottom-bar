import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/src/internal/scroll_notification_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('viewportFraction peeks do not make a neighboring list active', (
    tester,
  ) async {
    final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});
    final pages = PageController(initialPage: 2, viewportFraction: .25);
    final lists = List.generate(5, (_) => ScrollController());
    addTearDown(pages.dispose);
    addTearDown(() {
      for (final list in lists) {
        list.dispose();
      }
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            dispatcher.handle(notification);
            return false;
          },
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) {
              dispatcher.track(notification);
              return false;
            },
            child: SizedBox(
              width: 400,
              height: 500,
              child: PageView(
                controller: pages,
                children: [
                  for (var i = 0; i < lists.length; i++)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 40,
                        child: ListView.builder(
                          key: ValueKey('list-$i'),
                          controller: lists[i],
                          itemCount: 20,
                          itemBuilder: (_, index) =>
                              SizedBox(height: 40, child: Text('$i:$index')),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(dispatcher.activeScrollable()?.position, same(lists[2].position));
  });

  testWidgets('a selected page transformed outside the viewport is inactive', (
    tester,
  ) async {
    final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});
    final pages = PageController(initialPage: 1);
    final lists = List.generate(3, (_) => ScrollController());
    addTearDown(pages.dispose);
    addTearDown(() {
      for (final list in lists) {
        list.dispose();
      }
    });

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            dispatcher.handle(notification);
            return false;
          },
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (notification) {
              dispatcher.track(notification);
              return false;
            },
            child: SizedBox(
              width: 400,
              height: 500,
              child: PageView(
                controller: pages,
                children: [
                  for (var i = 0; i < lists.length; i++)
                    Transform.translate(
                      offset: i == 1 ? const Offset(1000, 0) : Offset.zero,
                      child: ListView.builder(
                        key: ValueKey('transformed-list-$i'),
                        controller: lists[i],
                        itemCount: 20,
                        itemBuilder: (_, index) =>
                            SizedBox(height: 40, child: Text('$i:$index')),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(dispatcher.activeScrollable(), isNull);
  });

  test('different page hosts do not share visibility memory', () {
    final dispatcher = ScrollNotificationDispatcher(
      onShouldHide: (_) {},
      restoreTabVisibility: true,
    );
    final oldHost = Object();
    final otherHost = Object();
    final replacementHost = Object();

    expect(dispatcher.enterTab((oldHost, 0), barVisible: false), isNull);
    expect(dispatcher.enterTab((otherHost, 0), barVisible: true), isTrue);
    expect(
      dispatcher.enterTab((replacementHost, 0), barVisible: false),
      isTrue,
    );
  });

  test('does not retain a departed tab anchor', () async {
    final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});
    final anchor = _trackAnchor(dispatcher);

    await _forceGC(timeout: const Duration(seconds: 10), fullGcCycles: 2);

    expect(anchor.target, isNull);
    expect(dispatcher.enterTab((Object(), 0), barVisible: false), isTrue);
  }, testOn: 'vm');

  testWidgets('restores a page after its non-keepalive list is recreated', (
    tester,
  ) async {
    final dispatcher = ScrollNotificationDispatcher(
      onShouldHide: (_) {},
      restoreTabVisibility: true,
    );
    final host = _PagesHost(dispatcher: dispatcher);
    addTearDown(host.pages.dispose);
    addTearDown(() {
      for (final list in host.lists) {
        list.dispose();
      }
    });
    await tester.pumpWidget(host);
    await tester.pumpAndSettle();

    final originalPosition = host.lists[0].position;
    final firstTab = dispatcher.resolve().active!.tab!;
    expect(dispatcher.enterTab(firstTab, barVisible: true), isNull);

    host.pages.jumpToPage(2);
    await tester.pumpAndSettle();
    expect(host.lists[0].hasClients, isFalse);
    final lastTab = dispatcher.resolve().active!.tab!;
    expect(dispatcher.enterTab(lastTab, barVisible: false), isTrue);

    host.pages.jumpToPage(0);
    await tester.pumpAndSettle();
    expect(host.lists[0].position, isNot(same(originalPosition)));
    final recreatedTab = dispatcher.resolve().active!.tab!;
    expect(dispatcher.enterTab(recreatedTab, barVisible: true), isFalse);
  });
}

@pragma('vm:never-inline')
WeakReference<Object> _trackAnchor(ScrollNotificationDispatcher dispatcher) {
  final anchor = Object();
  dispatcher.enterTab((anchor, 0), barVisible: true);
  return WeakReference(anchor);
}

Future<void> _forceGC({
  required Duration timeout,
  required int fullGcCycles,
}) async {
  final stopwatch = Stopwatch()..start();
  final barrier = developer.reachabilityBarrier;
  final storage = <List<int>>[];

  void allocateMemory() {
    storage.add(List.generate(30000, (n) => n));
    if (storage.length > 100) storage.removeAt(0);
  }

  while (developer.reachabilityBarrier < barrier + fullGcCycles) {
    if (stopwatch.elapsed > timeout) {
      throw TimeoutException('GC did not run before timeout', timeout);
    }
    await Future<void>.delayed(Duration.zero);
    allocateMemory();
  }
}

class _PagesHost extends StatelessWidget {
  _PagesHost({required this.dispatcher})
    : pages = PageController(),
      lists = List.generate(3, (_) => ScrollController());

  final ScrollNotificationDispatcher dispatcher;
  final PageController pages;
  final List<ScrollController> lists;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        dispatcher.handle(notification);
        return false;
      },
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (notification) {
          dispatcher.track(notification);
          return false;
        },
        child: SizedBox(
          width: 400,
          height: 500,
          child: PageView(
            controller: pages,
            children: [
              for (var i = 0; i < lists.length; i++)
                ListView.builder(
                  controller: lists[i],
                  itemCount: 20,
                  itemBuilder: (_, index) =>
                      SizedBox(height: 40, child: Text('$i:$index')),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
