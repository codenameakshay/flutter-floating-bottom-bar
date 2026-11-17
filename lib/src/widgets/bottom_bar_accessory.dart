import 'package:flutter/widgets.dart';

/// Where a [BottomBar.accessory] sits, like SwiftUI's
/// `TabViewBottomAccessoryPlacement`.
///
/// The accessory reads it with [BottomBarAccessoryPlacement.of] and decides
/// what to show in each placement, for example a full now-playing row when
/// [expanded] and only the artwork and a play button when [inline].
enum BottomBarAccessoryPlacement {
  /// Its own piece above the bar, as wide as the bar.
  expanded,

  /// Beside the minimized pill, in the width the pill leaves free.
  inline;

  /// The placement of the [BottomBar.accessory] that encloses [context].
  ///
  /// Asserts in debug mode when [context] is not inside an accessory. Use
  /// [maybeOf] for a null-safe variant.
  static BottomBarAccessoryPlacement of(BuildContext context) {
    final placement = maybeOf(context);
    assert(
      placement != null,
      'BottomBarAccessoryPlacement.of() called outside a BottomBar.accessory.',
    );
    return placement!;
  }

  /// The placement of the enclosing [BottomBar.accessory], or null outside
  /// one.
  static BottomBarAccessoryPlacement? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<AccessoryPlacementScope>()
      ?.placement;
}

/// Provides [BottomBarAccessoryPlacement.of] to an accessory.
class AccessoryPlacementScope extends InheritedWidget {
  const AccessoryPlacementScope({
    super.key,
    required this.placement,
    required super.child,
  });

  final BottomBarAccessoryPlacement placement;

  @override
  bool updateShouldNotify(AccessoryPlacementScope oldWidget) =>
      placement != oldWidget.placement;
}
