@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cases/table.dart';
import 'gallery_manifest.dart';
import 'golden_case.dart';

void main() {
  for (final feature in goldenFeatures) {
    group(feature.title, () {
      for (final c in feature.cases) {
        for (final shot in c.shots) {
          testWidgets(c.fileName(shot), (tester) async {
            pinGoldenView(tester, c.size);
            if (c.run case final run?) {
              await run(tester, shot);
            } else {
              await tester.pumpWidget(c.build!(shot));
              await tester.pumpAndSettle();
            }
            await expectLater(
              (c.target ?? () => find.byType(BottomBar).first)(),
              matchesGoldenFile(c.fileName(shot)),
            );
          });
        }
      }
    });
  }

  // The gallery reads this manifest. It is rewritten with the goldens and
  // must match the table otherwise.
  test('gallery.json matches the table', () {
    final file = File('test/goldens/gallery.json');
    final manifest = goldenGalleryManifest();
    if (autoUpdateGoldenFiles) {
      file.writeAsStringSync(manifest);
    } else {
      expect(
        file.readAsStringSync(),
        manifest,
        reason: 'run make goldens-update',
      );
    }
  });
}
