import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

import 'formatus_document.dart';
import 'formatus_node.dart';
import 'formatus_results.dart';

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

  /// Map of images. Key is [FormatusImage.src]
  Map<String, FormatusImage> _imageMap = {};

  /// Color of current node. _transparent_ is not used
  Color selectedColor = Colors.transparent;

  /// Formats set by cursor positioning and modified by user selection.
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
    List<FormatusImage> images = const [],
  }) {
    images.map((i) => _imageMap[i.src] = i);
    document = FormatusDocument(formatted: formattedText ?? '');
    _rememberNodeResults();
    addListener(_onListen);
  }

  // TODO implement factory FormatusController.fromMarkdown

  /// Returns anchor element at cursor position or `null` if there is none
  FormatusAnchor? get anchorAtCursor {
    NodeMeta meta = document.computeMeta(selection.baseOffset);
    return meta.node.isAnchor
        ? FormatusAnchor(href: meta.node.attribute, name: meta.node.text)
        : null;
  }

  /// Inserts or updates anchor at cursor position. Deletes it if empty
  set anchorAtCursor(FormatusAnchor? anchor) {
    NodeMeta meta = document.computeMeta(selection.baseOffset);
    FormatusNode node = meta.node;

    //--- Anchor exists at cursor position
    if (node.isAnchor) {
      if (anchor == null) {
        document.textNodes.removeAt(meta.nodeIndex);
      } else {
        node.text = anchor.name;
        node.attribute = anchor.href;
      }
    } else if (anchor == null) {
      return;
    }
    //--- Anchor to be inserted at cursor position
    else {
      FormatusNode anchorNode = FormatusNode(
        formats: [node.section, Formatus.anchor],
        text: anchor.name,
      );
      anchorNode.attribute = anchor.href;
      document.insertNewNode(meta, anchorNode);
    }
    document.computeResults();
    _rememberNodeResults();
  }

  /// Returns image element at cursor position or `null` if there is none
  FormatusImage? get imageAtCursor {
    NodeMeta meta = document.computeMeta(selection.baseOffset);
    return meta.node.isImage
        ? FormatusImage(src: meta.node.attribute, alt: meta.node.text)
        : null;
  }

  set imageAtCursor(FormatusImage? image) {
    if (image == null) return;
  }

  ///
  /// Formatting of text. Invoked by Flutter during build process
  ///
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => document.results.textSpan;

  /// Sets empty text with Paragraph and one empty _textNode_
  @override
  void clear() {
    super.clear();
    document.clear();
    selectedColor = Colors.transparent;
    selectedFormats.clear();
    selectedFormats.add(Formatus.paragraph);
    _prevSelection = _emptySelection;
    document.computeResults();
    _rememberNodeResults();
  }

  /// Computes index to text node
  // int computeTextNodeIndex(int charIndex) => document.computeMeta(charIndex);

  /// Returns formatted text
  @override
  String get formattedText => document.results.formattedText;

  /// Replaces current text with `formatted`
  @override
  set formattedText(String formatted) {
    if (formatted.isEmpty) {
      clear();
      return;
    }
    document = FormatusDocument(formatted: formatted);
    _rememberNodeResults();
  }

  List<Formatus> get formatsAtCursor {
    if (!selection.isValid) return [];
    NodeMeta meta = document.computeMeta(selection.start);
    return meta.node.formats;
  }

  @override
  set text(String _) {
    throw Exception(
      'Not supported. Use formattedText=... to replace current text',
    );
  }

  /// Internally used to update string in `TextField` or `TextFormField`
  set _text(String textForSuper) => super.text = textForSuper;

  /// Updates formats in selected text range.
  /// [FormatusBar] has already updated `selectedFormats` and `selectedColor`
  void updateInlineFormat(Formatus formatus) {
    if (selection.isCollapsed) return;
    document.updateInlineFormat(
      selection,
      selectedFormats,
      color: selectedColor,
    );
    _rememberNodeResults();
  }

  /// Changes section-format at current cursor position
  void updateSectionFormat(Formatus formatus) {
    document.updateSectionFormat(selection.start, formatus);
    _rememberNodeResults();
  }

  /// Used to determine if to fire `onChanged`
  FormatusResults _prevNodeResults = FormatusResults(
    textNodes: [FormatusNode.placeHolder],
  );

  @visibleForTesting
  FormatusResults get prevNodeResults => _prevNodeResults;

  /// Can be modified before set in [TextEditingController]
  TextSelection _nextSelection = _emptySelection;

  /// Used to determine range difference
  TextSelection _prevSelection = _emptySelection;

  @visibleForTesting
  TextSelection get prevSelection => _prevSelection;

  static const TextSelection _emptySelection = TextSelection(
    baseOffset: 0,
    extentOffset: 0,
  );

  @visibleForTesting
  void onListen() => _onListen();

  ///
  /// This closure will be called by the underlying system whenever the
  /// content of the text field changes or cursor is repositioned.
  ///
  void _onListen() {
    //--- Immediate handling of full deletion
    if (text.isEmpty) {
      clear();
      return;
    }

    //--- cannot update selection! (would refire _onListen)
    _nextSelection = selection;

    //--- Immediate handling of unmodified text but possible range change
    if (_prevNodeResults.plainText == text) {
      if (_areSelectionsDifferent(_prevSelection, _nextSelection)) {
        _updateSelection();
      }
      return;
    }

    //--- Determine delete / insert / update
    DeltaText deltaText = DeltaText(
      prevSelection: _prevSelection,
      prevText: _prevNodeResults.plainText,
      nextSelection: selection,
      nextText: text,
    );
    debugPrint('=== _onListen => $deltaText');

    //--- Replace all line-break in pasted text by single space
    // TODO transform pasted line-breaks to separate sections
    if (deltaText._textAdded.length > 1) {
      deltaText._textAdded = deltaText._textAdded.replaceAll('\n', ' ');
    }
    document.updateText(deltaText, selectedFormats, color: selectedColor);
    int cursorPosition = selection.baseOffset;
    _rememberNodeResults();
  }

  bool _areSelectionsDifferent(TextSelection a, TextSelection b) =>
      a.baseOffset != b.baseOffset || a.extentOffset != b.extentOffset;

  /// Remembers [FormatusResults].
  /// Fires [onChanged] if `formattedText` has changed.
  void _rememberNodeResults() {
    if ((_prevNodeResults.formattedText != document.results.formattedText) &&
        (onChanged != null)) {
      onChanged!(document.results.formattedText);
    }
    _prevNodeResults = document.results;
    _updateSelection();
  }

  /// Remembers _selection_ from [_nextSelection].
  /// Repositions cursor if in front of a list-item.
  /// Last step is updating [value] of [TextEditingController]
  void _updateSelection() {
    NodeMeta meta = document.computeMeta(_nextSelection.baseOffset);
    selectedColor = meta.node.color;

    //--- Cursor positioned in front of list-item
    if (meta.node.isList && (_nextSelection.baseOffset < meta.textBegin)) {
      int delta = (_nextSelection.baseOffset < 0)
          ? 2
          : (_prevSelection.baseOffset > _nextSelection.baseOffset)
          ? -1
          : 1;
      int offset = _nextSelection.baseOffset + delta;
      _nextSelection = TextSelection(baseOffset: offset, extentOffset: offset);
    }
    _prevSelection = _nextSelection;
    debugPrint(
      '_rememberSelection: [${_prevSelection.baseOffset}, ${_prevSelection.extentOffset}]',
    );
    value = TextEditingValue(
      text: _prevNodeResults.plainText,
      selection: _prevSelection,
    );
  }
}

