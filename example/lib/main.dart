import 'package:flutter/material.dart';

import 'demos/badges_demo.dart';
import 'demos/basic_demo.dart';
import 'demos/custom_transition_demo.dart';
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
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF111111),
        scaffoldBackgroundColor: const Color(0xFFFAFAF8),
        useMaterial3: true,
      ),
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
      ('Issues dock', (_) => const TabBarDemoPage()),
      ('AI prompt dock', (_) => const SearchBarDemoPage()),
      ('Minimal API', (_) => const BasicDemoPage()),
      ('Nested scroll', (_) => const NestedScrollDemoPage()),
      ('Badged nav', (_) => const BadgesDemoPage()),
      ('Custom transition', (_) => const CustomTransitionDemoPage()),
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
