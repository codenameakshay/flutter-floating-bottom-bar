import 'package:flutter/widgets.dart';

/// The largest text scale an item label or badge follows, the same cap as
/// Material's [NavigationBar]. Past it the tooltip and the accessible name
/// carry the label at full size.
const double maxLabelTextScale = 1.3;

/// [context]'s text scaler, capped at [maxLabelTextScale].
TextScaler labelTextScalerOf(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: maxLabelTextScale);

/// Whether [context]'s text scale is past [maxLabelTextScale], so a label
/// shows smaller than the user asked for.
bool labelTextCapped(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(100) > maxLabelTextScale * 100;
