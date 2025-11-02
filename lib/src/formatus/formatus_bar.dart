import 'package:flutter/material.dart';

import 'formatus_bar_impl.dart';
import 'formatus_controller.dart';
import 'formatus_controller_impl.dart';
import 'formatus_model.dart';

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
  factory FormatusBar({
    Key? key,
    required FormatusController controller,
    List<Formatus>? actions,
    WrapAlignment alignment = WrapAlignment.start,
    Axis direction = Axis.horizontal,
    AnchorEditor? onEditAnchor,
    ImageSelector? onSelectImage,
    FocusNode? textFieldFocus,
  }) => FormatusBarImpl(
    key: key,
    controller: controller as FormatusControllerImpl,
    actions: actions,
    alignment: alignment,
    direction: direction,
    onEditAnchor: onEditAnchor,
    onSelectImage: onSelectImage,
    textFieldFocus: textFieldFocus,
  );
}

/// List of inlines -> sublist of Formatus.values in useful order
List<Formatus> get listOfInlines => List.of(_listOfInlines);
final List<Formatus> _listOfInlines = [
  Formatus.bold,
  Formatus.italic,
  Formatus.underline,
  Formatus.strikeThrough,
  Formatus.color,
  Formatus.subscript,
  Formatus.superscript,
];

/// List of sections -> sublist of Formatus.values in useful order
List<Formatus> get listOfLists => List.of(_listOfLists);
final List<Formatus> _listOfLists = [
  Formatus.unorderedList,
  Formatus.orderedList,
];

/// List of sections -> sublist of Formatus.values in useful order
List<Formatus> get listOfSections => List.of(_listOfSections);
final List<Formatus> _listOfSections = [
  Formatus.header1,
  Formatus.header2,
  Formatus.header3,
  Formatus.paragraph,
];

/// List of sizes -> sublist of Formatus.values in useful order
List<Formatus> get listOfSizes => List.of(_listOfSizes);
final List<Formatus> _listOfSizes = [Formatus.small, Formatus.big];

List<Formatus> get formatusCollapsedActions => List.of(_collapsedActions);
final List<Formatus> _collapsedActions = [
  Formatus.collapseSections,
  ...listOfSections,
  Formatus.collapseLists,
  ...listOfLists,
  Formatus.collapseSizes,
  ...listOfSizes,
  Formatus.collapseInlines,
  ...listOfInlines,
];

List<Formatus> get formatusDefaultActions => List.of(_defaultActions);

final List<Formatus> _defaultActions = [
  Formatus.header1,
  Formatus.header2,
  Formatus.header3,
  Formatus.paragraph,
  Formatus.unorderedList,
  Formatus.orderedList,
  Formatus.gap,
  Formatus.italic,
  Formatus.bold,
  Formatus.underline,
  Formatus.strikeThrough,
  Formatus.color,
  Formatus.collapseSizes,
  Formatus.anchor,
  Formatus.image,
];
