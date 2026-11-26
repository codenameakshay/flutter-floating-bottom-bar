import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// One rendering of a case: a theme brightness, a text direction and a text
/// scale. [name] is the file-name suffix; an empty name means no suffix.
class Shot {
  const Shot(
    this.name, {
    this.brightness = Brightness.light,
    this.direction = TextDirection.ltr,
    this.textScale = 1,
  });

  static const light = Shot('light');
  static const dark = Shot('dark', brightness: Brightness.dark);
  static const rtl = Shot('rtl', direction: TextDirection.rtl);
  static const text2x = Shot('text2x', textScale: 2);

  final String name;
  final Brightness brightness;
  final TextDirection direction;
  final double textScale;

  bool get isDark => brightness == Brightness.dark;
}

const themed = [Shot.light, Shot.dark];
const themedRtl = [Shot.light, Shot.dark, Shot.rtl];

/// One row of the golden table: a widget state rendered once per [shots].
///
/// Give [build] for a widget that only needs a pump and a settle. Give [run]
/// when the state needs more (a controller call, a midpoint, a tap); it pumps
/// the widget itself.
class GoldenCase {
  const GoldenCase(
    this.id, {
    required this.caption,
    this.shots = themed,
    this.size = const Size(800, 600),
    this.build,
    this.run,
    this.target,
  }) : assert((build == null) != (run == null), 'give build or run');

  final String id;
  final String caption;
  final List<Shot> shots;

  /// The logical size of the test view. The device pixel ratio is always 1.
  final Size size;
  final Widget Function(Shot shot)? build;
  final Future<void> Function(WidgetTester tester, Shot shot)? run;

  /// What the golden captures. Defaults to the first `BottomBar`.
  final Finder Function()? target;

  String fileName(Shot shot) =>
      shot.name.isEmpty ? '$id.png' : '${id}_${shot.name}.png';
}

/// A gallery section: a feature with its README section and playground demo.
class GoldenFeature {
  const GoldenFeature(
    this.title, {
    required this.readme,
    required this.demo,
    required this.cases,
  });

  final String title;

  /// The README heading anchor, without the `#`.
  final String readme;

  /// The playground demo slug, or null when the playground has no demo.
  final String? demo;
  final List<GoldenCase> cases;
}

/// The app most cases render in: Material 3 seeded from indigo, in the shot's
/// brightness, direction and text scale.
Widget goldenApp(Shot shot, Widget home, {Color seed = Colors.indigo}) {
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: shot.brightness,
    ),
    builder: shot.textScale == 1
        ? null
        : (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(shot.textScale)),
            child: child!,
          ),
    home: Directionality(textDirection: shot.direction, child: home),
  );
}
