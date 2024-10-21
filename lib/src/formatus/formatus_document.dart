import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_parser.dart';

///
/// HTML formatted document parsed into a tree-like structure.
///
/// Essentially the `body` tag of an html text.
/// All children are top-level elements like `h1` or `p`.
/// Top-level elements cannot contain other top-level elements.
///
/// ### Structure of [htmlBody]:
///
/// * always starts with an opening top-level element like "\<p>" or "\<h1>"
/// * always ends with a closing top-level element like "</p>"
/// * children of a top-level element are a list of inline elements
/// * inline elements could be text-nodes or formats like `<b>` for bold
/// * inline elements can be nested
///
/// ### Structure of an html element
/// * opening element starts with `<` followed by name, optional attributes
///   and the closing `>`
/// * multiple attributes are separated by a single space
/// * an `attribute` is a key value pair like `color="#00a400"`
/// * a closing element has no attributes
///
class FormatusDocument {
  /// List of text nodes in sequence of occurrence
  List<FormatusNode> textNodes = [];

  /// Single root element. All children are top-level html elements
  FormatusNode root = FormatusNode();

  /// Creates a new instance from the given html-text
  factory FormatusDocument.fromHtml({
    required String htmlBody,
  }) {
    String text = FormatusDocument.cleanUp(htmlBody);
    if (text.isNotEmpty && !text.startsWith('<')) {
      text = '<p>$text';
    }
    FormatusDocument doc = FormatusDocument._();
    doc.root = FormatusParser().parse(htmlBody, doc.textNodes);
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })

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

  /// Returns text node and index to raw text within that node
  FormatusNode textNodeByCharIndex(int charIndex) {
    int charCount = 0;
    FormatusNode topLevelNode = root.children[0];
    for (int i = 0; i < textNodes.length; i++) {
      FormatusNode textNode = textNodes[i];
      FormatusNode currentTopLevelNode = textNode.topLevelTag;
      //--- Add one char (LF) between top-level elements
      if (topLevelNode != currentTopLevelNode) {
        topLevelNode = currentTopLevelNode;
        charCount++;
      }
      int textLen = textNode.text.length;
      if (charIndex < charCount + textLen) {
        textNode.offset = charIndex - charCount;
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
    for (FormatusNode node in root.children) {
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
    for (FormatusNode topLevelNode in root.children) {
      if (isFirst) {
        isFirst = false;
      } else {
        plain += '\n';
      }
      plain += topLevelNode.toPlainText();
    }
    return plain;
  }
}

///
/// Node in document resembles an html-element with optional attributes.
///
/// Text is always a leaf node without style. Style is taken from its parent.
///
/// Cannot extend [TextSpan] here because its immutable and we need `parent`.
///
class FormatusNode {
  /// Format of this node
  Formatus format;

  /// Style of this node
  TextStyle style = const TextStyle();

  /// Non empty only if this is a text-node
  String text = '';

  ///
  /// Creates a new node
  ///
  FormatusNode({
    this.format = Formatus.paragraph,
    this.style = const TextStyle(),
    this.text = '',
  }) {
    if (text.isNotEmpty) {
      format = Formatus.text;
    }
  }

  /// The _empty_ node is used as placeholder.
  static FormatusNode get placeHolder => _placeHolder;
  static final FormatusNode _placeHolder = FormatusNode();

  /// Tag attributes like href or color
  final Map<String, dynamic> attributes = {};
  String attrText = '';

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

  /// Index into plain text of this nodes text
  int offset = -1;

  /// Top-level tags have the single body element as parent
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

  FormatusNode get topLevelTag => hasParent ? parent!.topLevelTag : this;

  ///
  String toHtml() {
    if (isTextNode) return text;
    if (format == Formatus.lineBreak) return '<br/>';
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
