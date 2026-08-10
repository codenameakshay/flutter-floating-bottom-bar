import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Internal back action with a stable hit target and animated visual child.
class BottomBarAction extends StatelessWidget {
  const BottomBarAction({
    super.key,
    required this.animation,
    required this.enabled,
    required this.visualWidth,
    required this.visualHeight,
    required this.decoration,
    required this.tooltip,
    required this.semanticLabel,
    required this.onTap,
    required this.visualBuilder,
  });

  final Animation<double> animation;
  final bool enabled;
  final double visualWidth;
  final double visualHeight;
  final Decoration decoration;
  final String tooltip;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget Function(double width, double height) visualBuilder;

  @override
  Widget build(BuildContext context) {
    final targetExtent =
        math.max(48.0, math.max(visualWidth, visualHeight)).toDouble();

    Widget child = SizedBox(
      width: targetExtent,
      height: targetExtent,
      child: ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Center(
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final progress = animation.value.clamp(0.0, 1.0);
                  final width = visualWidth * progress;
                  final height = visualHeight * progress;
                  return Opacity(
                    opacity: progress,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: DecoratedBox(
                        decoration: decoration,
                        child: visualBuilder(width, height),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    child = IgnorePointer(ignoring: !enabled, child: child);
    child = ExcludeSemantics(excluding: !enabled, child: child);
    if (!enabled) {
      return child;
    }

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Tooltip(
        excludeFromSemantics: true,
        message: tooltip,
        child: child,
      ),
    );
  }
}
