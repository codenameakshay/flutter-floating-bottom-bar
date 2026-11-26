import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../golden_case.dart';

final basicsFeature = GoldenFeature(
  'Default bar',
  readme: 'basic-usage',
  demo: 'minimal-api',
  cases: [
    GoldenCase(
      'bottom_bar_default',
      caption: 'Default bar in light and dark themes',
      build: (shot) => MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          brightness: shot.brightness,
        ),
        home: Scaffold(
          body: BottomBar(
            body: const SizedBox.shrink(),
            child: const SizedBox(
              height: 56,
              child: Center(child: Text('Bar')),
            ),
          ),
        ),
      ),
    ),
  ],
);
