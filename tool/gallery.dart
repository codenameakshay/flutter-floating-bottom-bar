// Builds the golden gallery from test/goldens/gallery.json and the PNGs.
//
//   dart run tool/gallery.dart --check          # fail if goldens and table disagree
//   dart run tool/gallery.dart --out build/gallery
//
// gallery.json is written by `make goldens-update` from the case table in
// test/goldens/cases/. The page links each feature to its README section and
// playground demo, and lays the shots of a case side by side.
import 'dart:convert';
import 'dart:io';

const _repo = 'https://github.com/codenameakshay/flutter-floating-bottom-bar';

void main(List<String> args) {
  final goldens = Directory('test/goldens');
  final features =
      (jsonDecode(File('${goldens.path}/gallery.json').readAsStringSync())
              as List)
          .cast<Map<String, dynamic>>();

  final listed = {
    for (final f in features)
      for (final c in (f['cases'] as List).cast<Map<String, dynamic>>())
        ...(c['shots'] as Map).values.cast<String>(),
  };
  final onDisk = {
    for (final e in goldens.listSync())
      if (e is File && e.path.endsWith('.png')) e.uri.pathSegments.last,
  };
  final problems = [
    for (final f in listed.difference(onDisk)) 'missing golden: $f',
    for (final f in onDisk.difference(listed)) 'golden not in the table: $f',
  ]..sort();
  if (problems.isNotEmpty) {
    stderr
      ..writeln(problems.join('\n'))
      ..writeln('The gallery is out of date. Run make goldens-update.');
    exit(1);
  }
  if (args.contains('--check')) {
    stdout.writeln('Gallery: ${listed.length} goldens match the table.');
    return;
  }

  final i = args.indexOf('--out');
  final out = Directory(
    i >= 0 && i + 1 < args.length ? args[i + 1] : 'build/gallery',
  );
  final images = Directory('${out.path}/images')..createSync(recursive: true);
  for (final f in listed) {
    File('${goldens.path}/$f').copySync('${images.path}/$f');
  }
  final flutter = RegExp(
    r'"flutter":\s*"([^"]+)"',
  ).firstMatch(File('.fvmrc').readAsStringSync())!.group(1);
  File('${out.path}/index.html').writeAsStringSync(
    _page(features, flutter!, (f) => _size(File('${goldens.path}/$f'))),
  );
  stdout.writeln('Gallery: ${listed.length} goldens -> ${out.path}/index.html');
}

/// Width and height from the PNG header, so the page does not reflow.
(int, int) _size(File png) {
  final b = png.openSync()..setPositionSync(16);
  final h = b.readSync(8);
  b.closeSync();
  int word(int o) => h[o] << 24 | h[o + 1] << 16 | h[o + 2] << 8 | h[o + 3];
  return (word(0), word(4));
}

String _slug(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

const _esc = HtmlEscape();

String _page(
  List<Map<String, dynamic>> features,
  String flutter,
  (int, int) Function(String file) size,
) {
  final total = features.fold<int>(
    0,
    (n, f) =>
        n +
        (f['cases'] as List).fold<int>(
          0,
          (m, c) => m + (c['shots'] as Map).length,
        ),
  );
  final html = StringBuffer('''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Golden gallery</title>
<meta name="description" content="Every golden of flutter_floating_bottom_bar, rendered on the pinned Linux setup.">
<style>
:root { color-scheme: light dark; --bg: #f7f7fa; --fg: #17171c; --muted: #5d5d6b; --card: #ffffff; --line: #e2e2ea; --accent: #3f51b5; }
@media (prefers-color-scheme: dark) { :root { --bg: #111116; --fg: #ececf2; --muted: #a3a3b2; --card: #1b1b22; --line: #2c2c36; --accent: #9fa8ff; } }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--fg); font: 15px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
header, main { max-width: 1200px; margin: 0 auto; padding: 0 16px; }
header { padding-top: 40px; padding-bottom: 8px; }
h1 { font-size: 28px; margin: 0 0 6px; letter-spacing: -0.01em; }
header p { color: var(--muted); margin: 0 0 16px; max-width: 70ch; }
a { color: var(--accent); }
nav { display: flex; flex-wrap: wrap; gap: 6px 14px; padding: 12px 0 4px; border-top: 1px solid var(--line); }
nav a { text-decoration: none; font-size: 14px; }
section { padding: 28px 0 8px; border-top: 1px solid var(--line); margin-top: 20px; }
.feature-head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 4px 16px; }
h2 { font-size: 21px; margin: 0; }
.links { font-size: 14px; display: flex; gap: 14px; }
.case { margin: 22px 0 0; }
.case h3 { font-size: 15px; font-weight: 600; margin: 0 0 10px; }
.shots { display: flex; flex-wrap: wrap; gap: 12px; }
figure { margin: 0; background: var(--card); border: 1px solid var(--line); border-radius: 10px; padding: 8px; max-width: 100%; }
figure img { display: block; max-width: 100%; height: auto; border-radius: 4px; }
figcaption { font-size: 12px; color: var(--muted); padding-top: 6px; display: flex; justify-content: space-between; gap: 12px; }
figcaption code { font-size: 11px; }
footer { max-width: 1200px; margin: 40px auto; padding: 0 16px; color: var(--muted); font-size: 13px; }
</style>
</head>
<body>
<header>
<h1>Golden gallery</h1>
<p>Every golden test of <a href="$_repo">flutter_floating_bottom_bar</a>: $total images, rendered by <code>flutter test</code> on Linux x86_64 with Flutter $flutter and the Roboto and Material Icons fonts. CI checks each one for an exact pixel match on every pull request. <a href="../">Open the playground</a>.</p>
<nav>
''');
  for (final f in features) {
    html.writeln(
      '<a href="#${_slug(f['title'])}">${_esc.convert(f['title'])}</a>',
    );
  }
  html.writeln('</nav>\n</header>\n<main>');
  for (final f in features) {
    final title = _esc.convert(f['title'] as String);
    html
      ..writeln('<section id="${_slug(f['title'])}">')
      ..writeln('<div class="feature-head"><h2>$title</h2><span class="links">')
      ..writeln('<a href="$_repo#${f['readme']}">README</a>');
    if (f['demo'] case final String demo) {
      html.writeln('<a href="../#/$demo">Playground demo</a>');
    }
    html.writeln('</span></div>');
    for (final c in (f['cases'] as List).cast<Map<String, dynamic>>()) {
      final caption = _esc.convert(c['caption'] as String);
      html.writeln(
        '<div class="case" id="${c['id']}"><h3>$caption</h3><div class="shots">',
      );
      for (final MapEntry(key: shot, value: file as String)
          in (c['shots'] as Map).entries) {
        final (w, h) = size(file);
        final label = shot == '' ? 'default' : shot;
        html.writeln(
          '<figure><img src="images/$file" width="$w" height="$h" loading="lazy" '
          'alt="$caption, $label"><figcaption><span>$label</span><code>$file</code></figcaption></figure>',
        );
      }
      html.writeln('</div></div>');
    }
    html.writeln('</section>');
  }
  html.writeln(
    '</main>\n<footer>Built by <code>dart run tool/gallery.dart</code> from <code>test/goldens/</code>. '
    'Run <code>make goldens</code> to check and <code>make goldens-update</code> to regenerate.</footer>\n</body>\n</html>',
  );
  return html.toString();
}
