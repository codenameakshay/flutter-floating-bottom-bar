import 'dart:convert';

import 'cases/table.dart';

/// The checked-in gallery metadata derived from the golden case table.
String goldenGalleryManifest() =>
    '${const JsonEncoder.withIndent('  ').convert([
      for (final f in goldenFeatures) {
          'title': f.title,
          'readme': f.readme,
          'demo': f.demo,
          'cases': [
            for (final c in f.cases) {
                'id': c.id,
                'caption': c.caption,
                'shots': {for (final s in c.shots) s.name: c.fileName(s)},
              },
          ],
        },
    ])}\n';
