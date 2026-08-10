import 'package:flutter/material.dart';

/// A simple, opinionated nav-item widget for use inside [BottomBar.child].
///
/// Renders an [icon] (or [selectedIcon] when [selected]), an optional [label]
/// underneath, and an optional [badge] floating on the icon's top-end.
/// Wraps the whole thing in an [InkWell] with an explicit 48 by 48 minimum
/// interactive target, button semantics, and an optional [Tooltip].
///
/// Use [semanticLabel] to provide a deterministic accessible name when the
/// visible [label] is decorative, custom, or otherwise unsuitable for
/// accessibility. When [semanticLabel] is null, [tooltip] becomes the explicit
/// accessible name fallback. If neither is provided, the child's own semantics
/// remain visible.
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
    this.semanticLabel,
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

  /// Optional badge rendered in the top-end corner of the icon.
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

  /// Explicit accessible name for this item.
  ///
  /// When non-null, this name is exposed as the only semantics label for the
  /// item and descendant semantics are excluded to prevent duplicate
  /// announcements. When null, [tooltip] becomes the explicit accessible name
  /// fallback. If both are null, descendant semantics remain visible.
  final String? semanticLabel;

  /// Tooltip shown on long-press.
  ///
  /// When [semanticLabel] is null, this also becomes the explicit accessible
  /// name fallback. When null no tooltip is rendered.
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
    final explicitSemanticLabel = semanticLabel ?? tooltip;

    final iconWidget = selected ? (selectedIcon ?? icon) : icon;

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        IconTheme.merge(
          data: IconThemeData(color: effectiveColor),
          child: iconWidget,
        ),
        if (badge != null)
          PositionedDirectional(
            top: -4,
            end: -4,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(child: column),
        ),
      ),
    );

    if (tooltip != null) {
      child = Tooltip(
        message: tooltip!,
        excludeFromSemantics: true,
        child: child,
      );
    }

    if (explicitSemanticLabel != null) {
      child = ExcludeSemantics(child: child);
    }

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: explicitSemanticLabel,
      onTap: explicitSemanticLabel != null ? onTap : null,
      child: child,
    );
  }
}
