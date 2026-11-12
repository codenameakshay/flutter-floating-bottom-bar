import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

import '../internal/bottom_bar_item_height.dart';
import '../internal/item_theme_scope.dart';
import '../internal/reduce_motion.dart';
import 'bottom_bar_indicator.dart';
import 'bottom_bar_item_theme.dart';

/// Controls when a [BottomBarItem]'s label is visible when it is placed
/// inside a [BottomBarItems] row.
enum BottomBarLabelBehavior {
  /// Always show the label, regardless of selection state.
  alwaysShow,

  /// Only show the label on the selected item.
  onlySelected,

  /// Never show the label.
  alwaysHide,
}

/// A thin row layout helper for [BottomBarItem]s (or any other widgets).
///
/// Arranges [children] horizontally with [spacing] as the main-axis alignment.
/// In bounded rows wide enough for each child's 48px minimum target, each
/// child is wrapped in [Expanded] so all items share the available width
/// equally. Narrow bounded rows use a horizontal [SingleChildScrollView] to
/// preserve those targets. Unbounded rows keep their raw children. Designed
/// to be passed as [BottomBar.child]:
///
/// ```dart
/// BottomBar(
///   child: BottomBarItems(
///     children: [
///       BottomBarItem(icon: Icon(Icons.home), selected: true, onTap: () {}),
///       BottomBarItem(icon: Icon(Icons.search), onTap: () {}),
///     ],
///   ),
///   body: ...,
/// )
/// ```
///
/// Set [selectedIndex] to let the row own selection: each child learns its
/// index and whether it is selected through [BottomBarItemSelectionScope],
/// a [BottomBarItem] uses that over its own [BottomBarItem.selected], and
/// tapping an item calls its own `onTap` and then [onSelected]. Add an
/// [indicator] to draw a selection indicator that slides between items:
///
/// ```dart
/// BottomBarItems(
///   selectedIndex: index,
///   onSelected: (i) => setState(() => index = i),
///   indicator: const BottomBarIndicator.pill(),
///   children: [...],
/// )
/// ```
///
/// Tapping the selected item again calls [onReselected], and
/// [scrollToStartOnReselect] scrolls the visible list back to its start.
/// [dragToSelect] lets the user slide a finger along the row to pick an item.
/// There is no double-tap callback: a double-tap recognizer would delay every
/// single tap.
class BottomBarItems extends StatelessWidget {
  /// Creates a [BottomBarItems] row.
  const BottomBarItems({
    super.key,
    required this.children,
    this.spacing = MainAxisAlignment.spaceAround,
    this.labelBehavior = BottomBarLabelBehavior.alwaysShow,
    this.selectedIndex,
    this.onSelected,
    this.indicator,
    this.indicatorMotion,
    this.onReselected,
    this.scrollToStartOnReselect = false,
    this.onLongPressed,
    this.dragToSelect = false,
  });

  /// The widgets to display in the row — typically [BottomBarItem] instances.
  final List<Widget> children;

  /// Main-axis alignment applied to the [Row].
  ///
  /// Defaults to [MainAxisAlignment.spaceAround]. In wide bounded rows, this
  /// only affects layout when [children] is empty because each child is
  /// expanded.
  final MainAxisAlignment spacing;

  /// Controls when descendant [BottomBarItem] labels are visible.
  ///
  /// Exposed to descendants via [BottomBarItemsScope]. Defaults to
  /// [BottomBarLabelBehavior.alwaysShow].
  final BottomBarLabelBehavior labelBehavior;

  /// The index of the selected child, or null to leave selection to each
  /// child (for example [BottomBarItem.selected]).
  ///
  /// When non-null, it takes precedence over [BottomBarItem.selected]. An
  /// out-of-range index asserts in debug builds and shows no indicator in
  /// release builds.
  final int? selectedIndex;

  /// Called with a child's index when it is tapped, after the child's own
  /// `onTap`. Only used when [selectedIndex] is non-null.
  ///
  /// It also fires when the selected item is tapped again, after
  /// [onReselected].
  final ValueChanged<int>? onSelected;

  /// Called with the selected child's index when it is tapped again, or
  /// picked again by [dragToSelect]. Only used when [selectedIndex] is
  /// non-null.
  ///
  /// Runs after [scrollToStartOnReselect] starts its scroll and before
  /// [onSelected], so it can pop the tab's navigator to its root.
  final ValueChanged<int>? onReselected;

