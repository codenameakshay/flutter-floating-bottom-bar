import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GoldenFileComparator previous;
  setUpAll(() {
    previous = goldenFileComparator;
    goldenFileComparator = _TolerantComparator(
      (previous as LocalFileComparator).basedir.resolve(
        'bottom_bar_badge_test.dart',
      ),
    );
  });
  tearDownAll(() => goldenFileComparator = previous);

  _badgeGolden('badge_light.png', Brightness.light);
  _badgeGolden('badge_dark.png', Brightness.dark);
  _badgeGolden('badge_rtl.png', Brightness.light, direction: TextDirection.rtl);
}

void _badgeGolden(
  String fileName,
  Brightness brightness, {
  TextDirection direction = TextDirection.ltr,
}) {
  testWidgets(fileName, (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Builder(
              builder: (context) => BottomBar(
                body: const SizedBox.shrink(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: BottomBarItems(
                    selectedIndex: 0,
                    children: [
                      BottomBarItem(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                        label: const Text('Home'),
                        badge: const BottomBarBadge.dot(),
                      ),
                      BottomBarItem(
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        badge: const BottomBarBadge.count(3),
                      ),
                      BottomBarItem(
                        icon: const Icon(Icons.inbox_outlined),
                        selectedIcon: const Icon(Icons.inbox),
                        label: const Text('Inbox'),
                        badge: const BottomBarBadge.count(150),
                      ),
                      BottomBarItem(
                        icon: const Icon(Icons.notifications_outlined),
                        label: const Text('Updates'),
                        badge: const BottomBarBadge.label('New'),
                      ),
                      BottomBarItem(
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Profile'),
                        badge: BottomBarBadge.count(
                          7,
                          outline: BorderSide(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(BottomBar), matchesGoldenFile(fileName));
  });
}

/// Accepts antialiasing drift between machines: the GitHub macOS runner
/// rasterises these icon glyphs and curves a few pixels differently from a
/// local Mac. A misplaced indicator changes thousands of pixels, far above
/// this limit.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const _maxDiff = 0.0001;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _maxDiff) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
