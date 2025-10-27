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
  FormatusAction({required this.formatus, Widget? icon, TextStyle? style}) {
    this.icon = icon ?? formatus.icon ?? SizedBox(height: 8, width: 8);
    this.style = style ?? formatus.style;
  }

  bool get isList => formatus.isList;

  bool get isSection => formatus.isSection;

  @override
  String toString() => formatus.toString();
}

/// Signature for callback `onEditAnchor`
typedef AnchorEditor =
    Future<FormatusAnchor?> Function(
      BuildContext context,
      FormatusAnchor anchor,
    );

/// Signature for callback `onSelectImage``
typedef ImageSelector =
    Future<FormatusImage?> Function(BuildContext context, FormatusImage image);

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
  /// Supplying `null` for `actions` will use [formatusDefaultActions].
  ///
  /// TODO `condense` will bundle format actions by [DropdownMenu]s
  ///
  factory FormatusBar({
    Key? key,
    required FormatusController controller,
    List<FormatusAction>? actions,
    WrapAlignment alignment = WrapAlignment.start,
    bool condense = false,
    Axis direction = Axis.horizontal,
    AnchorEditor? onEditAnchor,
    ImageSelector? onSelectImage,
    FocusNode? textFieldFocus,
  }) => FormatusBarImpl(
    key: key,
    controller: controller as FormatusControllerImpl,
    actions: actions,
    alignment: alignment,
    condense: condense,
    direction: direction,
    onEditAnchor: onEditAnchor,
    onSelectImage: onSelectImage,
    textFieldFocus: textFieldFocus,
  );
}

/// Separately specified to put into expected position
final FormatusAction anchorAction = FormatusAction(formatus: Formatus.anchor);

final FormatusAction imageAction = FormatusAction(formatus: Formatus.image);

final List<FormatusAction> formatusDefaultActions = [
  FormatusAction(formatus: Formatus.header1),
  FormatusAction(formatus: Formatus.header2),
  FormatusAction(formatus: Formatus.header3),
  FormatusAction(formatus: Formatus.paragraph),
  FormatusAction(formatus: Formatus.unorderedList),
  FormatusAction(formatus: Formatus.orderedList),
  FormatusAction(formatus: Formatus.gap),
  FormatusAction(formatus: Formatus.italic),
  FormatusAction(formatus: Formatus.bold),
  FormatusAction(formatus: Formatus.underline),
  FormatusAction(formatus: Formatus.strikeThrough),
  FormatusAction(formatus: Formatus.color),
  FormatusAction(formatus: Formatus.textSize),
  anchorAction,
  imageAction,
];
