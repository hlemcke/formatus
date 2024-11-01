import 'package:flutter/material.dart';

import 'formatus_controller.dart';
import 'formatus_model.dart';

///
/// Extendable action to format text.
///
class FormatusAction {
  /// Top level or inline format
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
    this.icon = icon ?? formatus.icon!;
    this.style = style ?? formatus.style;
  }

  bool get isTopLevel => formatus.type == FormatusType.topLevel;
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
/// The bar itself is a [Wrap] of [_FormatusButton] widgets.
///
class FormatusBar extends StatefulWidget {
  /// Actions to be included in the toolbar. Defaults to all actions.
  late final List<FormatusAction> actions;

  /// TODO `true` will condense top-level formats and alignments
  /// into dropdown selections.
  final bool condense;
  final Axis direction;
  final FormatusController formatusController;

  /// Callback invoked with parameter [FormatusAnchor] from cursor position.
  /// Setting this parameter will activate [anchorAction] in the toolbar.
  final AnchorEditor? onEditAnchor;

  /// Callback invoked with parameter [FormatusAnchor] from cursor position
  final AnchorActivity? onTapAnchor;
  final FocusNode? textFieldFocus;

  ///
  /// Creates action bar to format text in a [TextField] or [TextFormField].
  /// The same [FormatusController] must be supplied both to the [TextField]
  /// and to this `FormatusBar`.
  ///
  /// To automatically switch back the focus from this `FormatusBar` the
  /// same [FocusNode] must be supplied both to the [TextField]
  /// and to this [FormatusBar].
  ///
  FormatusBar({
    super.key,
    required this.formatusController,
    List<FormatusAction>? actions,
    this.condense = false,
    this.direction = Axis.horizontal,
    this.onEditAnchor,
    this.onTapAnchor,
    this.textFieldFocus,
  }) {
    this.actions = actions ?? _defaultActions;
    if (onEditAnchor == null) {
      this.actions.remove(anchorAction);
    }
  }

  @override
  State<StatefulWidget> createState() => _FormatusBarState();
}

///
/// `selectedFormats` are managed in [FormatusController].
///
class _FormatusBarState extends State<FormatusBar> {
  late final FormatusController _ctrl;

  Set<Formatus> get _selectedFormats => _ctrl.selectedFormats;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.formatusController;
    _ctrl.addListener(_updateActivatedActions);
    _deactivateActions();
  }

  @override
  Widget build(BuildContext context) => Wrap(
        direction: widget.direction,
        children: [
          for (FormatusAction action in widget.actions)
            _FormatusButton(
              action: action,
              isSelected: _selectedFormats.contains(action.formatus),
              onPressed: () => _onToggleAction(action.formatus),
            ),
        ],
      );

  void _deactivateActions() => _selectedFormats.clear();

  void _deactivateTopLevelActions() {
    for (FormatusAction action in widget.actions) {
      if (action.isTopLevel) {
        _selectedFormats.remove(action);
      }
    }
  }

  ///
  /// Toggles format button
  ///
  /// Only one top-level format may be active at any time.
  ///
  void _onToggleAction(Formatus formatus) {
    if (formatus == Formatus.anchor) {
      // invoke method "onEditAnchor"
      FormatusAnchor anchor = widget.formatusController.anchorAtCursor;
      widget.onEditAnchor!(context, anchor);
      return;
    } else if (formatus.isTopLevel) {
      _deactivateTopLevelActions();
      _selectedFormats.add(formatus);
    } else if (_selectedFormats.contains(formatus)) {
      _selectedFormats.remove(formatus);
    } else {
      _selectedFormats.add(formatus);
    }
    setState(() => widget.textFieldFocus?.requestFocus());
  }

  void _updateActivatedActions() {
    Set<Formatus> formatsInPath = _ctrl.formatsAtCursor;
    _deactivateActions();
    for (Formatus format in formatsInPath) {
      _selectedFormats.add(format);
    }
    setState(() {});
  }
}

///
/// Single formatting action
///
class _FormatusButton extends StatelessWidget {
  final FormatusAction action;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _FormatusButton({
    required this.action,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => IconButton(
        icon: action.icon,
        isSelected: isSelected,
        key: ValueKey<String>(action.formatus.name),
        onPressed: onPressed,
        style: isSelected ? _formatusButtonStyleActive : _formatusButtonStyle,
      );
}

/// Separately specified to put into expected position
final FormatusAction anchorAction = FormatusAction(formatus: Formatus.anchor);
final List<FormatusAction> _defaultActions = [
  FormatusAction(formatus: Formatus.header1),
  FormatusAction(formatus: Formatus.header2),
  FormatusAction(formatus: Formatus.header3),
  FormatusAction(formatus: Formatus.paragraph),
  FormatusAction(formatus: Formatus.italic),
  FormatusAction(formatus: Formatus.bold),
  FormatusAction(formatus: Formatus.underline),
  FormatusAction(formatus: Formatus.strikeThrough),
  anchorAction,
];

final ButtonStyle _formatusButtonStyle = ButtonStyle(
//  iconSize: WidgetStateProperty.all(kMinInteractiveDimension * 0.7),
  fixedSize: WidgetStateProperty.all(
      const Size.square(kMinInteractiveDimension * 0.7)),
  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
    const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(6),
        topRight: Radius.circular(6),
      ),
      side: BorderSide(color: Colors.grey),
    ),
  ),
);

final ButtonStyle _formatusButtonStyleActive =
    _formatusButtonStyle.merge(ButtonStyle(
  backgroundColor: WidgetStateProperty.all<Color>(Colors.amberAccent),
));
