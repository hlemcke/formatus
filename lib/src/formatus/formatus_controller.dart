import 'package:flutter/material.dart';

import 'formatus_document.dart';
import 'formatus_model.dart';

///
/// [FormatusController] displays the tree-like structure of a
/// [FormatusDocument] into [TextSpan]s to be displayed in a [TextFormField].
///
class FormatusController extends TextEditingController {
  /// Tree-like structure with nodes for formatting and text leaf nodes
  late FormatusDocument document;

  /// Formats set by cursor positioning and modifiable by user selection.
  Set<Formatus> selectedFormats = {};

  /// Selection before any change
  final TextSelection _previousSelection =
      const TextSelection(baseOffset: 0, extentOffset: 0);

  FormatusController._();

  // TODO implement factory FormatusController.fromMarkdown

  ///
  /// Creates a controller for [TextField] or [TextFormField].
  ///
  factory FormatusController.fromHtml({
    required String initialHtml,
    VoidCallback? onListen,
  }) {
    FormatusController ctrl = FormatusController._();
    ctrl.document = FormatusDocument.fromHtml(htmlBody: initialHtml);
    debugPrint(ctrl.document.toHtml());
    ctrl.text = ctrl.document.toPlainText();
    ctrl.addListener(ctrl._onListen);
    return ctrl;
  }

  /// Returns element at cursor position or creates a new one
  FormatusAnchor get anchorAtCursor {
    FormatusAnchor anchor = FormatusAnchor();
    return anchor;
  }

  ///
  /// Formatting of text. Invoked on every change of text content
  ///
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    List<TextSpan> spans = [];
    for (FormatusNode topLevelNode in document.root.children) {
      spans.add(topLevelNode.toTextSpan());
      spans.add(const TextSpan(text: '\n'));
    }
    return TextSpan(children: spans);
  }

  Set<Formatus> get formatsAtCursor {
    int nodeIndex = document.computeNodeIndex(selection.baseOffset);
    return document.textNodes[nodeIndex].formatsInPath;
  }

  /// Returns current text as a html formatted string
  String toHtml() => document.toHtml();

  ///
  /// This closure will be called by the underlying system whenever the
  /// content of the text field changes.
  ///
  void _onListen() {
    if (document.update(text).hasDelta) {
      return;
    }
    //--- Selection has changed
    debugPrint('=== range: ${selection.baseOffset} ${selection.extentOffset}');
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
  FormatusNode startingNode = FormatusNode();
  FormatusNode endingNode = FormatusNode();
}

///
/// Difference of formats at cursor position and selected formats (added and removed)
///
class DeltaFormat {
  Set<Formatus> added = {};
  Set<Formatus> removed = {};
  Set<Formatus> same = {};

  /// Constructor builds both sets
  DeltaFormat({
    required FormatusNode textNode,
    required Set<Formatus> selectedFormats,
  }) {
    Set<Formatus> formatsInPath = textNode.formatsInPath;
    for (Formatus formatus in selectedFormats) {
      if (formatsInPath.contains(formatus)) {
        formatsInPath.remove(formatus);
        same.add(formatus);
      } else {
        added.add(formatus);
      }
    }
    removed.addAll(formatsInPath);
  }

  bool get isEmpty => added.isEmpty && removed.isEmpty;

  @override
  String toString() => '+: $added, =:$same, -:$removed';
}
