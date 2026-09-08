import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'formatus_controller_impl.dart';
import 'formatus_model.dart';
import 'formatus_node.dart';
import 'formatus_parser.dart';
import 'formatus_results.dart';

///
/// HTML formatted document parsed into a tree-like structure.
///
/// This document represents the `body` tag of an html text.
/// All children are section elements like `h1` or `p`.
/// Section elements cannot contain other section elements.
///
/// Does **not** extend [FormatusNode] anymore. The tree's root node lives
/// in [results] (`results.root` / [FormatusOutput.root]) so that document
/// and output always share the exact same object graph instead of the
/// document duplicating itself as an extra node.
///
class FormatusDocument {
  /// Internal constructor
  FormatusDocument._();

  factory FormatusDocument.empty() {
    FormatusDocument doc = FormatusDocument._();
    doc.results.root = FormatusNode.root();
    return doc;
  }

  ///
  /// Creates a new instance from `formatted` text
  ///
  factory FormatusDocument({required String formatted}) {
    FormatusDocument doc = FormatusDocument._();
    doc.results.root = FormatusParser(formatted: formatted).root;
    doc.computeResultsAt(0);
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })

  /// Root node of the tree. Delegates to `results.root`.
  FormatusNode get root => results.root;

  /// Return child of root-node at index
  FormatusNode operator [](int index) => root.children[index];

  /// Set child of root-node at index
  void operator []=(int index, FormatusNode node) =>
      root.children[index] = node;

  /// Updated by [computeResults] / [computeResultsAt] / [compute]
  final FormatusOutput results = FormatusOutput();

  /// Check if all `nodes` have the same `format` anywhere up the tree
  bool allHaveFormat(List<FormatusNode> nodes, Formatus format) =>
      nodes.every((n) => n.formats.contains(format));

  /// Number of children in root-node
  int get childCount => root.childCount;

  ///
  /// Clears document by setting an empty text-node into a _paragraph_.
  ///
  void clear() {
    _setupEmptyRoot();
    computeResultsAt(0);
  }

  @visibleForTesting
  List<FormatusNode> get collectAllNodesWithText => collectNodesWithTextInRange(
    TextSelection(baseOffset: 0, extentOffset: results.plainText.length),
  );

  List<FormatusNode> collectNodesWithTextInRange(TextSelection selection) {
    //--- Fresh position map reflecting the tree as it stands right now.
    //--- Stale textIndex0/1 from earlier lookups are cleared globally by
    //--- FormatusResults.compute(), not here -- see class doc there.
    final segments = FormatusResults.buildSegments(root);
    final int textLength = results.plainText.length;
    final int selStart = selection.start.clamp(0, textLength);
    final int selEnd = selection.end.clamp(0, textLength);
    final found = <FormatusNode>[];
    FormatusNode lastLeaf = FormatusNode.placeHolder;

    for (final seg in segments) {
      if (seg.leaf != null) lastLeaf = seg.leaf!;

      final int nodeStart = seg.start;
      final int nodeEnd = seg.end;

      if (nodeEnd <= selStart) continue; // before selection -> skip
      if (nodeStart > selEnd) break; // past selection -> done

      if (seg.leaf != null) {
        final leaf = seg.leaf!;
        found.add(leaf);
        leaf.textIndex0 = (selStart - nodeStart).clamp(0, leaf.length);
        leaf.textIndex1 = (selEnd - nodeStart).clamp(0, leaf.length);
        if (selEnd <= nodeEnd) break;
      } else if (seg.prefixOwner != null) {
        if (seg.prefixOwner!.text.isNotEmpty) {
          found.add(seg.prefixOwner!);
        }
      }
      //--- separators carry no node, nothing to collect
    }

    if (found.isEmpty) {
      lastLeaf.textIndex0 = lastLeaf.length;
      lastLeaf.textIndex1 = lastLeaf.length;
      found.add(lastLeaf);
    }

    return found;
  }

  ///
  /// Compute common color and formats of text-nodes in the selected range
  /// (`output.rangeBegin`..`output.rangeEnd`) and write them directly into
  /// `output.formats` / `output.color`.
  ///
  void commonFormatsAndColor(FormatusOutput output) {
    List<FormatusNode> textNodes = collectNodesWithTextInRange(output.range);
    Color color = textNodes[0].findColor;
    Set<Formatus> formats = textNodes[0].formats;

    //--- remove formats which do not exist in following node-paths
    for (int i = 1; i < textNodes.length; i++) {
      Set<Formatus> nodeFormats = textNodes[i].formats;
      formats.retainWhere((f) => nodeFormats.contains(f));
      color = (color == Colors.transparent)
          ? Colors.transparent
          : (color == textNodes[i].findColor)
          ? color
          : Colors.transparent;
    }
    output.formats = formats;
    output.color = color;
  }

  ///
  /// Single entry point used by [FormatusControllerImpl].
  ///
  /// Classifies `input` against `previous`:
  /// * `plainText` differs             -> text was edited
  /// * `formats`/`color` differ        -> a format or color was toggled
  /// * otherwise                       -> cursor moved / range selected
  ///
  /// Mutates the tree accordingly (or not at all, for a pure selection
  /// change), then returns [results] with range/formats/color refreshed
  /// to reflect `input`'s selection.
  ///
  FormatusOutput compute(FormatusInput input, FormatusOutput previous) {
    if (input.plainText != previous.plainText) {
      _applyTextInput(input, previous);
    } else if (input.formats.length != previous.formats.length ||
        !input.formats.containsAll(previous.formats) ||
        input.color != previous.color) {
      _applyFormatInput(input, previous);
    }
    //--- else: pure cursor repositioning / range selection -> tree is
    //--- untouched, results.* from the last mutation are still current
    results.range = input.range;
    commonFormatsAndColor(results);
    return results;
  }

  /// Text was edited: derive the classic [DeltaText] from previous/next
  /// plainText + selection and feed it into the existing insert/delete/
  /// update logic, unchanged.
  void _applyTextInput(FormatusInput input, FormatusOutput previous) {
    final DeltaText deltaText = DeltaText(
      prevText: previous.plainText,
      prevSelection: previous.range,
      nextText: input.plainText,
      nextSelection: input.range,
    );
    updateText(deltaText, input.formats, color: input.color);
  }

  /// A format or color was toggled: diff `input.formats`/`input.color`
  /// against `previous` and apply/remove exactly what changed. Section
  /// formats (header/paragraph) replace rather than wrap.
  void _applyFormatInput(FormatusInput input, FormatusOutput previous) {
    if (input.color != previous.color) {
      updateInlineFormat(
        input.range,
        Formatus.color,
        input.color != Colors.transparent,
        color: input.color,
      );
    }

    final Set<Formatus> added = input.formats.difference(previous.formats);
    final Set<Formatus> removed = previous.formats.difference(input.formats);

    for (final Formatus format in added) {
      if (format == Formatus.color) continue; // handled above
      if (format.isSection) {
        updateSectionFormat(input.range, format);
      } else {
        updateInlineFormat(input.range, format, true);
      }
    }
    for (final Formatus format in removed) {
      if (format.isSection || format == Formatus.color) continue;
      updateInlineFormat(input.range, format, false);
    }
  }

  ///
  /// Condense tree and (re)compute [results] from the tree.
  /// Range, formats and color on [results] are left as-is.
  ///
  void computeResults() {
    condenseTree(root);
    FormatusResults(output: results).compute();
  }

  /// Convenience for callers that mutate via a bare cursor position
  /// (anchor/image insertion, initial parse, clear) rather than a full
  /// [FormatusInput]: recomputes [results] with a collapsed selection at
  /// `curPos` and its common format/color.
  FormatusOutput computeResultsAt(int curPos) {
    computeResults();
    results.range = TextSelection.collapsed(offset: curPos);
    commonFormatsAndColor(results);
    return results;
  }

  ///
  /// Tree optimizer. Bottom-up, in three steps per level:
  /// 1. Recurse into every child first, so each child's own subtree is
  ///    already fully condensed before it's compared against its siblings.
  /// 2. Prune inline nodes which ended up with zero children (structural
  ///    nodes like sections and list-items are never pruned, and text
  ///    nodes may legitimately be empty as placeholders).
  /// 3. Merge adjacent mergeable siblings in one left-to-right pass.
  ///
  void condenseTree(FormatusNode node) {
    //--- Step 1: fully condense each child's subtree first
    for (final child in node.children) {
      condenseTree(child);
    }

    //--- Step 2: drop inline nodes that ended up empty
    node.children.removeWhere(
      (child) => child.isEmpty && !child.isLeaf && !child.isStructural,
    );

    //--- Step 3: merge adjacent siblings
    _mergeAdjacentChildren(node);
  }

  /// Merges adjacent mergeable children of `node` in a single pass.
  void _mergeAdjacentChildren(FormatusNode node) {
    int i = 0;
    while (i < node.childCount - 1) {
      FormatusNode child = node[i];
      FormatusNode nextSibling = node[i + 1];

      if (!_canMerge(child, nextSibling)) {
        i++;
        continue;
      }

      if (child.isText) {
        child.text += nextSibling.text;
      } else {
        for (final grandChild in List<FormatusNode>.from(
          nextSibling.children,
        )) {
          child.appendChild(grandChild);
        }
        _mergeAdjacentChildren(child);
      }
      node.children.removeAt(i + 1);
    }
  }

  void deleteAndReplaceText(
    DeltaText deltaText,
    Set<Formatus> formats,
    Color color,
  ) {
    //--- Handle deletion and replacement
    List<FormatusNode> affected = collectNodesWithTextInRange(
      deltaText.removedRange,
    );
    FormatusNode firstNode = affected.first;
    FormatusNode lastNode = affected.last;
    FormatusNode startTop = firstNode.topNode;
    FormatusNode endTop = lastNode.topNode;

    //--- Keep tail if last node is split
    firstNode.split(.head, insert: .ifNotEmpty);
    lastNode.split(.tail, insert: .ifNotEmpty);

    //--- Merge sections/list items if deletion crossed linebreaks (\n)
    if (startTop != endTop) {
      int startIndex = startTop.indexInParent;
      int endIndex = endTop.indexInParent;

      // Move remaining children from endTop into startTop
      for (FormatusNode child in List.from(endTop.children)) {
        startTop.appendChild(child);
      }

      // Remove endTop and intermediate sections from root
      for (int i = endIndex; i > startIndex; i--) {
        startTop.parent.children.removeAt(i);
      }
    }
    //--- Remove all nodes in between
    for (FormatusNode node in affected) {
      removeNode(node);
    }

    //--- attach any replacement text to prefixing node
    FormatusNode prefixNode = findNodeAtCursor(
      deltaText.prevSelection.baseOffset - 1,
    );
    prefixNode.text += deltaText.textAdded;
  }

  ///
  /// Finds text-node by cursor position.
  /// Sets computed `textIndex0` in returned node.
  ///
  FormatusNode findNodeAtCursor(final int curPos) {
    final segments = FormatusResults.buildSegments(root);
    FormatusNode lastLeaf = FormatusNode.placeHolder;

    for (final seg in segments) {
      if (seg.leaf != null) {
        final leaf = seg.leaf!;
        if (curPos < seg.start) {
          //--- curPos fell inside a prefix just skipped -> forward-snap
          leaf.textIndex0 = 0;
          return leaf;
        }
        if (curPos < seg.end) {
          leaf.textIndex0 = curPos - seg.start;
          return leaf;
        }
        lastLeaf = leaf;
        continue;
      }
      if (seg.prefixOwner != null) continue; // never a cursor target itself
      //--- separator: sticks backward to the leaf just walked
      if (curPos == seg.start) {
        lastLeaf.textIndex0 = lastLeaf.length;
        return lastLeaf;
      }
    }

    lastLeaf.textIndex0 = lastLeaf.length;
    return lastLeaf;
  }

  /// Delete line-break between sections or behind a list-item
  void _handleLineBreakDelete(int cursorOffset) {
    FormatusNode node = findNodeAtCursor(cursorOffset);
    FormatusNode top = node.topNode;
    int leftIndex = (node.textIndex0 == 0)
        ? top.indexInParent + 1
        : top.indexInParent;
    FormatusNode topLeft = top.parent[leftIndex];
    FormatusNode topRight = top.parent[leftIndex + 1];

    //--- Move children of right top to left one
    for (FormatusNode child in topRight.children) {
      topLeft.appendChild(child);
    }
    topRight.parent.children.removeAt(topRight.indexInParent);
  }

  void removeNode(FormatusNode node) {
    if (node.isRoot) return;
    int childIndex = node.indexInParent;
    while (node.isEmpty) {
      node.parent.children.removeAt(childIndex);
      node = node.parent;
      if (node.isRoot) return _setupEmptyRoot();
    }
  }

  ///
  /// Creates and inserts a new text-node in front of (`head`)
  /// or behind (`tail`) this one.
  ///
  void splitAndInsertNode(FormatusNode node, SplitPosition where) {
    FormatusNode created = node.split(where);
    if (where == .tail) {
      node.parent.insertChildAt(created, node.indexInParent + 1);
      return;
    }
    node.parent.insertChildAt(created, node.indexInParent);
  }

  /// Split tree at `offset`. If `offset` is in the middle of some text then
  /// the node will be split first.
  void splitTree(int offset) {
    FormatusNode node = findNodeAtCursor(offset);
    if (node.textIndex0 > 0) node.split(.head);
  }

  /// Insert (no anchor-node at `curPos`), modify or remove (`anchor == null`)
  /// image at cursor index `curPos`.
  void updateAnchorAtCursor(FormatusAnchor? anchor, int curPos) {
    FormatusNode node = findNodeAtCursor(curPos);

    //--- No anchor given => remove at cursor position
    if (anchor == null) {
      if (node.isAnchor) removeNode(node);
    }
    //--- Anchor given -> update the one at cursor position
    else if (node.isAnchor) {
      node.attribute = anchor.href;
      node.text = anchor.name;
    }
    //--- Create new image-node and insert at cursor position
    else {
      FormatusNode anchorNode = FormatusNode(
        tag: .anchor,
        attribute: anchor.href,
        text: anchor.name,
      );
      _insertChild(child: anchorNode, nodeAtCursor: node);
    }
    computeResultsAt(curPos);
  }

  /// Insert (no image-node at `curPos`), modify or remove (`image == null`)
  /// image at cursor index `curPos`.
  void updateImageAtCursor(FormatusImage? image, int curPos) {
    FormatusNode node = findNodeAtCursor(curPos);

    //--- No image given => remove at cursor position
    if (image == null) {
      if (node.isImage) removeNode(node);
    }
    //--- Image given -> update the one at cursor position
    else if (node.isImage) {
      node.ariaLabel = image.aria;
      node.attribute = image.src;
      node.text = imagePlaceholderChar;
    }
    //--- Create new image-node and insert at cursor position
    else {
      FormatusNode imageNode = FormatusNode(
        tag: .image,
        ariaLabel: image.aria,
        attribute: image.src,
      );
      _insertChild(child: imageNode, nodeAtCursor: node);
    }
    computeResultsAt(curPos);
  }

  ///
  /// Entrypoint to apply (_apply = true_) or remove (_appy = false_) `format`
  /// on selected text-range.
  ///
  void updateInlineFormat(
    TextSelection selection,
    Formatus format,
    bool apply, {
    Color color = Colors.transparent,
  }) {
    if (selection.isCollapsed) return;

    //--- collect all text-nodes in selected range
    final affected = collectNodesWithTextInRange(selection);
    if (affected.isEmpty) return;
    affected[0].split(.head, insert: .ifNotEmpty);
    affected.last.split(.tail, insert: .ifNotEmpty);

    //--- add or remove format
    for (FormatusNode node in affected) {
      if (apply) {
        _applyFormatToNode(node, format, color);
      } else {
        _removeFormatFromNode(node, format);
      }
    }
    computeResults();
  }

  ///
  /// Entrypoint to update format of section or list based on selection-start
  ///
  void updateSectionFormat(TextSelection selection, Formatus format) {
    //--- Determine first and last text-node from selection
    FormatusNode first = findNodeAtCursor(selection.start);
    FormatusNode last = findNodeAtCursor(selection.end);
    int from = first.section.indexInParent;
    int to = last.section.indexInParent;

    for (int i = from; i <= to; i++) {
      root[i].tag = format;
    }
    computeResults();
  }

  ///
  /// Entrypoint to handle all cases of modified text
  ///
  void updateText(
    DeltaText deltaText,
    Set<Formatus> formats, {
    Color color = Colors.transparent,
  }) {
    if (deltaText.textRemoved == '\n') {
      _handleLineBreakDelete(deltaText.nextSelection.start);
      return computeResults();
    }

    //--- Immediately handle replacement of all text
    if (deltaText.isAll) {
      FormatusNode firstTextNode = findNodeAtCursor(0);
      Formatus sectionFormat =
          formats.firstWhereOrNull((f) => f.isSection) ??
          firstTextNode.section.tag;
      _setupEmptyRoot();
      root[0].tag = sectionFormat;
      root[0][0].text = deltaText.textAdded;
      return computeResults();
    }

    FormatusNode node = findNodeAtCursor(deltaText.headLength);
    debugPrint('isInsert=${deltaText.isInsert}, node=$node');

    //--- Handle text insertion
    if (deltaText.isInsert) {
      insertAtCursor(node, deltaText.textAdded, formats, color);
    } else {
      deleteAndReplaceText(deltaText, formats, color);
    }
    return computeResults();
  }

  @visibleForTesting
  void insertAtCursor(
    FormatusNode node,
    String text,
    Set<Formatus> formats,
    Color color,
  ) {
    if (text == '\n') {
      _insertLineBreak(node);
    } else if (node.matchesFormatsAndColor(formats, color)) {
      //--- Insert text with same format into nodes text
      int i = node.textIndex0;
      node.text = node.text.replaceRange(i, i, text);
    } else {
      _insertTextWithDifferentFormat(node, text, formats, color);
    }
    return computeResults();
  }

  /// `true` if `a` and `b` are adjacent siblings that can be merged into one
  bool _canMerge(FormatusNode a, FormatusNode b) {
    if (a.isStructural || b.isStructural) return false;
    if (a.isText && b.isText) return true;
    return a.tag == b.tag && a.attribute == b.attribute && a.color == b.color;
  }

  ///
  /// Insert given `node` at `cursorOffset`
  ///
  void _insertChild({
    required FormatusNode child,
    required FormatusNode nodeAtCursor,
  }) {
    //--- Insert before
    if (nodeAtCursor.textIndex0 <= 0) {
      nodeAtCursor.parent.insertChildAt(child, nodeAtCursor.indexInParent);
    }
    //--- Insert behind
    else if (nodeAtCursor.textIndex0 >= nodeAtCursor.length) {
      nodeAtCursor.parent.insertChildAt(child, nodeAtCursor.indexInParent + 1);
    } else {
      nodeAtCursor.split(.head, insert: .ifNotEmpty);
      nodeAtCursor.parent.insertChildAt(child, nodeAtCursor.indexInParent);
    }
  }

  /// Split tree left of `node`
  void _insertLineBreak(FormatusNode node) {
    FormatusNode splitNode = node.split(.head);
    node.parent.insertChildAt(splitNode, node.indexInParent);

    //--- Determine top-node to be split
    FormatusNode topNode = node;
    while (!topNode.isSection && topNode.tag != .listItem && !topNode.isRoot) {
      topNode = topNode.parent;
    }
    if (topNode.isRoot) return;

    //--- Extract left subtree up to topNode
    FormatusNode leftBranch = _splitSubtreeUpTo(node, topNode);

    //--- Ensure the right-hand topNode isn't left empty
    if (topNode.isEmpty) {
      topNode.appendChild(FormatusNode.text());
    }
    if (topNode.isHeader) topNode.tag = .paragraph;

    topNode.parent.insertChildAt(leftBranch, topNode.indexInParent);
  }

  /// _formats_ of given _node_ differ from selected _formats_
  void _insertTextWithDifferentFormat(
    FormatusNode node,
    String text,
    Set<Formatus> selectedFormats,
    Color color,
  ) {
    //--- Split node. New text will be inserted between
    FormatusNode splitNode = node.split(.head);
    if (splitNode.text.isNotEmpty) {
      node.parent.insertChildAt(splitNode, node.indexInParent);
    }
    //--- Find top-node still having one of the required formats
    List<FormatusNode> path = node.path;
    FormatusNode topNode = path[0]; // Start with section directly below root
    int i = 1;
    while ((i < path.length) && selectedFormats.contains(topNode.tag)) {
      topNode = path[i++];
    }

    //--- Extract everything left of node up to (but excluding) topNode.
    //--- topNode (typically the section) must never be duplicated.
    FormatusNode current = node;
    FormatusNode? leftBranch;
    while (current.parent != topNode) {
      FormatusNode parent = current.parent;
      int idx = current.indexInParent;

      List<FormatusNode> leftSiblings = parent.children.sublist(0, idx);
      parent.children.removeRange(0, idx);

      FormatusNode parentCopy = parent.copy;
      for (final child in leftSiblings) {
        parentCopy.appendChild(child);
      }
      if (leftBranch != null) {
        parentCopy.appendChild(leftBranch);
      }
      if (parentCopy.isEmpty) {
        parentCopy.appendChild(FormatusNode.text());
      }
      leftBranch = parentCopy;
      current = parent;
    }

    //--- Remove formats already provided by topNode's own path
    Set<Formatus> remainingFormats = selectedFormats.difference(
      topNode.formats.toSet(),
    );

    //--- Create fresh text-node with missing formats
    FormatusNode textNode = FormatusNode(tag: .text, text: text);
    FormatusNode branchHead = textNode;
    for (final fmt in remainingFormats) {
      final parentWrapper = FormatusNode(
        tag: fmt,
        color: fmt == Formatus.color ? color : Colors.transparent,
      );
      parentWrapper.appendChild(branchHead);
      branchHead = parentWrapper;
    }

    //--- Insert extracted left content (if any) and the new branch as
    //--- children of topNode -- never as a sibling of topNode
    int insertIndex = current.indexInParent;
    if (leftBranch != null) {
      topNode.insertChildAt(leftBranch, insertIndex);
      insertIndex++;
    }
    topNode.insertChildAt(branchHead, insertIndex);

    //--- Drop now-empty leftover text-node
    if (node.text.isEmpty) {
      removeNode(node);
    }
  }

  void _applyFormatToNode(FormatusNode node, Formatus format, Color color) {
    //--- Applying "no color" is really a removal, never a wrap
    if (format == Formatus.color && color == Colors.transparent) {
      return _removeFormatFromNode(node, format);
    }

    if (node.formats.contains(format)) {
      //--- Already exactly this format+color -> nothing to do
      if (format != .color || node.findColor == color) return;
      //--- Same format type, different color -> detach from the old
      //--- wrapper first so the new one doesn't nest inside it
      _removeFormatFromNode(node, format);
    }

    //--- Add format above remaining node
    FormatusNode formatNode = FormatusNode(
      tag: format,
      color: format == Formatus.color ? color : Colors.transparent,
    );
    node.parent.replaceChild(prev: node, next: formatNode);
    formatNode.appendChild(node);
  }

  /// Remove format from (part of) node
  void _removeFormatFromNode(FormatusNode node, Formatus format) {
    //--- Nothing to do if node does not have this format
    if (!node.formats.contains(format)) return;

    FormatusNode formatNode = node.parent;
    while (formatNode.tag != format) {
      if (formatNode.isRoot) return;
      node = formatNode;
      formatNode = node.parent;
    }

    //--- Split formatNode's children around `node`: everything before
    //--- `node` stays in formatNode, everything after moves into a fresh
    //--- copy of formatNode, and `node` itself is extracted entirely
    int nodeIndex = node.indexInParent;
    List<FormatusNode> tailChildren = formatNode.children.sublist(
      nodeIndex + 1,
    );
    formatNode.children.removeRange(nodeIndex, formatNode.children.length);

    if (tailChildren.isNotEmpty) {
      FormatusNode tailNode = formatNode.copy;
      for (final child in tailChildren) {
        tailNode.appendChild(child);
      }
      formatNode.parent.insertChildAt(tailNode, formatNode.indexInParent + 1);
    }

    //--- formatNode now empty -> just replace it with node, no wrapper left
    if (formatNode.isEmpty) {
      return formatNode.parent.replaceChild(prev: formatNode, next: node);
    }

    //--- Otherwise insert the now-plain node right after formatNode
    formatNode.parent.insertChildAt(node, formatNode.indexInParent + 1);
  }

  void _setupEmptyRoot() {
    FormatusNode textNode = FormatusNode(tag: .text);
    FormatusNode paraNode = FormatusNode(tag: .paragraph)
      ..appendChild(textNode);
    root.clearChildren();
    root.appendChild(paraNode);
  }

  /// Traverse up from [leaf] to [topNode], extracting left siblings at each
  /// level and building a new left subtree which is returned.
  FormatusNode _splitSubtreeUpTo(FormatusNode leaf, FormatusNode topNode) {
    FormatusNode current = leaf;
    FormatusNode? leftBranch;

    while (true) {
      FormatusNode parent = current.parent;
      int idx = current.indexInParent;

      //--- Extract left siblings before `current`
      List<FormatusNode> leftSiblings = parent.children.sublist(0, idx);
      parent.children.removeRange(0, idx);

      FormatusNode parentCopy = parent.copy;
      for (final child in leftSiblings) {
        parentCopy.appendChild(child);
      }
      if (leftBranch != null) {
        parentCopy.appendChild(leftBranch);
      }

      //--- Ensure empty split node contains an empty text node
      if (parentCopy.isEmpty) {
        parentCopy.appendChild(FormatusNode.text());
      }
      leftBranch = parentCopy;

      //--- Stop after topNode has been processed as `parent`
      if (parent == topNode) break;
      current = parent;
    }
    return leftBranch;
  }
}

