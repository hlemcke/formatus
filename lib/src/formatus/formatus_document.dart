import 'package:flutter/material.dart';

import 'formatus_controller_impl.dart';
import 'formatus_model.dart';
import 'formatus_node.dart';
import 'formatus_parser.dart';
import 'formatus_results.dart';

///
/// HTML formatted document parsed into a tree-like structure.
///
/// Essentially the `body` tag of an html text.
/// All children are section elements like `h1` or `p`.
/// Section elements cannot contain other section elements.
///
/// ### Structure of [htmlBody]:
///
/// * always starts with an opening section element like "\<p>" or "\<h1>"
/// * always ends with a closing section element like "</p>"
/// * children of a section element are a list of inline elements
/// * inline elements could be text-nodes or formats like `<b>` for bold
/// * inline elements can be nested
///
/// ### Structure of an html element
///
/// * opening element starts with `<` followed by name, optional attributes
///   and the closing `>`
/// * multiple attributes are separated by a single space
/// * an `attribute` is a key value pair like `color="#00a400"`
/// * a closing element has no attributes
///
class FormatusDocument {
  /// Internal constructor
  FormatusDocument._();

  factory FormatusDocument.empty() {
    FormatusDocument doc = FormatusDocument._();
    doc.clear();
    return doc;
  }

