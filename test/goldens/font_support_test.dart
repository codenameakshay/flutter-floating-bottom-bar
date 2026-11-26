import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'font_support.dart';

void main() {
  group('flutterRoot', () {
    final separator = Platform.pathSeparator;
    final tester = [
      '',
      'sdk',
      'bin',
      'cache',
      'artifacts',
      'engine',
      'linux-x64',
      'flutter_tester',
    ].join(separator);

    test('prefers a non-empty FLUTTER_ROOT', () {
      expect(
        flutterRoot(
          environmentRoot: '/sdk/from/env',
          resolvedExecutable: '/other/sdk/bin/cache/dart-sdk/bin/dart',
        ),
        '/sdk/from/env',
      );
    });

    test('falls back from flutter_tester to the SDK root', () {
      expect(
        flutterRoot(environmentRoot: null, resolvedExecutable: tester),
        '${separator}sdk',
      );
    });

    test('ignores an empty FLUTTER_ROOT and uses the tester path', () {
      expect(
        flutterRoot(environmentRoot: '', resolvedExecutable: tester),
        '${separator}sdk',
      );
    });
  });

  group('requiredRobotoFonts', () {
    late Directory fonts;

    setUp(() {
      fonts = Directory.systemTemp.createTempSync('golden-fonts-');
    });

    tearDown(() => fonts.deleteSync(recursive: true));

    test('requires the loaded faces and excludes condensed Roboto', () {
      const faces = [
        'Black',
        'BlackItalic',
        'Bold',
        'BoldItalic',
        'Italic',
        'Light',
        'LightItalic',
        'Medium',
        'MediumItalic',
        'Regular',
        'Thin',
        'ThinItalic',
      ];
      for (final face in faces) {
        File(
          '${fonts.path}${Platform.pathSeparator}Roboto-$face.ttf',
        ).createSync();
      }
      File(
        '${fonts.path}${Platform.pathSeparator}RobotoCondensed-Regular.ttf',
      ).createSync();
      final selected = requiredRobotoFonts(fonts);

      expect(selected, hasLength(faces.length));
      expect(selected.map((file) => file.uri.pathSegments.last).toList(), [
        for (final face in faces) 'Roboto-$face.ttf',
      ]);
      expect(
        selected.map((file) => file.uri.pathSegments.last),
        isNot(contains('RobotoCondensed-Regular.ttf')),
      );
    });

    test('fails loudly when the family is absent or incomplete', () {
      expect(
        () => requiredRobotoFonts(fonts),
        throwsA(isA<FileSystemException>()),
      );

      const incompleteFaces = [
        'Black',
        'BlackItalic',
        'Bold',
        'BoldItalic',
        'Italic',
        'Light',
        'LightItalic',
        'Medium',
        'MediumItalic',
        'Regular',
        'Thin',
      ];
      for (final face in incompleteFaces) {
        File(
          '${fonts.path}${Platform.pathSeparator}Roboto-$face.ttf',
        ).createSync();
      }
      expect(
        () => requiredRobotoFonts(fonts),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('fails loudly when MaterialIcons is absent', () {
      expect(
        () => requiredFontFile(fonts, 'MaterialIcons-Regular.otf'),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}
