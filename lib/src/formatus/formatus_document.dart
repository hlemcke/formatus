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

  /// Output from [toPlainText] for later [update]
  String _previousText = '';

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

  ///
  /// Optimizes the tree by combining sibling nodes of same format into one.
  ///
  void optimize() {
    _optimize(root);
  }

  void _optimize(FormatusNode node) {
    //--- first round: remove empty children
    for (FormatusNode child in node.children) {
      if (child.isEmpty) {
        node.children.remove(child);
      }
    }
    //--- second round: combine same formats into one node
    for (int i = 0; i < node.children.length - 1; i++) {
      FormatusNode child = node.children[i];
      FormatusNode sibling = node.children[i + 1];
      if (child.format == sibling.format) {
        if (child.format == Formatus.text) {
          child.text += sibling.text;
        } else {
          child.children.addAll(sibling.children);
        }
        node.children.removeAt(i + 1);
      }
    }
    //--- third round: do this recursively
    for (FormatusNode child in node.children) {
      _optimize(child);
    }
  }

  ///
  /// Returns text-node from given `index`.
  /// Sets `textOffset` inside text-node.
  ///
  FormatusNode textNodeByIndex(int index) {
    int charCount = 0;
    FormatusNode topLevelNode = root.children[0];
    for (int i = 0; i < textNodes.length; i++) {
      FormatusNode textNode = textNodes[i];
      FormatusNode currentTopLevelNode = textNode.topLevelTag;
      //--- Count for one char (LF) between top-level elements
      if (topLevelNode != currentTopLevelNode) {
        topLevelNode = currentTopLevelNode;
        charCount++;
      }
      int textLen = textNode.text.length;
      if (index < charCount + textLen) {
        textNode.textOffset = index - charCount;
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
    bool isNotFirst = false;
    for (FormatusNode topLevelNode in root.children) {
      if (isNotFirst) plain += '\n';
      isNotFirst = true;
      plain += topLevelNode.toPlainText();
    }
    _previousText = plain;
    return plain;
  }

  ///
  /// Updates tree structure from `currentText`
  ///
  void update(String current) {
    DeltaText diff = DeltaText.compute(previous: _previousText, next: current);
    if (diff.hasDelta == false) return;

    //--- Modify tree according to text delta
    FormatusNode leadNode = textNodeByIndex(diff.trailing.length);

    // TODO determine cases and handle them

    //--- Handle cases:
    if (diff.trailing.isNotEmpty) {
      FormatusNode trailNode = textNodeByIndex(diff.trailingStartIndex);
    }

    //--- Handle case: text inserted at start

    //--- Handle case: text deleted at end
    // TODO cut text of leadNode and remove nodes to the right of it

//--- Handle case: text deleted at start

    //--- Handle case: text appended to end
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
  /// Tag attributes like href or color
  final Map<String, dynamic> attributes = {};

  /// Format of this node
  Formatus format;

  /// Style of this node
  TextStyle style = const TextStyle();

  /// Non empty only if this is a text node (`format == Formatus.text`)
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

  List<FormatusNode> get children => _children;
  final List<FormatusNode> _children = [];

  void addChild(FormatusNode child) {
    _children.add(child);
    child.parent = this;
  }

  /// Index of this node in parents children. Relevant in path
  int get childIndexInParent =>
      (parent == null) ? -1 : parent!.children.indexOf(this);

  void cleanup() {
    if (isEmpty && parent != null) {
      parent!.children.remove(this);
      parent!.cleanup();
    }
  }

  /// Gets formats from path. Root format is removed!
  Set<Formatus> get formatsInPath {
    Set<Formatus> formats = {};
    FormatusNode? node = isTextNode ? parent : this;
    while (node != null) {
      formats.add(node.format);
      node = node.parent;
    }
    formats.remove(Formatus.body);
    return formats;
  }

  bool get hasParent => parent != null;

  bool get isEmpty => isTextNode ? text.isEmpty : _children.isEmpty;

  bool get isTextNode => format == Formatus.text;

  bool get isTopLevel => format.type == FormatusType.topLevel;

  /// Top-level tags have the single body element as parent
  FormatusNode? parent;

  /// Gets path from root node (`body`) down to this one
  List<FormatusNode> get path {
    List<FormatusNode> path = [];
    FormatusNode? node = this;
    while (node != null) {
      path.insert(0, node);
      node = node.parent;
    }
    return path;
  }

  /// Offset into this nodes `text` of cursor position.
  int textOffset = -1;

  FormatusNode get topLevelTag => isTopLevel ? this : parent!.topLevelTag;

  ///
  String toHtml() {
    if (isTextNode) return text;
    String html = '<${format.key}';
    for (String key in attributes.keys) {
      html += ' $key="${attributes[key]}"';
    }
    html += '>';
    for (FormatusNode node in children) {
      html += node.toHtml();
    }
    return '$html</${format.key}>';
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
      ? '$textOffset:"$text"'
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

///
/// Delta between two texts.
///
class DeltaText {
  /// Text which is added
  String added = '';

  /// Leading characters which are identical in both texts
  String leading = '';
  int leadingEndIndex = -1;

  /// Trailing characters which are identical in both texts
  String trailing = '';
  int trailingStartIndex = -1;
  bool _hasDelta = true;

  DeltaText._();

  factory DeltaText.compute({required String previous, required String next}) {
    DeltaText diff = DeltaText._();
    diff._compute(previous, next);
    return diff;
  }

  bool get hasDelta => _hasDelta;

  void _compute(String prev, String next) {
    _computeLeading(prev, next);
    if (_hasDelta) _computeRest(prev, next);
  }

  void _computeLeading(String prev, String next) {
    int i = 0;
    while (i < prev.length && i < next.length && prev[i] == next[i]) {
      i++;
    }
    leading = (i > 0) ? prev.substring(0, i) : '';
    leadingEndIndex = leading.length;
    _hasDelta = ((i < prev.length) || (i < next.length)) ? true : false;
  }

  /// Identical trailing text is computed from right to left
  void _computeRest(String prev, String next) {
    int leadLen = leading.length;
    int i = prev.length;
    int j = next.length;
    while ((i > leadLen) && j > leadLen && (prev[i - 1] == next[j - 1])) {
      i--;
      j--;
    }
    if (j < next.length - 1) trailing = next.substring(j);
    trailingStartIndex = j;
    if (j > leadLen) {
      added = trailing.isEmpty
          ? next.substring(leadLen)
          : next.substring(leadLen, j);
    }
  }
}

enum DeltaType {
  /// Text inserted at start: lead='', added=text, trail=previous
  insertAtStart,

  /// Text inserted in middle: lead=lead, added=text, trail=trail
  insertInMiddle,

  /// Text inserted at end: lead=previous, added=text, trail=''
  insertAtEnd,

  /// Text deleted at start: lead='', added='', trail=trail
  deleteAtStart,

  /// Text deleted in middle: lead=lead, added='', trail=trail
  deleteInMiddle,

  /// Text deleted at end: lead=lead, added='', trail=''
  deleteAtEnd,

  /// Text replaced at start: lead='', added=text, trail=trail
  replaceAtStart,

  /// Text replaced in middle: lead=lead, added=text, trail=trail
  replaceInMiddle,

  /// Text replaced at end: lead=lead, added=text, trail=''
  replaceAtEnd,
}
