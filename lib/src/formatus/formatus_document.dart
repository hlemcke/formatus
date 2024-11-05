import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

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

  /// Internal constructor
  FormatusDocument._();

  factory FormatusDocument.empty() {
    FormatusDocument doc = FormatusDocument._();
    doc.setupEmpty();
    return doc;
  }

  /// Creates a new instance from the given html-text
  factory FormatusDocument.fromHtml({
    required String htmlBody,
  }) {
    FormatusDocument doc = FormatusDocument._();
    String cleanedHtml = FormatusDocument.cleanUpHtml(htmlBody);
    if (cleanedHtml.isEmpty) return FormatusDocument.empty();
    if (cleanedHtml.isNotEmpty && !cleanedHtml.startsWith('<')) {
      cleanedHtml = '<p>$cleanedHtml';
    }
    doc.root = FormatusParser().parse(htmlBody, doc.textNodes);
    doc.toPlainText();
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })

  /// Output from [toPlainText] for later [update]
  String _previousText = '';

  ///
  /// Cleanup given text by:
  /// * remove cr+lf
  /// * replace tab with space
  /// * replace multiple spaces with one space
  ///
  static String cleanUpHtml(String htmlBody) => htmlBody
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll('\t', ' ')
      .replaceAll('  ', ' ');

  ///
  /// Returns index of text-node which contains given `charIndex`
  ///
  int computeNodeIndex(int charIndex) =>
      textNodes.computeNodeIndex(_previousText, charIndex);

  ///
  /// Creates a new subtree with text-node from `text` and parents from `formats`.
  /// Returns leaf of subtree (which is the new text-node).
  ///
  FormatusNode createSubtree(String text, Set<Formatus> formats) {
    FormatusNode textNode = FormatusNode(format: Formatus.text, text: text);
    FormatusNode node = textNode;
    for (Formatus formatus in formats) {
      FormatusNode parent = FormatusNode(format: formatus);
      parent.addChild(node);
      node = parent;
    }
    return textNode;
  }

  ///
  /// Gets first different node in `textNode.path`.
  /// Its parent is the last node with same format.
  ///
  FormatusNode getFirstDifferentNode(
      FormatusNode textNode, Set<Formatus> sameFormats) {
    List<FormatusNode> path = textNode.path;
    int i = 1;
    while ((i < path.length) && sameFormats.contains(path[i].format)) {
      i++;
    }
    return path[i];
  }

  ///
  /// Handle cases for `delete` and `update`.
  ///
  void handleDeleteAndUpdate(DeltaText diff) {
    if (diff.isAtStart) {
      int nodeIndex = computeNodeIndex(diff.tailTextIndex);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeBefore(nodeIndex);
      textNode.text = diff.added + textNode.text.substring(textNode.textOffset);
      if (textNode.isEmpty) textNode.dispose();
    } else if (diff.isAtEnd) {
      int nodeIndex = computeNodeIndex(diff.leadTextIndex);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeAfter(nodeIndex);
      textNode.text =
          textNode.text.substring(0, textNode.textOffset) + diff.added;
      if (textNode.isEmpty) textNode.dispose();
    } else {
      int leadNodeIndex = computeNodeIndex(diff.leadTextIndex);
      FormatusNode leadNode = textNodes[leadNodeIndex];
      int leadOffset = leadNode.textOffset;
      int tailNodeIndex = computeNodeIndex(diff.tailTextIndex);
      //--- Replacement within same node
      if (leadNodeIndex == tailNodeIndex) {
        String pre = leadNode.text.substring(0, leadOffset);
        String post = leadNode.text.substring(leadNode.textOffset);
        leadNode.text = pre + diff.added + post;
        if (leadNode.isEmpty) {
          leadNode.dispose();
        }
      } else {
        FormatusNode tailNode = textNodes[tailNodeIndex];
        leadNode.text = leadNode.text.substring(0, leadOffset) + diff.added;
        tailNode.text = tailNode.text.substring(tailNode.textOffset);

        //--- Remove nodes in between. Must do from right to left!
        for (int i = tailNodeIndex - 1; i > leadNodeIndex; i--) {
          textNodes.removeAt(i);
        }
        //--- Must remove lead and tail at end!
        if (leadNode.isEmpty) leadNode.dispose();
        if (tailNode.isEmpty) tailNode.dispose();
      }
    }
  }

  ///
  /// Handle cases for `insert`
  ///
  void handleInsert(DeltaText diff, DeltaFormat deltaFormat) {
    FormatusNode textNode = FormatusNode();
    if (diff.isAtStart) {
      textNode = textNodes.first;
      if (deltaFormat.isEmpty) {
        textNode.text = diff.added + textNode.text;
      } else {
        handleInsertWithDifferentFormat(
            textNode, diff.added, true, deltaFormat);
      }
    } else if (diff.isAtEnd) {
      textNode = textNodes.last;
      if (deltaFormat.isEmpty) {
        textNode.text = textNode.text + diff.added;
      } else {
        handleInsertWithDifferentFormat(
            textNode, diff.added, false, deltaFormat);
      }
    } else {
      int nodeIndex = computeNodeIndex(diff.leadTextIndex);
      textNode = textNodes[nodeIndex];
      if (deltaFormat.isEmpty) {
        textNode.text = textNode.text.substring(0, textNode.textOffset) +
            diff.added +
            textNode.text.substring(textNode.textOffset);
      }
      //--- Handle insert in middle with different format
      else {
        String leadText = textNode.text.substring(0, textNode.textOffset);
        String tailText = textNode.text.substring(textNode.textOffset);
        textNode.text = leadText;
        debugPrint('--- lead="$leadText" tail="$tailText"');

        //--- Create and attach differently formatted nodes
        FormatusNode subTreeTop = handleInsertWithDifferentFormat(
            textNode, diff.added, false, deltaFormat);

        //--- Create and attach node with same format and rest of text
        if (tailText.isNotEmpty) {
          FormatusNode tailTextNode =
              createSubtree(tailText, deltaFormat.removed);
          subTreeTop.parent?.insertChild(
              subTreeTop.childIndexInParent + 1, tailTextNode.path[0]);
          int textNodeIndex = textNodes.textNodes.indexOf(textNode);
          textNodes.insert(textNodeIndex + 2, tailTextNode);
        }

        //--- Cleanup eventually empty lead node
        if (leadText.isEmpty) textNode.dispose();
        debugPrint('--- $textNodes');
      }
    }
  }

  ///
  /// Creates and inserts a new subtree with text `added` for the leaf text-node.
  ///
  /// Returns the topmost node of new subtree (`before == false`)
  /// or of `textNode` (`before == true`).
  /// Its parent is the lowest node with same formats.
  ///
  FormatusNode handleInsertWithDifferentFormat(FormatusNode textNode,
      String added, bool before, DeltaFormat deltaFormat) {
    FormatusNode firstDifferentNode =
        getFirstDifferentNode(textNode, deltaFormat.same);
    FormatusNode sameFormatNode = firstDifferentNode.parent!;
    FormatusNode newSubTreeLeaf = createSubtree(added, deltaFormat.added);
    FormatusNode newSubTreeTop = newSubTreeLeaf.path[0];

    //--- Attach text-node to last format node and update list of text nodes
    int childIndex = firstDifferentNode.childIndexInParent;
    sameFormatNode.insertChild(
        before ? childIndex : childIndex + 1, newSubTreeTop);
    int textNodeIndex = textNodes.textNodes.indexOf(textNode);
    textNodes.insert(
        before ? textNodeIndex : textNodeIndex + 1, newSubTreeLeaf);
    return before ? firstDifferentNode : newSubTreeTop;
  }

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

  void setupEmpty() {
    FormatusNode emptyTextNode = createSubtree(' ', {Formatus.paragraph});
    root = FormatusNode(format: Formatus.body);
    root.addChild(emptyTextNode.parent!);
    textNodes.clear();
    textNodes.textNodes.add(emptyTextNode);
  }

  ///
  /// Updates tree structure from `current`.
  ///
  /// Returns `false` if text is not changed.
  ///
  DeltaText update(String current, DeltaFormat deltaFormat) {
    DeltaText deltaText =
        DeltaText.compute(previous: _previousText, next: current);
    if (deltaText.hasDelta) {
      debugPrint('$deltaText ### $deltaFormat');
      if (deltaText.isInsert) {
        handleInsert(deltaText, deltaFormat);
      } else {
        handleDeleteAndUpdate(deltaText);
      }
//      optimize();
      _previousText = toPlainText();
    }
    return deltaText;
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

  /// Inserts `newChild` into `children` at index
  void insertChild(int index, FormatusNode child) {
    children.insert(index, child);
    child.parent = this;
  }

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

  void removeFirst() {
    removeAt(0);
  }

  void removeLast() {
    removeAt(textNodes.length);
  }

  @override
  String toString() => textNodes.toString();
}

