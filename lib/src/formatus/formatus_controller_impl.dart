import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

import 'formatus_document.dart';
import 'formatus_node.dart';
import 'formatus_tree.dart';

///
/// [FormatusController] displays the tree-like structure of a
/// [FormatusDocument] into [TextSpan] to be displayed in a [TextFormField].
///
/// The controller has three triggers:
///
/// 1. [_onListen] will be invoked by [TextEditingController]
///    on any change of text string, cursor position or range selection
/// 2. [updateInlineFormat] will be invoked by [FormatusBar]
///    on any change of an inline format
/// 3. [updateSectionFormat] will be invoked by [FormatusBar]
///    on any change of a section format
///
class FormatusControllerImpl extends TextEditingController
    implements FormatusController {
  /// Tree-like structure with nodes for formatting and text leaf nodes
  late FormatusDocument document;

  /// Formats set by cursor positioning and modifiable by user selection.
  Set<Formatus> selectedFormats = {};

  /// Called when the formatted text changes
  /// either by modifying the text string or its format.
  final ValueChanged<String>? onChanged;

  ///
  /// Creates a controller for [TextField] or [TextFormField].
  ///
  FormatusControllerImpl({
    String? formattedText,
    this.onChanged,
  }) {
    document = FormatusDocument(body: formattedText ?? '');
    _rememberNodeResults();
    _text = document.nodeResults.plainText;
    addListener(_onListen);
  }

  // TODO implement factory FormatusController.fromMarkdown

  /// Returns anchor element  at cursor position or `null` if there is none
  FormatusAnchor? get anchorAtCursor {
    int nodeIndex = computeTextNodeIndex(selection.baseOffset);
    FormatusNode node = document.textNodes[nodeIndex];
    if (node.parent!.format == Formatus.anchor) {
      FormatusAnchor anchor = FormatusAnchor(
          href: node.parent!.attributes[0] ?? '', name: node.text);
      return anchor;
    }
    return null;
  }

  /// Inserts or updates anchor at cursor position. Deletes is if `null`
  set anchorAtCursor(FormatusAnchor? anchor) {
    int nodeIndex = computeTextNodeIndex(selection.baseOffset);
    FormatusNode node = document.textNodes[nodeIndex];

    //--- Anchor exists at cursor position
    if (node.parent!.format == Formatus.anchor) {
      //--- Update existing anchor
      if (anchor != null) {
        node.text = anchor.name;
        node.parent!.attributes[0] = anchor.href;
      } else {
        //--- Delete existing anchor
        FormatusTree.dispose(document.textNodes, node);
      }
    } else {
      //--- Insert a new anchor element at cursor position
      if (anchor != null) {
        FormatusNode anchorTextNode = FormatusTree.createSubTree(
            document.textNodes, anchor.name, [Formatus.anchor]);
        anchorTextNode.parent!.attributes[0] = anchor.href;
        // TODO split current textNode and insert anchorNode between
      } // else do nothing because there is no anchor and none is created
    }
  }

  ///
  /// Formatting of text. Invoked by Flutter during build process
  ///
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) =>
      document.nodeResults.textSpan;

  /// Sets empty text with Paragraph and one empty _textNode_
  @override
  void clear() {
    super.clear();
    document.clear();
    selectedFormats.clear();
    selectedFormats.add(Formatus.paragraph);
    _prevSelection = _emptySelection;
    document.computeNodeResults();
    _rememberNodeResults();
  }

  /// Computes index to text node
  int computeTextNodeIndex(int charIndex) =>
      document.computeNodeIndex(charIndex);

  /// Returns formatted text
  @override
  String get formattedText => document.nodeResults.formattedText;

  /// Replaces current text with `formatted`
  @override
  set formattedText(String formatted) {
    if (formatted.isEmpty) {
      clear();
      return;
    }
    document = FormatusDocument(body: formatted);
    _rememberNodeResults();
    _text = document.nodeResults.plainText;
    value = TextEditingValue(text: text);
  }

  List<Formatus> get formatsAtCursor {
    if (!selection.isValid) return [];
    int nodeIndex = computeTextNodeIndex(selection.start);
    return document.textNodes[nodeIndex].formatsInPath;
  }

  @override
  set text(String _) {
    throw Exception(
        'Not supported. Use formattedText=... to replace current text');
  }

  /// Internally used to update string in `TextField` or `TextFormField`
  set _text(String textForSuper) => super.text = textForSuper;

  /// Updates formats in selected text range.
  /// Immediately returns if no text is selected.
  void updateInlineFormat(Formatus formatus, bool isSet) {
    if (selection.isCollapsed) return;
    DeltaFormat deltaFormat = isSet
        ? DeltaFormat.added(selectedFormats: selectedFormats, added: formatus)
        : DeltaFormat.removed(
            selectedFormats: selectedFormats, removed: formatus);
    document.updateFormatOfSelection(deltaFormat, selection);
    _rememberNodeResults();
  }

  /// Changes section-format at current cursor position
  void updateSectionFormat(Formatus formatus) {
    int textNodeIndex = computeTextNodeIndex(selection.baseOffset);
    FormatusNode textNode = document.textNodes[textNodeIndex];
    textNode.path.first.format = formatus;
    document.computeNodeResults();
    _rememberNodeResults();
  }

  /// Used to determine if to fire `onChanged`
  FormatusNodeResults _prevNodeResults = FormatusNodeResults();

  @visibleForTesting
  FormatusNodeResults get prevNodeResults => _prevNodeResults;

  /// Used to determine range difference
  TextSelection _prevSelection = _emptySelection;

  @visibleForTesting
  TextSelection get prevSelection => _prevSelection;

  static const TextSelection _emptySelection =
      TextSelection(baseOffset: 0, extentOffset: 0);

  ///
  /// This closure will be called by the underlying system whenever the
  /// content of the text field changes.
  ///
  void _onListen() {
    //--- Determine deletion / insertion / replacement
    DeltaText deltaText = DeltaText(
      prevSelection: _prevSelection,
      prevText: _prevNodeResults.plainText,
      nextSelection: selection,
      nextText: text,
    );
    debugPrint(
        '=== _onlisten [${selection.start},${selection.end}] => $deltaText');

    //--- Immediate handling of full deletion
    if (text.isEmpty) {
      clear();
      return;
    }

    //--- Immediate handling of unmodified text but possible range change
    if (_prevNodeResults.plainText == text) {
      _updateSelection();
      return;
    }

    if (deltaText.type == DeltaTextType.insert) {
      int nodeIndex = document.computeNodeIndex(selection.start);
      DeltaFormat deltaFormat = DeltaFormat(
          textFormats: document.textNodes[nodeIndex].formatsInPath,
          selectedFormats: selectedFormats);
      document.handleInsert(deltaText, deltaFormat);
    } else {
      document.handleDeleteAndUpdate(deltaText);
    }
    _rememberNodeResults();
  }

  @visibleForTesting
  void onListen() {
    _onListen();
  }

  /// Computes [FormatusNodeResults] and fires [onChanged]
  /// if `formattedText` has changed.
  void _rememberNodeResults() {
    if ((_prevNodeResults.formattedText !=
            document.nodeResults.formattedText) &&
        (onChanged != null)) {
      onChanged!(document.nodeResults.formattedText);
    }
    _prevNodeResults = document.nodeResults;
    _updateSelection();
  }

  void _updateSelection() {
    _prevSelection = TextSelection(
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
/// Delta between two texts provides position and type of change.
///
class DeltaText {
  /// Position of modification
  DeltaTextPosition position = DeltaTextPosition.unknown;

  /// Type of modification
  DeltaTextType type = DeltaTextType.none;

  /// Leading characters which are identical in both texts
  String get headText => _headText;
  String _headText = '';

  final TextSelection nextSelection;
  final String nextText;

  /// Text which is added
  String get plusText => _plusText;
  String _plusText = '';

  final TextSelection prevSelection;
  final String prevText;

  /// Trailing characters which are identical in both texts
  String get tailText => _tailText;
  String _tailText = '';

  ///
  /// Computes unmodifiable delta text
  ///
  DeltaText({
    required this.prevText,
    required this.prevSelection,
    required this.nextText,
    required this.nextSelection,
  }) {
    //--- Text is unchanged
    if (prevText == nextText) {
      type = DeltaTextType.none;
      return;
    }

    //--- All text deleted
    if (nextText.isEmpty) {
      position = DeltaTextPosition.all;
      type = DeltaTextType.delete;
      return;
    }

    //--- All text selected
    if ((prevSelection.start == 0) && (prevSelection.end >= prevText.length)) {
      position = DeltaTextPosition.all;
      type = prevText.isNotEmpty ? DeltaTextType.update : DeltaTextType.insert;
      _plusText = nextText;
      return;
    }

    //--- Compute text parts
    String prevHead = prevSelection.textBefore(prevText);
    String nextTail = nextSelection.textAfter(nextText);
    _headText = _computeHead(prevHead, nextText);
    _tailText = _computeTail(prevText, nextTail);
    _plusText =
        nextText.substring(_headText.length, nextText.length - tailText.length);

    //--- determine position of change
    if ((prevSelection.start == 0) || (nextSelection.start == 0)) {
      position = DeltaTextPosition.start;
    } else if ((prevSelection.end >= prevText.length) ||
        (nextSelection.end >= nextText.length)) {
      position = DeltaTextPosition.end;
    } else {
      position = DeltaTextPosition.middle;
    }

    //--- determine type of change
    type = plusText.isEmpty
        ? DeltaTextType.delete
        : (headText + tailText == prevText)
            ? DeltaTextType.insert
            : DeltaTextType.update;
  }

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
  String toString() => '${type.name} at ${position.name} =>'
      ' plus="$plusText", head="$headText", tail="$tailText"';
}

enum DeltaTextPosition { all, end, middle, start, unknown }

enum DeltaTextType { delete, insert, none, update }
