import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/src/internal/scroll_notification_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('new metrics do not replace the most recently scrolled list', (
    tester,
  ) async {
    final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});
    final first = ScrollController();
    final second = ScrollController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var includeSecond = false;
    late StateSetter update;
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
            child: StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return Column(
                  children: [
                    Expanded(child: _list(first)),
                    if (includeSecond) Expanded(child: _list(second)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    first.jumpTo(100);
    await tester.pumpAndSettle();
    expect(dispatcher.activeScrollable()!.position, same(first.position));

    update(() => includeSecond = true);
    await tester.pumpAndSettle();
    expect(dispatcher.activeScrollable()!.position, same(first.position));

    second.jumpTo(100);
    await tester.pumpAndSettle();
    expect(dispatcher.activeScrollable()!.position, same(second.position));
  });

  testWidgets('metrics-only lists cannot evict the last scrolled source', (
    tester,
  ) async {
    final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});
    final controllers = List.generate(18, (_) => ScrollController());
    addTearDown(() {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
    var count = 1;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        dispatcher,
        StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return Column(
              children: [
                for (final controller in controllers.take(count))
                  Expanded(child: _list(controller)),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    controllers.first.jumpTo(100);
    await tester.pumpAndSettle();
    update(() => count = controllers.length);
    await tester.pumpAndSettle();
    expect(
      dispatcher.activeScrollable()!.position,
      same(controllers.first.position),
    );
  });

  testWidgets('an offstage list is not an active scroll source', (
    tester,
  ) async {
    final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var hidden = false;
    late StateSetter update;
    await tester.pumpWidget(
      _host(
        dispatcher,
        StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            return Offstage(offstage: hidden, child: _list(controller));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dispatcher.activeScrollable()!.position, same(controller.position));
    update(() => hidden = true);
    await tester.pumpAndSettle();
    expect(dispatcher.activeScrollable(), isNull);
    update(() => hidden = false);
    await tester.pumpAndSettle();
    expect(dispatcher.activeScrollable()!.position, same(controller.position));
  });
}

Widget _list(ScrollController controller) => ListView.builder(
  controller: controller,
  itemCount: 100,
  itemBuilder: (_, index) => SizedBox(height: 50, child: Text('$index')),
);

Widget _host(ScrollNotificationDispatcher dispatcher, Widget body) =>
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
          child: body,
        ),
      ),
    );
