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
  final Map<String, FormatusImage> _imageMap = {};

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

  @override
  void dispose() {
    removeListener(_onListen);
    super.dispose();
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
        ? FormatusImage(src: meta.node.attribute, aria: meta.node.ariaLabel)
        : null;
  }

  set imageAtCursor(FormatusImage? image) {
    NodeMeta meta = document.computeMeta(selection.baseOffset);
    FormatusNode node = meta.node;

    //--- Image exists at cursor position
    if (node.isImage) {
      if (image == null) {
        document.textNodes.removeAt(meta.nodeIndex);
      } else {
        node.ariaLabel = image.aria;
        //node.text = image.name; --- no text to show for an image ?
        node.attribute = image.src;
      }
    } else if (image == null) {
      return;
    }
    //--- Image to be inserted at cursor position
    else {
      FormatusNode anchorNode = FormatusNode(
        formats: [node.section, Formatus.image],
        ariaLabel: node.ariaLabel,
        text: '', //---no text to be shown for images
      );
      anchorNode.ariaLabel = image.aria;
      anchorNode.attribute = image.src;
      document.insertNewNode(meta, anchorNode);
    }
    document.computeResults();
    _rememberNodeResults();
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
    selectedColor = Colors.transparent;
    selectedFormats.clear();
    selectedFormats.add(Formatus.paragraph);
    document.clear();
    _cleanup();
    _prevResults = document.results;
    super.clear();
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
    _cleanup();
    document = FormatusDocument(formatted: formatted);
    _rememberNodeResults();
  }

  /// After selectin a text range user has activated a format or a color
  /// in [FormatusBar].
  void updateInlineFormat(Formatus formatus) {
    if (selection.isCollapsed) return;
    document.updateInlineFormat(selection, formatus, color: selectedColor);
    _rememberNodeResults();
  }

  /// Changes section-format at current cursor position
  void updateSectionFormat(Formatus formatus) {
    document.updateSectionFormat(selection, formatus);
    _rememberNodeResults();
  }

  /// Used to update text if user has edited it
  bool _needsTextUpdate = false;

  /// Used to determine if to fire `onChanged`
  FormatusResults _prevResults = FormatusResults.placeHolder;

  @visibleForTesting
  FormatusResults get prevResults => _prevResults;

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

  /// Returns `true` if _baseOffset_ or _extendOffset_ differ
  bool _areSelectionsDifferent(TextSelection a, TextSelection b) =>
      a.baseOffset != b.baseOffset || a.extentOffset != b.extentOffset;

  void _cleanup() {
    _prevResults = FormatusResults.placeHolder;
    _prevSelection = _emptySelection;
    text = '';
  }

  /// Handles pasted text by:
  ///
  /// * replacing all CRLF by a single space
  bool _handlePastedText(DeltaText deltaText) {
    if (deltaText.textAdded.length < 2) return false;
    deltaText._textAdded = deltaText._textAdded.replaceAll('\r', '');
    deltaText._textAdded = deltaText._textAdded.replaceAll('\n', ' ');

    //--- Check if pasted text contains html tags
    return false;
  }

  @visibleForTesting
  void onListen() => _onListen();

  ///
  /// Will be called by the underlying system whenever
  /// the content of the text field changes or cursor is repositioned.
  ///
  void _onListen() {
    //--- must not update selection! (would refire _onListen)
    _nextSelection = selection;

    //--- Immediate handling of unmodified text but possible range change
    if (_prevResults.plainText == text) {
      _needsTextUpdate = false;
      if (_areSelectionsDifferent(_prevSelection, _nextSelection)) {
        _updateSelection();
      }
      return;
    }
    _needsTextUpdate = true;

    //--- Immediate handling of full deletion
    if (text.isEmpty) {
      clear();
      return;
    }

    //--- Determine delete / insert / update
    DeltaText deltaText = DeltaText(
      prevSelection: _prevSelection,
      prevText: _prevResults.plainText,
      nextSelection: selection,
      nextText: text,
    );
    // debugPrint('=== _onListen => $deltaText');
    if (_handlePastedText(deltaText)) {
      // return document.insertFormatted(deltaText);
    }
    document.updateText(deltaText, selectedFormats, color: selectedColor);
    _rememberNodeResults();
  }

  /// Remembers [FormatusResults].
  /// Fires [onChanged] if `formattedText` has changed.
  void _rememberNodeResults() {
    if ((_prevResults.formattedText != document.results.formattedText) &&
        (onChanged != null)) {
      onChanged!(document.results.formattedText);
    }
    _prevResults = document.results;
    _updateSelection();
  }

  /// Remembers _selection_ from [_nextSelection].
  /// Repositions cursor if in front of a list-item.
  /// Last step is updating [value] of [TextEditingController]
  void _updateSelection() {
    NodeMeta meta = document.computeMeta(_nextSelection.baseOffset);
    selectedColor = meta.node.color;
    selectedFormats = document.textNodes[meta.nodeIndex].formats.toSet();
    if (meta.node.isAnchor && (meta.textOffset >= meta.length)) {
      selectedFormats.remove(Formatus.anchor);
    }
    int plainLength = document.results.plainText.length;

    //--- Cursor positioned in front of list-item
    if (meta.node.isList && (_nextSelection.baseOffset < meta.textBegin)) {
      int delta = (_nextSelection.baseOffset < 0)
          ? 2
          : (_prevSelection.baseOffset > _nextSelection.baseOffset)
          ? -1
          : 1;
      int offset = _nextSelection.baseOffset + delta;
      _nextSelection = TextSelection(baseOffset: offset, extentOffset: offset);
    } else if ((_nextSelection.baseOffset > plainLength) ||
        (_nextSelection.extentOffset > plainLength)) {
      _nextSelection = TextSelection.collapsed(offset: plainLength);
    }
    if (_areSelectionsDifferent(_prevSelection, _nextSelection)) {
      _prevSelection = _nextSelection;
      if (_needsTextUpdate) {
        value = TextEditingValue(
          text: _prevResults.plainText,
          selection: _prevSelection,
        );
      } else {
        selection = _nextSelection;
      }
    } else {
      super.text = _prevResults.plainText;
    }
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
