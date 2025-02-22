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
  /// Optional attribute
  ///
  /// * color -> hex string
  /// * anchor -> href
  /// * image -> src
  String? attribute;

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
  void applyFormats(Set<Formatus> selectedFormats, String? selectedColor) {
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

  /// Returns `true` if last format is anchor
  bool get isAnchor => formats.last == Formatus.anchor;

  /// Returns `true` if last format is color
  bool get isColor => formats.last == Formatus.color;

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

  FormatusResults();

  ///
  /// Must be called after `textNodes` are updated
  ///
  factory FormatusResults.fromNodes(List<FormatusNode> textNodes) {
    FormatusResults results = FormatusResults();
    List<TextSpan> sections = [];
    List<_ResultNode> path = [];

    //--- Remove last elements from path and close tags
    void reducePath() {
      TextStyle? style = (path.last.formatus == Formatus.color)
          ? TextStyle(
              color: Color(int.tryParse(path.last.attribute!) ?? 0xFFFFFFFF))
          : path.last.formatus.style;
      TextSpan span = TextSpan(children: path.last.textSpans, style: style);
      if (path.length < 2) {
        sections.add(span);
      } else {
        path[path.length - 2].textSpans.add(span);
      }
      if (path.last.formatus != Formatus.lineBreak) {
        results.formattedText += '</${path.last.formatus.key}>';
      }
      path.removeLast();
    }

    //--- Condense similar nodes
    results._joinNodesWithSameFormat(textNodes);

    //--- Loop text nodes
    for (FormatusNode node in textNodes) {
      //--- Loop formats of text node
      for (int i = 0; i < node.formats.length; i++) {
        Formatus nodeFormat = node.formats[i];
        if ((path.length > i) && (path[i].formatus != nodeFormat)) {
          while (path.length > i) {
            reducePath();
          }
        }
        if (path.length < i + 1) {
          path.add(_ResultNode()
            ..formatus = nodeFormat
            ..attribute = nodeFormat.withAttribute ? node.attribute : null);
          if (node.isNotLineBreak) {
            results.formattedText += '<${nodeFormat.key}'
                '${nodeFormat.withAttribute ? " ${node.attribute}" : ""}>';
          }
        }
      }
      //--- Cleanup additional path elements
      while (path.length > node.formats.length) {
        reducePath();
      }
      path.last.textSpans.add(TextSpan(text: node.text));
      results.formattedText += node.isLineBreak ? '' : node.text;
      results.plainText += node.text;
    }
    while (path.isNotEmpty) {
      reducePath();
    }
    results.textSpan = TextSpan(children: sections, style: Formatus.root.style);
    return results;
  }

  ///
  /// Joins nodes having same format and same attribute
  /// by appending text of next node to current one then deleting next one.
  ///
  void _joinNodesWithSameFormat(List<FormatusNode> textNodes) {
    int nodeIndex = 0;
    while (nodeIndex < textNodes.length - 1) {
      if (textNodes[nodeIndex]
              .hasSameFormats(textNodes[nodeIndex + 1].formats.toSet()) &&
          (textNodes[nodeIndex].attribute ==
              textNodes[nodeIndex + 1].attribute)) {
        textNodes[nodeIndex].text += textNodes[nodeIndex + 1].text;
        textNodes.removeAt(nodeIndex + 1);
        continue;
      }
      nodeIndex++;
    }
  }
}

///
/// Internal class only used by [FormatusDocument.computeResults()]
///
class _ResultNode {
  String? attribute;
  Formatus formatus = Formatus.placeHolder;
  List<TextSpan> textSpans = [];

  @override
  String toString() => '<${formatus.key}> ${textSpans.length}';
}
