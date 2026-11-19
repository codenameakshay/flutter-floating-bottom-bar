import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:material_ui/material_ui.dart';

import 'bar_code.dart';
import 'bar_config.dart';
import 'bar_preview.dart';

const _playgroundUrl =
    'https://codenameakshay.github.io/flutter-floating-bottom-bar/';

/// The configurator for a route such as `/configurator?c=lay:docked`, or
/// null for any other route. A link that does not parse opens the defaults.
Route<void>? configuratorRoute(RouteSettings settings) {
  final uri = Uri.tryParse(settings.name ?? '');
  if (uri?.path != BarConfig.route) return null;
  String? encoded;
  try {
    encoded = uri!.queryParameters['c'];
  } on FormatException {
    encoded = null;
  }
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => ConfiguratorPage(encoded: encoded),
  );
}

/// Knobs for every part of the bar, a live preview, and the Dart that builds
/// it. [encoded] is the `c` parameter of a share link.
class ConfiguratorPage extends StatefulWidget {
  const ConfiguratorPage({super.key, this.encoded});

  final String? encoded;

  @override
  State<ConfiguratorPage> createState() => _ConfiguratorPageState();
}

class _ConfiguratorPageState extends State<ConfiguratorPage> {
  static const _wideBreakpoint = 900.0;
  static const _codeBreakpoint = 1320.0;

  late BarConfig _config = BarConfig.decode(widget.encoded);
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _update(BarConfig config) {
    setState(() => _config = config);
    if (kIsWeb) {
      SystemNavigator.routeInformationUpdated(
        uri: Uri.parse(config.location),
        replace: true,
      );
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _copyCode({required bool showPanel}) async {
    final code = generateCode(_config);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _toast('Code copied');
    if (!showPanel) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
          child: _CodePanel(
            code: code,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final location = _config.location;
    final link = kIsWeb
        ? Uri.base.replace(fragment: location).toString()
        : '$_playgroundUrl#$location';
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) _toast('Link copied');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < _wideBreakpoint) return _buildPhone(constraints);
        final showCode = width >= _codeBreakpoint;
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 380,
                child: SafeArea(
                  right: false,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      _header(showPanel: !showCode),
                      ..._knobs(),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: _PhoneFrame(child: BarPreview(config: _config)),
                  ),
                ),
              ),
              if (showCode) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 480,
                  child: _CodePanel(code: generateCode(_config)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhone(BoxConstraints constraints) {
    final extent = _sheetController.isAttached
        ? _sheetController.size
        : _Sheet.initial;
    final covered = constraints.maxHeight * extent.clamp(0.0, 0.5);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            bottom: covered,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: BarPreview(config: _config),
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {});
              return false;
            },
            child: _Sheet(
              controller: _sheetController,
              builder: (controller) => ListView(
                controller: controller,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  const _DragHandle(),
                  _header(showPanel: true),
                  ..._knobs(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header({required bool showPanel}) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (canPop) const BackButton() else const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configurator',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Reset',
                onPressed: _config == BarConfig.defaults
                    ? null
                    : () => _update(BarConfig.defaults),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _copyCode(showPanel: showPanel),
                  icon: const Icon(Icons.code_rounded),
                  label: const Text('Copy code'),
                ),
                OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _knobs() {
    String? group;
    return [
      for (final knob in Knob.values) ...[
        if (knob.group != group && knob.group != knob.label)
          _GroupHeader(group = knob.group)
        else if (knob.group != group)
          _GroupHeader(group = knob.group, top: 4),
        _knob(knob),
      ],
    ];
  }

  Widget _knob<T extends Object>(Knob<T> knob) {
    final value = _config.get(knob);
    final reason = _config.disabledReason(knob);
    void set(T next) => _update(_config.set(knob, next));
    final enabled = reason == null;
    final reasonText = reason == null
        ? null
        : Text(
            reason,
            key: ValueKey('reason-${knob.key}'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
    if (value is bool) {
      return SwitchListTile(
        key: ValueKey('knob-${knob.key}'),
        dense: true,
        title: Text(knob.label),
        subtitle: reasonText,
        value: value,
        onChanged: enabled ? (next) => set(next as T) : null,
      );
    }
    final range = knob.range;
    return Padding(
      key: ValueKey('knob-${knob.key}'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (knob.group != knob.label)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                range == null
                    ? knob.label
                    : '${knob.label}  ${formatNumber(value as double)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          if (range case (final min, final max))
            Slider(
              value: (value as double).clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min) ~/ 2,
              label: formatNumber(value),
              onChanged: enabled ? (next) => set(next as T) : null,
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in knob.options!)
                  ChoiceChip(
                    label: Text(_optionLabel(knob, option)),
                    selected: option == value,
                    showCheckmark: false,
                    onSelected: enabled ? (_) => set(option) : null,
                  ),
              ],
            ),
          ?reasonText,
        ],
      ),
    );
  }
}

String _optionLabel(Knob knob, Object option) => switch (option) {
  BarPreset(:final label) ||
  IndicatorStyle(:final label) ||
  SurfaceStyle(:final label) ||
  BarTint(:final label) ||
  LayoutStyle(:final label) ||
  MotionStyle(:final label) ||
  CenterStyle(:final label) => label,
  BottomBarMinimizeBehavior.never => 'Off',
  BottomBarMinimizeBehavior.onScrollDown => 'Scrolling down',
  BottomBarMinimizeBehavior.onScrollUp => 'Scrolling up',
  100.0 when knob == Knob.radius => 'Capsule',
  final double number when knob == Knob.textScale => '${formatNumber(number)}×',
  final double number => formatNumber(number),
  _ => '$option',
};

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title, {this.top = 20});

  final String title;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.controller, required this.builder});

  static const initial = 0.45;

  final DraggableScrollableController controller;
  final Widget Function(ScrollController controller) builder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: initial,
      minChildSize: 0.16,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [initial],
      builder: (context, controller) => Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: builder(controller),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// A phone-sized frame, so the preview shows the bar at the size it ships.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  static const _radius = BorderRadius.all(Radius.circular(44));

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 932),
        child: AspectRatio(
          aspectRatio: 430 / 932,
          child: DecoratedBox(
            key: const Key('configurator-frame'),
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: _radius,
              border: Border.all(color: const Color(0xFF111111), width: 6),
            ),
            child: ClipRRect(
              borderRadius: _radius,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const padding = EdgeInsets.symmetric(vertical: 12);
                  return MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: constraints.biggest,
                      padding: padding,
                      viewPadding: padding,
                      viewInsets: EdgeInsets.zero,
                    ),
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.code, this.onClose});

  final String code;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF16161A);
    const foreground = Color(0xFFE8E8EC);
    return ColoredBox(
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'main.dart',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  color: foreground,
                  onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                  icon: const Icon(Icons.copy_rounded),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: 'Close',
                    color: foreground,
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  code,
                  key: const Key('configurator-code'),
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontFamilyFallback: ['Courier', 'monospace'],
                    fontSize: 12.5,
                    height: 1.45,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
