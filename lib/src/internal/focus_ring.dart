import 'package:material_ui/material_ui.dart';

/// Draws a ring of [shape] over [child] while keyboard focus is inside it.
///
/// It shows only in [FocusHighlightMode.traditional], so a touch that
/// focuses a control draws nothing, like Material's own focus highlights.
class FocusRing extends StatefulWidget {
  const FocusRing({super.key, required this.shape, required this.child});

  final OutlinedBorder shape;
  final Widget child;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onHighlightMode);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightMode);
    super.dispose();
  }

  void _onHighlightMode(FocusHighlightMode mode) {
    if (_focused) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: visible
            ? ShapeDecoration(
                shape: widget.shape.copyWith(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              )
            : const BoxDecoration(),
        child: widget.child,
      ),
    );
  }
}
