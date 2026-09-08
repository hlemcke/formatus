import 'package:flutter/material.dart';

import 'formatus_model.dart';

///
/// A [FormatusNode] is one node in the tree. It contains the [Formatus] tag
/// which must be different from its predecessor or successor.
/// It also contains an optional sequence of characters and optional attributes.
///
class FormatusNode {
  /// Accessible rich internet application standard
  String ariaLabel;

  ///
  /// Optional attribute
  /// * anchor → href
  /// * image → src
  String attribute;

  /// Ordered list of children
  List<FormatusNode> children = [];

  /// Color of this node. Transparent means no color.
  Color color;

  /// Current number for list-item if this is an "ol"-node
  int orderedListNumber = 0;

  /// References its parent
  late FormatusNode parent;

  /// Formats of this node. First format is section format and always exist.
  Formatus tag;

  /// Text if this is a text-node
  String text;

  /// If cursor selection starts inside the text then this is the index.
  int textIndex0 = -1;

  /// If cursor selection ends inside the text then this is the index.
  int textIndex1 = -1;

  ///
  /// Constructor for a new node
  ///
  FormatusNode({
    required this.tag,
    this.text = '',
    this.ariaLabel = '',
    this.attribute = '',
    this.color = Colors.transparent,
  }) {
    parent = this;
  }

  /// Creates an empty paragraph node
  factory FormatusNode.para() => FormatusNode(tag: .paragraph);

  /// Creates a root node with child paragraph with child text
  factory FormatusNode.root() => FormatusNode(tag: .root);

  /// Creates an empty text node
  factory FormatusNode.text() => FormatusNode(tag: .text);

  /// Automatically inserted between sections
  static final FormatusNode lineBreak = FormatusNode(
    tag: .lineFeed,
    text: '\n',
  );

  /// Single empty node to be used as placeholder to ensure null safety
  static final FormatusNode placeHolder = FormatusNode(
    tag: .placeHolder,
    text: '',
  );

  /// Return child at index
  FormatusNode operator [](int index) => children[index];

  /// Set child at index
  void operator []=(int index, FormatusNode node) => children[index] = node;

  /// Append child
  void appendChild(FormatusNode child) {
    children.add(child);
    child.parent = this;
  }

  int get childCount => children.length;

  /// Clears all children
  void clearChildren() => children.clear();

  /// Copies this node excluding children, parent and text
  FormatusNode get copy => FormatusNode(tag: tag)
    ..ariaLabel = ariaLabel
    ..attribute = attribute
    ..color = color
    ..orderedListNumber = orderedListNumber;

  /// Finds color for this node by walking the tree up
  Color get findColor => isRoot || identical(parent, this)
      ? Colors.transparent
      : color == Colors.transparent
      ? parent.findColor
      : color;

  /// Returns format-node above this one or `null` if not found
  FormatusNode? findFormatNode(Formatus format) => isRoot
      ? null
      : tag == format
      ? this
      : parent.findFormatNode(format);

  /// Set of tags from root (exclusive) to this node (exclusive)
  Set<Formatus> get formats => (tag == .root) || (parent == this)
      ? {}
      : (tag == .text)
      ? parent.formats
      : {...parent.formats, tag};

  /// Returns `true` if this node contains an attribute
  bool get hasAttribute => attribute.isNotEmpty;

  /// Returns `true` if this node has a color
  bool get hasColor => color != Colors.transparent;

  /// Gets index in parents children
  int get indexInParent => parent.children.indexOf(this);

  /// Inserts `child` into children at `index`
  void insertChildAt(FormatusNode child, int index) {
    child.parent = this;
    (index <= 0)
        ? children.insert(0, child)
        : (index >= children.length)
        ? children.add(child)
        : children.insert(index, child);
  }

  bool get isAnchor => tag == .anchor;

  bool get isEmpty => children.isEmpty;

  bool get isHeader => tag.isHeader;

  bool get isImage => tag == .image;

  /// Returns `true` if this node is a link, an image or just text
  bool get isLeaf => isText || isAnchor || isImage;

  bool get isRoot => tag == .root;

  /// Returns `true` if this node is a header (1..3) or a paragraph
  bool get isSection => tag.isSection;

  /// Returns `true` if this node is a section or part of a list structure
  bool get isStructural =>
      isSection ||
      <Formatus>[.listItem, .orderedList, .unorderedList].contains(tag);

  bool get isText => tag == .text;

  /// Length of text
  int get length => text.length;

  /// Returns `true` if this node has the same formats in no specific order
  /// and the same color
  bool matchesFormatsAndColor(Set<Formatus> formats, Color color) {
    final currentFormats = this.formats;
    return currentFormats.length == formats.length &&
        currentFormats.containsAll(formats) &&
        findColor == color;
  }

  /// List of nodes starting with section below root until this node (excluded)
  List<FormatusNode> get path => (tag == .root)
      ? []
      : (tag == .text)
      ? parent.path
      : [...parent.path, this];

  void replaceChild({required FormatusNode prev, required FormatusNode next}) {
    int index = children.indexOf(prev);
    if (index >= 0) {
      children.removeAt(index);
      children.insert(index, next);
      next.parent = this;
    }
  }

  /// Get section of this node by moving up the tree
  FormatusNode get section => isSection ? this : parent.section;

