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

  /// The icon displayed when [selected] is `false`.
  final Widget icon;

  /// The icon displayed when [selected] is `true`.
  ///
  /// Falls back to [icon] when null.
  final Widget? selectedIcon;

  /// Optional label rendered below the icon.
  ///
  /// Styled with `textTheme.labelSmall` tinted to [color] or [selectedColor].
  final Widget? label;

  /// Optional badge rendered in the top-right corner of the icon.
  ///
  /// Typically a [Badge] widget. Use for notification counts or dot indicators.
  final Widget? badge;

  /// Whether this item is currently the active/selected tab.
  ///
  /// Does not maintain state internally — pass from your own state and update
  /// in [onTap].
  final bool selected;

  /// Called when the item is tapped.
  final VoidCallback? onTap;

  /// Tooltip shown on long-press.
  ///
  /// When null no tooltip is rendered.
  final String? tooltip;

  /// Icon and label colour when [selected] is `false`.
  ///
  /// Defaults to `colorScheme.onSurfaceVariant`.
  final Color? color;

  /// Icon and label colour when [selected] is `true`.
  ///
  /// Defaults to `colorScheme.primary`.
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