  /// Whether reselecting an item shows the enclosing [BottomBar] and scrolls
  /// the list on screen in [BottomBar.body] back to its start.
  ///
  /// It uses the same target as [BottomBarController.scrollToStart]: the
  /// most recently scrolled list that is still visible, with
  /// [NestedScrollView] headers expanded. Does nothing outside a
  /// [BottomBar]. Defaults to false.
  final bool scrollToStartOnReselect;

  /// Called with a child's index when it is long-pressed, after the child's
  /// own `onLongPress`. Only used when [selectedIndex] is non-null.
  ///
  /// While set, a [BottomBarItem.tooltip] shows on hover only.
  final ValueChanged<int>? onLongPressed;

  /// Whether pressing the row and sliding sideways picks an item, like the
  /// iOS tab bar.
  ///
  /// The [indicator] follows the finger and the item under it shows its
  /// selected look. Lifting the finger selects that item through
  /// [onSelected], or reselects it. Sliding off the bar vertically cancels.
  /// A plain tap works as before. It has no effect without an [indicator]
  /// or in a row too narrow for its items, which scrolls instead. Under
  /// reduced motion the indicator stays put during the drag and jumps on
  /// release. Defaults to false.
  final bool dragToSelect;

  /// The selection indicator drawn behind the selected child. Only used when
  /// [selectedIndex] is non-null.
  ///
  /// Defaults to [BottomBarItemThemeData.indicator]. Pass
  /// [BottomBarIndicator.none] to draw none whatever the theme says.
  final BottomBarIndicator? indicator;

  /// The spring the [indicator] moves on.
  ///
  /// Defaults to [BottomBarItemThemeData.indicatorMotion], then to a snappy
  /// Cupertino spring. Reduced motion skips the animation.
  final Motion? indicatorMotion;

  @override
  Widget build(BuildContext context) {
    final index = selectedIndex;
    assert(
      index == null || (index >= 0 && index < children.length),
      'selectedIndex $index is out of range for ${children.length} children',
    );
    if (index != null) return _SelectableItems(items: this);
    return _layout(children, null);
  }

