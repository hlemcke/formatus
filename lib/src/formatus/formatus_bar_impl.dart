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
  State<StatefulWidget> createState() => FormatusBarState();
}

///
/// `selectedFormats` are managed in [FormatusController].
///
class FormatusBarState extends State<FormatusBarImpl> {
  late final FormatusControllerImpl _ctrl;
  late final FormatusActionGroups _groups;

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
    _ctrl.addListener(_updateActionsDisplay);
    _groups = FormatusActionGroups(actions: widget.actions);
    _deactivateActions();
  }

  @override
  Widget build(BuildContext context) => widget.textFieldFocus?.hasFocus ?? true
      ? Wrap(
          alignment: widget.alignment,
          direction: widget.direction,
          children: widget.condense ? _buildCondensed() : _buildExpanded(),
        )
      : SizedBox.shrink();

  List<Widget> _buildCondensed() => [
    FormatusGroupButton(ctrl: _ctrl, group: _groups[FormatusType.section]!),
    FormatusGroupButton(ctrl: _ctrl, group: _groups[FormatusType.list]!),
    FormatusGroupButton(ctrl: _ctrl, group: _groups[FormatusType.size]!),
    FormatusGroupButton(ctrl: _ctrl, group: _groups[FormatusType.inline]!),
  ];

  List<Widget> _buildExpanded() => [
    for (FormatusAction action in widget.actions)
      (action.formatus == Formatus.textSize)
          ? FormatusGroupButton(ctrl: _ctrl, group: _groups[FormatusType.size]!)
          : FormatusButton(
              action: action,
              key: ValueKey('${action.formatus.key}_${widget.key}'),
              isSelected: _selectedFormats.contains(action.formatus),
              onPressed: () => _onToggleAction(action.formatus),
              textColor: _selectedColor,
            ),
  ];

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
  Widget build(BuildContext context) => (action.formatus == Formatus.gap)
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
              : getFormatusButtonStyle(),
        );
}

///
///
///
class FormatusActionGroups {
  FormatusActionGroups({required List<FormatusAction> actions}) {
    for (FormatusAction action in actions) {
      this[action.formatus.type]?.actions.add(action);
    }
  }

  FormatusActionGroup? operator [](FormatusType type) => {
    FormatusType.inline: FormatusActionGroup(
      icon: Icon(Icons.abc_outlined),
      type: FormatusType.inline,
    ),
    FormatusType.list: FormatusActionGroup(
      icon: Icon(Icons.line_weight_outlined),
      type: FormatusType.list,
    ),
    FormatusType.section: FormatusActionGroup(
      icon: Icon(Icons.question_mark_outlined),
      isMandatory: true,
      type: FormatusType.section,
    ),
    FormatusType.size: FormatusActionGroup(
      actions: [
        FormatusAction(formatus: Formatus.big),
        FormatusAction(formatus: Formatus.small),
      ],
      icon: Icon(Icons.format_size_outlined),
      type: FormatusType.size,
    ),
  }[type];
}

///
/// Groups actions for a `condensed` [FormatusBar]
///
class FormatusActionGroup {
  /// Type of this action group
  final FormatusType type;

  /// Icon displayed if no action is active
  final Widget icon;

  /// Actions will be filled by [FormatusBar]
  late List<FormatusAction> actions;

  /// One item must always be selected
  final bool isMandatory;

  FormatusActionGroup({
    required this.type,
    required this.icon,
    List<FormatusAction>? actions,
    this.isMandatory = false,
  }) {
    this.actions = (actions == null) ? [] : actions;
  }
}

///
/// Compact menu of formatting actions in a dropdown menu.
///
/// Button itself displays an icon followed by a dropdown arrow:
///
/// * [icon] if no action is active
/// * _action_  if exactly one action is active
/// * number of actions if multiple actions are active (only for inlines)
///
class FormatusGroupButton extends StatelessWidget {
  final FormatusActionGroup group;
  final FormatusControllerImpl ctrl;

  const FormatusGroupButton({
    super.key,
    required this.ctrl,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    List<FormatusButton> buttons = [];
    int count = 0;
    FormatusButton? activeButton;

    //--- determine active actions while building menu items
    for (FormatusAction action in group.actions) {
      bool isActive = ctrl.selectedFormats.contains(action.formatus);
      count += isActive ? 1 : 0;
      FormatusButton button = FormatusButton(
        action: action,
        isSelected: isActive,
      );
      buttons.add(button);
      activeButton = isActive ? button : activeButton;
    }

    return IconButton(
      icon: _buildGroupIcon(count, activeButton),
      onPressed: () => _showIconMenu(context, buttons),
      style: (count > 0)
          ? _formatusButtonStyleActive
          : getFormatusButtonStyle(isGroup: true),
    );
  }

  Widget _buildGroupIcon(int count, FormatusButton? active) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      (count == 0)
          ? group.icon
          : (count == 1)
          ? active!
          : Text('$count'),
      Text(
        '▼',
        style: TextStyle(
          fontSize: 12, // Control the size here
          fontWeight: FontWeight.bold, // Make it look crisp
          height: 1.0, // Adjust line height to compact vertical space
        ),
      ),
    ],
  );

  void _showIconMenu(BuildContext context, List<FormatusButton> buttons) =>
      showMenu(
        context: context,
        items: [
          for (FormatusButton button in buttons) PopupMenuItem(child: button),
        ],
        position: RelativeRect.fromLTRB(0, 0, 0, 0),
      );
}

ButtonStyle getFormatusButtonStyle({bool isGroup = false}) => ButtonStyle(
  fixedSize: WidgetStateProperty.all(
    isGroup
        ? Size(
            kMinInteractiveDimension * 0.7 + 20,
            kMinInteractiveDimension * 0.7,
          )
        : const Size.square(kMinInteractiveDimension * 0.7),
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

final ButtonStyle _formatusButtonStyleActive = getFormatusButtonStyle().merge(
  ButtonStyle(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.amberAccent),
  ),
);
