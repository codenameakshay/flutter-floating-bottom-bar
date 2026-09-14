import 'package:material_ui/material_ui.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';

class ScrollUnderDemoPage extends StatefulWidget {
  const ScrollUnderDemoPage({this.controller, super.key});

  final BottomBarController? controller;

  @override
  State<ScrollUnderDemoPage> createState() => _ScrollUnderDemoPageState();
}

class _ScrollUnderDemoPageState extends State<ScrollUnderDemoPage> {
  late final BottomBarController _controller;
  late final bool _ownsController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? BottomBarController();
    _ownsController = widget.controller == null;
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BottomBar(
        controller: _controller,
        layout: const BottomBarLayout(
          width: 360,
          offset: 16,
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
        ),
        body: Builder(
          builder: (context) {
            final barHeight = BottomBarScope.of(context).barHeight;
            return ValueListenableBuilder<double>(
              valueListenable: barHeight,
              builder: (context, value, _) {
                return CustomScrollView(
                  key: const PageStorageKey<String>('scroll-under-list'),
                  slivers: [
                    const SliverAppBar(
                      key: ValueKey<String>('scroll-under-header'),
                      pinned: true,
                      title: Text('Scroll under'),
                      backgroundColor: Color(0xFFF4F1EA),
                      surfaceTintColor: Colors.transparent,
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(bottom: value),
                      sliver: SliverList.builder(
                        itemCount: 32,
                        itemBuilder: (context, index) => _ScrollRow(
                          key: index == 31
                              ? const ValueKey<String>('scroll-under-last-row')
                              : null,
                          index: index,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        child: _ScrollUnderDock(
          key: const ValueKey<String>('scroll-under-dock'),
          isExpanded: _isExpanded,
          onToggle: () => setState(() => _isExpanded = !_isExpanded),
        ),
      ),
    );
  }
}

class _ScrollUnderDock extends StatelessWidget {
  const _ScrollUnderDock({
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final label = isExpanded ? 'Collapse dock' : 'Expand dock';
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isExpanded ? 104 : 72),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Flexible(
                  child: Text(
                    'Floating dock',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: label,
                  onPressed: onToggle,
                  icon: Icon(
                    semanticLabel: label,
                    isExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                  ),
                ),
              ],
            ),
            if (isExpanded)
              const Text(
                'List continues behind dock.',
                style: TextStyle(color: Color(0x99000000)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScrollRow extends StatelessWidget {
  const _ScrollRow({required this.index, super.key});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Scroll item ${index + 1}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: index.isEven ? const Color(0xFFF8F7F3) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0x12000000))),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${index + 1}'.padLeft(2, '0'),
                  style: const TextStyle(
                    color: Color(0x99000000),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 18),
                Flexible(
                  child: Text(
                    'A long list row',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
