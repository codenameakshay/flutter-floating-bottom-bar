import 'package:flutter/material.dart';

/// A simple, opinionated nav-item widget for use inside [BottomBar.child].
///
/// Renders an [icon] (or [selectedIcon] when [selected]), an optional [label]
/// underneath, and an optional [badge] floating on the icon's top-right.
/// Wraps the whole thing in an [InkWell] for tap feedback and a [Tooltip] when
/// [tooltip] is non-null.
///
/// No internal selection state — pass [selected] from your own state and
/// handle [onTap].
class BottomBarItem extends StatelessWidget {
  const BottomBarItem({
    super.key,
    required this.icon,
    this.selectedIcon,
    this.label,
    this.badge,
    this.selected = false,
    this.onTap,
    this.tooltip,
    this.color,
    this.selectedColor,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final Widget? label;
  final Widget? badge;
  final bool selected;
  final VoidCallback? onTap;
  final String? tooltip;
  final Color? color;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = selected
        ? (selectedColor ?? cs.primary)
        : (color ?? cs.onSurfaceVariant);

    final iconWidget = selected ? (selectedIcon ?? icon) : icon;

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: effectiveColor),
          child: iconWidget,
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: badge!,
          ),
      ],
    );

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        stack,
        if (label != null) ...[
          const SizedBox(height: 2),
          DefaultTextStyle(
            style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                .copyWith(color: effectiveColor),
            child: label!,
          ),
        ],
      ],
    );

    Widget child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: column,
      ),
    );

    if (tooltip != null) {
      child = Tooltip(message: tooltip!, child: child);
    }

    return child;
  }
}
