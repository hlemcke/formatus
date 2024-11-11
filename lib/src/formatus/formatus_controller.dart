import 'package:flutter/material.dart';

import 'formatus_document.dart';
import 'formatus_model.dart';
import 'formatus_node.dart';

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
            FormatusDocument.createSubTree(anchor.name, [Formatus.anchor]);
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
  }

  List<Formatus> get formatsAtCursor {
    if (!selection.isValid) return [];
    int nodeIndex = document.computeNodeIndex(selection.start);
    return document.textNodes[nodeIndex].formatsInPath;
  }

  @override
  set text(String _) {
    throw Exception(
        'Not supported. Use formattedText=... to replace current text');
  }

  /// Updates formats in selected text range.
  /// Immediately returns if no range is selected.
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
      document.setupEmpty();
      _previousSelection = _emptySelection;
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
    debugPrint('=== _onlisten => $deltaText');
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
    debugPrint(
        '=== $deltaText range: ${selection.baseOffset} ${selection.extentOffset}');
  }

  void _updateSelection() {
    debugPrint(
        '-> updateSelection(${selection.baseOffset}..${selection.extentOffset})');
    _previousSelection = TextSelection(
        baseOffset: selection.baseOffset, extentOffset: selection.extentOffset);
  }
}

///
/// Difference of formats at cursor position and formats selected in
/// [FormatusBar].
///
class DeltaFormat {
  final List<Formatus> textFormats;
  final Set<Formatus> selectedFormats;

  Set<Formatus> get added => _added;
  Set<Formatus> _added = {};

  List<Formatus> get same => _same;
  List<Formatus> _same = [];

  Set<Formatus> get removed => _removed;
  Set<Formatus> _removed = {};

  bool get hasDelta => added.isNotEmpty || removed.isNotEmpty;

  ///
  /// Constructor takes formats.
  ///
  DeltaFormat({
    required this.textFormats,
    required this.selectedFormats,
  }) {
    _added = selectedFormats.difference(textFormats.toSet());
    _removed = textFormats.toSet().difference(selectedFormats);
    for (Formatus formatus in textFormats) {
      if (selectedFormats.contains(formatus)) {
        _same.add(formatus);
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
    int textNodeIndex = document.computeNodeIndex(caretIndex);
    FormatusNode textNode = document.textNodes[textNodeIndex];
    return DeltaFormat(
        textFormats: textNode.formatsInPath, selectedFormats: selectedFormats);
  }

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
    // debugPrint('### prev ### ${prevSelection.start}..${prevSelection.end}'
    //     ' len=${prevText.length} head="$prevHead" tail="%"\n'
    //     '### next ### ${nextSelection.start}..${nextSelection.end}'
    //     ' len=${nextText.length} head="%" tail="$nextTail" added="$added"');
    // debugPrint(toString());
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