///
/// Delta between two texts.
///
class DeltaText {
  /// Text which is added
  String get added => _added;
  String _added = '';

  /// Leading characters which are identical in both texts
  String get leadText => _leadText;
  String _leadText = '';

  /// Index to end of leading text which is identical in both texts
  int get leadTextIndex => _leadText.length;

  /// Trailing characters which are identical in both texts
  String get tailText => _tailText;
  String _tailText = '';

  /// Index to start of `tailText` in `previous` text
  int get tailTextIndex => _tailTextIndex;
  int _tailTextIndex = -1;

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
  bool get isAtEnd => _hasDelta && tailText.isEmpty;

  /// Returns `true` if change has occurred at end of previous text
  bool get isAtStart => leadText.isEmpty;

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
      _isInsert = (_leadText.length + _tailText.length == prev.length);
    }
  }

  void _computeLeading(String prev, String next) {
    int i = 0;
    while (i < prev.length && i < next.length && prev[i] == next[i]) {
      i++;
    }
    _leadText = (i > 0) ? prev.substring(0, i) : '';
    _hasDelta = ((i < prev.length) || (i < next.length)) ? true : false;
  }

  /// Identical trailing text is computed from right to left
  void _computeRest(String prev, String next) {
    int leadLen = _leadText.length;
    int i = prev.length;
    int j = next.length;
    while ((i > leadLen) && j > leadLen && (prev[i - 1] == next[j - 1])) {
      i--;
      j--;
    }
    if (i < prev.length - 1) _tailText = prev.substring(i);
    _tailTextIndex = i;
    if (j > leadLen) {
      _added = tailText.isEmpty
          ? next.substring(leadLen)
          : next.substring(leadLen, j);
    }
  }

  @override
  String toString() {
    if (hasDelta == false) return '<no delta>';
    return '${isDelete ? "DELETE" : isInsert ? "INSERT" : "UPDATE"}'
        ' ${isAtStart ? "START " : isAtEnd ? "END   " : "MIDDLE"}'
        ' leadTextIdx=$leadTextIndex tailTextIdx=$tailTextIndex'
        ' added="$added"\nlead="$leadText"\ntail="$tailText"';
  }
}
