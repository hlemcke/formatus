import 'package:flutter/material.dart';
import 'package:formatus/src/formatus/formatus_tree.dart';

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
  /// List of text nodes in sequence of occurrence
  List<FormatusNode> textNodes = [];

  /// Single root element. All children are section elements
  FormatusNode root = FormatusNode();

  /// Internal constructor
  FormatusDocument._();

  factory FormatusDocument.empty() {
    FormatusDocument doc = FormatusDocument._();
    doc.clear();
    return doc;
  }

  /// Creates a new instance from the given html-text
  factory FormatusDocument.fromHtml({
    required String htmlBody,
  }) {
    String cleanedHtml = FormatusDocument.cleanUpHtml(htmlBody);
    if (cleanedHtml.isEmpty) return FormatusDocument.empty();
    if (!cleanedHtml.startsWith('<')) {
      cleanedHtml = '<p>$cleanedHtml';
    }
    FormatusDocument doc = FormatusDocument._();
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
  /// Clears the document tree by setting an empty text-node into a _paragraph_.
  ///
  void clear() {
    textNodes.clear();
    root = FormatusNode(format: Formatus.root);
    FormatusNode emptyTextNode =
        FormatusTree.createSubTree(textNodes, '', [Formatus.paragraph]);
    FormatusTree.appendChild(textNodes, root, emptyTextNode.top);
    textNodes.add(emptyTextNode);
  }

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
        FormatusNode newTextNode = FormatusTree.buildAndInsert(
            textNodes, nodeIndex, textNode.text, format.added, format.same, 1);
        FormatusTree.dispose(textNodes, textNode);
        FormatusTree.reduceNode(textNodes, newTextNode.parent!);
        return 0;
      }

      //--- apply format to head
      FormatusTree.buildAndInsert(textNodes, nodeIndex,
          textNode.text.substring(0, end), format.added, format.same, 0);
      textNode.text = textNode.text.substring(end);
      return 1;
    }

    //--- apply format to tail
    if (end >= textNode.length) {
      FormatusTree.buildAndInsert(textNodes, nodeIndex,
          textNode.text.substring(start), format.added, format.same, 1);
      textNode.text = textNode.text.substring(0, start);
      return 1;
    }

    //--- apply format to range inside text
    String headText = textNode.text.substring(0, start);
    String splitText = textNode.text.substring(start, end);
    String tailText = textNode.text.substring(end);
    textNode.text = headText;
    FormatusTree.buildAndInsert(
        textNodes, nodeIndex, splitText, format.added, format.same, 1);
    FormatusTree.buildAndInsert(
        textNodes, nodeIndex + 1, tailText, format.removed, format.same, 1);
    return 2;
  }

  ///
  /// Returns index of text-node which contains given `charIndex`
  ///
  int computeTextNodeIndex(int charIndex) =>
      FormatusTree.computeIndex(textNodes, _previousText, charIndex);

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
      FormatusTree.removeTextNodesAhead(textNodes, nodeIndex);
      String remains = textNode.text.isEmpty
          ? ''
          : textNode.text.substring(textNode.textOffset);
      textNode.text = diff.added + remains;
      if (textNode.isEmpty) FormatusTree.dispose(textNodes, textNode);
    } else if (diff.isAtEnd) {
      int nodeIndex = computeTextNodeIndex(diff.headText.length);
      FormatusNode textNode = textNodes[nodeIndex];
      FormatusTree.removeTextNodesBehind(textNodes, nodeIndex);
      textNode.text =
          textNode.text.substring(0, textNode.textOffset) + diff.added;
      if (textNode.isEmpty) FormatusTree.dispose(textNodes, textNode);
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
          FormatusTree.dispose(textNodes, leadNode);
        }
      }
      //--- Deletion covers multiple text-nodes
      else {
        //--- Adapt text-nodes
        FormatusNode tailNode = textNodes[tailNodeIndex];
        leadNode.text = leadNode.text.substring(0, leadOffset) + diff.added;
        tailNode.text = tailNode.text.substring(tailNode.textOffset);
        FormatusTree.removeTextNodesBetween(
            textNodes, leadNodeIndex + 1, tailNodeIndex);

        //--- Right side is another section element -> move children
        FormatusNode leadTopNode = leadNode.top;
        FormatusNode tailTopNode = tailNode.top;
        if (leadTopNode != tailTopNode) {
          int idx = tailNode.path[1].childIndexInParent;
          while (idx < tailTopNode.children.length) {
            FormatusNode node = tailTopNode.children.removeAt(idx);
            FormatusTree.appendChild(textNodes, leadTopNode, node);
          }
          FormatusTree.dispose(textNodes, tailTopNode);
        }
      }
    }
    toPlainText();
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
          FormatusNode tailTextNode =
              FormatusTree.createSubTree(textNodes, tailText, deltaFormat.same);
          FormatusTree.insertChild(textNodes, subTreeTop.parent!,
              subTreeTop.childIndexInParent + 1, tailTextNode.top);
          int textNodeIndex = textNodes.indexOf(textNode);
          textNodes.insert(textNodeIndex + 2, tailTextNode);
        }

        //--- Cleanup eventually empty lead node
        if (leadText.isEmpty) {
          FormatusTree.dispose(textNodes, textNode);
        }
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
        FormatusTree.getFirstDifferentNode(textNode, deltaFormat.same);
    FormatusNode sameFormatNode = firstDifferentNode.parent!;
    FormatusNode newSubTreeLeaf =
        FormatusTree.createSubTree(textNodes, added, deltaFormat.added);
    FormatusNode newSubTreeTop = newSubTreeLeaf.path[0];

    //--- Attach text-node to last format node and update list of text nodes
    int childIndex = firstDifferentNode.childIndexInParent;
    FormatusTree.insertChild(textNodes, sameFormatNode,
        before ? childIndex : childIndex + 1, newSubTreeTop);
    int textNodeIndex = textNodes.indexOf(textNode);
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
    int headTextOffset = textNodes[headTextIndex].textOffset;
    int tailTextIndex = computeTextNodeIndex(selection.end);
    int tailTextOffset = textNodes[tailTextIndex].textOffset;

    //--- Apply format to single node
    if (headTextIndex == tailTextIndex) {
      applyFormatToTextNode(
          format, headTextIndex, headTextOffset, tailTextOffset);
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
  /// -> attach children of right section element to left one
  void _handleLineBreakDelete(DeltaText deltaText) {
    int indexOfLineBreak = deltaText.headText.length;
    int leftTextNodeIndex = computeTextNodeIndex(indexOfLineBreak - 1);
    FormatusNode leftTopNode = textNodes[leftTextNodeIndex].top;
    int leftTopNodeIndex = leftTopNode.childIndexInParent;
    FormatusNode rightTopNode = root.children[leftTopNodeIndex + 1];
    FormatusTree.moveChildren(textNodes, rightTopNode, leftTopNode);
    root.children.removeAt(leftTopNodeIndex + 1);
  }

  /// Insert a line break -> at start, at end, within an element, between elements
  void _handleLineBreakInsert(DeltaText deltaText) {
    if (deltaText.isAtStart) {
      FormatusNode newNode =
          FormatusTree.createSubTree(textNodes, '', [Formatus.paragraph]);
      FormatusTree.insertChild(textNodes, root, 0, newNode.top);
      textNodes.insert(0, newNode);
    } else if (deltaText.isAtEnd) {
      FormatusNode newNode =
          FormatusTree.createSubTree(textNodes, '', [Formatus.paragraph]);
      FormatusTree.appendChild(textNodes, root, newNode.top);
      textNodes.add(newNode);
    } else if (_isLineBreakInsertedBetweenSectionElements(deltaText)) {
      //--- Insert new paragraph between the two section nodes
      int prevIndex = computeTextNodeIndex(deltaText.headText.length - 1);
      FormatusNode newTextNode =
          FormatusTree.createSubTree(textNodes, '', [Formatus.paragraph]);
      textNodes.insert(prevIndex + 1, newTextNode);
      int topLevelNodeIndex = textNodes[prevIndex].path[0].childIndexInParent;
      FormatusTree.insertChild(
          textNodes, root, topLevelNodeIndex + 1, newTextNode.top);
    } else {
      //--- Create new paragraph and fill with nodes right of split
      int splitNodeIndex = FormatusTree.computeIndex(
          textNodes, previousText, deltaText.headText.length);
      FormatusNode splitTextNode = textNodes[splitNodeIndex];
      FormatusNode splitTopNode = splitTextNode.top;
      int splitTopIndex = splitTopNode.childIndexInParent;
      String cut = splitTextNode.text.substring(splitTextNode.textOffset);
      if (cut.isNotEmpty) {
        splitTextNode.text =
            splitTextNode.text.substring(0, splitTextNode.textOffset);
      }

      //--- Create new paragraph after split section node
      List<Formatus> formatsInPath = splitTextNode.formatsInPath;
      formatsInPath[0] = Formatus.paragraph;
      FormatusNode newTextNode =
          FormatusTree.createSubTree(textNodes, cut, formatsInPath);
      FormatusNode newTopNode = newTextNode.top;
      FormatusTree.insertChild(textNodes, root, splitTopIndex + 1, newTopNode);

      //--- append nodes of split section to new paragraph
      int splitIndexBelowTopLevel = splitTextNode.path[1].childIndexInParent;
      for (int i = splitIndexBelowTopLevel + 1;
          i < splitTopNode.children.length;
          i++) {
        FormatusNode node = splitTopNode.children.removeAt(i);
        FormatusTree.appendChild(textNodes, newTopNode, node);
      }

      //--- Remove initially create "cut" node if its empty
      if (cut.isEmpty) {
        FormatusTree.dispose(textNodes, newTextNode);
      } else {
        textNodes.insert(splitNodeIndex + 1, newTextNode);
      }
    }
  }

  bool _isLineBreakInsertedBetweenSectionElements(DeltaText deltaText) {
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
          textNodes.removeAt(i + 1);
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
  /// Returns plain text with line breaks between section elements
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
}
