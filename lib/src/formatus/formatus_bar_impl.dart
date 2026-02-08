import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'formatus_bar.dart';
import 'formatus_controller_impl.dart';
import 'formatus_model.dart';

///
/// Actions to format text.
///
class FormatusBarImpl extends StatefulWidget implements FormatusBar {
  final Map<Formatus, List<Formatus>> actionGroups = {};

  /// Actions to be included in the toolbar (see [defaultActions])
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

  /// This callback activates and is used by action `color`
  final ColorSelector? onSelectColor;

  /// This callback activates and is used by action `emoji`
  final EmojiSelector? onSelectEmoji;

  /// Callback invoked when user double taps on an anchor text.
  ///
  /// The callback gets the [FormatusAnchor] from cursor position.
  final ImageSelector? onSelectImage;

  /// Supply [FocusNode] from [TextField] to have [FormatusBar] automatically
  /// switch back focus to the text field after any format change.
  final FocusNode? textFieldFocus;

  /// Supply a builder to get localized tooltips
  final TooltipBuilder? tooltipBuilder;

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
    this.onSelectColor,
    this.onSelectEmoji,
    this.onSelectImage,
    this.textFieldFocus,
    this.tooltipBuilder,
  }) {
    _cleanupActions(actions);
  }

  void _cleanupActions(List<Formatus>? suppliedActions) {
    List<Formatus> initialActions = [
      ...(suppliedActions == null) || suppliedActions.isEmpty
          ? FormatusBar.defaultActions
          : suppliedActions,
    ];

    //--- Remove anchor if onEditAnchor not supplied
    if (onEditAnchor == null) {
      initialActions.remove(Formatus.anchor);
    }

    //--- Remove emoji if onEditEmoji not supplied
    if (onSelectEmoji == null) {
      initialActions.remove(Formatus.emoji);
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
            ? FormatusBar.listOfInlines
            : (group == Formatus.collapseLists)
            ? FormatusBar.listOfLists
            : (group == Formatus.collapseSections)
            ? FormatusBar.listOfSections
            : (group == Formatus.collapseSizes)
            ? FormatusBar.listOfSizes
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
    BarThemeConfig();
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
      child: CallbackShortcuts(
        bindings: _shortcutBindings,
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
              tooltipBuilder: widget.tooltipBuilder,
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
    if (widget.onEditAnchor == null) return;
    final FormatusAnchor? result = await _trackOverlay(
      widget.onEditAnchor!(context, _ctrl.anchorAtCursor ?? FormatusAnchor()),
    );
    if (result != null) _ctrl.applyAnchor(result);
  }

  Future<void> _onSelectImage() async {
    if (widget.onSelectImage == null) return;
    final FormatusImage? result = await _trackOverlay(
      widget.onSelectImage!(context, _ctrl.imageAtCursor ?? FormatusImage()),
    );
    if (result != null) _ctrl.applyImage(result);
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
    } else if (formatus == Formatus.emoji) {
      return _selectAndInsertEmoji();
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

  void _selectAndInsertEmoji() async {
    if (widget.onSelectEmoji == null) return;
    final String? emoji = await _trackOverlay(widget.onSelectEmoji!(context));
    if (emoji != null) _ctrl.replaceText(emoji);
  }

  /// Uses external picker if provided, otherwise the internal one
  void _selectAndRememberColor() async {
    final ColorSelector colorSelector =
        widget.onSelectColor ?? (context, current) => _showColorDialog();
    Color? color = await _trackOverlay(colorSelector(context, _selectedColor));
    _ctrl.applySelectedColor(color);
  }

  Map<ShortcutActivator, VoidCallback> get _shortcutBindings => {
    // Bold: Ctrl+B / Cmd+B
    const SingleActivator(
      LogicalKeyboardKey.keyB,
      control: true,
      meta: true,
    ): () =>
        _onToggleAction(Formatus.bold),

    // Italic: Ctrl+I / Cmd+I
    const SingleActivator(
      LogicalKeyboardKey.keyI,
      control: true,
      meta: true,
    ): () =>
        _onToggleAction(Formatus.italic),

    // Underline: Ctrl+U / Cmd+U
    const SingleActivator(
      LogicalKeyboardKey.keyU,
      control: true,
      meta: true,
    ): () =>
        _onToggleAction(Formatus.underline),

    // Optional: Add Strikethrough if your model supports it
    const SingleActivator(
      LogicalKeyboardKey.keyS,
      control: true,
      shift: true,
    ): () =>
        _onToggleAction(Formatus.strikeThrough),
  };

  Future<Color?> _showColorDialog() => showAdaptiveDialog<Color>(
    context: context,
    builder: (BuildContext context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
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
                      border: color == Colors.transparent
                          ? Border.all(color: Colors.grey)
                          : null,
                      color: color == Colors.transparent ? Colors.white : color,
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
///
///
class BarThemeConfig {
  static BarThemeConfig get instance => _instance!;
  static BarThemeConfig? _instance;

  final double height;
  final double iconSize;
  final double arrowSize;
  final VisualDensity density;
  late final TargetPlatform platform;
  late final String platformCtrlKey;

  BarThemeConfig._internal({
    required this.height,
    required this.iconSize,
    required this.arrowSize,
    required this.density,
  }) {
    platform = defaultTargetPlatform;
    platformCtrlKey =
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)
        ? '⌘'
        : 'Ctrl';
  }

  factory BarThemeConfig() {
    if (_instance == null) {
      final bool isDesktop =
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows;

      _instance = BarThemeConfig._internal(
        height: isDesktop ? 30.0 : 38.0,
        iconSize: isDesktop ? 18.0 : 22.0,
        arrowSize: isDesktop ? 9.0 : 11.0,
        density: isDesktop ? VisualDensity.compact : VisualDensity.standard,
      );
    }
    return _instance!;
  }

  ButtonStyle getButtonStyle({bool isGroup = false, bool isSelected = false}) =>
      ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: density,
        backgroundColor: isSelected
            ? WidgetStateProperty.all(Colors.amberAccent)
            : null,
        fixedSize: WidgetStateProperty.all(
          isGroup ? Size(height + 14, height) : Size.square(height),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: Colors.grey, width: 0.5),
          ),
        ),
      );

  /// Internal mapping for default tooltips
  String? getDefaultTooltip(Formatus action) => switch (action) {
    Formatus.anchor => 'Insert or edit Link',
    Formatus.bold => 'Bold ($platformCtrlKey+B)',
    Formatus.collapseInlines => 'Inline Formats',
    Formatus.collapseLists => 'List Formats',
    Formatus.color => 'Text Color',
    Formatus.emoji => 'Insert Emoji',
    Formatus.image => 'Insert Image',
    Formatus.italic => 'Italic ($platformCtrlKey+I)',
    Formatus.strikeThrough => 'Strikethrough ($platformCtrlKey+Shift+S)',
    Formatus.underline => 'Underline ($platformCtrlKey+U)',
    _ => null,
  };
}

///
/// Single formatting action also used inside [FormatusGroupButton]
///
class FormatusActionButton extends StatelessWidget {
  final Formatus action;
  final bool isSelected;
  final ValueChanged<Formatus> onPressed;
  final Color textColor;
  final TooltipBuilder? tooltipBuilder;

  const FormatusActionButton({
    super.key,
    required this.action,
    this.isSelected = false,
    required this.onPressed,
    this.textColor = Colors.transparent,
    this.tooltipBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (action == Formatus.gap) return SizedBox(height: 8, width: 8);
    final String? tooltipMessage =
        tooltipBuilder?.call(context, action) ??
        BarThemeConfig.instance.getDefaultTooltip(action);

    return (tooltipMessage == null)
        ? _buildButton()
        : Tooltip(
            message: tooltipMessage,
            waitDuration: const Duration(milliseconds: 600),
            child: _buildButton(),
          );
  }

  Widget _buildButton() => IconButton(
    color: ((action == Formatus.color) && (textColor != Colors.transparent))
        ? textColor
        : null,
    icon: action.icon!,
    isSelected: isSelected,
    key: ValueKey<String>(action.name),
    onPressed: () => onPressed(action),
    style: BarThemeConfig.instance.getButtonStyle(isSelected: isSelected),
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
  final TooltipBuilder? tooltipBuilder;

  const FormatusGroupButton({
    super.key,
    required this.ctrl,
    required this.group,
    required this.actions,
    required this.onPressed,
    required this.onTrackOverlay,
    this.tooltipBuilder,
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
          tooltipBuilder: tooltipBuilder,
        ),
      );
    }

    Widget button = IconButton(
      icon: _buildGroupIcon((count == 1) ? activeAction! : group, count),
      onPressed: () => _showIconMenu(context, buttons),
      style: BarThemeConfig.instance.getButtonStyle(
        isGroup: true,
        isSelected: (count > 0),
      ),
    );

    //--- localize tooltip if there is a callback supplied
    final String? tooltipMessage =
        tooltipBuilder?.call(context, group) ??
        BarThemeConfig.instance.getDefaultTooltip(group);
    return (tooltipMessage == null)
        ? button
        : Tooltip(message: tooltipMessage, child: button);
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
        constraints: BoxConstraints.tightFor(
          width: BarThemeConfig.instance.height + 8,
        ),
        context: context,
        items: [
          for (FormatusActionButton button in buttons)
            PopupMenuItem(
              height: BarThemeConfig.instance.height,
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
