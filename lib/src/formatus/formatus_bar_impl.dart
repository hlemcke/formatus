import 'dart:core';

import 'package:flutter/material.dart';

import 'formatus_bar.dart';
import 'formatus_controller_impl.dart';
import 'formatus_model.dart';

/// Height of a formatting action button
final double buttonHeight = kMinInteractiveDimension * 0.7;

///
/// Actions to format text.
///
class FormatusBarImpl extends StatefulWidget implements FormatusBar {
  final Map<Formatus, List<Formatus>> actionGroups = {};

  /// Actions to be included in the toolbar (see [formatusDefaultActions])
  final List<Formatus> actions = [];

  final WrapAlignment alignment;

  /// Required controller
  final FormatusControllerImpl controller;

  /// Formatting actions are aligned horizontal (default) or vertical
  final Axis direction;

  /// `true` will hide the bar if the focus is outside (default is `false`)
  final bool hideInactive;

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
    List<Formatus>? actions,
    this.alignment = WrapAlignment.start,
    this.direction = Axis.horizontal,
    this.hideInactive = false,
    this.onEditAnchor,
    this.onSelectImage,
    this.textFieldFocus,
  }) {
    _cleanupActions(actions);
  }

  void _cleanupActions(List<Formatus>? suppliedActions) {
    List<Formatus> initialActions = [
      ...(suppliedActions == null) || suppliedActions.isEmpty
          ? formatusDefaultActions
          : suppliedActions,
    ];

    //--- Remove anchor if onEditAnchor not supplied
    if (onEditAnchor == null) {
      initialActions.remove(Formatus.anchor);
    }

    //--- Remove image if onSelectImage not supplied
    if (onSelectImage == null) {
      initialActions.remove(Formatus.image);
    }
    //--- Build groups
    Formatus? currentCollapsible;
    for (Formatus action in initialActions) {
      if (action == Formatus.collapseEnd) {
        currentCollapsible = null;
      } else if (action.isCollapsible) {
        actionGroups[action] = [];
        currentCollapsible = action;
        actions.add(action);
      } else if (currentCollapsible != null) {
        if (action.type == currentCollapsible.type) {
          actionGroups[currentCollapsible]?.add(action);
        } else {
          currentCollapsible = null;
          actions.add(action);
        }
      } else {
        actions.add(action);
      }
    }

    //--- Fill empty groups
    for (Formatus group in actionGroups.keys) {
      if (actionGroups[group]!.isEmpty) {
        actionGroups[group] = (group == Formatus.collapseInlines)
            ? listOfInlines
            : (group == Formatus.collapseLists)
            ? listOfLists
            : (group == Formatus.collapseSections)
            ? listOfSections
            : (group == Formatus.collapseSizes)
            ? listOfSizes
            : [];
      }
    }
  }

  @override
  State<StatefulWidget> createState() => FormatusBarState();
}

