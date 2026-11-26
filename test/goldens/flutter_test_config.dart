import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens render on one pinned setup: Linux x86_64 in the `tool/goldens`
/// image with the Flutter version from `.fvmrc`, real Roboto and MaterialIcons
/// fonts from the Flutter SDK, and a device pixel ratio of 1. On that setup
/// the comparison is exact. Run them with `make goldens`.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await _loadSdkFonts();

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..devicePixelRatio = 1
      ..physicalSize = const Size(800, 600);
  });

  if (Platform.environment['FFBB_GOLDENS'] != 'pinned') {
    goldenFileComparator = _UnpinnedComparator();
  }

  await testMain();
}

Future<void> _loadSdkFonts() async {
  final fonts = Directory(
    '${_flutterRoot()}/bin/cache/artifacts/material_fonts',
  );
  final roboto = FontLoader('Roboto');
  for (final file in fonts.listSync().whereType<File>()) {
    if (RegExp(r'/Roboto-\w+\.ttf$').hasMatch(file.path)) {
      roboto.addFont(_bytes(file));
    }
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(_bytes(File('${fonts.path}/MaterialIcons-Regular.otf')))).load();
}

Future<ByteData> _bytes(File file) async =>
    ByteData.sublistView(await file.readAsBytes());

/// The flutter tool exports FLUTTER_ROOT. Fall back to the tester binary at
/// `<root>/bin/cache/artifacts/engine/<platform>/flutter_tester`.
String _flutterRoot() =>
    Platform.environment['FLUTTER_ROOT'] ??
    File(
      Platform.resolvedExecutable,
    ).parent.parent.parent.parent.parent.parent.path;

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
