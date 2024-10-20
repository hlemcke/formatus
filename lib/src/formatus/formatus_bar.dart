import 'package:flutter/material.dart';

import 'formatus_anchor.dart';
import 'formatus_controller.dart';
import 'formatus_document.dart';
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

///
/// Actions to format text.
///
/// The allowed actions can be supplied. They default to all actions.
///
/// `condense: true` will condense top-level formats and alignments
/// into a dropdown selection.
///
class FormatusBar extends StatefulWidget {
  late final List<FormatusAction> actions;
  final bool condense;
  final Axis direction;
  final FormatusController formatusController;
  final FocusNode? textFieldFocus;

  ///
  /// Creates action bar to format text in a [TextField] or [TextFormField].
  /// The same [FormatusController] must be supplied to the [TextField]
  /// and to this `FormatusBar`.
  ///
  /// To automatically switch back the focus from this `FormatusBar` the
  /// same [FocusNode] must be supplied to both the [TextField]
  /// and to this `FormatusBar`.
  ///
  /// The bar itself is a [Wrap] of [_FormatusButton] widgets.
  ///
  FormatusBar({
    super.key,
    required this.formatusController,
    List<FormatusAction>? actions,
    this.condense = false,
    this.direction = Axis.horizontal,
    this.textFieldFocus,
  }) {
    this.actions = actions ?? _defaultActions;
  }

  @override
  State<StatefulWidget> createState() => _FormatusBarState();
}

class _FormatusBarState extends State<FormatusBar> {
  late final FormatusController _ctrl;
  final Set<Formatus> _activeFormats = {};

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
              isSelected: _activeFormats.contains(action.formatus),
              onPressed: () => _onToggleAction(action.formatus),
            ),
        ],
      );

  void _deactivateActions() => _activeFormats.clear();

  void _deactivateTopLevelActions() {
    for (FormatusAction action in widget.actions) {
      if (action.isTopLevel) {
        _activeFormats.remove(action);
      }
    }
  }

  ///
  /// Toggles format button
  ///
  /// Only one top-level format may be active at any time.
  ///
  void _onToggleAction(Formatus formatus) {
    if (formatus == Formatus.link) {
      showFormatusAnchorDialog(context, _ctrl);
      return;
    } else if (formatus.isTopLevel) {
      _deactivateTopLevelActions();
      _activeFormats.add(formatus);
    } else if (_activeFormats.contains(formatus)) {
      _activeFormats.remove(formatus);
    } else {
      _activeFormats.add(formatus);
    }
    setState(() => widget.textFieldFocus?.requestFocus());
  }

  void _updateActivatedActions() {
    FormatusNode textNode =
        _ctrl.document.textNodeByCharIndex(_ctrl.cursorPosition);
    List<FormatusNode> path = textNode.path;
    _deactivateActions();
    for (FormatusNode node in path) {
      _activeFormats.add(node.format);
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

final List<FormatusAction> _defaultActions = [
  FormatusAction(formatus: Formatus.header1),
  FormatusAction(formatus: Formatus.header2),
  FormatusAction(formatus: Formatus.header3),
  FormatusAction(formatus: Formatus.paragraph),
  FormatusAction(formatus: Formatus.italic),
  FormatusAction(formatus: Formatus.bold),
  FormatusAction(formatus: Formatus.underline),
  FormatusAction(formatus: Formatus.strikeThrough),
  FormatusAction(formatus: Formatus.link),
];

final ButtonStyle _formatusButtonStyle = ButtonStyle(
  iconSize: MaterialStateProperty.all(kMinInteractiveDimension * 0.7),
  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
  backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent),
));
