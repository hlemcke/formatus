import 'package:flutter/material.dart';

import 'formatus_bar.dart';
import 'formatus_controller_impl.dart';
import 'formatus_model.dart';

///
/// Actions to format text.
///
class FormatusBarImpl extends StatefulWidget implements FormatusBar {
  /// Actions to be included in the toolbar. Defaults to all actions.
  late final List<FormatusAction> actions;

  final WrapAlignment alignment;

  /// `true` will provide the inline formats in a [DropdownMenu].
  /// Default is `false`.
  final bool compactInlineFormats;

  /// `true` will provide the section formats in a [DropdownMenu].
  /// Default is `false`.
  final bool compactSectionFormats;

  /// Required controller
  final FormatusControllerImpl controller;

  /// Formatting actions are aligned horizontal (default) or vertical
  final Axis direction;

  /// Setting this parameter will include the link-action into the bar.
  ///
  /// Callback invoked when user activates the link-action in the bar.
  /// The callback gets the [FormatusAnchor] from cursor position.
  final AnchorEditor? onEditAnchor;

  /// Callback invoked when user double taps on an anchor text.
  ///
  /// The callback get the [FormatusAnchor] from cursor position.
  final AnchorActivity? onTapAnchor;

  /// Supply [FocusNode] from [TextField] to have [FormatusBar] automatically
  /// switch back focus to the text field after any format change.
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
  FormatusBarImpl({
    super.key,
    required this.controller,
    List<FormatusAction>? actions,
    this.alignment = WrapAlignment.start,
    this.compactInlineFormats = false,
    this.compactSectionFormats = false,
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
class _FormatusBarState extends State<FormatusBarImpl> {
  late final FormatusControllerImpl _ctrl;

  Set<Formatus> get _selectedFormats => _ctrl.selectedFormats;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller;
    _ctrl.addListener(_updateActivatedActions);
    _deactivateActions();
  }

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: widget.alignment,
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

  void _deactivateSectionActions() {
    for (FormatusAction action in widget.actions) {
      if (action.isSection) {
        _selectedFormats.remove(action.formatus);
      }
    }
  }

  Future<void> _onEditAnchor() async {
    FormatusAnchor? anchorAtCursor = widget.controller.anchorAtCursor;
    FormatusAnchor? result =
        await widget.onEditAnchor!(context, anchorAtCursor ?? FormatusAnchor());
    widget.controller.anchorAtCursor = result;
  }

  ///
  /// Toggles format button
  ///
  /// Only one section format may be active at any time.
  ///
  void _onToggleAction(Formatus formatus) {
    //--- Special handling if anchor is present in formatting actions
    if (formatus == Formatus.anchor) {
      _onEditAnchor();
      return;
    }
    if (formatus.isSection) {
      _deactivateSectionActions();
      _selectedFormats.add(formatus);
      widget.controller.updateSectionFormat(formatus);
    } else if (_selectedFormats.contains(formatus)) {
      _selectedFormats.remove(formatus);
      _ctrl.updateInlineFormat(formatus, false);
    } else {
      _selectedFormats.add(formatus);
      _ctrl.updateInlineFormat(formatus, true);
    }
    setState(() => widget.textFieldFocus?.requestFocus());
  }

  void _updateActivatedActions() {
    List<Formatus> formatsInPath = _ctrl.formatsAtCursor;
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
  Widget build(BuildContext context) => (action.formatus == Formatus.gap)
      ? SizedBox(height: 8, width: 8)
      : IconButton(
          icon: action.icon,
          isSelected: isSelected,
          key: ValueKey<String>(action.formatus.name),
          onPressed: onPressed,
          style: isSelected ? _formatusButtonStyleActive : _formatusButtonStyle,
        );
}

final List<FormatusAction> _defaultActions = [
  FormatusAction(formatus: Formatus.header1),
  FormatusAction(formatus: Formatus.header2),
  FormatusAction(formatus: Formatus.header3),
  FormatusAction(formatus: Formatus.paragraph),
  FormatusAction(formatus: Formatus.gap),
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
