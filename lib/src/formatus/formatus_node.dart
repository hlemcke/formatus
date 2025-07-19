import 'package:flutter/material.dart';

import 'formatus_model.dart';

///
/// Node resembles part of all text with a list of formats and one optional
/// attribute.
///
class FormatusNode {
  ///
  /// Optional attribute
  ///
  /// * anchor -> href
  /// * image -> src
  String attribute;

  /// Color of this node. Transparent means no color.
  Color color;

  /// Formats of this node. First format is section format and always exist.
  List<Formatus> formats;

  /// Text part of this node
  String text;

  ///
  /// Constructor for a new node
  ///
  FormatusNode({
    required this.formats,
    required this.text,
    this.attribute = '',
    this.color = Colors.transparent,
  });

  /// Automatically inserted between sections
  static final FormatusNode lineBreak = FormatusNode(
    formats: [Formatus.lineBreak],
    text: '\n',
  );

  /// Single final empty node to be used as placeholder to ensure null safety
  static final FormatusNode placeHolder = FormatusNode(
    formats: [Formatus.placeHolder],
    text: '',
  );

  ///
  /// Applies `selectedFormats` to `formats` by removing missing formats
  /// and by appending additional ones.
  ///
  void applyFormats(Set<Formatus> selectedFormats, Color color) {
    Set<Formatus> toAdd = selectedFormats.difference(formats.toSet());
    formats.addAll(toAdd);
    //--- Apply color
    if (formats.contains(Formatus.color)) {
      this.color = color;
    }
    Set<Formatus> toRemove = formats.toSet().difference(selectedFormats);
    for (Formatus formatus in toRemove) {
      formats.remove(formatus);
    }
  }

  /// Returns a deep clone of this one
  FormatusNode clone() =>
      FormatusNode(formats: formats.toList(), text: text)
        ..attribute = attribute;

  /// Returns `true` if last format requires an attribute
  bool get hasAttribute => attribute.isNotEmpty;

  /// Returns `true` if `otherFormats` are the same formats
  /// and both `otherAttribute` and `otherColor` are equal to this one
  bool hasSameFormats(
    Set<Formatus> otherFormats,
    String otherAttribute,
    Color otherColor,
  ) =>
      (formats.length == otherFormats.length) &&
      formats.toSet().difference(otherFormats).isEmpty &&
      attribute == otherAttribute &&
      color == otherColor;

  /// Returns `true` if `other` has same formats and attribute
  bool isSimilar(FormatusNode other) =>
      hasSameFormats(other.formats.toSet(), other.attribute, other.color);

  /// Returns `true` if this node has a color
  bool get hasColor => formats.contains(Formatus.color);

  /// Returns `true` if last format is anchor
  bool get isAnchor => formats.last == Formatus.anchor;

  /// Returns `true` if this is a line-break between two sections
  bool get isLineBreak => formats[0] == Formatus.lineBreak;

  /// Returns `true` for all nodes except line-break
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
    List<String> tags = formats.map((e) => '<${e.key}').toList();
    String str = tags.join('>');
    str += hasColor ? ' "style="color: #${hexFromColor(color)}">' : '';
    str += hasAttribute ? ' $attribute' : '';
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
