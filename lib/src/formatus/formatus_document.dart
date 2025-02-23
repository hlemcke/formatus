import 'package:flutter/material.dart';

import 'formatus_controller_impl.dart';
import 'formatus_model.dart';
import 'formatus_node.dart';
import 'formatus_parser.dart';

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
  }) {
    FormatusDocument doc = FormatusDocument._();
    if (formatted.isNotEmpty) {
      doc.textNodes = FormatusParser().parse(formatted);
    }
    doc.computeResults();
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })

  /// Updated by [computeResults]
  FormatusResults results = FormatusResults();

  /// List of text nodes in sequence of occurrence
  List<FormatusNode> textNodes = [];

  ///
  /// Clears the document tree by setting an empty text-node into a _paragraph_.
  ///
  void clear() {
    _setupEmptyDocument();
    computeResults();
  }

  ///
  /// Applies `format` to given `node`.
  /// `start` and `end` specify the part of the text-node to be formatted.
  /// Returns number of new text-nodes:
  ///
  /// * 0 = format applied to full text or nothing changed at all
  /// * 1 = format applied to head or tail
  /// * 2 = format applied to range within text
  ///
  int applyFormatsToTextNode(int nodeIndex, Set<Formatus> formats, int start,
      int end, String selectedColor) {
    if (start == end) return 0;
    FormatusNode node = textNodes[nodeIndex];

    if (start <= 0) {
      //--- apply format to full node
      if (end >= node.length) {
        node.applyFormats(formats, selectedColor);
        return 0;
      }

      //--- apply format to head -> create tail with current format
      FormatusNode tail = node.clone();
      tail.text = tail.text.substring(end);
      textNodes.insert(nodeIndex + 1, tail);
      node.text = node.text.substring(0, end);
      node.applyFormats(formats, selectedColor);
      return 1;
    }

    //--- apply format to tail
    if (end >= node.length) {
      FormatusNode head = node.clone();
      head.text = head.text.substring(0, start);
      textNodes.insert(nodeIndex, head);
      node.text = node.text.substring(start);
      node.applyFormats(formats, selectedColor);
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
    node.applyFormats(formats, selectedColor);
    return 2;
  }

  ///
  /// Returns meta information about node found at `charIndex`
  ///
  NodeMeta computeMeta(int charIndex) {
    if (charIndex >= results.plainText.length) {
      FormatusNode last = textNodes.last;
      return NodeMeta()
        ..node = last
        ..nodeIndex = textNodes.length - 1
        ..textBegin = results.plainText.length - last.length
        ..textOffset = last.length;
    }
    int charCount = 0;
    int nodeIndex = 0;
    while (nodeIndex < textNodes.length - 1) {
      if (charIndex < (charCount + textNodes[nodeIndex].length)) {
        break;
      }
      charCount += textNodes[nodeIndex].length;
      nodeIndex++;
    }

    //--- Back to previous node if:
    // a) there is a previous node
    // b) at start of this one (charCount == charIndex)
    // c) and previous is no LF or ends with space
    if ((nodeIndex > 0) &&
        (charCount == charIndex) &&
        textNodes[nodeIndex - 1].isNotLineBreak &&
        !textNodes[nodeIndex - 1].text.endsWith(' ')) {
      nodeIndex--;
      charCount -= textNodes[nodeIndex].length;
    }

    return NodeMeta()
      ..node = textNodes[nodeIndex]
      ..nodeIndex = nodeIndex
      ..textBegin = charCount
      ..textOffset = charIndex - charCount;
  }

  ///
  /// Computes `formattedText` and results for [TextField]
  ///
  void computeResults() => results = FormatusResults.fromNodes(textNodes);

  ///
  /// Apply `formats` to selected text-range.
  ///
  void updateInlineFormat(
      TextSelection selection, Set<Formatus> formats, String selectedColor) {
    if (selection.isCollapsed) return;

    //--- Determine first and last text-node from selection
    NodeMeta headMeta = computeMeta(selection.start);
    NodeMeta tailMeta = computeMeta(selection.end);

    //--- Apply format to single node
    if (headMeta.nodeIndex == tailMeta.nodeIndex) {
      applyFormatsToTextNode(headMeta.nodeIndex, formats, headMeta.textOffset,
          tailMeta.textOffset, selectedColor);
      computeResults();
      return;
    }

    //--- Apply format to first text-node in selection
    int firstNode = headMeta.nodeIndex +
        1 +
        applyFormatsToTextNode(headMeta.nodeIndex, formats, headMeta.textOffset,
            headMeta.node.length, selectedColor);

    //--- Apply format to last text-node in selection
    int lastNode = tailMeta.nodeIndex - 1;
    applyFormatsToTextNode(
        tailMeta.nodeIndex, formats, 0, tailMeta.textOffset, selectedColor);

    //--- Apply formats to all nodes in between
    for (int i = firstNode; i <= lastNode && i < textNodes.length; i++) {
      applyFormatsToTextNode(i, formats, 0, 9999, selectedColor);
    }
    computeResults();
  }

  ///
  /// Updates section format of all nodes in section identified by `cursorIndex`
  ///
  void updateSectionFormat(int cursorIndex, Formatus newSectionFormat) {
    NodeMeta meta = computeMeta(cursorIndex);
    Formatus oldSectionFormat = meta.node.formats[0];
    for (int i = meta.nodeIndex;
        (i > 0) && (textNodes[i].formats[0] == oldSectionFormat);
        i--) {
      textNodes[i].formats[0] = newSectionFormat;
    }
    _updateFollowingSections(meta.nodeIndex);
    computeResults();
  }

  ///
  /// Handle cases for modified text
  ///
  void updateText(
      DeltaText deltaText, Set<Formatus> formats, String selectedColor) {
    //--- Handle line break insert
    if (deltaText.textAdded == '\n') {
      _handleLineBreakInsert(deltaText);
      return computeResults();
    }
    if (deltaText.textRemoved == '\n') {
      _handleLineBreakDelete(deltaText);
      return computeResults();
    }

    if (deltaText.isAll) {
      _setupEmptyDocument();
      textNodes[0].text = deltaText.textAdded;
      return computeResults();
    }

    //--- Preparations
    NodeMeta metaStart = computeMeta(deltaText.headLength);
    NodeMeta metaEnd = computeMeta(deltaText.tailOffset);

    //--- change within same node
    if (metaStart.nodeIndex == metaEnd.nodeIndex) {
      FormatusNode node = metaStart.node;
      //--- Insert with different format
      if (deltaText.isInsert && !node.hasSameFormats(formats)) {
        FormatusNode newNode =
            FormatusNode(formats: formats.toList(), text: deltaText.textAdded);
        if (newNode.hasColor) {
          newNode.attribute = selectedColor;
        }
        if (metaStart.textOffset == 0) {
          textNodes.insert(metaStart.nodeIndex, newNode);
        } else if (metaStart.textOffset >= metaStart.length) {
          textNodes.insert(metaStart.nodeIndex + 1, newNode);
        } else {
          FormatusNode clone = node.clone();
          textNodes.insert(metaStart.nodeIndex, newNode);
          textNodes.insert(metaStart.nodeIndex, clone);
          clone.text = clone.text.substring(0, metaStart.textOffset);
          node.text = node.text.substring(metaStart.textOffset);
        }
      } else {
        node.text = node.text.substring(0, metaStart.textOffset) +
            deltaText.textAdded +
            node.text.substring(metaEnd.textOffset);
      }
    }

    //--- change covers multiple nodes
    else {
      int firstIndexToDelete = metaStart.nodeIndex + 1;
      int lastIndexToDelete = metaEnd.nodeIndex - 1;

      //--- cut text in start node or remove it completely
      FormatusNode startNode = metaStart.node;
      startNode.text = startNode.text.substring(0, metaStart.textOffset) +
          deltaText.textAdded;
      if (startNode.text.isEmpty) {
        firstIndexToDelete--;
      } else if (deltaText.isInsert) {
        applyFormatsToTextNode(metaStart.nodeIndex, formats,
            metaStart.textOffset, metaStart.node.length, selectedColor);
      }

      //--- cut text in last node or remove it completely
      FormatusNode endNode = metaEnd.node;
      endNode.text = endNode.text.substring(metaEnd.textOffset);
      if (endNode.text.isEmpty) {
        lastIndexToDelete++;
      }

      //--- remove nodes between
      int count = lastIndexToDelete + 1 - firstIndexToDelete;
      while (count > 0) {
        textNodes.removeAt(firstIndexToDelete);
        count--;
      }
      _updateFollowingSections(firstIndexToDelete - 1);
    }
    computeResults();
  }

  void _handleLineBreakDelete(DeltaText deltaText) {
    NodeMeta meta = computeMeta(deltaText.headLength);
    textNodes.removeAt(meta.nodeIndex + 1); // remove line-break node
    _updateFollowingSections(meta.nodeIndex);
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
    FormatusNode newNode =
        FormatusNode(formats: [Formatus.paragraph], text: '');

    if (deltaText.isAtStart) {
      // debugPrint('insert line break at start or end of section -> $meta');
      textNodes.insert(0, FormatusNode.lineBreak);
      textNodes.insert(0, newNode);
    } else if (deltaText.isAtEnd) {
      // debugPrint('insert line break at end');
      textNodes.add(FormatusNode.lineBreak);
      textNodes.add(newNode);
    } else if (results.plainText[cursorIndex] == '\n') {
      // debugPrint('insert line break at end of section -> $meta');
      textNodes.insert(meta.nodeIndex + 1, newNode);
      textNodes.insert(meta.nodeIndex + 1, FormatusNode.lineBreak);
    } else if (results.plainText[cursorIndex - 1] == '\n') {
      // debugPrint('insert line break in front of section -> $meta');
      textNodes.insert(meta.nodeIndex, FormatusNode.lineBreak);
      textNodes.insert(meta.nodeIndex, newNode);
    } else {
      // debugPrint('insert line break in middle of section -> $meta');
      if (meta.textOffset == 0) {
        textNodes.insert(meta.nodeIndex, FormatusNode.lineBreak);
      } else if (meta.textOffset >= meta.length) {
        textNodes.insert(meta.nodeIndex + 1, FormatusNode.lineBreak);
      } else {
        FormatusNode head = meta.node.clone();
        head.text = head.text.substring(0, meta.textOffset);
        textNodes.insert(meta.nodeIndex, head);
        textNodes.insert(meta.nodeIndex + 1, FormatusNode.lineBreak);
        meta.node.text = meta.node.text.substring(meta.textOffset);
      }
    }
  }

  ///
  void _setupEmptyDocument() {
    textNodes.clear();
    FormatusNode para = FormatusNode(formats: [Formatus.paragraph], text: '');
    textNodes.add(para);
  }

  ///
  /// Sets section format of following nodes to current one until line-break.
  ///
  /// If first following section has same format path as current one
  /// then it will be joined into current one.
  ///
  void _updateFollowingSections(int nodeIndex) {
    Formatus currentSection = textNodes[nodeIndex].formats[0];
    for (int i = nodeIndex + 1;
        i < textNodes.length && textNodes[i].isNotLineBreak;
        i++) {
      textNodes[i].formats[0] = currentSection;
    }
  }
}