///
/// Delta between previous and current text
///
class DeltaText {
  /// Returns `true` if all text is selected
  bool get isAll => _isAll;
  bool _isAll = false;

  bool get isAtEnd => _tailLength == 0;

  bool get isAtStart => _headLength == 0;

  bool get isInsert => type == DeltaTextType.insert;

  bool get isModified => type == DeltaTextType.none;

  /// Length of leading text in front of modification
  int get headLength => _headLength;
  int _headLength = -1;

  /// Current selection
  final TextSelection nextSelection;

  /// Length of previous text
  int get prevLength => _prevLength;
  int _prevLength = -1;

  /// Previous selection before change
  final TextSelection prevSelection;

  /// Length of trailing text behind modification
  int get tailLength => _tailLength;
  int _tailLength = -1;

  /// Offset into previous text to start of tail
  int get tailOffset => _tailOffset;
  int _tailOffset = -1;

  /// Text which is added
  String get textAdded => _textAdded;
  String _textAdded = '';

  /// Text which is removed
  String get textRemoved => _textRemoved;
  String _textRemoved = '';

  /// Type of modification
  DeltaTextType type = DeltaTextType.none;

  ///
  /// Computes unmodifiable delta text
  ///
  DeltaText({
    required String prevText,
    required this.prevSelection,
    required String nextText,
    required this.nextSelection,
  }) {
    _prevLength = prevText.length;
    //--- Text is unchanged
    if (prevText == nextText) {
      type = DeltaTextType.none;
      return;
    }

    //--- All text deleted
    if (nextText.isEmpty) {
      _isAll = true;
      type = DeltaTextType.delete;
      return;
    }

    //--- Computations
    _headLength = (prevSelection.start < nextSelection.start)
        ? prevSelection.start
        : nextSelection.start;
    int nextLen = nextText.length;
    int prevTailLen = _prevLength - prevSelection.end;
    int nextTailLen = nextLen - nextSelection.end;
    _tailLength = (prevTailLen < nextTailLen) ? prevTailLen : nextTailLen;
    _tailOffset = _prevLength - _tailLength;
    _isAll = (prevSelection.start == 0) && (prevSelection.end >= _prevLength);

    //--- Insert
    if (_headLength + _tailLength == _prevLength) {
      type = DeltaTextType.insert;
      _textAdded = nextText.substring(_headLength, nextLen - _tailLength);
      return;
    }

    _textAdded = nextText.substring(_headLength, nextLen - _tailLength);
    _textRemoved = prevText.substring(_headLength, _prevLength - _tailLength);
    type = textAdded.isEmpty ? DeltaTextType.delete : DeltaTextType.update;
  }

  @override
  String toString() => isAll
      ? '${type.name} at all => added: "${textAdded.replaceAll('\n', '\\n')}"'
      : '${type.name} [$_headLength..${_prevLength - _tailLength}]'
            ' => ${textAdded.isEmpty ? '' : 'added: "${textAdded.replaceAll('\n', '\\n')}"'}'
            '${textRemoved.isEmpty ? '' : ' removed: "${textRemoved.replaceAll('\n', '\\n')}"'}';
}

enum DeltaTextType { delete, insert, none, update }
