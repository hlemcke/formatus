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
  final bool condense;

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
    this.condense = false,
    this.direction = Axis.horizontal,
    this.onEditAnchor,
    this.onSelectImage,
    this.textFieldFocus,
  }) {
    //--- Cleanup actions
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

  final List<FormatusAction> _groupSections = [];
  final List<FormatusAction> _groupInlines = [];
  final List<FormatusAction> _groupLists = [];
  final List<FormatusAction> _groupSizes = [
    FormatusAction(formatus: Formatus.big),
    FormatusAction(formatus: Formatus.small),
  ];

  Color get _selectedColor => _ctrl.selectedColor;

  Set<Formatus> get _selectedFormats => _ctrl.selectedFormats;

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
    _fillGroup(_groupInlines, FormatusType.inline);
    _fillGroup(_groupLists, FormatusType.list);
    _fillGroup(_groupSections, FormatusType.section);
  }

  @override
  Widget build(BuildContext context) => widget.textFieldFocus?.hasFocus ?? true
      ? Wrap(
          alignment: widget.alignment,
          direction: widget.direction,
          children: widget.condense
              ? [
                  _buildGroup(FormatusType.section, _groupSections),
                  _buildGroup(FormatusType.list, _groupLists),
                  _buildGroup(FormatusType.inline, _groupInlines),
                ]
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

  Widget _buildGroup(FormatusType type, List<FormatusAction> actions) {
    int activeCount = 0;
    FormatusButton? activeButton;
    List<DropdownMenuEntry> entries = [];
    for (FormatusAction action in actions) {
      bool isActive = _selectedFormats.contains(action.formatus);
      activeCount += isActive ? 1 : 0;
      FormatusButton button = FormatusButton(
        action: action,
        isSelected: isActive,
        onPressed: () => _onToggleAction(action.formatus),
      );
      activeButton = isActive ? button : activeButton;
      entries.add(
        DropdownMenuEntry(
          value: action.formatus,
          label: '',
          labelWidget: button,
        ),
      );
    }
    return DropdownMenu(
      dropdownMenuEntries: entries,
      label: (activeCount > 1) ? Text('$activeCount') : activeButton,
    );
  }

  void _deactivateActions() => _selectedFormats.clear();

  void _deactivateSectionActions() {
    for (FormatusAction action in widget.actions) {
      if (action.isSection || action.isList) {
        _selectedFormats.remove(action.formatus);
      }
    }
  }

  void _fillGroup(List<FormatusAction> group, FormatusType type) {
    for (FormatusAction action in widget.actions) {
      if (action.formatus.type == type) {
        group.add(action);
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
  Widget build(BuildContext context) => (action.formatus == Formatus.gap)
      ? SizedBox(height: 8, width: 8)
      : (action.formatus == Formatus.textSize)
      ? _buildSizeSelector()
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
          style: isSelected ? _formatusButtonStyleActive : _formatusButtonStyle,
        );

  Widget _buildSizeSelector() => PopupMenuButton(
    itemBuilder: (BuildContext context) => [
      for (Formatus formatus in [])
        PopupMenuItem(
          key: ValueKey(formatus.key),
          value: formatus,
          child: FormatusButton(
            action: FormatusAction(formatus: formatus),
            isSelected: false,
            onPressed: () => {},
          ),
        ),
    ],
    child: Badge(
      label: Icon(Icons.arrow_drop_down_circle_outlined),
      child: Icon(Icons.format_size_outlined),
    ),
  );
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
