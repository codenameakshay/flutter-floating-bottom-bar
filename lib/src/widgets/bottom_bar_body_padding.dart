import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../bottom_bar_scope.dart';

/// Adds bottom padding equal to the current [BottomBar] footprint.
///
/// Use inside [BottomBar.body] to keep content clear of the floating bar while
/// still layering the bar above the scrollable. The reserved space stays in
/// place while the bar is hidden because [BottomBarScope.barHeight] reports the
/// bar's layout footprint, not its animated transform. That footprint includes
/// the measured bar height plus [BottomBarLayout.offset] and bottom safe-area
/// when enabled.
///
/// The bottom safe-area inset counts exactly once:
///
/// * The footprint already includes it, so this widget removes the bottom
///   padding from the [MediaQuery] below it. A `ListView` or `SafeArea` inside
///   does not add the inset again.
/// * When a `SafeArea` between the [BottomBar] and this widget already
///   padded the body by the inset, this widget reserves that much less.
/// * When a `SafeArea` above the [BottomBar] removed the inset, the bar sees
///   none and the footprint excludes it.
///
/// This widget is intentionally bottom-edge clearance for bottom-aligned bars.
/// It does not inspect [BottomBarLayout.alignment] or try to reserve space on
/// any other edge.
class BottomBarBodyPadding extends StatelessWidget {
  const BottomBarBodyPadding({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Extra padding applied in addition to the reserved bar footprint.
  final EdgeInsetsGeometry padding;

  /// Descendant content that should be inset away from the bar.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = BottomBarScope.of(context);
    final remainingInset = MediaQuery.maybePaddingOf(context)?.bottom;
    final consumedAbove = remainingInset == null
        ? 0.0
        : math.max(0.0, scope.bottomInset - remainingInset);

    return ValueListenableBuilder<double>(
      valueListenable: scope.barHeight,
      builder: (context, value, child) {
        final resolved = padding.resolve(Directionality.of(context));
        return Padding(
          padding: EdgeInsets.fromLTRB(
            resolved.left,
            resolved.top,
            resolved.right,
            resolved.bottom +
                math.max(
                  0.0,
                  math.max(value, scope.bottomInset) - consumedAbove,
                ),
          ),
          child: child,
        );
      },
      child: MediaQuery.maybeOf(context) == null
          ? child
          : MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: child,
            ),
    );
  }
}
