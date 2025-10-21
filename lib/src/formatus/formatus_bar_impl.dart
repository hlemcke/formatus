import 'package:flutter/material.dart';

import 'formatus_bar.dart';
import 'formatus_controller_impl.dart';
import 'formatus_model.dart';

///
/// Actions to format text.
///
class FormatusBarImpl extends StatefulWidget implements FormatusBar {
  /// Actions to be included in the toolbar (see [formatusDefaultActions])
  late final List<FormatusAction> actions;

  final WrapAlignment alignment;

  ///
  /// `true` groups format-actions into [DropdownMenu].
  ///
  /// Group _section-format_ displays current section format.
  ///
  /// Group _inline-format_ displays:
  /// `0` -> no inline format applied
  /// `?` -> the icon of the inline format if a single format is applied
  /// `n` -> the number of applied inline formats
  ///
  final bool condenseActions;

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
  final ImageSelector? onSelectImage;

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
    this.condenseActions = false,
    this.direction = Axis.horizontal,
    this.onEditAnchor,
    this.onSelectImage,
    this.textFieldFocus,
  }) {
    this.actions = actions ?? formatusDefaultActions;
    if (onEditAnchor == null) {
      this.actions.remove(anchorAction);
    }
    if (onSelectImage == null) {
      this.actions.remove(imageAction);
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

  Color get _selectedColor => _ctrl.selectedColor;

  Set<Formatus> get _selectedFormats => _ctrl.selectedFormats;

  /// Get current inline formats
  List<Formatus> get _currentInlineFormats =>
      _selectedFormats.where((f) => f.isInline).toList();

  /// Get current list. Returns _placeHolder_ if not in a list element
  Formatus get _currentListFormat => _selectedFormats.firstWhere(
    (f) => f.isList,
    orElse: () => Formatus.placeHolder,
  );

  /// Get current section format
  Formatus get _currentSectionFormat =>
      _selectedFormats.firstWhere((f) => f.isSection);

  @override
  void dispose() {
    _ctrl.removeListener(_updateActionsDisplay);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller;
    _deactivateActions();
    _ctrl.addListener(_updateActionsDisplay);
  }

  @override
  Widget build(BuildContext context) => widget.textFieldFocus?.hasFocus ?? true
      ? Wrap(
          alignment: widget.alignment,
          direction: widget.direction,
          children: widget.condenseActions
              ? [_buildSectionGroup(), _buildListGroup(), _buildInlineGroup()]
              : [
                  for (FormatusAction action in widget.actions)
                    FormatusButton(
                      action: action,
                      key: ValueKey('${action.formatus.key}_${widget.key}'),
                      isSelected: _selectedFormats.contains(action.formatus),
                      onPressed: () => _onToggleAction(action.formatus),
                      textColor: _selectedColor,
                    ),
                ],
        )
      : SizedBox.shrink();

  Widget _buildGroup(List<Formatus> currents, List<FormatusAction> actions) =>
      DropdownMenu(
        dropdownMenuEntries: [
          for (FormatusAction action in actions)
            DropdownMenuEntry(
              value: action.formatus,
              label: '',
              labelWidget: FormatusButton(
                action: action,
                isSelected: _selectedFormats.contains(action.formatus),
                onPressed: () => _onToggleAction(action.formatus),
              ),
            ),
        ],
        label: (currents.length > 1)
            ? Text('${currents.length}')
            : currents.first.icon,
      );

  final List<FormatusAction> _groupSection = [
    FormatusAction(formatus: Formatus.header1),
    FormatusAction(formatus: Formatus.header2),
    FormatusAction(formatus: Formatus.header3),
    FormatusAction(formatus: Formatus.paragraph),
  ];

  Widget _buildSectionGroup() =>
      _buildGroup([_currentSectionFormat], _groupSection);

  final List<FormatusAction> _groupList = [
    FormatusAction(formatus: Formatus.orderedList),
    FormatusAction(formatus: Formatus.unorderedList),
  ];

  Widget _buildListGroup() => _buildGroup([_currentListFormat], _groupList);

  final List<FormatusAction> _groupInline = [
    FormatusAction(formatus: Formatus.bold),
    FormatusAction(formatus: Formatus.italic),
    FormatusAction(formatus: Formatus.strikeThrough),
    FormatusAction(formatus: Formatus.underline),
    FormatusAction(formatus: Formatus.subscript),
    FormatusAction(formatus: Formatus.superscript),
  ];

  Widget _buildInlineGroup() =>
      _buildGroup(_currentInlineFormats, _groupInline);

  void _deactivateActions() => _selectedFormats.clear();

  void _deactivateSectionActions() {
    for (FormatusAction action in widget.actions) {
      if (action.isSection || action.isList) {
        _selectedFormats.remove(action.formatus);
      }
    }
  }

  Future<void> _onEditAnchor() async {
    FormatusAnchor? anchorAtCursor = widget.controller.anchorAtCursor;
    FormatusAnchor? result = await widget.onEditAnchor!(
      context,
      anchorAtCursor ?? FormatusAnchor(),
    );
    debugPrint('Anchor result = $result');
    widget.controller.anchorAtCursor = result;
  }

  Future<void> _onSelectImage() async {
    FormatusImage? imageAtCursor = widget.controller.imageAtCursor;
    FormatusImage? result = await widget.onSelectImage!(
      context,
      imageAtCursor ?? FormatusImage(),
    );
    debugPrint('Image = $result');
    widget.controller.imageAtCursor = result;
  }

  ///
  /// Toggles format button
  ///
  /// Only one section format may be active at any time.
  ///
  void _onToggleAction(Formatus formatus) {
    if (formatus == Formatus.anchor) {
      _onEditAnchor();
    } else if (formatus == Formatus.color) {
      return _selectAndRememberColor();
    } else if (formatus == Formatus.image) {
      _onSelectImage();
    } else if (formatus.isSection || formatus.isList) {
      _deactivateSectionActions();
      _selectedFormats.add(formatus);
      _ctrl.updateSectionFormat(formatus);
    } else if (_selectedFormats.contains(formatus)) {
      _selectedFormats.remove(formatus);
      _ctrl.updateInlineFormat(formatus);
    } else {
      _selectedFormats.add(formatus);
      _ctrl.updateInlineFormat(formatus);
    }
    setState(() => widget.textFieldFocus?.requestFocus());
  }

  void _selectAndRememberColor() async {
    Color? color = await _showColorDialog();
    _ctrl.selectedColor = color ?? Colors.transparent;
    if (color == Colors.transparent) {
      _selectedFormats.remove(Formatus.color);
    } else {
      _selectedFormats.add(Formatus.color);
    }
    _ctrl.updateInlineFormat(Formatus.color);
    setState(() => widget.textFieldFocus?.requestFocus());
  }

  Future<Color?> _showColorDialog() => showAdaptiveDialog<Color>(
    context: context,
    builder: (BuildContext context) => Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(8.0),
        child: Wrap(
          runSpacing: 8.0,
          spacing: 8.0,
          children: [
            for (Color color in formatusColors)
              InkWell(
                onTap: () => Navigator.pop(context, color),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  height: kMinInteractiveDimension,
                  width: kMinInteractiveDimension,
                  child: (color == Colors.transparent)
                      ? Center(child: Text('X'))
                      : null,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  void _updateActionsDisplay() => setState(() {});
}

///
/// Single formatting action
///
class FormatusButton extends StatelessWidget {
  final FormatusAction action;
  final bool isSelected;
  final VoidCallback? onPressed;
  final Color textColor;

  const FormatusButton({
    super.key,
    required this.action,
    this.isSelected = false,
    this.onPressed,
    this.textColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return (action.formatus == Formatus.gap)
        ? SizedBox(height: 8, width: 8)
        : IconButton(
            color:
                ((action.formatus == Formatus.color) &&
                    (textColor != Colors.transparent))
                ? textColor
                : null,
            icon: action.icon,
            isSelected: isSelected,
            key: ValueKey<String>(action.formatus.name),
            onPressed: onPressed,
            style: isSelected
                ? _formatusButtonStyleActive
                : _formatusButtonStyle,
          );
  }
}

final ButtonStyle _formatusButtonStyle = ButtonStyle(
  //  iconSize: WidgetStateProperty.all(kMinInteractiveDimension * 0.7),
  fixedSize: WidgetStateProperty.all(
    const Size.square(kMinInteractiveDimension * 0.7),
  ),
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

final ButtonStyle _formatusButtonStyleActive = _formatusButtonStyle.merge(
  ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.amberAccent),
  ),
);
