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
  factory FormatusController.fromFormattedText({
    required String formattedText,
    VoidCallback? onListen,
  }) {
    FormatusController ctrl = FormatusController._();
    ctrl.document = FormatusDocument.fromHtml(htmlBody: formattedText);
    ctrl._text = ctrl.document.toPlainText();
    ctrl.addListener(ctrl._onListen);
    debugPrint(ctrl.document.toHtml());
    return ctrl;
  }

  set _text(String textForSuper) => super.text = textForSuper;

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
        FormatusNode anchorTextNode =
            document.createSubtree(anchor.name, {Formatus.anchor});
        anchorTextNode.parent!.attributes[FormatusAttribute.href.name] =
            anchor.href;
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

  /// Returns current text as a html formatted string
  String get formattedText => document.toHtml();

  /// Replaces current text with the parsed `html`
  set formattedText(String html) {
    document = FormatusDocument.fromHtml(htmlBody: html);
    _text = document.toPlainText();
    value = TextEditingValue(text: text);
    debugPrint('===set=== $html\n===$text\n===$formattedText');
  }

  Set<Formatus> get formatsAtCursor {
    if (!selection.isValid) return {};
    int nodeIndex = document.computeNodeIndex(selection.start);
    return document.textNodes[nodeIndex].formatsInPath;
  }

  @override
  set text(String _) {
    throw Exception(
        'Not supported. Use formattedText=... to replace current text');
  }

  /// Updates formats in selected text range. Immediately returns
  /// if no range is selected.
  void updateRangeFormats(Formatus formatus, bool isSet) {
    if (selection.isCollapsed) return;
    debugPrint('${isSet ? "set" : "clear"} ${formatus.name}'
        ' in [${selection.baseOffset}..${selection.extentOffset}]');
  }

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
    //--- Immediate handling of full deletion
    if (text.isEmpty) {
      document.setupEmpty();
    } else {
      DeltaFormat deltaFormat = DeltaFormat(
          formatsAtCursor: formatsAtCursor, selectedFormats: selectedFormats);
      DeltaText deltaText = document.update(text, deltaFormat);
      debugPrint(
          '=== ${deltaText.hasDelta ? 'document updated' : 'range: ${selection.baseOffset} ${selection.extentOffset}'}');
    }
  }
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

  bool get isNotEmpty => added.isNotEmpty || removed.isNotEmpty;

  @override
  String toString() => '+:$added, =:$same, -:$removed';
}
