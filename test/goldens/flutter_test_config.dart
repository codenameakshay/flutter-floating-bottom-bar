import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'font_support.dart';

/// Goldens render on one pinned setup: Linux x86_64 in the `tool/goldens`
/// image with the Flutter version from `.fvmrc`, real Roboto and MaterialIcons
/// fonts from the Flutter SDK, and a device pixel ratio of 1. On that setup
/// the comparison is exact. Run them with `make goldens`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.environment['FFBB_GOLDENS'] == 'pinned') {
    await _loadSdkFonts();
  } else {
    goldenFileComparator = _UnpinnedComparator();
  }

  await testMain();
}

Future<void> _loadSdkFonts() async {
  final fonts = Directory(
    '${_flutterRoot()}/bin/cache/artifacts/material_fonts',
  );
  final robotoFiles = requiredRobotoFonts(fonts);
  final icons = requiredFontFile(fonts, 'MaterialIcons-Regular.otf');
  final roboto = FontLoader('Roboto');
  for (final file in robotoFiles) {
    roboto.addFont(_bytes(file));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(_bytes(icons))).load();
}

Future<ByteData> _bytes(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

/// The flutter tool exports FLUTTER_ROOT. Fall back to the tester binary at
/// `<root>/bin/cache/artifacts/engine/<platform>/flutter_tester`.
String _flutterRoot() => flutterRoot(
  environmentRoot: Platform.environment['FLUTTER_ROOT'],
  resolvedExecutable: Platform.resolvedExecutable,
);

class _UnpinnedComparator extends GoldenFileComparator {
  static const _message =
      'Goldens render only on the pinned Linux setup. Run `make goldens` to '
      'check them or `make goldens-update` to regenerate them (CONTRIBUTING.md).';

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) =>
      throw TestFailure(_message);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      throw TestFailure(_message);
}
