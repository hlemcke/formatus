import 'package:flutter/widgets.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

///
/// Contains helper methods
///
class FormatusTree {
  /// Appends `child` to `children` of `parent`
  static void appendChild(List<FormatusNode> textNodes, FormatusNode parent,
          FormatusNode child) =>
      insertChild(textNodes, parent, parent.children.length, child);

  ///
  /// Builds a new text-node from `newText` having `newFormat`.
  /// Inserts the new text-node at `nodeIndex + increment` and returns it.
  ///
  static FormatusNode buildAndInsert(
      List<FormatusNode> textNodes,
      int nodeIndex,
      String newText,
      List<Formatus> newFormat,
      List<Formatus> sameFormat,
      int increment) {
    //--- Build new text-node and insert at nodeIndex + increment
    nodeIndex = (nodeIndex > textNodes.length) ? textNodes.length : nodeIndex;
    FormatusNode textNode = textNodes[nodeIndex];
    FormatusNode newTextNode = createSubTree(textNodes, newText, newFormat);
    textNodes.insert(nodeIndex + increment, newTextNode);

    //--- Integrate formats into tree
    FormatusNode diffNode = getFirstDifferentNode(textNode, sameFormat);
    int childIndex = diffNode.childIndexInParent + increment;
    insertChild(textNodes, diffNode.parent!, childIndex, newTextNode.top);
    return newTextNode;
  }

  ///
  /// Build [TextSpan] for [FormatusController] and [FormatusViewer]
  ///
  static TextSpan buildFormattedText(List<FormatusNode> childrenOfRoot) {
    List<TextSpan> spans = [];
    for (FormatusNode topLevelNode in childrenOfRoot) {
      spans.add(topLevelNode.toTextSpan());
      spans.add(const TextSpan(text: '\n'));
    }
    return TextSpan(children: spans);
  }

  ///
  /// Creates a new subtree with text-node from `text` and parents from `formatPath`.
  /// Returns leaf of subtree (which is the new text-node).
  ///
  static FormatusNode createSubTree(
      List<FormatusNode> textNodes, String text, List<Formatus> formatPath) {
    if (formatPath.isEmpty) {
      FormatusNode textNode = FormatusNode(format: Formatus.text, text: text);
      return textNode;
    }
    FormatusNode node = FormatusNode(format: formatPath[0]);
    for (int i = 1; i < formatPath.length; i++) {
      FormatusNode child = FormatusNode(format: formatPath[i]);
      appendChild(textNodes, node, child);
      node = child;
    }
    FormatusNode textNode = FormatusNode(format: Formatus.text, text: text);
    appendChild(textNodes, node, textNode);
    return textNode;
  }

  ///
  /// Returns index to text-node where `charIndex` <= sum of previous
  /// text-nodes plus current one.
  ///
  static int computeIndex(
    List<FormatusNode> textNodes,
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
          i = (i > 0) ? i - 1 : i;
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

  ///
  /// Removes `node` from tree.
  /// If parent becomes empty then it will be removed also.
  /// Removes all children including text-node leaves.
  ///
  static void dispose(List<FormatusNode> textNodes, FormatusNode node) {
    if (node.isRoot) return;
    node.text = '';
    if (node.isText) {
      textNodes.remove(node);
    }

    //--- Remove from parent
    FormatusNode parent = node.parent!;
    parent.children.remove(node);
    node.parent = null;

    //--- Remove children
    if (node.hasChildren) {
      disposeChildren(textNodes, node);
      node.children.clear();
    }

    //--- Go up the tree
    if (parent.children.isEmpty) {
      dispose(textNodes, parent);
    }
  }

  /// Disposes all text-nodes of any child of `node`
  static void disposeChildren(List<FormatusNode> textNodes, FormatusNode node) {
    for (FormatusNode child in node.children) {
      if (child.isText) {
        textNodes.remove(child);
      } else {
        dispose(textNodes, child);
      }
    }
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

  static void insertChild(List<FormatusNode> textNodes, FormatusNode parent,
      int index, FormatusNode child) {
    parent.children.insert(index, child);
    child.parent = parent;
    reduceNode(textNodes, parent);
  }

  ///
  /// Top-down reduction of nodes having identical formats.
  /// Section nodes will not be reduced.
  ///
  static void reduceTree(List<FormatusNode> textNodes, FormatusNode root) {
    for (FormatusNode topLevelNode in root.children) {
      reduceNode(textNodes, topLevelNode);
    }
  }

  ///
  /// Combines children of `node` if two of them have the same format
  ///
  static void reduceNode(List<FormatusNode> textNodes, FormatusNode node) {
    if (node.isRoot) return;
    for (int i = 0; i < node.children.length - 1; i++) {
      if (node.children[i].format == node.children[i + 1].format) {
        FormatusNode child = node.children[i];
        FormatusNode sibling = node.children[i + 1];
        if (child.isText) {
          child.text += sibling.text;
        } else {
          moveChildren(textNodes, sibling, child);
          reduceNode(textNodes, child);
        }
        dispose(textNodes, sibling);
      }
    }
  }

  static void moveChildren(
      List<FormatusNode> textNodes, FormatusNode source, FormatusNode target) {
    while (source.hasChildren) {
      appendChild(textNodes, target, source.children.removeAt(0));
    }
  }

  /// Removes text-nodes ahead of given `index` (exclusive).
  static void removeTextNodesAhead(List<FormatusNode> textNodes, int index) {
    for (int i = 0; i < index; i++) {
      dispose(textNodes, textNodes[i]);
    }
  }

  /// Removes text-nodes behind given `index` (exclusive).
  static void removeTextNodesBehind(List<FormatusNode> textNodes, int index) {
    while (textNodes.length > index + 1) {
      dispose(textNodes, textNodes.last);
    }
  }

  /// Removes text-nodes and all empty parents between `start` (inclusive)
  /// and `end` (exclusive).
  static void removeTextNodesBetween(
      List<FormatusNode> textNodes, int start, int end) {
    for (int i = start; i < end; i++) {
      dispose(textNodes, textNodes[start]);
    }
  }
}
