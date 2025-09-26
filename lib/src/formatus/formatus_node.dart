import 'package:flutter/material.dart';

import 'formatus_model.dart';

///
/// A [FormatusNode] contains a sequence of characters with a different format
/// than its predecessor or successor has.
///
class FormatusNode {
  /// Accessible rich internet application standard
  String ariaLabel;

  ///
  /// Optional attribute
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
    this.ariaLabel = '',
    this.attribute = '',
    this.color = Colors.transparent,
  });

  /// Automatically inserted between sections
  static final FormatusNode lineBreak = FormatusNode(
    formats: [Formatus.lineFeed],
    text: '\n',
  );

  /// Single empty node to be used as placeholder to ensure null safety
  static final FormatusNode placeHolder = FormatusNode(
    formats: [Formatus.placeHolder],
    text: '',
  );

  /// Appends [formatus] to [formats] if `apply is true`.
  /// Else removes it. Does nothing if node is either anchor or image.
  void applyFormat(bool apply, Formatus formatus, Color color) {
    if (isAnchor || isImage) return;
    if (apply) {
      if (!formats.contains(formatus)) {
        formats.add(formatus);
      }
      if (formatus == Formatus.color) {
        if (color == Colors.transparent) {
          this.color = Colors.transparent;
          formats.remove(Formatus.color);
        } else {
          this.color = color;
        }
      }
    } else {
      formats.remove(formatus);
      if (formatus == Formatus.color) {
        color = Colors.transparent;
      }
    }
  }

  /// Returns a deep clone of this one
  FormatusNode clone() => FormatusNode(formats: formats.toList(), text: text)
    ..ariaLabel = ariaLabel
    ..attribute = attribute
    ..color = color;

  /// Returns `true` if last format requires an attribute
  bool get hasAttribute => attribute.isNotEmpty;

  /// Returns `true` if this node has a color
  bool get hasColor => formats.contains(Formatus.color);

  /// Returns `true` if this nodes text is formatted as subscript
  bool get hasSubscript => formats.contains(Formatus.subscript);

  /// Returns `true` if this nodes text is formatted as superscript
  bool get hasSuperscript => formats.contains(Formatus.superscript);

  /// Returns `true` if last format is anchor
  bool get isAnchor => formats.last == Formatus.anchor;

  /// Returns `true` if `otherFormats` or `otherColor` is different
  bool isDifferent(Set<Formatus> otherFormats, Color otherColor) =>
      (formats.length != otherFormats.length) ||
      formats.toSet().difference(otherFormats).isNotEmpty ||
      color != otherColor;

  /// Returns `true` if last format is image
  bool get isImage => formats.last == Formatus.image;

  /// Returns `true` if this is a linefeed between two sections
  bool get isLineFeed => formats[0] == Formatus.lineFeed;

  /// Returns `true` for all nodes except linefeed
  bool get isNotLineFeed => !isLineFeed;

  /// Returns `true` if this is a list node
  bool get isList => formats[0].isList;

  /// Returns `true` if `other` has same formats, attribute and color
  bool isSimilar(FormatusNode other) =>
      !isDifferent(other.formats.toSet(), other.color) &&
      (attribute == other.attribute);

  /// Length of text
  int get length => text.length;

  /// Returns section format
  Formatus get section => formats[0];

  set section(Formatus formatus) => formats[0] = formatus;

  void mixFormats(
    Set<Formatus> selectedFormats, {
    Color selectedColor = Colors.transparent,
  }) {
    Set<Formatus> given = selectedFormats.toSet();
    for (Formatus formatus in formats) {
      if (!given.remove(formatus)) {
        formats.remove(formatus);
      }
    }
    formats.addAll(given.toList());
    color = formats.contains(Formatus.color)
        ? selectedColor
        : Colors.transparent;
  }

  ///
  @override
  String toString() {
    String str = formats.map((f) => f.key).toList().join(' - ');
    str += hasColor ? ' "style="color: #${hexFromColor(color)};">' : '';
    str += hasAttribute ? ' $attribute' : '';
    return '$str "$text"';
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
  String toString() => 'NodeMeta[$nodeIndex] $textBegin + $textOffset -> $node';
}
