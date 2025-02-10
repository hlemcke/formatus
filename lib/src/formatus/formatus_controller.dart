import 'package:flutter/material.dart';

import 'formatus_document.dart';
import 'formatus_model.dart';
import 'formatus_node.dart';
import 'formatus_tree.dart';

///
/// [FormatusController] displays the tree-like structure of a
/// [FormatusDocument] into [TextSpan]s to be displayed in a [TextFormField].
///
class FormatusController extends TextEditingController {
  /// Tree-like structure with nodes for formatting and text leaf nodes
  late FormatusDocument document;

  /// Formats set by cursor positioning and modifiable by user selection.
  Set<Formatus> selectedFormats = {};

  ///
  /// Creates a controller for [TextField] or [TextFormField].
  ///
  FormatusController({
    String? formattedText,
  }) {
    document = FormatusDocument.fromHtml(htmlBody: formattedText ?? '');
    _text = document.toPlainText();
    if (text.isEmpty || text == ' ') {
      clear();
    }
    addListener(_onListen);
  }

  // TODO implement factory FormatusController.fromMarkdown

  set _text(String textForSuper) => super.text = textForSuper;

  /// Returns anchor element  at cursor position or `null` if there is none
  FormatusAnchor? get anchorAtCursor {
    int nodeIndex = document.computeTextNodeIndex(selection.baseOffset);
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
    int nodeIndex = document.computeTextNodeIndex(selection.baseOffset);
    FormatusNode node = document.textNodes[nodeIndex];

    //--- Anchor exists at cursor position
    if (node.parent!.format == Formatus.anchor) {
      //--- Update existing anchor
      if (anchor != null) {
        node.text = anchor.name;
        node.parent!.attributes[FormatusAttribute.href.name] = anchor.href;
      } else {
        //--- Delete existing anchor
        FormatusTree.dispose(document.textNodes, node);
      }
    } else {
      //--- Insert a new anchor element at cursor position
      if (anchor != null) {
        FormatusNode anchorTextNode = FormatusTree.createSubTree(
            document.textNodes, anchor.name, [Formatus.anchor]);
        anchorTextNode.parent!.attributes[FormatusAttribute.href.name] =
            anchor.href;
        // TODO split current textNode and insert anchorNode between
      } // else do nothing because there is no anchor and none is created
    }
  }

  ///
  /// Formatting of text. Invoked on every change of text
  ///
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      FormatusTree.buildFormattedText(document.root.children);

  /// Sets empty text with Paragraph and one empty _textNode_
  @override
  void clear() {
    document.clear();
    selectedFormats.clear();
    selectedFormats.add(Formatus.paragraph);
    _previousSelection = _emptySelection;
    super.clear();
  }

  /// Returns current text as a html formatted string
  String get formattedText => document.toHtml();

  /// Replaces current text with the parsed `html`
  set formattedText(String html) {
    if (html.isEmpty) {
      clear();
      return;
    }
    document = FormatusDocument.fromHtml(htmlBody: html);
    _text = document.toPlainText();
    value = TextEditingValue(text: text);
  }

  List<Formatus> get formatsAtCursor {
    if (!selection.isValid) return [];
    int nodeIndex = document.computeTextNodeIndex(selection.start);
    return document.textNodes[nodeIndex].formatsInPath;
  }

  @override
  set text(String _) {
    throw Exception(
        'Not supported. Use formattedText=... to replace current text');
  }

  /// Updates formats in selected text range.
  /// Immediately returns if no range is selected.
  void updateFormatsOfSelection(Formatus formatus, bool isSet) {
    if (selection.isCollapsed) return;
    DeltaFormat deltaFormat = isSet
        ? DeltaFormat.added(selectedFormats: selectedFormats, added: formatus)
        : DeltaFormat.removed(
            selectedFormats: selectedFormats, removed: formatus);
    document.updateFormatOfSelection(deltaFormat, selection);
  }

  /// Changes section-format at current cursor position
  void updateSectionFormat(Formatus formatus) {
    int textNodeIndex = document.computeTextNodeIndex(selection.baseOffset);
    FormatusNode textNode = document.textNodes[textNodeIndex];
    textNode.path.first.format = formatus;
    notifyListeners();
  }

  TextSelection _previousSelection = _emptySelection;
  static const TextSelection _emptySelection =
      TextSelection(baseOffset: 0, extentOffset: 0);

  ///
  /// This closure will be called by the underlying system whenever the
  /// content of the text field changes.
  ///
  void _onListen() {
    //--- Immediate handling of full deletion
    if (text.isEmpty) {
      clear();
      return;
    }

    //--- Immediate handling of unmodified text
    if (document.previousText == text) {
      _updateSelection();
      return;
    }

    //--- Determine deletion / insertion / modification
    DeltaText deltaText = DeltaText(
      prevSelection: _previousSelection,
      prevText: document.previousText,
      nextSelection: selection,
      nextText: text,
    );
    debugPrint('=== _onlisten [${selection.start}] => $deltaText');
    if (deltaText.hasDelta) {
      if (deltaText.isInsert) {
        DeltaFormat deltaFormat = DeltaFormat.fromDocument(
            document: document,
            caretIndex: selection.start,
            selectedFormats: selectedFormats);
        document.handleInsert(deltaText, deltaFormat);
      } else {
        document.handleDeleteAndUpdate(deltaText);
      }
    }
    _updateSelection();
  }

