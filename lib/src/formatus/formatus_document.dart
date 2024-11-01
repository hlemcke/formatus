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
  FormatusTextNodes textNodes = FormatusTextNodes();

  /// Single root element. All children are top-level html elements
  FormatusNode root = FormatusNode();

  factory FormatusDocument.empty() {
    FormatusDocument doc = FormatusDocument._();
    return doc;
  }

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
    doc.toPlainText();
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
  /// Returns index of text-node which contains given `charIndex`
  ///
  int indexOfCharIndex(int charIndex) =>
      textNodes.indexOfCharIndex(charIndex, _previousText);

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
  /// Updates tree structure from `current`.
  ///
  /// Returns `false` if text is not changed.
  ///
  /// TODO add parameter "selectedFormats" and apply them to insert and update
  ///
  DeltaText update(String current) {
    DeltaText diff = DeltaText.compute(previous: _previousText, next: current);
    if (diff.hasDelta) {
      //--- Modify tree according to text delta
      if (diff.isInsert) {
        handleInsert(diff);
      } else if (diff.isDelete) {
        handleDelete(diff);
      } else {
        handleUpdate(diff);
      }
//      optimize();
      _previousText = toPlainText();
    }
    return diff;
  }

  /// Handle cases for `delete`. Deletion can include multiple nodes
  void handleDelete(DeltaText diff) {
    if (diff.isAtStart) {
      int nodeIndex = indexOfCharIndex(diff.trailingStartIndex);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeBefore(nodeIndex);
      textNode.text = textNode.text.substring(textNode.textOffset);
    } else if (diff.isAtEnd) {
      int nodeIndex = indexOfCharIndex(diff.leadingEndIndex);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeAfter(nodeIndex);
      textNode.text = textNode.text.substring(0, textNode.textOffset);
    } else {
      debugPrint('DELETE MIDDLE');
      // TODO implement deletion in middle
    }
  }

  /// Handle cases for `insert`
  void handleInsert(DeltaText diff) {
    FormatusNode textNode = FormatusNode();
    debugPrint(diff.toString());
    if (diff.isAtStart) {
      textNode = textNodes.first;
      textNode.text = diff.added + textNode.text;
    } else if (diff.isAtEnd) {
      textNode = textNodes.last;
      textNode.text += diff.added;
    } else {
      int nodeIndex = indexOfCharIndex(diff.leadingEndIndex);
      textNode = textNodes[nodeIndex];
      debugPrint('=== node: $textNode');
      textNode.text = textNode.text.substring(0, textNode.textOffset) +
          diff.added +
          textNode.text.substring(textNode.textOffset);
    }
  }

  /// Handle cases for `update`. Modified text can include multiple nodes.
  ///
  /// TODO handle different start and end node
  void handleUpdate(DeltaText diff) {
    if (diff.isAtStart) {
      int nodeIndex = indexOfCharIndex(diff.trailingStartIndex);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeBefore(nodeIndex);
      textNode.text = diff.added + textNode.text;
    } else if (diff.isAtEnd) {
      int nodeIndex = indexOfCharIndex(diff.leadingEndIndex);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeAfter(nodeIndex);
      textNode.text =
          textNode.text.substring(0, textNode.textOffset) + diff.added;
    } else {
      debugPrint('UPDATE MIDDLE');
      // TODO implement update in middle
    }
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

  void dispose() {
    if (parent != null) {
      parent!.children.remove(this);
      if (parent!.children.isEmpty) {
        parent!.dispose();
      }
      parent = null;
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

  /// Gets path from top-level down to this one.
  /// The `body` element is removed from start of path.
  List<FormatusNode> get path {
    List<FormatusNode> path = [];
    FormatusNode? node = this;
    while (node != null) {
      if (node.format != Formatus.body) path.insert(0, node);
      node = node.parent;
    }
    return path;
  }

  /// Offset into this nodes `text` of cursor position.
  int textOffset = -1;

  FormatusNode get topLevelNode => isTopLevel ? this : parent!.topLevelNode;

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
      ? 'offset=$textOffset "$text"'
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
///
///
class FormatusTextNodes {
  List<FormatusNode> textNodes = [];

  FormatusNode operator [](int index) => textNodes[index];

  void add(FormatusNode textNode) {
    textNode.format = Formatus.text;
    textNodes.add(textNode);
  }

  FormatusNode get first => textNodes.first;

  ///
  /// Returns index to text-node where `charIndex` <= sum of previous
  /// text-nodes length.
  ///
  int indexOfCharIndex(int charIndex, String previousText) {
    int charCount = 0;
    for (int i = 0; i < textNodes.length; i++) {
      FormatusNode textNode = textNodes[i];

      //--- Adjust node based on first char of this node
      if ([' ', ',', '\n'].contains(previousText[charCount])) {
        if (charIndex == charCount) {
          i--;
          textNode = textNodes[i];
          textNode.textOffset = textNode.text.length;
          return i;
        }
        if (previousText[charCount] == '\n') {
          charCount++;
        }
      }
      int textLen = textNode.text.length;
      if (charIndex < charCount + textLen) {
        //--- Remember offset into text of node found
        textNode.textOffset = charIndex - charCount;
        return i;
      }
      charCount += textLen;
    }
    return textNodes.length - 1;
  }

  FormatusNode get last => textNodes.last;

  int get length => textNodes.length;

  void removeAfter(int index) {
    while (textNodes.length > index + 1) {
      removeLast();
    }
  }

  void removeAt(int index) {
    if (textNodes.isEmpty || index < 0) return;
    if (index >= textNodes.length) index = textNodes.length - 1;
    FormatusNode node = textNodes.removeAt(index);
    node.dispose();
  }

  void removeBefore(int index) {
    for (int i = 0; i < index; i++) {
      removeFirst();
    }
  }

  void removeFirst() {
    removeAt(0);
  }

  void removeLast() {
    removeAt(textNodes.length);
  }
}

///
/// Delta between two texts.
///
class DeltaText {
  /// Text which is added
  String get added => _added;
  String _added = '';

  /// Leading characters which are identical in both texts
  String get leading => _leading;
  String _leading = '';
  int leadingEndIndex = -1;

  /// Trailing characters which are identical in both texts
  String get trailing => _trailing;
  String _trailing = '';
  int trailingStartIndex = -1;

  DeltaText._();

  factory DeltaText.compute({required String previous, required String next}) {
    DeltaText diff = DeltaText._();
    diff._compute(previous, next);
    return diff;
  }

  /// Returns `true` if previous text is not equal to next text
  bool get hasDelta => _hasDelta;
  bool _hasDelta = true;

  /// Returns `true` if change has occurred at start of previous text
  bool get isAtEnd => _hasDelta && _trailing.isEmpty;

  /// Returns `true` if change has occurred at end of previous text
  bool get isAtStart => _leading.isEmpty;

  /// Returns `true` if characters were deleted
  bool get isDelete => hasDelta && _added.isEmpty;

  /// Returns `true` if character were added
  bool get isInsert => _isInsert;
  bool _isInsert = false;

  /// Returns `true` if characters were modified.
  /// The modified characters can be longer, shorter or have same length as
  /// the previous characters.
  bool get isUpdate => hasDelta && _added.isNotEmpty && !_isInsert;

  void _compute(String prev, String next) {
    _computeLeading(prev, next);
    if (_hasDelta) {
      _computeRest(prev, next);
      _isInsert = (_leading.length + _trailing.length == prev.length);
    }
  }

  void _computeLeading(String prev, String next) {
    int i = 0;
    while (i < prev.length && i < next.length && prev[i] == next[i]) {
      i++;
    }
    _leading = (i > 0) ? prev.substring(0, i) : '';
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
    if (j < next.length - 1) _trailing = next.substring(j);
    trailingStartIndex = j;
    if (j > leadLen) {
      _added = trailing.isEmpty
          ? next.substring(leadLen)
          : next.substring(leadLen, j);
    }
  }

  @override
  String toString() {
    if (hasDelta == false) return '<no delta>';
    return '${isDelete ? "DELETE" : isInsert ? "INSERT" : "UPDATE"}'
        ' ${isAtStart ? "START " : isAtEnd ? "END   " : "MIDDLE"}'
        ' added="$_added" lead="$_leading" trail="$_trailing"';
  }
}
