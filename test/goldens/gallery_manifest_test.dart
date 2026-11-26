import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gallery.dart';
import 'gallery_manifest.dart';

void main() {
  test('gallery.json matches the golden case table', () {
    final actual = File('test/goldens/gallery.json').readAsStringSync();
    expect(actual, goldenGalleryManifest(), reason: 'run make goldens-update');
  });

  test('gallery checker rejects empty and duplicate manifest entries', () {
    expect(
      galleryProblems(features: [], pngs: {}),
      containsAll([
        'gallery.json has no features',
        'no golden PNG files found',
      ]),
    );

    const duplicate = '''[
  {"title":"Feature","cases":[
    {"id":"case","shots":{"light":"case_light.png"}},
    {"id":"case","shots":{"dark":"case_dark.png"}}
  ]}
]''';
    expect(
      galleryProblems(
        features: _features(duplicate),
        pngs: {'case_light.png', 'case_dark.png'},
      ),
      contains('duplicate case id: case'),
    );

    const duplicatePng = '''[
  {"title":"Feature","cases":[
    {"id":"first","shots":{"light":"same.png"}},
    {"id":"second","shots":{"dark":"same.png"}}
  ]}
]''';
    expect(
      galleryProblems(features: _features(duplicatePng), pngs: {'same.png'}),
      contains('gallery.json contains duplicate golden filenames'),
    );
  });

  test('gallery checker catches missing, orphaned, and renamed PNGs', () {
    const manifest = '''[
  {"title":"Feature","cases":[
    {"id":"case","shots":{"light":"case_light.png"}}
  ]}
]''';
    final problems = galleryProblems(
      features: _features(manifest),
      pngs: {'renamed.png'},
    );
    expect(problems, [
      'golden not in gallery.json: renamed.png',
      'missing golden: case_light.png',
    ]);
  });
}

List<Map<String, dynamic>> _features(String json) =>
    (jsonDecode(json) as List).cast<Map<String, dynamic>>();
