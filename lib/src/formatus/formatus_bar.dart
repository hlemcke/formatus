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

/// Signature for callback `onSelectColor`
typedef ColorSelector =
    Future<Color?> Function(BuildContext context, Color currentColor);

/// Signature for callback `onSelectEmoji`
typedef EmojiSelector = Future<String?> Function(BuildContext context);

/// Callback invoked to supply localized tooltips to formatting actions.
///
/// If the callback returns `null` then no tooltip will be displayed.
typedef TooltipBuilder =
    String? Function(BuildContext context, Formatus action);

/// Signature for callback `onSelectImage``
typedef ImageSelector =
    Future<FormatusImage?> Function(BuildContext context, FormatusImage image);

///
/// Actions to format text.
///
abstract class FormatusBar extends StatefulWidget {
  ///
  /// Creates a [FormatusBar] instance linked to a [controller].
  ///
  /// * [controller] → The active controller managing the document state
  /// * [actions] → Optional list of formatting actions to display. If null, displays default actions.
  /// * [alignment] → Defines how action buttons are aligned in the toolbar.
  /// * [hideInactive] → When `true`, hides inactive or unavailable format buttons.
  /// * [direction] → Layout direction of the toolbar ([Axis.horizontal] or [Axis.vertical]).
  /// * [onEditAnchor] → Callback triggered when editing or inserting a link ([FormatusAnchor]).
  /// * [onSelectColor] → Callback triggered when opening the color picker.
  /// * [onSelectEmoji] → Callback triggered when selecting an emoji.
  /// * [onSelectImage] → Callback triggered when inserting or editing an image ([FormatusImage]).
  /// * [textFieldFocus] → Focus node of the attached [TextField] to preserve focus state when tapping buttons.
  /// * [tooltipBuilder] → Custom builder for formatting button tooltips
  ///
  factory FormatusBar({
    Key? key,
    required FormatusController controller,
    List<Formatus>? actions,
    WrapAlignment alignment = .start,
    bool hideInactive = false,
    Axis direction = .horizontal,
    AnchorEditor? onEditAnchor,
    ColorSelector? onSelectColor,
    EmojiSelector? onSelectEmoji,
    ImageSelector? onSelectImage,
    FocusNode? textFieldFocus,
    TooltipBuilder? tooltipBuilder,
  }) => FormatusBarImpl(
    key: key,
    controller: controller as FormatusControllerImpl,
    actions: actions,
    alignment: alignment,
    direction: direction,
    hideInactive: hideInactive,
    onEditAnchor: onEditAnchor,
    onSelectColor: onSelectColor,
    onSelectEmoji: onSelectEmoji,
    onSelectImage: onSelectImage,
    textFieldFocus: textFieldFocus,
    tooltipBuilder: tooltipBuilder,
  );

  /// List of inlines -> sublist of Formatus.values in useful order
  static List<Formatus> get listOfInlines => List.of(_listOfInlines);
  static final List<Formatus> _listOfInlines = [
    Formatus.bold,
    Formatus.italic,
    Formatus.underline,
    Formatus.strikeThrough,
    Formatus.color,
    Formatus.subscript,
    Formatus.superscript,
  ];

  /// List of sections -> sublist of Formatus.values in useful order
  static List<Formatus> get listOfLists => List.of(_listOfLists);
  static final List<Formatus> _listOfLists = [
    Formatus.unorderedList,
    Formatus.orderedList,
  ];

  /// List of sections -> sublist of Formatus.values in useful order
  static List<Formatus> get listOfSections => List.of(_listOfSections);
  static final List<Formatus> _listOfSections = [
    Formatus.header1,
    Formatus.header2,
    Formatus.header3,
    Formatus.paragraph,
  ];

  /// List of sizes -> sublist of Formatus.values in useful order
  static List<Formatus> get listOfSizes => List.of(_listOfSizes);
  static final List<Formatus> _listOfSizes = [Formatus.small, Formatus.big];

  static List<Formatus> get collapsedActions => List.of(_collapsedActions);
  static final List<Formatus> _collapsedActions = [
    Formatus.collapseSections,
    ...listOfSections,
    Formatus.collapseLists,
    ...listOfLists,
    Formatus.collapseSizes,
    ...listOfSizes,
    Formatus.collapseInlines,
    ...listOfInlines,
  ];

  static List<Formatus> get defaultActions => List.of(_defaultActions);
  static final List<Formatus> _defaultActions = [
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
    Formatus.emoji,
    Formatus.collapseSizes,
    Formatus.anchor,
    Formatus.image,
  ];
}
