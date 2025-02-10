import 'package:flutter/widgets.dart';
import 'package:formatus/formatus.dart';

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

  /// Index of this node in parents children. Relevant in path
  int get childIndexInParent =>
      (parent == null) ? -1 : parent!.children.indexOf(this);

  /// Gets depths in tree. Returns 0 for a section node
  int get depth => path.last == this ? path.length : parent?.depth ?? 0;

  ///
  /// Gets formats from path without `root`-format
  ///
  List<Formatus> get formatsInPath {
    List<Formatus> formats = [];
    FormatusNode? node = isText ? parent : this;
    while ((node != null) && (node.format != Formatus.root)) {
      formats.insert(0, node.format);
      node = node.parent;
    }
    return formats;
  }

  bool get hasChildren => children.isNotEmpty;

  bool get hasParent => parent != null;

  bool get isEmpty => isText ? text.isEmpty : _children.isEmpty;

  bool get isRoot => format == Formatus.root;

  bool get isText => format == Formatus.text;

  bool get isSection => format.type == FormatusType.section;

  /// Length of text in a text node. 0 for all other nodes.
  int get length => text.length;

  /// Section tags have the single body element as parent
  FormatusNode? parent;

  /// Gets path from section (below `root`) down to this node.
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
    if (isText) return text;
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