  void _updateSelection() {
    _previousSelection = TextSelection(
        baseOffset: selection.baseOffset, extentOffset: selection.extentOffset);
  }
}

///
/// Difference between formats selected in [FormatusBar] and `textFormats`.
///
class DeltaFormat {
  final List<Formatus> textFormats;
  final Set<Formatus> selectedFormats;

  List<Formatus> get added => _added;
  final List<Formatus> _added = [];

  List<Formatus> get removed => _removed;
  final List<Formatus> _removed = [];

  List<Formatus> get same => _same;
  final List<Formatus> _same = [];

  bool get hasDelta => added.isNotEmpty || removed.isNotEmpty;

  ///
  /// Constructor takes formats.
  ///
  DeltaFormat({
    required this.textFormats,
    required this.selectedFormats,
  }) {
    for (Formatus formatus in textFormats) {
      if (selectedFormats.contains(formatus)) {
        _same.add(formatus);
      } else {
        _removed.add(formatus);
      }
    }
    for (Formatus formatus in selectedFormats) {
      if (!textFormats.contains(formatus)) {
        _added.add(formatus);
      }
    }
  }

  ///
  /// Computes formats from `cursorPosition` in `document`.
  ///
  /// If `cursorPosition` points to start of a text-node then `headFormats`
  /// will become the formats of the previous text-node.
  ///
  factory DeltaFormat.fromDocument({
    required FormatusDocument document,
    required int caretIndex,
    required Set<Formatus> selectedFormats,
  }) {
    int textNodeIndex = document.computeTextNodeIndex(caretIndex);
    FormatusNode textNode = document.textNodes[textNodeIndex];
    return DeltaFormat(
        textFormats: textNode.formatsInPath, selectedFormats: selectedFormats);
  }

  factory DeltaFormat.added({
    required Set<Formatus> selectedFormats,
    required Formatus added,
  }) =>
      DeltaFormat(
          textFormats: (selectedFormats..remove(added)).toList(),
          selectedFormats: selectedFormats..add(added));

  factory DeltaFormat.removed({
    required Set<Formatus> selectedFormats,
    required Formatus removed,
  }) =>
      DeltaFormat(
          textFormats: selectedFormats.toList(),
          selectedFormats: selectedFormats..remove(removed));

  @override
  String toString() => '-:$removed, =:$same, +:$added';
}

///
/// Delta between two texts.
///
class DeltaText {
  /// Text which is added
  String get added => _added;
  String _added = '';

  /// Leading characters which are identical in both texts
  String get headText => _headText;
  String _headText = '';

  /// Trailing characters which are identical in both texts
  String get tailText => _tailText;
  String _tailText = '';

  DeltaText({
    required String prevText,
    required TextSelection prevSelection,
    required String nextText,
    required TextSelection nextSelection,
  }) {
    //--- Text is unchanged
    if (prevText == nextText) {
      _hasDelta = false;
      return;
    }

    //--- Compute delta
    String prevHead = prevSelection.textBefore(prevText);
    String nextTail = nextSelection.textAfter(nextText);

    //--- Text is modified
    _headText = _computeHead(prevHead, nextText);
    _tailText = _computeTail(prevText, nextTail);
    _added =
        nextText.substring(_headText.length, nextText.length - tailText.length);
    _isInsert = (_headText + _tailText == prevText) && _added.isNotEmpty;
  }

  /// Returns `true` if previous text is not equal to next text
  bool get hasDelta => _hasDelta;
  bool _hasDelta = true;

  /// Returns `true` if change has occurred at start of previous text
  bool get isAtEnd => _hasDelta && tailText.isEmpty;

  /// Returns `true` if change has occurred at end of previous text
  bool get isAtStart => _hasDelta && headText.isEmpty;

  /// Returns `true` if characters were deleted
  bool get isDelete => hasDelta && _added.isEmpty;

  /// Returns `true` if character were added
  bool get isInsert => _isInsert;
  bool _isInsert = false;

  /// Returns `true` if characters were modified.
  /// The modified characters can be longer, shorter or have same length as
  /// the previous characters.
  bool get isUpdate => hasDelta && _added.isNotEmpty && !_isInsert;

  /// Identical heading text is computed from left to right
  String _computeHead(String prev, String next) {
    int i = 0;
    while (i < prev.length && i < next.length && prev[i] == next[i]) {
      i++;
    }
    return (i > 0) ? prev.substring(0, i) : '';
  }

  /// Identical trailing text is computed from right to left
  String _computeTail(String prev, String next) {
    int i = prev.length;
    int j = next.length;
    while ((i > 0) && j > 0 && (prev[i - 1] == next[j - 1])) {
      i--;
      j--;
    }
    return prev.substring((i < 0) ? 0 : i);
  }

  @override
  String toString() {
    if (hasDelta == false) return '<no delta>';
    return '${isDelete ? "DELETE" : isInsert ? "INSERT" : "UPDATE"}'
        ' ${isAtStart ? "START " : isAtEnd ? "END   " : "MIDDLE"}'
        ' added="$added"\nhead="$headText"\ntail="$tailText"';
  }
}
