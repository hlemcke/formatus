import 'package:flutter/widgets.dart';

import 'formatus_model.dart';

///
/// Node in document resembles an html-element with optional attributes.
///
/// Text is always a leaf node without style. Style is taken from its parent.
///
/// Cannot extend [TextSpan] here because its immutable and we need `parent`.
///
class FormatusNode {
  /// Optional attribute like color or href
  String attribute = '';

  /// Formats of this node
  List<Formatus> formats;

  /// Text part of this node
  String text;

  ///
  /// Constructor for a new node
  ///
  FormatusNode({
    required this.formats,
    required this.text,
  });

  /// Automatically inserted between sections
  static final FormatusNode lineBreak =
      FormatusNode(formats: [Formatus.lineBreak], text: '\n');

  /// Single final empty node to be used as placeholder to ensure null safety
  static final FormatusNode placeHolder =
      FormatusNode(formats: [Formatus.placeHolder], text: '');

  /// Applies `selectedFormats` to `formats` by removing missing formats
  /// and by appending additional formats
  void applyFormats(Set<Formatus> selectedFormats) {
    Set<Formatus> toRemove = formats.toSet().difference(selectedFormats);
    for (Formatus formatus in toRemove) {
      formats.remove(formatus);
    }
    Set<Formatus> toAdd = selectedFormats.difference(formats.toSet());
    formats.addAll(toAdd);
  }

  /// Returns a deep clone of this one
  FormatusNode clone() => FormatusNode(formats: formats.toList(), text: text)
    ..attribute = attribute;

  /// Returns `true` if `other` has a different list of formats
  bool hasSameFormats(Object other) {
    if ((other is FormatusNode) && (formats.length == other.formats.length)) {
      for (int i = 0; i < formats.length; i++) {
        if (formats[i] != other.formats[i]) return false;
      }
      return true;
    }
    return false;
  }

  /// Returns `true` if this is an anchor node
  bool get isAnchor => formats.last == Formatus.anchor;

  /// Returns `true` if this is a line-break between two sections
  bool get isLineBreak => formats[0] == Formatus.lineBreak;

  bool get isNotLineBreak => !isLineBreak;

  /// Length of text
  int get length => text.length;

  ///
  @override
  String toString() {
    String str = '';
    for (Formatus formatus in formats) {
      str += '<${formatus.key}>';
    }
    return '$str -> "$text"';
  }
}

///
/// Result from [FormatusDocument.computeMeta()]
///
class NodeMeta {
  /// Length of text in node
  int get length => node.length;

  FormatusNode node = FormatusNode.placeHolder;

  /// Index into [FormatusDocument.textNodes]
  int nodeIndex = -1;

  /// Nodes text starts at this offset:
  /// 0 <= textStart <= previousText.length - node.text.length
  int textBegin = -1;

  /// Offset into nodes `text`: 0 <= textOffset <= node.text.length
  int textOffset = -1;

  @override
  String toString() => '[$nodeIndex] $textBegin + $textOffset -> $node';
}

///
/// Results to update formatted text and [TextField]
///
class FormatusResults {
  String plainText = '';
  String formattedText = '';
  TextSpan textSpan = TextSpan(text: '');
}