  Widget _layout(
    List<Widget> children,
    Widget Function(Widget row, {required bool reveal})? track,
  ) {
    Widget row(List<Widget> rowChildren, {bool reveal = false}) {
      final row = Row(
        mainAxisAlignment: spacing,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rowChildren,
      );
      return track == null ? row : track(row, reveal: reveal);
    }

    return BottomBarItemsScope(
      labelBehavior: labelBehavior,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget withItemHeight(Widget child) => BottomBarItemHeightScope(
            minHeight: constraints.hasTightHeight && constraints.maxHeight > 48
                ? constraints.maxHeight
                : 48,
            child: child,
          );

          if (!constraints.hasBoundedWidth) {
            return withItemHeight(row(children));
          }
          if (constraints.maxWidth < children.length * 48) {
            return withItemHeight(
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: row(children, reveal: true),
              ),
            );
          }
          return withItemHeight(
            row([
              for (final child in children)
                Expanded(
                  key: selectedIndex != null && child.key != null
                      ? ValueKey<Key>(child.key!)
                      : null,
                  child: child,
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _SelectableItems extends StatefulWidget {
  const _SelectableItems({required this.items});

  final BottomBarItems items;

  @override
  State<_SelectableItems> createState() => _SelectableItemsState();
}

class _SelectableItemsState extends State<_SelectableItems>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _defaultMotion = CupertinoMotion.snappy(
    duration: Duration(milliseconds: 450),
  );

  /// How far the finger may stray above or below the row before a drag
  /// cancels.
  static const _dragCancelSlop = 2 * kTouchSlop;

  late final IndicatorMotion _motion;
  bool _reduceMotion = false;
  BottomBarIndicator? _indicator;
  BottomBarHaptics _haptics = BottomBarHaptics.none;

  /// The item under the finger while a drag runs, else null.
  int? _dragIndex;

  @override
  void initState() {
    super.initState();
    _motion = IndicatorMotion(
      vsync: this,
      index: widget.items.selectedIndex!,
      motion: widget.items.indicatorMotion ?? _defaultMotion,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTheme();
    _updateReducedMotion();
  }

  void _syncTheme() {
    final theme = itemThemeOf(context);
    _indicator = effectiveIndicator(widget.items.indicator, theme.indicator);
    _haptics = theme.haptics ?? BottomBarHaptics.none;
    if (_indicator == null && _dragIndex != null) {
      _dragIndex = null;
      _settle();
    }
    _motion
      ..motion =
          widget.items.indicatorMotion ??
          theme.indicatorMotion ??
          _defaultMotion
      ..indicator = _indicator;
  }

  @override
  void didChangeAccessibilityFeatures() {
    _updateReducedMotion();
  }

  void _updateReducedMotion() {
    final reduced = reduceMotion(context);
    if (reduced && !_reduceMotion) {
      _motion.jumpTo(widget.items.selectedIndex!);
    }
    _reduceMotion = reduced;
  }

  @override
  void didUpdateWidget(_SelectableItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    final items = widget.items;
    final old = oldWidget.items;
    _syncTheme();
    final index = items.selectedIndex!;
    final moved = index != old.selectedIndex;
    if (_dragIndex != null &&
        (moved ||
            items.children.length != old.children.length ||
            !items.dragToSelect ||
            _indicator == null)) {
      _dragIndex = null;
      _settle();
    }
    if (items.children.length != old.children.length ||
        (moved && reduceMotion(context))) {
      _motion.jumpTo(index);
    } else if (moved) {
      _motion.animateTo(index);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dragIndex = null;
    _motion.dispose();
    super.dispose();
  }

  void _haptic(BottomBarHaptics haptics) {
    switch (haptics) {
      case BottomBarHaptics.none:
        break;
      case BottomBarHaptics.selectionClick:
        HapticFeedback.selectionClick();
      case BottomBarHaptics.lightImpact:
        HapticFeedback.lightImpact();
    }
  }

  void _select(int index) {
    final items = widget.items;
    _haptic(_haptics);
    if (index == items.selectedIndex) {
      if (items.scrollToStartOnReselect) barScrollToStart(context);
      items.onReselected?.call(index);
    }
    items.onSelected?.call(index);
  }

  void _onDragStart(DragStartDetails details) {
    _dragIndex = widget.items.selectedIndex;
    _onDragUpdate(details.localPosition);
  }

  void _onDragUpdate(Offset position) {
    if (_dragIndex == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final height = box != null && box.hasSize ? box.size.height : 0.0;
    if (position.dy < -_dragCancelSlop ||
        position.dy > height + _dragCancelSlop) {
      _cancelDrag();
      return;
    }
    if (!_reduceMotion) _motion.follow(position.dx);
    final index = _motion.indexAt(position.dx);
    if (index != null && index != _dragIndex) {
      setState(() => _dragIndex = index);
      if (_haptics != BottomBarHaptics.none) {
        _haptic(BottomBarHaptics.selectionClick);
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    final index = _dragIndex;
    if (index == null) return;
    setState(() => _dragIndex = null);
    if (_motion.dragging) {
      _motion.release(index, velocity: details.velocity.pixelsPerSecond.dx);
    }
    _select(index);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _dragIndex == null) _settle();
    });
  }

  void _cancelDrag() {
    if (!mounted || _dragIndex == null) return;
    setState(() => _dragIndex = null);
    _settle();
  }

  /// Returns the indicator to the selected item, after a cancelled drag or a
  /// release the parent did not accept.
  void _settle() {
    final index = widget.items.selectedIndex!;
    if (_reduceMotion) {
      if (_motion.dragging || _motion.target != index) _motion.jumpTo(index);
    } else {
      _motion.release(index);
    }
  }

  Map<Type, GestureRecognizerFactory> _dragGestures(bool enabled) {
    if (!enabled) return const {};
    return {
      HorizontalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
            () => HorizontalDragGestureRecognizer(debugOwner: this),
            (recognizer) => recognizer
              ..onlyAcceptDragOnThreshold = true
              ..onStart = _onDragStart
              ..onUpdate = ((details) => _onDragUpdate(details.localPosition))
              ..onEnd = _onDragEnd
              ..onCancel = _cancelDrag,
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final indicator = _indicator;
    final selectedIndex = items.selectedIndex!;
    final selectable =
        items.onSelected != null ||
        items.onReselected != null ||
        items.scrollToStartOnReselect;
    final onLongPressed = items.onLongPressed;
    final foreground = indicatorForeground(
      indicator,
      Theme.of(context).colorScheme,
    );
    final ink = indicatorInks(indicator);
    final children = [
      for (var i = 0; i < items.children.length; i++)
        IndicatorAnchor(
          key: items.children[i].key == null
              ? null
              : ValueKey<Key>(items.children[i].key!),
          role: IndicatorAnchorRole.slot,
          child: BottomBarItemSelectionScope(
            index: i,
            selected: i == (_dragIndex ?? selectedIndex),
            onSelect: selectable ? () => _select(i) : null,
            onLongPress: onLongPressed == null ? null : () => onLongPressed(i),
            selectedForegroundColor: foreground,
            ink: ink,
            child: items.children[i],
          ),
        ),
    ];
    return items._layout(
      children,
      indicator == null
          ? null
          : (row, {required reveal}) {
              if (reveal && _dragIndex != null) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  _cancelDrag();
                });
              }
              return Listener(
                // An accepted drag reports a cancelled pointer through onEnd.
                onPointerCancel: (_) => _cancelDrag(),
                child: RawGestureDetector(
                  excludeFromSemantics: true,
                  gestures: _dragGestures(items.dragToSelect && !reveal),
                  child: IndicatorTrack(
                    motion: _motion,
                    indicator: indicator,
                    reveal: reveal,
                    row: row,
                  ),
                ),
              );
            },
    );
  }
}

/// Tells a child of a [BottomBarItems] row with a
/// [BottomBarItems.selectedIndex] its index and whether it is selected.
///
/// [BottomBarItem] reads it automatically. Custom children can read it with
/// [BottomBarItemSelectionScope.maybeOf] and call [onSelect] when tapped.
class BottomBarItemSelectionScope extends InheritedWidget {
  /// Creates a [BottomBarItemSelectionScope].
  const BottomBarItemSelectionScope({
    super.key,
    required this.index,
    required this.selected,
    this.onSelect,
    this.onLongPress,
    this.selectedForegroundColor,
    this.ink = false,
    required super.child,
  });

  /// The child's index in the row.
  final int index;

  /// Whether the child is the selected one.
  final bool selected;

  /// Reports this child as selected through [BottomBarItems.onSelected],
  /// or reselected through [BottomBarItems.onReselected]. Null when the row
  /// has neither and no [BottomBarItems.scrollToStartOnReselect].
  final VoidCallback? onSelect;

  /// Reports a long-press on this child through
  /// [BottomBarItems.onLongPressed]. Null when the row has none.
  final VoidCallback? onLongPress;

  /// The content colour a selected child should use so it contrasts with
  /// the row's [BottomBarItems.indicator], or null to keep its own default.
  final Color? selectedForegroundColor;

  /// Whether the indicator reveals the selected look only where it covers
  /// this child. When true, [BottomBarItem] paints its plain look and lays
  /// its selected look over it, clipped to the indicator.
  final bool ink;

  /// Returns the nearest enclosing scope, or `null` if there isn't one.
  static BottomBarItemSelectionScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BottomBarItemSelectionScope>();
  }

  @override
  bool updateShouldNotify(BottomBarItemSelectionScope oldWidget) {
    return index != oldWidget.index ||
        selected != oldWidget.selected ||
        onSelect != oldWidget.onSelect ||
        onLongPress != oldWidget.onLongPress ||
        selectedForegroundColor != oldWidget.selectedForegroundColor ||
        ink != oldWidget.ink;
  }
}

/// Exposes the enclosing [BottomBarItems.labelBehavior] to descendant
/// [BottomBarItem]s.
///
/// [BottomBarItem] reads this via [BottomBarItemsScope.maybeOf] to decide
/// whether to render its label. An item used outside a [BottomBarItems] row
/// falls back to [BottomBarLabelBehavior.alwaysShow].
class BottomBarItemsScope extends InheritedWidget {
  /// Creates a [BottomBarItemsScope].
  const BottomBarItemsScope({
    super.key,
    required this.labelBehavior,
    required super.child,
  });

  /// The label behavior in effect for descendant [BottomBarItem]s.
  final BottomBarLabelBehavior labelBehavior;

  /// Returns the nearest enclosing [BottomBarItemsScope]'s [labelBehavior],
  /// or `null` if there isn't one.
  static BottomBarLabelBehavior? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BottomBarItemsScope>()
        ?.labelBehavior;
  }

  @override
  bool updateShouldNotify(BottomBarItemsScope oldWidget) {
    return labelBehavior != oldWidget.labelBehavior;
  }
}