  ///
  /// Creates a new instance from given `formatted` text
  ///
  factory FormatusDocument({
    required String formatted,
    bool forViewer = false,
  }) {
    FormatusDocument doc = FormatusDocument._();
    doc.forViewer = forViewer;
    doc.textNodes = FormatusParser(formatted: formatted).parse();
    doc.computeResults();
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })

  /// `true` will use [WidgetSpan] for subscript and superscript
  bool forViewer = false;

  /// Updated by [computeResults]
  FormatusResults results = FormatusResults(
    textNodes: [FormatusNode.placeHolder],
  );

  /// List of text nodes in sequence of occurrence
  List<FormatusNode> textNodes = [];

  ///
  /// Clears document by setting an empty text-node into a _paragraph_.
  ///
  void clear() {
    textNodes.clear();
    FormatusNode para = FormatusNode(formats: [Formatus.paragraph], text: '');
    textNodes.add(para);
    computeResults();
  }

  ///
  /// Applies `formatus` to `node` identified by `nodeIndex`.
  /// `start` and `end` specify the part of the text to be formatted.
  /// Returns number of new text-nodes:
  ///
  /// * 0 = format applied to full text or nothing changed at all
  /// * 1 = format applied to head or tail
  /// * 2 = format applied to range within text
  ///
  int applyFormatToNode(
    int nodeIndex,
    bool apply,
    Formatus formatus,
    Color color,
    int start,
    int end,
  ) {
    if (start == end) return 0;
    FormatusNode node = textNodes[nodeIndex];

    if (start <= 0) {
      //--- apply format to full node
      if (end >= node.length) {
        node.applyFormat(apply, formatus, color);
        return 0;
      }

      //--- apply format to head -> create tail with current format
      FormatusNode tail = node.clone();
      tail.text = tail.text.substring(end);
      textNodes.insert(nodeIndex + 1, tail);
      node.text = node.text.substring(0, end);
      node.applyFormat(apply, formatus, color);
      return 1;
    }

    //--- apply format to tail
    if (end >= node.length) {
      FormatusNode head = node.clone();
      head.text = head.text.substring(0, start);
      textNodes.insert(nodeIndex, head);
      node.text = node.text.substring(start);
      node.applyFormat(apply, formatus, color);
      return 1;
    }

    //--- apply format to range inside text
    FormatusNode head = node.clone();
    head.text = head.text.substring(0, start);
    textNodes.insert(nodeIndex, head);
    FormatusNode tail = node.clone();
    tail.text = tail.text.substring(end);
    textNodes.insert(nodeIndex + 2, tail);
    node.text = node.text.substring(start, end);
    node.applyFormat(apply, formatus, color);
    return 2;
  }

  ///
  /// Returns meta information about node found at `charIndex`
  ///
  NodeMeta computeMeta(int charIndex) {
    //--- in front of all text
    if (charIndex < 0) {
      return NodeMeta()
        ..node = textNodes[0]
        ..nodeIndex = 0
        ..textBegin = 0
        ..textOffset = 0;
    }
    //--- behind all text
    if (charIndex >= results.plainText.length) {
      FormatusNode last = textNodes.last;
      return NodeMeta()
        ..node = last
        ..nodeIndex = textNodes.length - 1
        ..textBegin = results.plainText.length - last.length
        ..textOffset = last.length;
    }
    int charCount = 0;
    int listPrefixes = 0;
    int nodeIndex = 0;
    int nodeLength = 0;
    while (nodeIndex < textNodes.length) {
      listPrefixes += textNodes[nodeIndex].section.isList ? 1 : 0;
      nodeLength = textNodes[nodeIndex].length;
      if (charIndex <= (charCount + listPrefixes + nodeLength)) {
        break;
      }
      charCount += nodeLength;
      nodeIndex++;
    }

    //--- Advance to next node if:
    // a) there is a next node
    // b) next node has same section format
    // c) cursor is at end of this node
    // d) last char of this node is a space
    int textOffset = (charIndex - (charCount + listPrefixes)).clamp(
      0,
      nodeLength,
    );
    FormatusNode node = textNodes[nodeIndex];
    if (node.isLineFeed ||
        ((nodeIndex < textNodes.length - 1) &&
            node.section == textNodes[nodeIndex + 1].section &&
            (node.length > 0) &&
            (node.length == textOffset) &&
            (node.text[textOffset - 1] == ' '))) {
      charCount = charIndex + textOffset;
      nodeIndex++;
      textOffset = 0;
    }

    return NodeMeta()
      ..node = textNodes[nodeIndex]
      ..nodeIndex = nodeIndex
      ..textBegin = charCount + listPrefixes
      ..textOffset = textOffset;
  }

  ///
  /// Computes `TextSpan' for [TextField] and `formattedText`
  ///
  void computeResults() =>
      results = FormatusResults(textNodes: textNodes, forViewer: forViewer);

  ///
  /// Inserts [newNode] at `offset` in _node_
  ///
  void insertNewNode(NodeMeta meta, FormatusNode newNode) {
    if (meta.textOffset <= 0) {
      textNodes.insert(meta.nodeIndex, newNode);
    } else if (meta.textOffset >= meta.length) {
      textNodes.insert(meta.nodeIndex + 1, newNode);
    } else {
      FormatusNode node = textNodes[meta.nodeIndex];
      FormatusNode clone = node.clone();
      node.text = node.text.substring(0, meta.textOffset);
      clone.text = clone.text.substring(meta.textOffset);
      textNodes.insert(meta.nodeIndex + 1, clone);
      textNodes.insert(meta.nodeIndex + 1, newNode);
    }
  }

  ///
  /// Apply [formatus] to selected text-range.
  ///
  /// If __all__ nodes in range have [formatus]` set then it will be removed.
  /// Otherwise [formatus] will be set in all nodes.
  ///
  void updateInlineFormat(
    TextSelection selection,
    Formatus formatus, {
    Color color = Colors.transparent,
  }) {
    if (selection.isCollapsed) return;

    //--- Determine first and last text-node from selection
    NodeMeta headMeta = computeMeta(selection.start);
    NodeMeta tailMeta = computeMeta(selection.end);

    //--- true sets format, false removes it
    bool apply = !_allNodesContainFormat(
      headMeta.nodeIndex,
      tailMeta.nodeIndex,
      formatus,
      color,
    );

    //--- Split tail to update only first part
    if ((0 < tailMeta.textOffset) && (tailMeta.textOffset < tailMeta.length)) {
      FormatusNode clone = tailMeta.node.clone();
      textNodes.insert(tailMeta.nodeIndex + 1, clone);
      clone.text = clone.text.substring(tailMeta.textOffset);
      tailMeta.node.text = tailMeta.node.text.substring(0, tailMeta.textOffset);
    }

    //--- Split head to update only second part
    if ((0 < headMeta.textOffset) && (headMeta.textOffset < headMeta.length)) {
      FormatusNode clone = headMeta.node.clone();
      textNodes.insert(headMeta.nodeIndex, clone);
      clone.text = clone.text.substring(0, headMeta.textOffset);
      headMeta.node.text = headMeta.node.text.substring(headMeta.textOffset);
      headMeta.nodeIndex++;
      tailMeta.nodeIndex++;
    }

    //--- Update nodes between head and tail
    for (int i = headMeta.nodeIndex; i <= tailMeta.nodeIndex; i++) {
      textNodes[i].applyFormat(apply, formatus, color);
    }
    return computeResults();
  }

  ///
  /// Updates section format of all nodes in all sections of selected text range
  ///
  void updateSectionFormat(TextSelection selection, Formatus newSectionFormat) {
    //--- Determine first and last text-node from selection
    NodeMeta headMeta = computeMeta(selection.start);
    NodeMeta tailMeta = computeMeta(selection.end);
    _updateSectionsUntilLineFeed(newSectionFormat, tailMeta.nodeIndex, 1);

    //--- Update all nodes backwards from tail to head
    for (int i = tailMeta.nodeIndex; i >= headMeta.nodeIndex; i--) {
      if (textNodes[i].isLineFeed) {
        textNodes.removeAt(i);
      } else {
        textNodes[i].section = newSectionFormat;
      }
    }

    //--- Update section backwards until linefeed
    _updateSectionsUntilLineFeed(newSectionFormat, headMeta.nodeIndex, -1);
    computeResults();
  }

  ///
  /// Handles all cases of modified text
  ///
  void updateText(
    DeltaText deltaText,
    Set<Formatus> formats, {
    Color color = Colors.transparent,
  }) {
    if (deltaText.textAdded == '\n') {
      _handleLineBreakInsert(deltaText);
      return computeResults();
    }

    if (deltaText.textRemoved == '\n') {
      _handleLineBreakDelete(deltaText);
      return computeResults();
    }

    if (deltaText.isAll) {
      Formatus section = textNodes[0].section;
      clear();
      textNodes[0].text = deltaText.textAdded;
      if (deltaText.textAdded.isNotEmpty) {
        textNodes[0].section = section;
      }
      return computeResults();
    }

    //--- Preparations
    NodeMeta headMeta = computeMeta(deltaText.headLength);
    FormatusNode headNode = headMeta.node;
    NodeMeta tailMeta = computeMeta(deltaText.tailOffset);

    //--- Delete all nodes between head and tail
    for (int i = headMeta.nodeIndex + 1; i < tailMeta.nodeIndex; i++) {
      textNodes.removeAt(i);
    }

    //--- head and tail are different nodes => append trailing text from tail then remove it
    if (tailMeta.nodeIndex > headMeta.nodeIndex) {
      headNode.text = headNode.text.substring(0, headMeta.textOffset);
      headNode.text += tailMeta.node.text.substring(tailMeta.textOffset);
      textNodes.remove(tailMeta.node);
      _updateSectionsUntilLineFeed(headNode.section, headMeta.nodeIndex, 1);
    }
    //--- head and tail are same node => delete text in middle (if any)
    else {
      headNode.text =
          headNode.text.substring(0, headMeta.textOffset) +
          headNode.text.substring(tailMeta.textOffset);
    }

    //--- text added
    if (deltaText.textAdded.isNotEmpty) {
      //--- new text has same formats => just insert it
      Set<Formatus> headFormats = headNode.formats.toSet();
      if (formats.containsAll(headFormats) &&
          headFormats.containsAll(formats) &&
          (color == headNode.color)) {
        headNode.text =
            headNode.text.substring(0, headMeta.textOffset) +
            deltaText.textAdded +
            headNode.text.substring(headMeta.textOffset);
      } else {
        int nodeIndex = _splitNode(headMeta);
        FormatusNode newNode = FormatusNode(
          formats: [],
          text: deltaText.textAdded,
        );
        newNode.mixFormats(formats, selectedColor: color);
        textNodes.insert(nodeIndex, newNode);
      }
    }
    computeResults();
  }

  /// Returns `true` if all nodes in range contain given format
  bool _allNodesContainFormat(
    int headIndex,
    int tailIndex,
    Formatus formatus,
    Color? color,
  ) {
    for (int i = headIndex; i <= tailIndex; i++) {
      if (!textNodes[i].formats.contains(formatus)) return false;
      if ((formatus == Formatus.color) && !(textNodes[i].color == color)) {
        return false;
      }
    }
    return true;
  }

  /// Sets section format taken from `textNodes[nodeIndex]` of nodes
  /// in [direction] until linefeed.
  void _updateSectionsUntilLineFeed(
    Formatus section,
    int nodeIndex,
    int direction,
  ) {
    assert(direction == 1 || direction == -1);
    for (
      int i = nodeIndex + direction;
      (i >= 0) && (i < textNodes.length) && textNodes[i].isNotLineFeed;
      i += direction
    ) {
      textNodes[i].section = section;
    }
  }

  /// Linebreak deleted => merge sections
  void _handleLineBreakDelete(DeltaText deltaText) {
    NodeMeta meta = computeMeta(deltaText.headLength);
    textNodes.removeAt(meta.nodeIndex + 1); // remove line-break node
    _updateSectionsUntilLineFeed(meta.node.section, meta.nodeIndex, 1);
  }

  ///
  /// Insert a line break
  ///
  /// * at start
  /// * at end
  /// * within a section
  /// * between sections
  ///
  void _handleLineBreakInsert(DeltaText deltaText) {
    int cursorIndex = deltaText.prevSelection.start;
    NodeMeta meta = computeMeta(cursorIndex);
    FormatusNode newNode = meta.node.isList
        ? FormatusNode(formats: [meta.node.section], text: '')
        : FormatusNode(formats: [Formatus.paragraph], text: '');

    if (deltaText.isAtStart) {
      // debugPrint('insert line break at start -> $meta');
      textNodes.insert(0, FormatusNode.lineBreak);
      textNodes.insert(0, newNode);
    } else if (deltaText.isAtEnd) {
      // debugPrint('insert line break at end -> $meta');
      textNodes.add(FormatusNode.lineBreak);
      textNodes.add(newNode);
    } else if (results.plainText[cursorIndex] == '\n') {
      // debugPrint('insert line break at end of section -> $meta');
      textNodes.insert(meta.nodeIndex + 1, FormatusNode.lineBreak);
      textNodes.insert(meta.nodeIndex + 2, newNode);
    } else if ((results.plainText[cursorIndex - 1] == '\n') ||
        (meta.node.isList && results.plainText[cursorIndex - 2] == '\n')) {
      // debugPrint('insert line break at start of section -> $meta');
      textNodes.insert(meta.nodeIndex, FormatusNode.lineBreak);
      textNodes.insert(meta.nodeIndex, newNode);
    } else {
      // debugPrint('insert line break in middle of node -> $meta');
      insertNewNode(meta, FormatusNode.lineBreak);
    }
  }

  ///
  /// Splits node identified by [NodeMeta.nodeIndex] at [NodeMeta.textOffset].
  /// Split only occurs if _textOffset_ is < 0 and smaller than length.
  /// Returns _nodeIndex_ if _textOffset_ is 0 else return _nodeIndex_ + 1.
  ///
  int _splitNode(NodeMeta meta) {
    int offset = meta.textOffset;
    if (offset <= 0) return meta.nodeIndex;
    if (offset >= meta.length) return meta.nodeIndex + 1;

    //--- Split node
    FormatusNode clone = meta.node.clone();
    clone.text = clone.text.substring(offset);
    meta.node.text = meta.node.text.substring(0, offset);
    textNodes.insert(meta.nodeIndex + 1, clone);
    return meta.nodeIndex + 1;
  }
}
