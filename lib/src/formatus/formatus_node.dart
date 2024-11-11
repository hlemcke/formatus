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
  ///
  /// Returns `true` if reduction has occurred
  bool addChild(FormatusNode child) {
    children.add(child);
    child.parent = this;
    return reduce();
  }

  /// Index of this node in parents children. Relevant in path
  int get childIndexInParent =>
      (parent == null) ? -1 : parent!.children.indexOf(this);

  /// Gets depths in tree. Returns 0 for a top-level node
  int get depth => path.last == this ? path.length : parent?.depth ?? 0;

  /// Disposes this node by removing it from its parents children.
  /// If parents children become empty then parent will be disposed also.
  void dispose() {
    if (parent != null) {
      parent!.children.remove(this);
      if (parent!.children.isEmpty) {
        parent!.dispose();
      }
      parent = null;
      text = '';
    }
  }

  ///
  /// Gets formats from path without `root`-format
  ///
  List<Formatus> get formatsInPath {
    List<Formatus> formats = [];
    FormatusNode? node = isTextNode ? parent : this;
    while ((node != null) && (node.format != Formatus.root)) {
      formats.insert(0, node.format);
      node = node.parent;
    }
    return formats;
  }

  bool get hasParent => parent != null;

  /// Inserts `child` into `children` at `index`.
  ///
  /// If child has same format as left node then its children will be added instead.
  ///
  /// Returns `true` if reduction has occurred
  bool insertChild(int index, FormatusNode child) {
    children.insert(index, child);
    child.parent = this;
    return reduce();
  }

  /// Reduces children below top-level node by combining same formats.
  /// Returns `true` if reduction has occurred.
  bool reduce() {
    //--- Never combine top-level elements
    if (format == Formatus.root) return false;
    bool isReduced = false;
    for (int i = 1; i < children.length; i++) {
      if (children[i - 1].format == children[i].format) {
        if (children[i].format == Formatus.text) {
          //--- Text-node -> join strings
          FormatusNode textNode = children.removeAt(i);
          children[i - 1].text += textNode.text;
          textNode.dispose();
          isReduced = true;
        } else {
          //--- format-node -> move children from next to current
          while (children[i].children.isNotEmpty) {
            children[-1].children.add(children[i].children.removeAt(0));
          }
          children[i].dispose();
          isReduced = true;
        }
      }
    }
    return isReduced;
  }

  bool get isEmpty => isTextNode ? text.isEmpty : _children.isEmpty;

  bool get isTextNode => format == Formatus.text;

  bool get isTopLevel => format.type == FormatusType.topLevel;

  /// Length of text in a text node. 0 for all other nodes.
  int get length => text.length;

  /// Top-level tags have the single body element as parent
  FormatusNode? parent;

  /// Gets path from top-level (below `root`) down to this node.
  List<FormatusNode> get path {
    List<FormatusNode> path = [];
    FormatusNode? node = this;
    while ((node != null) && (node.format != Formatus.root)) {
      path.insert(0, node);
      node = node.parent;
    }
    return path;
  }

  /// Offset into this nodes `text` of cursor position.
  int textOffset = -1;

  /// Gets top node (below `root`) of this subtree
  FormatusNode get top => (parent == null)
      ? this
      : (parent!.format == Formatus.root)
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
  /// text-nodes plus current one.
  ///
  int computeIndex(
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
