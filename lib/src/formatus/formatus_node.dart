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

  /// Single final empty node to be used as placeholder
  static final FormatusNode placeHolder =
      FormatusNode(format: Formatus.placeHolder);

  List<FormatusNode> get children => _children;
  final List<FormatusNode> _children = [];

  /// Appends `child` to end of current list of children and sets `parent`
  /// in child to `this`.
  void addChild(FormatusNode child) {
    _children.add(child);
    child.parent = this;
  }

  /// Index of this node in parents children. Relevant in path
  int get childIndexInParent =>
      (parent == null) ? -1 : parent!.children.indexOf(this);

  /// Gets depths in tree. Returns 0 for a top-level node
  int get depth => path.last == this ? path.length : parent?.depth ?? 0;

  void dispose() {
    if (parent != null) {
      parent!.children.remove(this);
      if (parent!.children.isEmpty) {
        parent!.dispose();
      }
      parent = null;
    }
  }

  /// Gets formats from path without `root`-format
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

  /// Inserts `newChild` into `children` at index
  void insertChild(int index, FormatusNode child) {
    children.insert(index, child);
    child.parent = this;
  }

  bool get isEmpty => isTextNode ? text.isEmpty : _children.isEmpty;

  bool get isTextNode => format == Formatus.text;

  bool get isTopLevel => format.type == FormatusType.topLevel;

  /// Length of text in a text node. 0 for all other nodes.
  int get length => text.length;

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

  /// Gets top node (below `root`) of this subtree
  FormatusNode get top => (parent == null)
      ? this
      : (parent!.parent == null)
          ? this
          : parent!.top;

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
      ? '[$textOffset] "$text"'
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

  void clear() => textNodes.clear();

  FormatusNode get first => textNodes.first;

  ///
  /// Returns index to text-node where `charIndex` <= sum of previous
  /// text-nodes length.
  ///
  int computeNodeIndex(
    String previousText,
    int charIndex,
  ) {
    //--- End of whole text
    if (charIndex >= previousText.length) {
      int nodeIndex = textNodes.length - 1;
      textNodes[nodeIndex].textOffset = textNodes[nodeIndex].text.length;
      return nodeIndex;
    }
    int charCount = 0;
    for (int i = 0; i < textNodes.length; i++) {
      FormatusNode textNode = textNodes[i];

      //--- Adjust node based on first char of this node
      if ((charCount < previousText.length) &&
          [' ', ',', '\n'].contains(previousText[charCount])) {
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

  void insert(int index, FormatusNode textNode) =>
      textNodes.insert(index, textNode);

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

  void removeFirst() => removeAt(0);

  void removeLast() => removeAt(textNodes.length);

  @override
  String toString() => textNodes.toString();
}
