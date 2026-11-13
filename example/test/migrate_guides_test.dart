import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_floating_bottom_bar_example/main.dart';
import 'package:flutter_floating_bottom_bar_example/migrate/animated_bottom_navigation_bar.dart'
    as animated_bottom_navigation_bar;
import 'package:flutter_floating_bottom_bar_example/migrate/bottom_navigation_bar.dart'
    as bottom_navigation_bar;
import 'package:flutter_floating_bottom_bar_example/migrate/convex_bottom_bar.dart'
    as convex_bottom_bar;
import 'package:flutter_floating_bottom_bar_example/migrate/google_nav_bar.dart'
    as google_nav_bar;
import 'package:flutter_floating_bottom_bar_example/migrate/navigation_bar.dart'
    as navigation_bar;
import 'package:flutter_floating_bottom_bar_example/migrate/persistent_bottom_nav_bar_v2.dart'
    as persistent_bottom_nav_bar_v2;
import 'package:flutter_floating_bottom_bar_example/migrate/salomon_bottom_bar.dart'
    as salomon_bottom_bar;
import 'package:material_ui/material_ui.dart';

final _afterSnippets = <String, Widget Function()>{
  'animated_bottom_navigation_bar': () =>
      const animated_bottom_navigation_bar.HomeShell(),
  'bottom_navigation_bar': () => const bottom_navigation_bar.HomeShell(),
  'convex_bottom_bar': () => const convex_bottom_bar.HomeShell(),
  'google_nav_bar': () => const google_nav_bar.HomeShell(),
  'navigation_bar': () => const navigation_bar.HomeShell(),
  'persistent_bottom_nav_bar_v2': () =>
      const persistent_bottom_nav_bar_v2.HomeShell(),
  'salomon_bottom_bar': () => const salomon_bottom_bar.HomeShell(),
};

final _guides = Directory('../docs/migrate')
    .listSync()
    .whereType<File>()
    .where((file) => file.path.endsWith('.md'))
    .toList();

final _linkedDocs = [
  ..._guides,
  File('../README.md'),
  File('../EXAMPLES.md'),
  File(
    '../.claude/skills/flutter-floating-bottom-bar/references/replacing-bars.md',
  ),
];

String _anchor(String heading) => heading
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
    .replaceAll(' ', '-');

void main() {
  test('every guide quotes its after file exactly', () {
    final quoted = <String>{};
    final marker = RegExp(
      r'<!-- (example/lib/migrate/(\w+)\.dart) -->\n```dart\n([\s\S]*?)```',
    );
    for (final guide in _guides) {
      for (final match in marker.allMatches(guide.readAsStringSync())) {
        final file = File('../${match[1]}');
        expect(
          match[3],
          file.readAsStringSync(),
          reason: '${guide.path} quotes ${match[1]}',
        );
        quoted.add(match[2]!);
      }
    }
    final files = Directory('lib/migrate')
        .listSync()
        .map((file) => file.uri.pathSegments.last.replaceAll('.dart', ''))
        .toSet();
    expect(quoted, files, reason: 'each after file is quoted by a guide');
    expect(_afterSnippets.keys.toSet(), files);
  });

  test('relative links, anchors and demo slugs resolve', () {
    final slugs = demos.map((demo) => demo.slug).toSet();
    final demoLink = RegExp(
      r'codenameakshay\.github\.io/flutter-floating-bottom-bar/#/([\w-]+)',
    );
    final repoLink = RegExp(
      r'github\.com/codenameakshay/flutter-floating-bottom-bar/(?:blob|tree)/main/([^)\s#]+)',
    );
    final link = RegExp(r'\]\(([^)\s]+)\)');
    for (final doc in _linkedDocs) {
      final text = doc.readAsStringSync();
      for (final match in demoLink.allMatches(text)) {
        expect(slugs, contains(match[1]), reason: '${doc.path} demo link');
      }
      for (final match in repoLink.allMatches(text)) {
        expect(
          FileSystemEntity.typeSync('../${match[1]}'),
          isNot(FileSystemEntityType.notFound),
          reason: '${doc.path} -> ${match[0]}',
        );
      }
      for (final match in link.allMatches(text)) {
        final target = match[1]!;
        if (target.contains('://') || target.startsWith('mailto:')) continue;
        final [path, ...rest] = target.split('#');
        final file = path.isEmpty ? doc : File('${doc.parent.path}/$path');
        expect(
          FileSystemEntity.typeSync(file.path),
          isNot(FileSystemEntityType.notFound),
          reason: '${doc.path} -> $target',
        );
        if (rest.isEmpty || !file.path.endsWith('.md')) continue;
        final anchors = RegExp(r'^#+ (.+)$', multiLine: true)
            .allMatches(file.readAsStringSync())
            .map((heading) => _anchor(heading[1]!))
            .toSet();
        expect(anchors, contains(rest.first), reason: '${doc.path} -> $target');
      }
    }
  });

  for (final MapEntry(key: name, value: build) in _afterSnippets.entries) {
    testWidgets('$name after snippet switches tabs', (tester) async {
      await tester.pumpWidget(MaterialApp(home: build()));
      await tester.tap(
        find
            .ancestor(
              of: find.byIcon(Icons.search),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Search row'), findsWidgets);
    });
  }

  testWidgets(
    'persistent tabs: back pops the tab, then goes Home, then exits',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: persistent_bottom_nav_bar_v2.HomeShell()),
      );
      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search row 2'));
      await tester.pumpAndSettle();
      expect(find.text('Search item 2'), findsOneWidget);

      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search').last);
      await tester.pumpAndSettle();
      expect(find.text('Search item 2'), findsOneWidget, reason: 'tab kept');

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Search item 2'), findsNothing);
      expect(find.text('Search row 2'), findsOneWidget);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Home row 0'), findsOneWidget);

      expect(
        await tester.binding.handlePopRoute(),
        isFalse,
        reason: 'Home root hands back to the system',
      );
    },
  );

  testWidgets('persistent tabs: reselect pops the tab to its root', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: persistent_bottom_nav_bar_v2.HomeShell()),
    );
    await tester.tap(find.text('Home row 1'));
    await tester.pumpAndSettle();
    expect(find.text('Home item 1'), findsOneWidget);
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Home item 1'), findsNothing);
    expect(find.text('Home row 1'), findsOneWidget);
  });
}
