/// A Dart expression, kept as a tree so it prints in dart format's tall
/// style: on one line when it fits, else one argument per line.
sealed class Code {
  const Code();

  bool get isConst;
}

/// Source printed as is, such as `Icons.home_outlined` or `() {}`.
final class Raw extends Code {
  const Raw(this.source, {this.isConst = true});

  final String source;

  @override
  final bool isConst;
}

/// A constructor or method call, such as `Text('Home')` or, with a
/// [target], `BottomBarThemeData.glass().copyWith(...)`.
final class Call extends Code {
  const Call(
    this.name, {
    this.args = const [],
    this.named = const {},
    this.target,
    this.constructor = true,
  });

  final String name;
  final List<Code> args;
  final Map<String, Code> named;
  final Code? target;

  /// Whether [name] is a const constructor.
  final bool constructor;

  @override
  bool get isConst =>
      constructor &&
      target == null &&
      args.every((arg) => arg.isConst) &&
      named.values.every((arg) => arg.isConst);
}

final class ListCode extends Code {
  const ListCode(this.items);

  final List<Code> items;

  @override
  bool get isConst => items.every((item) => item.isConst);
}

const _pageWidth = 80;

/// [code] printed at [indent], starting at [column] of its first line.
String printCode(Code code, {int indent = 0, int? column}) =>
    _print(code, indent, column ?? indent, false);

String _print(Code code, int indent, int column, bool inConst) {
  final flat = _flat(code, inConst);
  if (column + flat.length + 1 <= _pageWidth || !_canSplit(code)) return flat;
  final prefix = code.isConst && !inConst ? 'const ' : '';
  final innerConst = inConst || code.isConst;
  final pad = ' ' * (indent + 2);
  String arg(String label, Code value) =>
      '$pad$label${_print(value, indent + 2, indent + 2 + label.length, innerConst)},\n';
  switch (code) {
    case Call():
      final target = code.target;
      final head = target == null
          ? '$prefix${code.name}('
          : '${_print(target, indent, column, inConst)}.${code.name}(';
      return '$head\n'
          '${code.args.map((a) => arg('', a)).join()}'
          '${code.named.entries.map((e) => arg('${e.key}: ', e.value)).join()}'
          '${' ' * indent})';
    case ListCode():
      return '$prefix[\n'
          '${code.items.map((item) => arg('', item)).join()}'
          '${' ' * indent}]';
    case Raw():
      return flat;
  }
}

bool _canSplit(Code code) => switch (code) {
  Call(:final args, :final named) => args.isNotEmpty || named.isNotEmpty,
  ListCode(:final items) => items.isNotEmpty,
  Raw() => false,
};

String _flat(Code code, bool inConst) {
  final prefix = code.isConst && !inConst ? 'const ' : '';
  final innerConst = inConst || code.isConst;
  return switch (code) {
    Raw(:final source) => source,
    Call(:final target) =>
      '${target == null ? prefix : '${_flat(target, inConst)}.'}'
          '${code.name}(${_flatArgs(code, innerConst)})',
    ListCode(:final items) =>
      '$prefix[${items.map((item) => _flat(item, innerConst)).join(', ')}]',
  };
}

String _flatArgs(Call call, bool inConst) => [
  for (final arg in call.args) _flat(arg, inConst),
  for (final MapEntry(:key, :value) in call.named.entries)
    '$key: ${_flat(value, inConst)}',
].join(', ');

/// A Dart string literal for [text].
Raw string(String text) => Raw("'${text.replaceAll("'", r"\'")}'");
