/// Built-in transition presets for [BottomBar].
///
/// Pair with [BottomBarMotion.transition]. To customize beyond the presets,
/// supply [BottomBarMotion.transitionBuilder] (which overrides this enum).
enum BottomBarTransition {
  /// Slide the bar from offscreen toward its rest position.
  slide,

  /// Fade the bar in and out without translation.
  fade,

  /// Scale the bar from 0.0 to 1.0 (and back) while showing/hiding.
  scale,

  /// Slide and fade simultaneously.
  slideAndFade,
}
