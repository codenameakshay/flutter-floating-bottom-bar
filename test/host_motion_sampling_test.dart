import 'package:flutter/widgets.dart';
import 'package:flutter_floating_bottom_bar/src/internal/scroll_notification_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';

class _Moving extends ScrollActivity {
  _Moving(super.delegate);
  @override
  bool get isScrolling => true;
  @override
  bool get shouldIgnorePointer => false;
  @override
  double get velocity => 0;
}

class _Fixture {
  final pages = PageController();
  final lists = List.generate(3, (_) => ScrollController());
  final dispatcher = ScrollNotificationDispatcher(onShouldHide: (_) {});

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (n) {
            dispatcher.track(n);
            return false;
          },
          child: PageView(
            allowImplicitScrolling: true,
            controller: pages,
            children: [
              for (final list in lists)
                ListView(
                  controller: list,
                  children: const [SizedBox(height: 2000)],
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    pages.position.beginActivity(
      _Moving(pages.position as ScrollActivityDelegate),
    );
  }

  Future<({ActiveScrollable? active, bool paging})> sample(
    WidgetTester tester,
    Duration elapsed,
  ) async {
    late ({ActiveScrollable? active, bool paging}) result;
    tester.binding.addPostFrameCallback((_) {
      result = dispatcher.resolve();
    });
    tester.binding.scheduleFrame();
    await tester.pump(elapsed);
    return result;
  }

  void dispose() {
    pages.dispose();
    for (final list in lists) {
      list.dispose();
    }
  }
}

void main() {
  testWidgets('the first sample cannot establish landing speed', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    final result = await f.sample(tester, const Duration(milliseconds: 16));
    expect(result.paging, isTrue);
    expect(result.active, isNull);
  });

  testWidgets('a pointer query cannot seed a sample with an old frame time', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    f.pages.position.setPixels(6);
    expect(f.dispatcher.resolve().paging, isTrue);
    expect(
      (await f.sample(tester, const Duration(milliseconds: 16))).paging,
      isTrue,
    );
  });

  testWidgets('changed pixels within a frame cannot reuse its cached speed', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    await f.sample(tester, const Duration(milliseconds: 16));
    await f.sample(tester, const Duration(milliseconds: 16));
    tester.binding.addPostFrameCallback((_) {
      expect(f.dispatcher.resolve().paging, isFalse);
      f.pages.position.setPixels(6);
      expect(f.dispatcher.resolve().paging, isTrue);
      expect(f.dispatcher.resolve().paging, isTrue);
    });
    tester.binding.scheduleFrame();
    await tester.pump(const Duration(milliseconds: 16));
  });

  testWidgets('unchanged repeated calls share a frame sample', (tester) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    await f.sample(tester, const Duration(milliseconds: 16));
    final result = await f.sample(tester, const Duration(milliseconds: 16));
    expect(result.active?.position, same(f.lists[0].position));
    for (var i = 0; i < 5; i++) {
      expect(f.dispatcher.resolve(), result);
    }
  });

  testWidgets('pointer changes between frames cannot reuse a low speed', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    await f.sample(tester, const Duration(milliseconds: 16));
    expect(
      (await f.sample(tester, const Duration(milliseconds: 16))).paging,
      isFalse,
    );
    f.pages.position.setPixels(6);
    expect(f.dispatcher.resolve().paging, isTrue);
    expect(f.dispatcher.resolve().paging, isTrue);
  });

  testWidgets('pointer samples do not erase motion before the next frame', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    await f.sample(tester, const Duration(milliseconds: 16));
    await f.sample(tester, const Duration(milliseconds: 16));
    f.pages.position.setPixels(6);
    f.dispatcher.resolve();
    expect(
      (await f.sample(tester, const Duration(milliseconds: 16))).paging,
      isTrue,
    );
  });

  testWidgets('a frame with no elapsed time cannot conceal motion', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    await f.sample(tester, const Duration(milliseconds: 16));
    await f.sample(tester, const Duration(milliseconds: 16));
    f.pages.position.setPixels(6);
    expect((await f.sample(tester, Duration.zero)).paging, isTrue);
  });

  testWidgets('an old sample cannot average a fast middle-page crossing', (
    tester,
  ) async {
    final f = _Fixture();
    addTearDown(f.dispose);
    await f.mount(tester);
    await f.sample(tester, const Duration(milliseconds: 16));
    await f.sample(tester, const Duration(milliseconds: 16));
    f.pages.position.setPixels(f.pages.position.viewportDimension);
    final result = await f.sample(tester, const Duration(seconds: 20));
    expect(result.paging, isTrue);
    expect(result.active, isNull);
  });
}
