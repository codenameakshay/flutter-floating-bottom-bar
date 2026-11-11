import 'package:material_ui/material_ui.dart';

import 'demos/ai_prompt_dock_demo.dart';
import 'demos/badges_demo.dart';
import 'demos/basic_demo.dart';
import 'demos/basic_tab_bar_demo.dart';
import 'demos/custom_transition_demo.dart';
import 'demos/issues_dock_demo.dart';
import 'demos/nested_scroll_demo.dart';

void main() => runApp(const ExampleApp());

/// Every demo, keyed by the slug used in its deep link (`/#/<slug>` on web).
final demos = <({String slug, String title, WidgetBuilder builder})>[
  (
    slug: 'issues-dock',
    title: 'Issues dock',
    builder: (_) => const IssuesDockDemoPage(),
  ),
  (
    slug: 'ai-prompt-dock',
    title: 'AI prompt dock',
    builder: (_) => const AiPromptDockDemoPage(),
  ),
  (
    slug: 'basic-tab-bar',
    title: 'Basic TabBar',
    builder: (_) => const BasicTabBarDemoPage(),
  ),
  (
    slug: 'minimal-api',
    title: 'Minimal API',
    builder: (_) => const BasicDemoPage(),
  ),
  (
    slug: 'nested-scroll',
    title: 'Nested scroll',
    builder: (_) => const NestedScrollDemoPage(),
  ),
  (
    slug: 'badged-nav',
    title: 'Badged nav',
    builder: (_) => const BadgesDemoPage(),
  ),
  (
    slug: 'custom-transition',
    title: 'Custom transition',
    builder: (_) => const CustomTransitionDemoPage(),
  ),
];

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
      routes: {
        '/': (_) => const _DemoPicker(),
        for (final demo in demos) '/${demo.slug}': demo.builder,
      },
      builder: (context, child) => _DeviceFrame(child: child!),
    );
  }
}

/// Shows the app inside a phone-sized frame when the window is wider than a
/// phone, so desktop visitors see the demos at the size they were designed for.
class _DeviceFrame extends StatelessWidget {
  const _DeviceFrame({required this.child});

  static const _phoneBreakpoint = 600.0;
  static const _frameSize = Size(430, 932);
  static const _radius = BorderRadius.all(Radius.circular(44));

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < _phoneBreakpoint ? child : _framed(context),
    );
  }

  Widget _framed(BuildContext context) {
    final media = MediaQuery.of(context);
    return ColoredBox(
      color: const Color(0xFFE9E9E4),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints.loose(_frameSize),
            child: DecoratedBox(
              key: const Key('device-frame'),
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: _radius,
                border: Border.all(color: const Color(0xFF111111), width: 6),
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: _radius,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 48,
                      offset: Offset(0, 24),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: _radius,
                  child: LayoutBuilder(
                    builder: (context, constraints) => MediaQuery(
                      data: media.copyWith(
                        size: constraints.biggest,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        viewPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoPicker extends StatelessWidget {
  const _DemoPicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demos')),
      body: ListView(
        children: [
          for (final demo in demos)
            ListTile(
              title: Text(demo.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/${demo.slug}'),
            ),
        ],
      ),
    );
  }
}
