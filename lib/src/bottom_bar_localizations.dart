import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The words the package shows or announces, in English.
///
/// Every string the bar reads out comes from here, except the ones
/// [MaterialLocalizations] already has: an item's position
/// ([MaterialLocalizations.tabLabel], "Tab 2 of 4") and the minimized pill's
/// hint ([MaterialLocalizations.collapsedIconTapHint], "Expand").
///
/// To translate, extend this class, override the getters, and add a
/// [BottomBarLocalizationsDelegate] to the app's `localizationsDelegates`:
///
/// ```dart
/// class GermanBottomBarLocalizations extends BottomBarLocalizations {
///   const GermanBottomBarLocalizations();
///
///   @override
///   String get scrollToTop => 'Nach oben scrollen';
///   // ...
/// }
///
/// MaterialApp(
///   localizationsDelegates: [
///     BottomBarLocalizationsDelegate(
///       (locale) => locale.languageCode == 'de'
///           ? const GermanBottomBarLocalizations()
///           : const BottomBarLocalizations(),
///     ),
///     ...GlobalMaterialLocalizations.delegates,
///   ],
/// )
/// ```
///
/// A per-widget argument, such as [BottomBar.iconSemanticLabel] or
/// [BottomBarBadge.semanticLabel], wins over these strings.
class BottomBarLocalizations {
  /// Creates the English strings.
  const BottomBarLocalizations();

  /// The strings for [context]: the nearest [BottomBarLocalizations] from a
  /// [BottomBarLocalizationsDelegate], else English.
  static BottomBarLocalizations of(BuildContext context) =>
      Localizations.of<BottomBarLocalizations>(
        context,
        BottomBarLocalizations,
      ) ??
      const BottomBarLocalizations();

  /// The hidden action's name and tooltip when it scrolls back to the top.
  String get scrollToTop => 'Scroll to top';

  /// The hidden action's name and tooltip when the list runs bottom up
  /// ([BottomBarScrollBehavior.scrollOpposite]).
  String get scrollToBottom => 'Scroll to bottom';

  /// What a [BottomBarBadge.count] adds to its item's name, as in
  /// "Inbox, 3 new".
  String badgeCount(int count) => '$count new';

  /// What a [BottomBarBadge.count] above its `max` adds to its item's name,
  /// where it shows "99+".
  String badgeCountOverflow(int max) => 'More than $max new';

  /// What a [BottomBarBadge.dot] adds to its item's name.
  String get badgeDot => 'New';
}

/// Loads [BottomBarLocalizations] for the app's locale.
///
/// Without an argument it supplies English for every locale. Pass a
/// function to supply translations.
class BottomBarLocalizationsDelegate
    extends LocalizationsDelegate<BottomBarLocalizations> {
  /// Creates a delegate that loads [forLocale]'s strings, or English.
  const BottomBarLocalizationsDelegate([this.forLocale]);

  /// Returns the strings for a locale. Null loads English.
  final BottomBarLocalizations Function(Locale locale)? forLocale;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<BottomBarLocalizations> load(Locale locale) => SynchronousFuture(
    forLocale?.call(locale) ?? const BottomBarLocalizations(),
  );

  @override
  bool shouldReload(BottomBarLocalizationsDelegate old) =>
      old.forLocale != forLocale;
}
