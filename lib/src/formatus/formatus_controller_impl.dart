import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

import 'formatus_document.dart';
import 'formatus_node.dart';

///
/// [FormatusController] displays the tree-like structure of a
/// [FormatusDocument] into [TextSpan] to be displayed in a [TextFormField].
///
/// Four triggers feed into [FormatusDocument.compute] via a
/// [FormatusInput] built against the last [FormatusOutput] (`_prevOutput`):
///
/// 1. [_onListen] → text edited, or cursor moved / range selected
/// 2. [updateInlineFormat] → inline format toggled
/// 3. [updateSectionFormat] → section format toggled
/// 3. [applySelectedColor] → color changed
///
/// `document.results` is passed as both the document's own live state
/// *and* the `previous` snapshot `compute()` diffs against. That's safe
/// because `compute()` only ever reads a field of `previous` before it
/// mutates that same field on `results` (see its doc) -- so there's no
/// need for the controller to keep a separate "previous" copy of the
/// whole output. The one exception is `formatted`: since `String` is
/// immutable, a local `oldFormatted` snapshot taken right before
/// `compute()` stays valid afterwards and is all [_syncFromResults]
/// needs to decide whether to fire [onChanged].
///
class FormatusControllerImpl extends TextEditingController
    implements FormatusController {
  late FormatusDocument document;

  final Map<String, FormatusImage> _imageMap = {};

  Color selectedColor = Colors.transparent;
  Set<Formatus> selectedFormats = {};

  final ValueChanged<String>? onChanged;

  FormatusControllerImpl({
    String? formattedText,
    this.onChanged,
    List<FormatusImage> images = const [],
  }) {
    images.map((i) => _imageMap[i.src] = i);
    document = FormatusDocument(formatted: formattedText ?? '');
    //--- '' as the "old" value mirrors the pre-refactor behaviour: a
    //--- non-empty initial document does fire onChanged once.
    _syncFromResults(oldFormatted: '');
    addListener(_onListen);
  }

  @override
  void dispose() {
    removeListener(_onListen);
    super.dispose();
  }

  /// Returns anchor element at cursor position or `null` if there is none
  FormatusAnchor? get anchorAtCursor {
    FormatusNode node = document.findNodeAtCursor(selection.baseOffset);
    return node.isAnchor
        ? FormatusAnchor(href: node.attribute, name: node.text)
        : null;
  }

  /// Inserts or updates anchor at cursor position. Deletes it if empty
  set anchorAtCursor(FormatusAnchor? anchor) {
    final String oldFormatted = document.results.formatted;
    document.updateAnchorAtCursor(anchor, selection.baseOffset);
    _syncFromResults(oldFormatted: oldFormatted);
  }

  void applyAnchor(FormatusAnchor? anchor) {
    anchorAtCursor = anchor;
  }

  void applyImage(FormatusImage? image) {
    imageAtCursor = image;
  }

  /// Color changed in [FormatusBar] -> build the desired formats/color
  /// and let [FormatusDocument.compute] apply the diff.
  void applySelectedColor(Color? color) {
    final Color newColor = color ?? Colors.transparent;
    final Set<Formatus> newFormats = Set.of(selectedFormats);
    if (newColor == Colors.transparent) {
      newFormats.remove(Formatus.color);
    } else {
      newFormats.add(Formatus.color);
    }
    _applyFormatChange(formats: newFormats, color: newColor);
  }

  /// Returns image element at cursor position or `null` if there is none
  FormatusImage? get imageAtCursor {
    FormatusNode node = document.findNodeAtCursor(selection.baseOffset);
    return node.isImage
        ? FormatusImage(src: node.attribute, aria: node.ariaLabel)
        : null;
  }

  set imageAtCursor(FormatusImage? image) {
    final String oldFormatted = document.results.formatted;
    document.updateImageAtCursor(image, selection.baseOffset);
    _syncFromResults(oldFormatted: oldFormatted);
  }

  ///
  /// Formatting of text. Invoked by Flutter during build process
  ///
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) => document.results.textSpan4Editor;

  /// Sets empty _textNode_ inside a paragraph. No color, no formats
  @override
  void clear() {
    super.clear();
  }

  /// Returns formatted text
  @override
  String get formattedText => document.results.formatted;

  /// Replaces current text with `formatted`
  @override
  set formattedText(String formatted) {
    final String oldFormatted = document.results.formatted;
    document = FormatusDocument(formatted: formatted);
    TreeHelper.printAll(document, '=== Text Selection ===');
    _syncFromResults(oldFormatted: oldFormatted);
  }

  /// Replaces current selection (or inserts at cursor) with [newText]
  void replaceText(String newText) {
    final String oldText = text;

    //--- Safe bounds check
    final int start = selection.start.clamp(0, oldText.length);
    final int end = selection.end.clamp(0, oldText.length);

    final String updatedText = oldText.replaceRange(start, end, newText);

    value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + newText.length),
    );
  }

  ///
  /// After selecting a text range the user has activated (apply = true) or
  /// cleared (apply = false) an inline format in [FormatusBar].
  ///
  void updateInlineFormat(Formatus format, bool apply) {
    if (selection.isCollapsed) return;
    final Set<Formatus> newFormats = Set.of(selectedFormats);
    apply ? newFormats.add(format) : newFormats.remove(format);
    _applyFormatChange(formats: newFormats, color: selectedColor);
  }

  ///
  /// After positioning the cursor the user has activated a section format
  /// in [FormatusBar].
  ///
  void updateSectionFormat(Formatus formatus) {
    final Set<Formatus> newFormats = Set.of(selectedFormats)
      ..removeWhere((f) => f.isSection)
      ..add(formatus);
    _applyFormatChange(formats: newFormats, color: selectedColor);
  }

  /// Builds a [FormatusInput] carrying the current text/range unchanged
  /// but the newly desired `formats`/`color`, and lets the document diff
  /// it against its own current state.
  void _applyFormatChange({
    required Set<Formatus> formats,
    required Color color,
  }) {
    final FormatusOutput results = document.results;
    final int len = results.plainText.length;
    final TextSelection range = TextSelection(
      baseOffset: selection.start.clamp(0, len),
      extentOffset: selection.end.clamp(0, len),
    );
    final FormatusInput input = FormatusInput()
      ..plainText = results.plainText
      ..range = range
      ..formats = formats
      ..color = color;

    _computeAndSync(input);
  }

  @visibleForTesting
  void onListen() => _onListen();

  /// Text edited, or cursor moved / range selected -- both funnel through
  /// [FormatusDocument.compute], which tells the two apart internally.
  void _onListen() {
    final FormatusOutput results = document.results;
    final int len = text.length;
    final TextSelection range = TextSelection(
      baseOffset: selection.start.clamp(0, len),
      extentOffset: selection.end.clamp(0, len),
    );

    final bool textChanged = text != results.plainText;
    final bool selectionChanged = _areSelectionsDifferent(range, results.range);

    if (!textChanged && !selectionChanged) return;

    if (textChanged && text.isEmpty) {
      final String oldFormatted = results.formatted;
      document.clear();
      _syncFromResults(oldFormatted: oldFormatted);
      return;
    }

    final FormatusInput input = FormatusInput()
      ..plainText = text
      ..range = range
      ..formats = selectedFormats
      ..color = selectedColor;

    _computeAndSync(input);
  }

  /// Calls [FormatusDocument.compute] with `document.results` doubling as
  /// `previous`, capturing `formatted` beforehand purely to know whether
  /// to fire [onChanged] afterwards.
  void _computeAndSync(FormatusInput input) {
    final String oldFormatted = document.results.formatted;
    document.compute(input, document.results);
    _syncFromResults(oldFormatted: oldFormatted);
  }

  /// Applies the freshly computed `document.results`: syncs
  /// `selectedFormats`/`selectedColor`, pushes text+selection back into
  /// the field if the document changed them (e.g. list-item prefixes),
  /// and fires [onChanged] if `formatted` actually changed relative to
  /// `oldFormatted`.
  void _syncFromResults({required String oldFormatted}) {
    final FormatusOutput results = document.results;
    selectedColor = results.color;
    selectedFormats = results.formats;

    if (text != results.plainText ||
        _areSelectionsDifferent(selection, results.range)) {
      value = TextEditingValue(
        text: results.plainText,
        selection: results.range,
      );
    }

    if ((oldFormatted != results.formatted) && (onChanged != null)) {
      onChanged!(results.formatted);
    }
  }

  bool _areSelectionsDifferent(TextSelection a, TextSelection b) =>
      a.baseOffset != b.baseOffset || a.extentOffset != b.extentOffset;
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

  TextSelection get removedRange => TextSelection(
    baseOffset: headLength,
    extentOffset: headLength + textRemoved.length,
  );

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
    _headLength = (nextSelection.start < 0)
        ? 0
        : (prevSelection.start < nextSelection.start)
        ? prevSelection.start
        : nextSelection.start;
    int nextLen = nextText.length;
    int prevTailLen =
        _prevLength - (prevSelection.end < 0 ? 0 : prevSelection.end);
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
