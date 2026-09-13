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
/// 3. [updateColor] → color changed
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

  /// Colors selected by user or computed from text range
  Color selectedColor = Colors.transparent;

  /// Formates selected by user or computed from text range
  Set<Formatus> selectedFormats = {};

  final ValueChanged<String>? onChanged;

  FormatusControllerImpl({
    String? formattedText,
    this.onChanged,
    List<FormatusImage> images = const [],
  }) {
    images.map((i) => _imageMap[i.src] = i);
    document = FormatusDocument(formatted: formattedText ?? '');
    //--- Force initial sync
    document.needsUpdate = true;
    _syncFromResults();
    addListener(_onListen);
  }

  @override
  void dispose() {
    removeListener(_onListen);
    super.dispose();
  }

  /// Finds the segment that contains `offset`, using half-open [start, end).
  /// Returns null if `offset` sits exactly on a zero-width separator boundary
  /// or past the end of the segment list.
  FormatusSegment? _segmentAt(List<FormatusSegment> segments, int offset) {
    for (final seg in segments) {
      if (offset >= seg.start && offset < seg.end) return seg;
    }
    return null;
  }

  int _segmentIndex(List<FormatusSegment> segments, FormatusSegment seg) =>
      segments.indexOf(
        seg,
      ); // identity match is fine, segments aren't rebuilt mid-comparison

  /// Skips the list-item prefix span, redirecting based on travel direction.
  TextSelection adjustForListPrefix({
    required TextSelection prev,
    required TextSelection next,
    required List<FormatusSegment> segments,
  }) {
    if (!next.isCollapsed) return next;

    final seg = _segmentAt(segments, next.start);
    if (seg == null || seg.prefixOwner == null) return next;

    final movingForward = next.start >= prev.start;

    if (movingForward) {
      return TextSelection.collapsed(offset: seg.end);
    }

    final index = _segmentIndex(segments, seg);
    if (index > 0) {
      return TextSelection.collapsed(offset: segments[index - 1].end);
    }
    return const TextSelection.collapsed(offset: 0);
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
    debugPrint('Anchor = $anchor');
    document.updateAnchorAtCursor(anchor, selection.baseOffset);
    _syncFromResults();
  }

  /// Returns image element at cursor position or `null` if there is none
  FormatusImage? get imageAtCursor {
    FormatusNode node = document.findNodeAtCursor(selection.baseOffset);
    return node.isImage
        ? FormatusImage(src: node.attribute, aria: node.ariaLabel)
        : null;
  }

  set imageAtCursor(FormatusImage? image) {
    document.updateImageAtCursor(image, selection.baseOffset);
    _syncFromResults();
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
    document = FormatusDocument(formatted: formatted);
    document.needsUpdate = true;
    _syncFromResults();
  }

  ///
  /// Replaces current selection (or inserts at cursor) with [newText].
  /// Used by [FormatusBar] to insert an Emoji
  ///
  void replaceText(String newText) {
    final String oldText = text;

    //--- Safe bounds check
    final int start = selection.start.clamp(0, oldText.length);
    final int end = selection.end.clamp(0, oldText.length);

    final String updatedText = oldText.replaceRange(start, end, newText);

    //--- Fires _onListen
    value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: start + newText.length),
    );
  }

  /// Direct access for [FormatusViewer] to `TextSpan`
  @override
  TextSpan get textSpan4Viewer => document.results.textSpan4Viewer;

  ///
  /// Invoked by [FormatusBar] when user has selected a color
  ///
  void updateColor(Color? color) {
    final Color newColor = color ?? Colors.transparent;
    if (selectedColor == newColor) return;
    selectedColor = newColor;

    //--- insert or remove (if transparent) new color from formats
    if (newColor == Colors.transparent) {
      selectedFormats.remove(Formatus.color);
    } else {
      selectedFormats.add(Formatus.color);
    }
    _computeAndSync();
  }

  ///
  /// Invoked by [FormatusBar] when user has activated (apply = true) or
  /// cleared (apply = false) an inline format and there is a text-range.
  ///
  void updateInlineFormat(Formatus format, bool apply) {
    apply ? selectedFormats.add(format) : selectedFormats.remove(format);
    if (selection.isCollapsed) return;
    _computeAndSync();
  }

  ///
  /// Invoked by [FormatusBar] when user has activated a list format.
  /// Toggling the currently-active list off, switching list type, or
  /// starting a new list are all decided by [FormatusDocument.updateListFormat]
  /// itself from the current tree state -- no add/remove diffing needed here.
  ///
  void updateListFormat(Formatus format) {
    document.updateListFormat(selection, format);
    _syncFromResults();
  }

  ///
  /// Invoked by [FormatusBar] when user has activated a section format.
  ///
  /// Activating a section format clears the current one at cursor position
  /// (or start of range selection) and applies the new one.
  ///
  void updateSectionFormat(Formatus format) {
    Formatus currentSectionFormat = selectedFormats.firstWhere(
      (f) => f.isSection,
    );
    if (currentSectionFormat == format) return;
    selectedFormats
      ..removeWhere((f) => f.isSection)
      ..add(format);
    _computeAndSync();
  }

  @visibleForTesting
  void onListen() => _onListen();

  ///
  /// Text edited, or cursor moved / range selected -- both funnel through
  /// [FormatusDocument.compute], which tells the two apart internally.
  ///
  void _onListen() {
    final bool textChanged = text != document.results.plainText;

    //--- Pure cursor move / range selection: skip over list-item prefixes.
    //--- Segments are stale here if text was edited, so only do this when
    //--- the plainText itself hasn't changed.
    if (!textChanged) {
      final TextSelection prevSelection = TextSelection(
        baseOffset: document.commons.range.start,
        extentOffset: document.commons.range.end,
      );
      final TextSelection adjusted = adjustForListPrefix(
        prev: prevSelection,
        next: selection,
        segments: document.results.segments,
      );
      if (adjusted != selection) {
        selection =
            adjusted; // re-enters _onListen; lands past the prefix, so it settles there
        return;
      }
    }

    _computeAndSync();
  }

  /// Calls [FormatusDocument.compute] with `document.results` doubling as
  /// `previous`, capturing `formatted` beforehand purely to know whether
  /// to fire [onChanged] afterwards.
  void _computeAndSync() {
    FormatusInput input = FormatusInput()
      ..color = selectedColor
      ..fieldText = text
      ..formats = selectedFormats
      ..range = selection;

    //--- Remember old formatted to decide if calling onChanged
    document.compute(input);
    _syncFromResults();
  }

  ///
  /// Applies the freshly computed `document.results`:
  ///
  /// * syncs `selectedFormats`/`selectedColor`
  /// * pushes text+selection back into the field if the document changed them (e.g. list-item prefixes)
  /// * fires [onChanged] if `formatted` actually changed relative to `oldFormatted`
  ///
  void _syncFromResults() {
    //--- Update [FormatusBar] display
    selectedColor = document.commons.color;
    selectedFormats = Set<Formatus>.from(document.commons.formats);

    //--- Fire onChanged and update TextField if formatted was modified
    if (document.needsUpdate) {
      onChanged?.call(document.results.formatted);
      int start = document.commons.range.start;
      int end = document.commons.range.end;
      value = TextEditingValue(
        text: document.results.plainText,
        selection: TextSelection(baseOffset: start, extentOffset: end),
      );
    }
  }
}
