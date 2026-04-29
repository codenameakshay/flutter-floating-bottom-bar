import 'package:flutter/material.dart';

import 'demos/badges_demo.dart';
import 'demos/basic_demo.dart';
import 'demos/nested_scroll_demo.dart';
import 'demos/search_bar_demo.dart';
import 'demos/tab_bar_demo.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_floating_bottom_bar example',
      theme: ThemeData(colorSchemeSeed: Colors.yellow, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const _DemoPicker(),
    );
  }
}

class _DemoPicker extends StatelessWidget {
  const _DemoPicker();

  @override
  Widget build(BuildContext context) {
    final demos = <(String, WidgetBuilder)>[
      ('Tab bar', (_) => const TabBarDemoPage()),
      ('Basic', (_) => const BasicDemoPage()),
      ('Search bar', (_) => const SearchBarDemoPage()),
      ('Nested scroll', (_) => const NestedScrollDemoPage()),
      ('Badges', (_) => const BadgesDemoPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Demos')),
      body: ListView(
        children: [
          for (final (name, builder) in demos)
            ListTile(
              title: Text(name),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: builder),
              ),
            ),
        ],
      ),
    );
  }
}
