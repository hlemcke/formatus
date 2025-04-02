import 'package:flutter/material.dart';

import 'formatus_bar_impl.dart';
import 'formatus_controller.dart';
import 'formatus_controller_impl.dart';
import 'formatus_model.dart';

///
/// Extendable action to format text. Must be supplied to [FormatusBar]
///
class FormatusAction {
  /// section or inline format
  final Formatus formatus;

  /// Used as [Widget] for formatting button
  late final Widget icon;

  /// Formatting to be applied to text
  late final TextStyle? style;

  ///
  /// Action to format some text.
  ///
  /// If `icon` and `style` are not provided then their values
  /// will be taken from `formatus`.
  ///
  FormatusAction({
    required this.formatus,
    Widget? icon,
    TextStyle? style,
  }) {
    this.icon = icon ?? formatus.icon ?? SizedBox(height: 8, width: 8);
    this.style = style ?? formatus.style;
  }

  bool get isSection => formatus.isSection;
}

/// Signature for action `onEditAnchor`
typedef AnchorEditor = Future<FormatusAnchor?> Function(
    BuildContext context, FormatusAnchor anchorElement);

/// Signature for action `onTapAnchor`
typedef AnchorActivity = Future<void> Function(
    BuildContext context, FormatusAnchor anchorElement);

///
/// Actions to format text.
///
abstract class FormatusBar extends StatefulWidget {
  ///
  /// Creates action bar to format text in a [TextField] or [TextFormField].
  /// The same [FormatusController] must be supplied both to the [TextField]
  /// and to this `FormatusBar`.
  ///
  /// To automatically switch back the focus from this `FormatusBar` the
  /// same [FocusNode] must be supplied both to the [TextField]
  /// and to this [FormatusBar].
  ///
  /// TODO `compactFormats` will replace format actions by [DropdownMenu]
  ///
  /// TODO `onEditAnchor` to call a dialog to edit [FormatusAnchor]
  ///
  /// TODO `onTapAnchor` to call function if anchor text is tapped
  ///
  factory FormatusBar({
    Key? key,
    required FormatusController controller,
    List<FormatusAction>? actions,
    WrapAlignment alignment = WrapAlignment.start,
    bool compactFormats = false,
    Axis direction = Axis.horizontal,
    AnchorEditor? onEditAnchor,
    AnchorActivity? onTapAnchor,
    FocusNode? textFieldFocus,
  }) =>
      FormatusBarImpl(
        key: key,
        controller: controller as FormatusControllerImpl,
        actions: actions,
        alignment: alignment,
        compactFormats: compactFormats,
        direction: direction,
        onEditAnchor: onEditAnchor,
        onTapAnchor: onTapAnchor,
        textFieldFocus: textFieldFocus,
      );
}

/// Separately specified to put into expected position
final FormatusAction anchorAction = FormatusAction(formatus: Formatus.anchor);