///
/// static helper methods
///
class TreeHelper {
  /// Prints _title_, plain- and formatted text then tree to console
  static void printAll(FormatusDocument doc, String title) {
    debugPrint(
      '=== $title ===\nplainText = "${printPlainText(doc)}"\n'
      'formatted = "${doc.results.formatted}"\n${printTree(doc)}',
    );
  }

  /// Returns plainText from results with readable LFs
  static String printPlainText(FormatusDocument doc) =>
      doc.results.plainText.replaceAll('\n', '¶');

  ///
  /// Returns the document tree structure as a string
  ///
  static String printTree(FormatusDocument doc) {
    final buffer = StringBuffer();

    void buildNodeStr(FormatusNode node, String prefix, bool isLast) {
      final pointer = isLast ? '└── ' : '├── ';
      final tagStr = node.toOpening;
      final textStr = node.text.isNotEmpty || node.isText
          ? '"${node.text}"'
          : '';

      if (!node.isRoot) buffer.writeln('$prefix$pointer$tagStr$textStr');
      for (int i = 0; i < node.children.length; i++) {
        final childPrefix = prefix + (isLast ? '    ' : '│   ');
        buildNodeStr(
          node.children[i],
          childPrefix,
          i == node.children.length - 1,
        );
      }
    }

    buildNodeStr(doc.root, '', true);
    return buffer.toString();
  }
}
