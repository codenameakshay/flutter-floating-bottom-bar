import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// `find.byTooltip` lives in `flutter_test` and matches the **legacy**
/// `Tooltip` from `package:flutter/material.dart` by exact type, so it cannot
/// see the `material_ui` `Tooltip` this package now builds — it silently finds
/// zero widgets. Match on the widget instead.
Finder findByTooltip(String message) => find.byWidgetPredicate(
  (widget) => widget is Tooltip && widget.message == message,
  description: 'Tooltip("$message")',
);
