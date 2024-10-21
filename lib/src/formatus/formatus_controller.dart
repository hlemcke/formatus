import 'package:flutter/material.dart';

import 'formatus_document.dart';
import 'formatus_model.dart';

///
/// [FormatusController] displays the tree-like structure of a
/// [FormatusDocument] into [TextSpan]s to be displayed in a [TextFormField].
///
class FormatusController extends TextEditingController {
  /// Current index of cursor into content
  int get cursorPosition => _cursorPosition;
  int _cursorPosition = 0;

  /// Current text node
  FormatusNode? get currentTextNode => _currentTextNode;
  FormatusNode? _currentTextNode;

  /// Tree-like structure with nodes for formatting and text leaf nodes
  late FormatusDocument document;

  List<Formatus> activeFormats = [];

  /// Called on text changes
  final VoidCallback? onListen;

  String _previousText = '';

  FormatusController._({
    this.onListen,
  });

  // TODO implement factory FormatusController.fromMarkdown

  ///
  /// Creates a controller for [TextField] or [TextFormField].
  ///
  factory FormatusController.fromHtml({
    required String initialHtml,
    VoidCallback? onListen,
  }) {
    FormatusController ctrl = FormatusController._(
      onListen: onListen,
    );
    ctrl.document = FormatusDocument.fromHtml(htmlBody: initialHtml);
    debugPrint(ctrl.document.toHtml());
    ctrl.text = ctrl.document.toPlainText();
    ctrl._previousText = ctrl.text;
    ctrl.addListener(ctrl._onListen);
    return ctrl;
  }

  ///
  /// Formatting of text. Invoked on every change of text content
  ///
  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
      TextStyle? style,
      required bool withComposing}) {
    List<TextSpan> spans = [];
    for (FormatusNode topLevelNode in document.root.children) {
      spans.add(topLevelNode.toTextSpan());
      spans.add(const TextSpan(text: '\n'));
    }
    return TextSpan(children: spans);
  }

  /// Returns current text as a html formatted string
  String toHtml() => document.toHtml();

  /// Internal workhorse
  void _onListen() {
    _cursorPosition = selection.baseOffset;
    FormatusNode node = document.textNodeByCharIndex(_cursorPosition);
    _currentTextNode = node;
    debugPrint('=== $_cursorPosition-${selection.end} node=$_currentTextNode');

    //--- initial computations
    int prevLength = _previousText.length;
    int nextLength = text.length;

    if (prevLength != nextLength) {
      int trailingCount = _previousText.length - node.offset - node.text.length;
      String middle = (trailingCount > 0)
          ? text.substring(node.offset, text.length - trailingCount)
          : text.substring(node.offset);

      //--- Handle deletion
      if (prevLength > nextLength) {
        //--- Remove tag
        if (middle.isEmpty) {
          _currentTextNode!.cleanup();
          _currentTextNode = null;
        } else {
          node.text = middle;
        }
      }

      //--- Handle insertion
      else if (prevLength < nextLength) {
// TODO consider current format settings
        node.text = middle;
      }
      _previousText = text;
    }
    //--- length unchanged -> check range selection
    else {
      debugPrint(
          '=== length equal -> range ${selection.start} - ${selection.end}');
      //--- Format changed?
    }

    //--- Invoke callback if set
    if (onListen != null) {
      onListen!();
    }
  }
}

///
/// Managed by [FormatusController] and used by [FormatusBar]
///
class FormatusContext {
  int cursorPosition = -1;
  int rangeStart = -1;
  int rangeEnd = -1;

  bool get isRange => rangeStart >= 0;
  FormatusNode startingNode = FormatusNode.placeHolder;
  FormatusNode endingNode = FormatusNode.placeHolder;
}
