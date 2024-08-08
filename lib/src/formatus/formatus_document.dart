import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'text_helper.dart';

///
/// HTML formatted document parsed into a tree-like structure.
///
/// Essentially the root node. All children are top-level elements.
/// Top-level elements cannot contain other top-level elements.
///
/// Structure of [htmlBody]:
/// * always starts with an opening top-level element like "<p>" or "<h1>"
/// * always ends with a closing top-level element like "</p>"
/// * a top-level contains a list of inline elements like text-nodes
/// * inline elements can be nested
///
class FormatusDocument {
  /// List of text nodes in sequence of occurrence
  List<FormatusNode> textNodes = [];

  /// List of top-level html tags -> children
  List<FormatusNode> topLevelTags = [];

  /// Creates a new instance from the given html-text
  factory FormatusDocument.fromHtml({
    required String htmlBody,
  }) {
    String text = FormatusDocument.cleanUp(htmlBody);
    if (text.isNotEmpty && !text.startsWith('<')) {
      text = '<p>$text';
    }
    FormatusDocument doc = FormatusDocument._();
    doc._parse(text);
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })
  // Parse markdown internally into the node structure

  /// Internal constructor
  FormatusDocument._();

  ///
  /// Cleanup given text by:
  /// * remove cr+lf
  /// * replace tab with space
  /// * replace multiple spaces with one space
  ///
  static String cleanUp(String htmlBody) => htmlBody
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll('\t', ' ')
      .replaceAll('  ', ' ');

  /// Returns text node and index to raw text of that node
  FormatusNode textNodeByCharIndex(int charIndex) {
    int charCount = 0;
    FormatusNode topLevelNode = topLevelTags[0];
    for (int i = 0; i < textNodes.length; i++) {
      FormatusNode textNode = textNodes[i];
      FormatusNode currentTopLevelNode = textNode.topLevelTag;
      if (topLevelNode != currentTopLevelNode) {
        topLevelNode = currentTopLevelNode;
        charCount++;
      }
      int textLen = textNode.text.length;
      if (charIndex < charCount + textLen) {
        textNode.offset = charCount;
        return textNode;
      }
      charCount += textLen;
    }
    return textNodes.last;
  }

  ///
  /// Returns this document as a string in html format
  ///
  String toHtml() {
    String html = '';
    for (FormatusNode node in topLevelTags) {
      html += node.toHtml();
    }
    return html;
  }

  ///
  /// Returns plain text with line breaks between top-level elements
  ///
  /// Used for [TextFormField.text]
  ///
  String toPlainText() {
    String plain = '';
    bool isFirst = true;
    for (FormatusNode topLevelNode in topLevelTags) {
      if (isFirst) {
        isFirst = false;
      } else {
        plain += '\n';
      }
      plain += topLevelNode.toPlainText();
    }
    return plain;
  }

  void _parse(String htmlBody) {
    if (htmlBody.isEmpty) {
      FormatusNode node = FormatusNode()..format = Formatus.paragraph;
      topLevelTags.add(node);
      FormatusNode textNode = FormatusNode()..format = Formatus.text;
      node.addChild(textNode);
      return;
    }

    int offset = 0;
    while (offset < htmlBody.length) {
      FormatusNode node = FormatusNode();
      topLevelTags.add(node);
      offset = _parseTag(node, htmlBody, offset);
    }
  }

  int _parseTag(FormatusNode node, String htmlBody, int offset) {
    if (htmlBody[offset] == '<') {
      offset++;
    }
    String tagName = TextHelper.extractWord(htmlBody, offset);
    node.format = Formatus.find(tagName);
    offset += tagName.length;
    while ((offset < htmlBody.length) && (htmlBody[offset] != '>')) {
      // TODO parse attributes into map
      node.attrText += htmlBody[offset];
      offset++;
    }
    offset++;

    //--- Text or nested inline tag
    while (offset < htmlBody.length) {
      if (htmlBody[offset] == '<') {
        offset++;

        if (htmlBody[offset] == '/') {
          //--- Closing tag
          while (offset < htmlBody.length && htmlBody[offset] != '>') {
            offset++;
          }
          offset++;
          return offset;
        } else {
          //--- Opening tag -> must be a nested inline tag
          FormatusNode inlineTag = FormatusNode();
          node.addChild(inlineTag);
          offset = _parseTag(inlineTag, htmlBody, offset);
        }
      } else {
        offset = _parseText(node, htmlBody, offset);
      }
    }
    return offset;
  }

  ///
  /// Creates a new text node and attaches it to given `node`.
  /// Advances offset to next `<`.
  ///
  int _parseText(FormatusNode node, String htmlBody, int offset) {
    int initialOffset = offset;
    while ((offset < htmlBody.length) && (htmlBody[offset] != '<')) {
      offset++;
    }
    FormatusNode textNode = FormatusNode()..format = Formatus.text;
    textNode.text = htmlBody.substring(initialOffset, offset);
    node.addChild(textNode);
    textNodes.add(textNode);
    return offset;
  }
}

///
/// Node of document resembles an element with optional attributes.
///
/// Text is always a leaf node without style.
///
/// Cannot extend [TextSpan] here because its immutable and we need `parent`.
///
class FormatusNode {
  FormatusNode();

  /// The _empty_ node is used as placeholder.
  static FormatusNode get placeHolder => _placeHolder;
  static final FormatusNode _placeHolder = FormatusNode();

  /// Tag attributes like url or color
  final Map<String, dynamic> attributes = {};
  String attrText = '';

  Formatus format = Formatus.paragraph;

  List<FormatusNode> get children => _children;
  final List<FormatusNode> _children = [];

  void addChild(FormatusNode child) {
    _children.add(child);
    child.parent = this;
  }

  bool get hasParent => parent != null;

  bool get isEmpty => isTextNode ? text.isEmpty : _children.isEmpty;

  bool get isTextNode => format == Formatus.text;

  bool get isTopLevel => format.type == FormatusType.topLevel;

  /// Index into plain text to start of this nodes text
  int offset = -1;

  /// Top-level tags have no parent
  FormatusNode? parent;

  void cleanup() {
    if (parent != null) {
      parent!.children.remove(this);
      parent!.cleanup();
    }
  }

  /// Gets path from top-level element down to this one
  List<FormatusNode> get path {
    FormatusNode? node = this;
    List<FormatusNode> path = [];
    while (node != null) {
      path.insert(0, node);
      node = node.parent;
    }
    return path;
  }

  /// Style of this node
  TextStyle style = const TextStyle();

  /// Non empty only if this is a text-node
  String text = '';

  FormatusNode get topLevelTag => hasParent ? parent!.topLevelTag : this;

  ///
  String toHtml() {
    if (isTextNode) return text;
    String html = '';
    for (FormatusNode node in children) {
      html += node.toHtml();
    }
    return '<${format.key}>$html</${format.key}>';
  }

  ///
  String toPlainText() {
    String plain = text;
    for (FormatusNode child in children) {
      plain += child.toPlainText();
    }
    return plain;
  }

  ///
  @override
  String toString() => text.isNotEmpty
      ? '$offset:"$text"'
      : '<${format.key}> ${_children.length}';

  TextSpan toTextSpan() {
    if (text.isNotEmpty) {
      return TextSpan(style: Formatus.text.style, text: text);
    }
    List<TextSpan> spans = [];
    for (FormatusNode child in children) {
      spans.add(child.toTextSpan());
    }
    return TextSpan(children: spans, style: format.style);
  }
}
