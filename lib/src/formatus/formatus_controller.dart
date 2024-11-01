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

  /// Returns anchor element  at cursor position or `null` if there is none
  FormatusAnchor? get anchorAtCursor {
    int nodeIndex = document.computeNodeIndex(selection.baseOffset);
    FormatusNode node = document.textNodes[nodeIndex];
    if (node.parent!.format == Formatus.anchor) {
      FormatusAnchor anchor = FormatusAnchor(
          href: node.parent!.attributes[FormatusAttribute.href.name] ?? '',
          name: node.text);
      return anchor;
    }
    return null;
  }

  /// Inserts or updates anchor at cursor position. Deletes is if `null`
  set anchorAtCursor(FormatusAnchor? anchor) {
    int nodeIndex = document.computeNodeIndex(selection.baseOffset);
    FormatusNode node = document.textNodes[nodeIndex];

    //--- Anchor exists at cursor position
    if (node.parent!.format == Formatus.anchor) {
      //--- Update existing anchor
      if (anchor != null) {
        node.text = anchor.name;
        node.parent!.attributes[FormatusAttribute.href.name] = anchor.href;
      } else {
        //--- Delete existing anchor
        node.dispose();
      }
    } else {
      //--- Insert a new anchor element at cursor position
      if (anchor != null) {
        FormatusNode anchorNode = anchor.buildNodes();
        // TODO split current textNode and insert anchorNode between
      } // else do nothing because there is no anchor and none is created
    }
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

  /// Changes top-level format at current cursor position
  void updateTopLevelFormat(Formatus formatus) {
    int textNodeIndex = document.computeNodeIndex(selection.baseOffset);
    FormatusNode textNode = document.textNodes[textNodeIndex];
    textNode.path.first.format = formatus;
    notifyListeners();
  }

  ///
  /// This closure will be called by the underlying system whenever the
  /// content of the text field changes.
  ///
  void _onListen() {
    DeltaFormat deltaFormat = DeltaFormat(
        formatsAtCursor: formatsAtCursor, selectedFormats: formatsAtCursor);
    bool hasDelta = document.update(text, deltaFormat).hasDelta;
    debugPrint(
        '=== ${hasDelta ? 'document updated' : 'range: ${selection.baseOffset} ${selection.extentOffset}'}');
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
    required Set<Formatus> formatsAtCursor,
    required Set<Formatus> selectedFormats,
  }) {
    for (Formatus formatus in selectedFormats) {
      if (formatsAtCursor.contains(formatus)) {
        formatsAtCursor.remove(formatus);
        same.add(formatus);
      } else {
        added.add(formatus);
      }
    }
    removed.addAll(formatsAtCursor);
  }

  bool get isEmpty => added.isEmpty && removed.isEmpty;

  @override
  String toString() => '+: $added, =:$same, -:$removed';
}
