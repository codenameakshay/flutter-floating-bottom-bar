import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Whether the platform or the ambient [MediaQuery] asks for reduced motion.
bool reduceMotion(BuildContext context) {
  return SemanticsBinding.instance.disableAnimations ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .disableAnimations ||
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}
