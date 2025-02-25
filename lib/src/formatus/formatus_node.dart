import 'package:flutter/material.dart';

import 'formatus_model.dart';

///
/// Node in document resembles an html-element with optional attributes.
///
/// Text is always a leaf node without style. Style is taken from its parent.
///
/// Cannot extend [TextSpan] here because its immutable and we need `parent`.
///
class FormatusNode {
  /// Optional attribute
  ///
  /// * color -> hex string
  /// * anchor -> href
  /// * image -> src
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

  ///
  /// Applies `selectedFormats` to `formats` by removing missing formats
  /// and by appending additional ones.
  ///
  void applyFormats(Set<Formatus> selectedFormats, String selectedColor) {
    Set<Formatus> toRemove = formats.toSet().difference(selectedFormats);
    for (Formatus formatus in toRemove) {
      formats.remove(formatus);
    }
    Set<Formatus> toAdd = selectedFormats.difference(formats.toSet());
    formats.addAll(toAdd);
    //--- Apply color
    if (formats.contains(Formatus.color)) {
      attribute = selectedColor;
    }
  }

  /// Returns a deep clone of this one
  FormatusNode clone() => FormatusNode(formats: formats.toList(), text: text)
    ..attribute = attribute;

  /// Returns `true` if last format requires an attribute
  bool get hasAttribute => formats.last.withAttribute;

  /// Returns `true` if `others` are the same formats
  bool hasSameFormats(Set<Formatus> others) =>
      (formats.length == others.length) &&
      formats.toSet().difference(others).isEmpty;

  /// Returns `true` if last format is color
  bool get hasColor => formats.contains(Formatus.color);

  /// Returns `true` if last format is anchor
  bool get isAnchor => formats.last == Formatus.anchor;

  /// Returns `true` if this is a line-break between two sections
  bool get isLineBreak => formats[0] == Formatus.lineBreak;

  bool get isNotLineBreak => !isLineBreak;

  /// Returns `true` if this nodes text is formatted as subscript
  bool get isSubscript => formats.contains(Formatus.subscript);

  /// Returns `true` if this nodes text is formatted as superscript
  bool get isSuperscript => formats.contains(Formatus.superscript);

  /// Length of text
  int get length => text.length;

  /// Returns section format
  Formatus get section => formats[0];

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
