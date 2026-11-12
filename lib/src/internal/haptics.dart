import 'package:flutter/services.dart';

import '../widgets/bottom_bar_item_theme.dart';

void playHaptics(BottomBarHaptics haptics) {
  switch (haptics) {
    case BottomBarHaptics.none:
      break;
    case BottomBarHaptics.selectionClick:
      HapticFeedback.selectionClick();
    case BottomBarHaptics.lightImpact:
      HapticFeedback.lightImpact();
  }
}