///
/// `selectedFormats` are managed in [FormatusController].
///
class FormatusBarState extends State<FormatusBarImpl>
    with SingleTickerProviderStateMixin {
  late final FormatusControllerImpl _ctrl;
  late AnimationController _animCtrl;
  late Animation<double> _heightFactor;
  bool _isOverlayOpen = false; // track if in sub-menu or dialog

  Color get _selectedColor => _ctrl.selectedColor;

  Set<Formatus> get _selectedFormats => _ctrl.selectedFormats;

  @override
  void dispose() {
    widget.textFieldFocus?.removeListener(_handleFocusChange);
    _ctrl.removeListener(_updateActionsDisplay);
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller;
    _ctrl.addListener(_updateActionsDisplay);
    _deactivateActions();

    //--- Setup Animation to hide / show the toolbar
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightFactor = CurvedAnimation(
      curve: Curves.easeOutCubic,
      parent: _animCtrl,
    );
    widget.textFieldFocus?.addListener(_handleFocusChange);

    //--- Initial State: If field has focus, show immediately
    if (widget.textFieldFocus?.hasFocus ?? false) {
      _animCtrl.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _heightFactor,
    axisAlignment: -1.0,
    child: FadeTransition(
      opacity: _heightFactor,
      child: Focus(
        // This allows the bar to be part of the focus group
        canRequestFocus: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Wrap(
            alignment: widget.alignment,
            direction: widget.direction,
            children: _buildActions(),
          ),
        ),
      ),
    ),
  );

  List<Widget> _buildActions() => [
    for (Formatus action in widget.actions)
      (action.isCollapsible)
          ? FormatusGroupButton(
              actions: widget.actionGroups[action]!,
              ctrl: _ctrl,
              group: action,
              onPressed: _onToggleAction,
              onTrackOverlay: _trackOverlay,
            )
          : FormatusActionButton(
              action: action,
              key: ValueKey('${action.key}_${widget.key}'),
              isSelected: _selectedFormats.contains(action),
              onPressed: (action) => _onToggleAction(action),
              textColor: _selectedColor,
            ),
  ];

  void _deactivateActions() => _selectedFormats.clear();

  void _deactivateSectionActions() {
    for (Formatus action in widget.actions) {
      if (action.isSection || action.isList) {
        _selectedFormats.remove(action);
      }
    }
    List<Formatus>? collapsedSections =
        widget.actionGroups[Formatus.collapseSections];
    if (collapsedSections != null) {
      for (Formatus action in collapsedSections) {
        if (action.isSection || action.isList) {
          _selectedFormats.remove(action);
        }
      }
    }
  }

  void _handleFocusChange() {
    if (!mounted) return;

    if (widget.textFieldFocus?.hasFocus ?? false) {
      _animCtrl.forward();
    } else {
      //--- Debounce hide
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted &&
            !(widget.textFieldFocus?.hasFocus ?? false) &&
            !_isOverlayOpen) {
          _animCtrl.reverse();
        }
      });
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
  void _onToggleAction(Formatus formatus) async {
    final TextSelection currentSelection = _ctrl.selection;
    if (formatus == Formatus.anchor) {
      await _onEditAnchor();
    } else if (formatus == Formatus.color) {
      return _selectAndRememberColor();
    } else if (formatus == Formatus.image) {
      await _onSelectImage();
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
    if (mounted) {
      widget.textFieldFocus?.requestFocus();
      _ctrl.value = _ctrl.value.copyWith(selection: currentSelection);
      setState(() {});
    }
  }

  void _selectAndRememberColor() async {
    final TextSelection currentSelection = _ctrl.selection;
    Color? color = await _trackOverlay(_showColorDialog());
    _ctrl.selectedColor = color ?? Colors.transparent;
    if (color == Colors.transparent) {
      _selectedFormats.remove(Formatus.color);
    } else {
      _selectedFormats.add(Formatus.color);
    }
    _ctrl.updateInlineFormat(Formatus.color);
    if (mounted) {
      _ctrl.selection = currentSelection;
      setState(() {});
    }
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

  /// Wrapper for any action that opens a new Route (Dialog, Menu, Picker)
  Future<T?> _trackOverlay<T>(Future<T?> overlayFuture) async {
    final TextSelection currentSelection = _ctrl.selection;
    _isOverlayOpen = true;
    final result = await overlayFuture;
    _isOverlayOpen = false;

    //--- Return focus to text field so bar stays open after overlay is dismissed
    if (mounted) {
      widget.textFieldFocus?.requestFocus();
      _ctrl.value = _ctrl.value.copyWith(selection: currentSelection);
    }
    return result;
  }

  void _updateActionsDisplay() {
    if (mounted) setState(() {});
  }
}

///
/// Single formatting action also used inside [FormatusGroupButton]
///
class FormatusActionButton extends StatelessWidget {
  final Formatus action;
  final bool isSelected;
  final ValueChanged<Formatus> onPressed;
  final Color textColor;

  const FormatusActionButton({
    super.key,
    required this.action,
    this.isSelected = false,
    required this.onPressed,
    this.textColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) => (action == Formatus.gap)
      ? SizedBox(height: 8, width: 8)
      : IconButton(
          color:
              ((action == Formatus.color) && (textColor != Colors.transparent))
              ? textColor
              : null,
          icon: action.icon!,
          isSelected: isSelected,
          key: ValueKey<String>(action.name),
          onPressed: () => onPressed(action),
          style: isSelected
              ? getFormatusButtonStyleActive()
              : getFormatusButtonStyle(),
        );
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
  final List<Formatus> actions;
  final FormatusControllerImpl ctrl;
  final Formatus group;
  final ValueChanged<Formatus> onPressed;
  final Future<T?> Function<T>(Future<T?> future) onTrackOverlay;

  const FormatusGroupButton({
    super.key,
    required this.ctrl,
    required this.group,
    required this.actions,
    required this.onPressed,
    required this.onTrackOverlay,
  });

  @override
  Widget build(BuildContext context) {
    List<FormatusActionButton> buttons = [];
    int count = 0;
    Formatus? activeAction;

    //--- determine active actions while building menu items
    for (Formatus action in actions) {
      bool isActive = ctrl.selectedFormats.contains(action);
      activeAction = isActive ? action : activeAction;
      count += isActive ? 1 : 0;
      buttons.add(
        FormatusActionButton(
          action: action,
          key: ValueKey('${action.key}_$key'),
          isSelected: isActive,
          onPressed: (action) {
            Navigator.of(context).pop();
            onPressed(action);
          },
        ),
      );
    }

    return IconButton(
      icon: _buildGroupIcon((count == 1) ? activeAction! : group, count),
      onPressed: () => _showIconMenu(context, buttons),
      style: (count > 0)
          ? getFormatusButtonStyleActive(isGroup: true)
          : getFormatusButtonStyle(isGroup: true),
    );
  }

  Widget _buildGroupIcon(Formatus formatus, int count) => Row(
    mainAxisAlignment: MainAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      (count > 1) ? Text('$count') : formatus.icon!,
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

  void _showIconMenu(BuildContext context, List<FormatusActionButton> buttons) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final Size size = button.size;
    onTrackOverlay(
      showMenu(
        clipBehavior: Clip.hardEdge,
        constraints: BoxConstraints.tightFor(width: buttonHeight + 8),
        context: context,
        items: [
          for (FormatusActionButton button in buttons)
            PopupMenuItem(
              height: buttonHeight,
              padding: EdgeInsets.zero,
              child: button,
            ),
        ],
        menuPadding: EdgeInsets.zero,
        position: RelativeRect.fromLTRB(
          offset.dx,
          offset.dy + size.height,
          offset.dx + size.width,
          offset.dy,
        ),
      ),
    );
  }
}

ButtonStyle getFormatusButtonStyle({bool isGroup = false}) => ButtonStyle(
  fixedSize: WidgetStateProperty.all(
    isGroup ? Size(buttonHeight + 20, buttonHeight) : Size.square(buttonHeight),
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

ButtonStyle getFormatusButtonStyleActive({bool isGroup = false}) =>
    getFormatusButtonStyle(isGroup: isGroup).merge(
      ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(Colors.amberAccent),
      ),
    );
