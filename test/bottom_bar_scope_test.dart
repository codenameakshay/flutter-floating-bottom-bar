import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'BottomBarScope.barHeight reports outer footprint including offset and safe area',
      (tester) async {
    double? observed;
    const childHeight = 56.0;
    const offset = 10.0;
    const safeAreaBottom = 24.0;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: safeAreaBottom),
        ),
        child: MaterialApp(
          home: Scaffold(
            body: BottomBar(
              layout: const BottomBarLayout(offset: offset),
              body: Builder(
                builder: (ctx) {
                  final h = BottomBarScope.of(ctx).barHeight;
                  return ValueListenableBuilder<double>(
                    valueListenable: h,
                    builder: (_, value, __) {
                      observed = value;
                      return ListView(
                        children: const [SizedBox(height: 1000)],
                      );
                    },
                  );
                },
              ),
              child: const SizedBox(height: childHeight, width: 200),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(observed, isNotNull);
    expect(
        observed!, closeTo(childHeight + (offset * 2) + safeAreaBottom, 0.01));
  });

  testWidgets(
      'BottomBarScope.barHeight updates when bar child height changes without rebuilding BottomBar',
      (tester) async {
    final barChildKey = GlobalKey<_ResizableBarChildState>();
    double? observed;
    var bottomBarBuilds = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _BottomBarBuildCounter(
          onBuild: () => bottomBarBuilds += 1,
          child: BottomBar(
            layout: const BottomBarLayout(offset: 0, respectSafeArea: false),
            body: Builder(
              builder: (ctx) {
                final h = BottomBarScope.of(ctx).barHeight;
                return ValueListenableBuilder<double>(
                  valueListenable: h,
                  builder: (_, value, __) {
                    observed = value;
                    return ListView(
                      children: const [SizedBox(height: 1000)],
                    );
                  },
                );
              },
            ),
            child: ResizableBarChild(key: barChildKey, initialHeight: 40),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(observed, closeTo(40, 0.01));
    expect(bottomBarBuilds, 1);

    barChildKey.currentState!.setHeight(88);
    await tester.pump();
    await tester.pump();

    expect(observed, closeTo(88, 0.01));
    expect(bottomBarBuilds, 1);
  });

  testWidgets('BottomBarScope.isVisible reflects controller', (tester) async {
    final controller = BottomBarController();
    bool? observed;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BottomBar(
          controller: controller,
          body: Builder(
            builder: (ctx) {
              final v = BottomBarScope.of(ctx).isVisible;
              return ValueListenableBuilder<bool>(
                valueListenable: v,
                builder: (_, value, __) {
                  observed = value;
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          child: const SizedBox(height: 56, width: 200),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(observed, isTrue);

    controller.hide();
    await tester.pumpAndSettle();
    expect(observed, isFalse);
  });
}

class _BottomBarBuildCounter extends StatelessWidget {
  const _BottomBarBuildCounter({
    required this.onBuild,
    required this.child,
  });

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}

class ResizableBarChild extends StatefulWidget {
  const ResizableBarChild({
    required this.initialHeight,
    super.key,
  });

  final double initialHeight;

  @override
  State<ResizableBarChild> createState() => _ResizableBarChildState();
}

class _ResizableBarChildState extends State<ResizableBarChild> {
  late double _height = widget.initialHeight;

  void setHeight(double height) {
    setState(() {
      _height = height;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: _height, width: 200);
  }
}