  /// Split this node by moving either its `head` (0 to `textIndex0`)
  /// or its `tail` (`textIndex1` to end) to a new node.
  /// Returns the new node and inserts it depending on `insert`
  FormatusNode split(SplitPosition where, {SplitInsert insert = .never}) {
    FormatusNode splitNode = copy;
    int parentIndex = -1;
    if (where == .head) {
      int begin = textIndex0.clamp(0, length);
      splitNode.text = text.substring(0, begin);
      text = text.substring(begin);
      textIndex1 = (textIndex1 - begin).clamp(0, length);
      textIndex0 = 0;
      parentIndex = indexInParent;
    } else {
      int end = textIndex1.clamp(0, length);
      splitNode.text = text.substring(end);
      text = text.substring(0, end);
      textIndex1 = length;
      parentIndex = indexInParent + 1;
    }
    if ((insert == .always) ||
        ((insert == .ifNotEmpty) && splitNode.text.isNotEmpty)) {
      parent.insertChildAt(splitNode, parentIndex);
    }
    return splitNode;
  }

  /// Get list-item or section by moving up the tree
  FormatusNode get topNode =>
      isSection || tag == .listItem ? this : parent.topNode;

  /// Get closing tag. Image is already self-closed
  String get toClosing => tag == .image ? '' : '</${tag.key}>';

  String get toOpening {
    if (tag == .text) return '';
    String open = '<${tag.key}';
    if (tag == .anchor) return '$open href="$attribute">$text';
    if (tag == .color) open += ' style="color: ${colorToHex(color)};"';
    if (tag == .image) {
      String aria = ariaLabel.isEmpty ? '' : ' aria-label="$ariaLabel"';
      return '$open src="$attribute"$aria/>';
    }
    return '$open>';
  }

  ///
  @override
  String toString() {
    String str = toOpening;
    str += textIndex0 >= 0 ? ' [$textIndex0' : '';
    str += (textIndex1 > 0 && textIndex1 < length) ? ',$textIndex1]' : '';
    str += text.isEmpty ? '' : '→"$text"';
    return str;
  }
}

///
/// Base state of a Formatus point in time.
///
/// TODO implement undo / redo based on this class
///
/// * `formatted` → string for persistency
/// * `range` → start and end of selected text
///
class FormatusBaseState {
  /// Formatted text for persistency
  String formatted = '';

  /// Cursor position. Collapsed or a range
  TextSelection range = TextSelection.collapsed(offset: 0);

  /// Returns `true` if cursor position is collapsed
  bool get isCollapsed => range.isCollapsed;
}

///
/// Input from [FormatusBar] and [TextField]
///
/// * `color` → selected by user in [FormatusBar]
/// * `formats` → selected by user in [FormatusBar]
/// * 'plainText` → input for Flutter [TextField]
///
class FormatusInput extends FormatusBaseState {
  /// Color of [FormatusBar]
  Color color = Colors.transparent;

  /// Formats
  Set<Formatus> formats = {};

  /// Plain text of [TextEditingController]
  String plainText = '';
}

///
/// Output used to compute colors, formats, selection
///
/// * `root` → like &lt;body> of HTML content
/// * `textSpan4Editor` → rendered input for Flutter [TextField]
/// * `textSpan4Viewer` → rendered input for [FormatusViewer]
///
class FormatusOutput extends FormatusInput {
  /// Root node of tree computed from [FormatusBaseState.formatted]
  FormatusNode root = FormatusNode(tag: .placeHolder);

  /// Segments laid out exactly as `plainText`
  List<FormatusSegment> segments = [];

  /// [TextSpan] for [TextField]. Children are sections separated by `\n`
  TextSpan textSpan4Editor = TextSpan(text: '');

  /// [TextSpan] for [FormatusViewer]. Children are sections separated by `\n`
  TextSpan textSpan4Viewer = TextSpan(text: '');
}

///
/// One addressable unit in document order, laid out exactly as
/// [FormatusInput.plainText] as computed by [FormatusResults].
/// Used by [findNodeAtCursor] and [collectNodesWithTextInRange] so both use
/// the identical position model.
///
class FormatusSegment {
  final FormatusNode? leaf; // text / anchor / image node
  final FormatusNode? prefixOwner; // list-item node, for its prefix span
  final int start;
  final int end; // exclusive; == start for a separator

  const FormatusSegment.leaf(this.leaf, this.start, this.end)
    : prefixOwner = null;

  const FormatusSegment.prefix(this.prefixOwner, this.start, this.end)
    : leaf = null;

  const FormatusSegment.separator(int pos)
    : leaf = null,
      prefixOwner = null,
      start = pos,
      end = pos;
}

/// Specifies insert of a split node
enum SplitInsert {
  /// Insert split node in parent even if it has no text
  always,

  /// Insert split node in parent if it contains text
  ifNotEmpty,

  /// Only return split node
  never,
}

/// Specifies split position of a node
enum SplitPosition {
  /// Creates a new node from current text substring ending at `textIndex0`
  /// and inserts it before the current one.
  /// Current node text is reduced to its trailing part.
  head,

  /// Creates a new node from current text substring starting at `textIndex1`
  /// and inserts the new node behind the current one
  /// Current node text is reduced to its leading part.
  tail,
}
