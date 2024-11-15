import 'package:flutter/material.dart';
import 'package:formatus/formatus.dart';

import 'formatus_node.dart';
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
  String get previousText => _previousText;
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
  /// Applies `format` to text-node given by `index`.
  /// `start` and `end` define the part of the text-node.
  ///
  /// Returns number of new text-nodes: 0 (format applied to full text),
  /// 1 (format applied to head or tail) or 2 (format applied to range within text).
  ///
  int applyFormatToTextNode(
      DeltaFormat format, int nodeIndex, int start, int end) {
    FormatusNode textNode = textNodes[nodeIndex];

    if (start <= 0) {
      //--- apply format to full node
      if (end >= textNode.length) {
        buildAndInsertTextNode(
            nodeIndex, textNode.text, format.added, '', format.same, 0);
        textNode.dispose();
        return 0;
      }

      //--- apply format to head
      buildAndInsertTextNode(nodeIndex, textNode.text.substring(0, end),
          format.added, textNode.text.substring(end), format.same, 0);
      return 1;
    }

    //--- apply format to tail
    if (end >= textNode.length) {
      buildAndInsertTextNode(nodeIndex, textNode.text.substring(start, end),
          format.added, textNode.text.substring(0, start), format.same, 1);
      return 1;
    }

    //--- apply format to range inside text
    String headText = textNode.text.substring(0, start);
    String splitText = textNode.text.substring(start, end);
    String tailText = textNode.text.substring(end);
    buildAndInsertTextNode(
        nodeIndex, splitText, format.added, headText, format.same, 1);
    buildAndInsertTextNode(
        nodeIndex + 1, tailText, format.removed, splitText, format.same, 1);
    return 2;
  }

  void buildAndInsertTextNode(
      int nodeIndex,
      String newText,
      List<Formatus> newFormat,
      String oldText,
      List<Formatus> sameFormat,
      int increment) {
    FormatusNode textNode = textNodes[nodeIndex];
    FormatusNode newNode = createSubTree(newText, newFormat);
    FormatusNode diffNode = getFirstDifferentNode(textNode, sameFormat);
    int childIndex = diffNode.childIndexInParent + increment;
    diffNode.parent!.insertChild(childIndex, newNode.top);
    textNode.text = oldText;
    textNodes.insert(nodeIndex + increment, newNode);
  }

  ///
  /// Returns index of text-node which contains given `charIndex`
  ///
  int computeTextNodeIndex(int charIndex) =>
      textNodes.computeIndex(_previousText, charIndex);

  ///
  /// Creates a new subtree with text-node from `text` and parents from `formatPath`.
  /// Returns leaf of subtree (which is the new text-node).
  ///
  static FormatusNode createSubTree(String text, List<Formatus> formatPath) {
    if (formatPath.isEmpty) {
      FormatusNode textNode = FormatusNode(format: Formatus.text, text: text);
      return textNode;
    }
    FormatusNode node = FormatusNode(format: formatPath[0]);
    for (int i = 1; i < formatPath.length; i++) {
      FormatusNode child = FormatusNode(format: formatPath[i]);
      node.addChild(child);
      node = child;
    }
    FormatusNode textNode = FormatusNode(format: Formatus.text, text: text);
    node.addChild(textNode);
    return textNode;
  }

  ///
  /// Gets first different node in `textNode.path`.
  /// Its parent is the last node with same format.
  ///
  static FormatusNode getFirstDifferentNode(
      FormatusNode textNode, List<Formatus> sameFormats) {
    List<FormatusNode> path = textNode.path;
    int i = 0;
    while ((i < path.length) &&
        (i < sameFormats.length) &&
        (path[i].format == sameFormats[i])) {
      i++;
    }
    return path[i];
  }

  ///
  /// Handle cases for `delete` and `update`. A `DeltaFormat` cannot exist here!
  ///
  void handleDeleteAndUpdate(DeltaText diff) {
    //--- Line-break deleted
    if (previousText[diff.headText.length] == '\n') {
      _handleLineBreakDelete(diff);
    } else if (diff.isAtStart) {
      int nodeIndex =
          computeTextNodeIndex(_previousText.length - diff.tailText.length);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeBefore(nodeIndex);
      textNode.text = diff.added + textNode.text.substring(textNode.textOffset);
      if (textNode.isEmpty) textNode.dispose();
    } else if (diff.isAtEnd) {
      int nodeIndex = computeTextNodeIndex(diff.headText.length);
      FormatusNode textNode = textNodes[nodeIndex];
      textNodes.removeAfter(nodeIndex);
      textNode.text =
          textNode.text.substring(0, textNode.textOffset) + diff.added;
      if (textNode.isEmpty) textNode.dispose();
    } else {
      int leadNodeIndex = computeTextNodeIndex(diff.headText.length);
      FormatusNode leadNode = textNodes[leadNodeIndex];
      int leadOffset = leadNode.textOffset;
      int tailNodeIndex =
          computeTextNodeIndex(_previousText.length - diff.tailText.length);

      //--- Deletion or replacement within same node
      if (leadNodeIndex == tailNodeIndex) {
        String pre = leadNode.text.substring(0, leadOffset);
        String post = leadNode.text.substring(leadNode.textOffset);
        leadNode.text = pre + diff.added + post;
        if (leadNode.isEmpty) {
          leadNode.dispose();
        }
      }
      //--- Deletion covers multiple text-nodes
      else {
        //--- Adapt text-nodes
        FormatusNode tailNode = textNodes[tailNodeIndex];
        leadNode.text = leadNode.text.substring(0, leadOffset) + diff.added;
        tailNode.text = tailNode.text.substring(tailNode.textOffset);
        for (int i = leadNodeIndex + 1; i < tailNodeIndex; i++) {
          textNodes[i].text = '';
        }

        //--- Right side is another top-level element -> move children
        FormatusNode leadTopNode = leadNode.top;
        FormatusNode tailTopNode = tailNode.top;
        if (leadTopNode != tailTopNode) {
          int idx = tailNode.path[1].childIndexInParent;
          while (idx < tailTopNode.children.length) {
            FormatusNode node = tailTopNode.children.removeAt(idx);
            leadTopNode.addChild(node);
          }
          tailTopNode.dispose();
        }

        //--- Remove empty text-nodes
        for (int i = 0; i < textNodes.length; i++) {
          if (textNodes[i].isEmpty) {
            textNodes[i].dispose();
            textNodes.removeAt(i);
          }
        }
      }
    }
    _previousText = toPlainText();
  }

  ///
  /// Handle cases for `insert`
  ///
  void handleInsert(DeltaText deltaText, DeltaFormat deltaFormat) {
    FormatusNode textNode = FormatusNode();
    if (deltaText.added == '\n') {
      _handleLineBreakInsert(deltaText);
    } else if (deltaText.isAtStart) {
      textNode = textNodes.first;
      if (deltaFormat.hasDelta) {
        handleInsertWithDifferentFormat(
            textNode, deltaText.added, true, deltaFormat);
      } else {
        textNode.text = deltaText.added + textNode.text;
      }
    } else if (deltaText.isAtEnd) {
      textNode = textNodes.last;
      if (deltaFormat.hasDelta) {
        handleInsertWithDifferentFormat(
            textNode, deltaText.added, false, deltaFormat);
      } else {
        textNode.text = textNode.text + deltaText.added;
      }
    } else {
      int nodeIndex = computeTextNodeIndex(deltaText.headText.length);
      textNode = textNodes[nodeIndex];
      if (!deltaFormat.hasDelta) {
        textNode.text = textNode.text.substring(0, textNode.textOffset) +
            deltaText.added +
            textNode.text.substring(textNode.textOffset);
      }
      //--- Handle insert in middle with different format
      else {
        String leadText = textNode.text.substring(0, textNode.textOffset);
        String tailText = textNode.text.substring(textNode.textOffset);
        textNode.text = leadText;

        //--- Create and attach differently formatted nodes
        FormatusNode subTreeTop = handleInsertWithDifferentFormat(
            textNode, deltaText.added, false, deltaFormat);

        //--- Create and attach node with same format and rest of text
        if (tailText.isNotEmpty) {
          FormatusNode tailTextNode = createSubTree(tailText, deltaFormat.same);
          subTreeTop.parent?.insertChild(
              subTreeTop.childIndexInParent + 1, tailTextNode.top);
          int textNodeIndex = textNodes.textNodes.indexOf(textNode);
          textNodes.insert(textNodeIndex + 2, tailTextNode);
        }

        //--- Cleanup eventually empty lead node
        if (leadText.isEmpty) textNode.dispose();
      }
    }
    _previousText = toPlainText();
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
    FormatusNode newSubTreeLeaf = createSubTree(added, deltaFormat.added);
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
  /// Apply `deltaFormat` to selected text-range.
  ///
  void updateFormatOfSelection(DeltaFormat format, TextSelection selection) {
    if (selection.isCollapsed) return;

    //--- Determine first and last text-node from selection
    int headTextIndex = computeTextNodeIndex(selection.start);
    int tailTextIndex = computeTextNodeIndex(selection.end);

    //--- Apply format to single node
    if (headTextIndex == tailTextIndex) {
      applyFormatToTextNode(
          format, headTextIndex, selection.start, selection.end);
      return;
    }

    //--- Apply format to first text-node in selection
    headTextIndex += applyFormatToTextNode(
        format, headTextIndex, textNodes[headTextIndex].textOffset, 9999);

    //--- Apply format to last text-node in selection
    tailTextIndex -= applyFormatToTextNode(
        format, tailTextIndex, 0, textNodes[headTextIndex].textOffset);

    //--- Apply format to all nodes in between
    for (int i = headTextIndex; i < tailTextIndex; i++) {
      applyFormatToTextNode(format, i, 0, 9999);
    }
  }

  /// Delete a single line break
  /// -> attach children of right top-level element to left one
  void _handleLineBreakDelete(DeltaText deltaText) {
    int indexOfLineBreak = deltaText.headText.length;
    int leftTextNodeIndex = computeTextNodeIndex(indexOfLineBreak - 1);
    FormatusNode leftTopNode = textNodes[leftTextNodeIndex].top;
    int leftTopNodeIndex = leftTopNode.childIndexInParent;
    FormatusNode rightTopNode = root.children[leftTopNodeIndex + 1];
    while (rightTopNode.children.isNotEmpty) {
      FormatusNode rightChild = rightTopNode.children.removeAt(0);
      leftTopNode.addChild(rightChild);
      if (rightChild.format == Formatus.text) {
        textNodes.textNodes.remove(rightChild);
      }
    }
    root.children.removeAt(leftTopNodeIndex + 1);
  }

  /// Insert a line break -> at start, at end, within an element, between elements
  void _handleLineBreakInsert(DeltaText deltaText) {
    if (deltaText.isAtStart) {
      FormatusNode newNode = createSubTree(' ', [Formatus.paragraph]);
      root.insertChild(0, newNode.top);
      textNodes.insert(0, newNode);
    } else if (deltaText.isAtEnd) {
      FormatusNode newNode = createSubTree(' ', [Formatus.paragraph]);
      root.addChild(newNode.top);
      textNodes.add(newNode);
    } else if (_isLineBreakInsertedBetweenTopLevelElements(deltaText)) {
      //--- Insert new paragraph between the two top-level nodes
      int prevIndex = computeTextNodeIndex(deltaText.headText.length - 1);
      FormatusNode newTextNode = createSubTree(' ', [Formatus.paragraph]);
      textNodes.insert(prevIndex + 1, newTextNode);
      int topLevelNodeIndex = textNodes[prevIndex].path[0].childIndexInParent;
      root.insertChild(topLevelNodeIndex + 1, newTextNode.top);
    } else {
      //--- Create new paragraph and fill with nodes right of split
      int splitNodeIndex =
          textNodes.computeIndex(previousText, deltaText.headText.length);
      FormatusNode splitTextNode = textNodes[splitNodeIndex];
      FormatusNode splitTopNode = splitTextNode.top;
      int splitTopIndex = splitTopNode.childIndexInParent;
      String cut = splitTextNode.text.substring(splitTextNode.textOffset);
      if (cut.isNotEmpty) {
        splitTextNode.text =
            splitTextNode.text.substring(0, splitTextNode.textOffset);
      }

      //--- Create new paragraph after split top-level node
      List<Formatus> formatsInPath = splitTextNode.formatsInPath;
      formatsInPath[0] = Formatus.paragraph;
      FormatusNode newTextNode = createSubTree(cut, formatsInPath);
      FormatusNode newTopNode = newTextNode.top;
      root.insertChild(splitTopIndex + 1, newTopNode);

      //--- append nodes of split top-level to new paragraph
      int splitIndexBelowTopLevel = splitTextNode.path[1].childIndexInParent;
      for (int i = splitIndexBelowTopLevel + 1;
          i < splitTopNode.children.length;
          i++) {
        FormatusNode node = splitTopNode.children.removeAt(i);
        newTopNode.addChild(node);
      }

      //--- Remove initially create "cut" node if its empty
      if (cut.isEmpty) {
        newTextNode.dispose();
      } else {
        textNodes.insert(splitNodeIndex + 1, newTextNode);
      }
    }
  }

  bool _isLineBreakInsertedBetweenTopLevelElements(DeltaText deltaText) {
    int i = deltaText.headText.length;
    return ((previousText[i - 1] == '\n') || (previousText[i] == '\n'))
        ? true
        : false;
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
    FormatusNode emptyTextNode = createSubTree(' ', [Formatus.paragraph]);
    root = FormatusNode(format: Formatus.root);
    root.addChild(emptyTextNode.parent!);
    textNodes.clear();
    textNodes.textNodes.add(emptyTextNode);
  }
}
