import 'dart:io';

const _robotoFaces = <String>[
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

/// Resolves the Flutter SDK root from the tool environment or tester binary.
String flutterRoot({
  required String? environmentRoot,
  required String resolvedExecutable,
}) {
  if (environmentRoot != null && environmentRoot.isNotEmpty) {
    return environmentRoot;
  }

  var directory = File(resolvedExecutable).parent;
  // `<root>/bin/cache/artifacts/engine/<platform>/flutter_tester`
  for (var i = 0; i < 5; i++) {
    directory = directory.parent;
  }
  return directory.path;
}

/// Returns the required Roboto faces in filename order. Missing faces are
/// errors because FontLoader can silently fall back to another font.
List<File> requiredRobotoFonts(Directory fontsDirectory) {
  return [
    for (final face in _robotoFaces)
      requiredFontFile(fontsDirectory, 'Roboto-$face.ttf'),
  ];
}

/// Resolves a required SDK font, failing before FontLoader can silently omit it.
File requiredFontFile(Directory directory, String name) {
  final file = File('${directory.path}${Platform.pathSeparator}$name');
  if (!file.existsSync()) {
    throw FileSystemException('Required golden font is missing.', file.path);
  }
  return file;
}
