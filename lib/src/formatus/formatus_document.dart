import 'package:flutter/material.dart';

import 'formatus_controller_impl.dart';
import 'formatus_model.dart';
import 'formatus_node.dart';
import 'formatus_parser.dart';
import 'formatus_results.dart';

///
/// HTML formatted document parsed into a tree-like structure.
///
/// This document holds and manages an HTML tree in `root`.
/// All children of _root_ are section elements like `h1` or `p`.
/// Section elements cannot contain other section elements.
///
class FormatusDocument {
  /// Common color and formats in selected range of text
  FormatusCommons commons = FormatusCommons();

  /// Set to `false` on start of [compute], to `true` by [computeResults]
  bool needsUpdate = true;

  /// Results from tree as computed by [FormatusResults]
  late FormatusResults results;

  /// Root node of the mutable tree
  FormatusNode get root => _root;
  final FormatusNode _root = FormatusNode(tag: .root);

  /// Internal constructor
  FormatusDocument._();

  /// Factory constructor creates a tree-root with one paragraph
  factory FormatusDocument.empty() {
    FormatusDocument doc = FormatusDocument._();
    doc._setupEmptyRoot();
    return doc;
  }

  ///
  /// Creates a new instance from `formatted` text
  ///
  factory FormatusDocument({required String formatted}) {
    FormatusDocument doc = FormatusDocument._();
    FormatusParser(formatted: formatted, target: doc._root);
    doc.computeResults();
    return doc;
  }

  // TODO factory FormatusDocument.fromMarkdown({ required String markdownBody, })

  /// Return section at index
  FormatusNode operator [](int index) => root.children[index];

  /// Set section at index
  void operator []=(int index, FormatusNode node) =>
      root.children[index] = node;

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
    computeResults();
  }

  @visibleForTesting
  List<FormatusNode> get collectAllNodesWithText => collectNodesWithTextInRange(
    TextRange(start: 0, end: results.plainText.length),
  );

  ///
  List<FormatusNode> collectNodesWithTextInRange(TextRange range) {
    //--- Returns single node at cursor position if no range
    if (range.isCollapsed) return [findNodeAtCursor(range.start)];

    final int textLength = results.plainText.length;
    final int selStart = range.start.clamp(0, textLength);
    final int selEnd = range.end.clamp(0, textLength);
    final found = <FormatusNode>[];
    FormatusNode lastLeaf = FormatusNode.placeHolder;

    for (final seg in results.segments) {
      final int nodeStart = seg.start;
      final int nodeEnd = seg.end;

      //--- past selection -> done; lastLeaf untouched
      if (nodeStart > selEnd) break;

      //--- only leaves not yet past selEnd
      if (seg.leaf != null) lastLeaf = seg.leaf!;

      //--- before selection -> skip
      if (nodeEnd <= selStart) continue;

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
  ///
  FormatusCommons commonColorAndFormats(TextRange range) {
    TextRange clampedRange = TextRange(
      start: range.start.clamp(0, 9999),
      end: range.end.clamp(0, 9999),
    );
    FormatusCommons commons = FormatusCommons();
    List<FormatusNode> textNodes = collectNodesWithTextInRange(clampedRange);
    commons.color = textNodes[0].findColor;
    commons.formats = textNodes[0].formats;
    commons.range = clampedRange;

    //--- remove formats which do not exist in following node-paths
    for (int i = 1; i < textNodes.length; i++) {
      Set<Formatus> nodeFormats = textNodes[i].formats;
      commons.formats.retainWhere((f) => nodeFormats.contains(f));
      commons.color = (commons.color == Colors.transparent)
          ? Colors.transparent
          : (commons.color == textNodes[i].findColor)
          ? commons.color
          : Colors.transparent;
    }
    return commons;
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
  /// change), then returns color/formats to reflect `input`'s selection.
  ///
  FormatusCommons compute(FormatusInput input) {
    needsUpdate = false;

    //--- User has modified the text
    if (input.fieldText != results.plainText) {
      _applyTextInput(input);
    }
    //--- User has modified color or format
    else if (input.formats.length != commons.formats.length ||
        !input.formats.containsAll(commons.formats) ||
        input.color != commons.color) {
      _applyFormatInput(input);
    }

    //--- else: pure cursor repositioning / range selection
    commons = commonColorAndFormats(input.range);
    return commons;
  }

  /// Text was edited: derive the classic [DeltaText] from previous/next
  /// plainText + selection and feed it into the existing insert/delete/
  /// update logic, unchanged.
  void _applyTextInput(FormatusInput input) {
    final DeltaText deltaText = DeltaText(
      prevRange: commons.range,
      prevText: results.plainText,
      nextRange: input.range,
      nextText: input.fieldText,
    );
    updateText(deltaText, input.formats, color: input.color);
  }

  /// A color or format was toggled.
  /// Section formats (header/paragraph) replace rather than wrap.
  void _applyFormatInput(FormatusInput input) {
    if (input.color != commons.color) {
      updateInlineFormat(
        input.range,
        Formatus.color,
        input.color != Colors.transparent,
        color: input.color,
      );
      return;
    }

    final Set<Formatus> added = input.formats.difference(commons.formats);
    final Set<Formatus> removed = commons.formats.difference(input.formats);

    for (final Formatus format in added) {
      if (format == Formatus.color) continue; // already handled above
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
  ///
  void computeResults() {
    condenseTree(root);
    results = FormatusResults(tree: _root);
    needsUpdate = true;
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
    if (node.isStructural && node.isEmpty) {
      node.appendChild(FormatusNode.text());
    }
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

      if (child.isText || child.isAnchor) {
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
    FormatusNode prefixNode = findNodeAtCursor(deltaText.prevRange.start - 1);
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

  /// Returns the top-node (section or list-item) that immediately follows
  /// [node] in document order -- a sibling list-item if there is one,
  /// otherwise escalating past the enclosing list to whatever follows it,
  /// and so on up to root.
  FormatusNode? _nextTopNode(FormatusNode node) {
    FormatusNode? sibling = node.nextSibling;
    if (sibling != null) {
      //--- Root's next child might be a list itself -> descend to its first item
      return (node.parent.isRoot &&
              (sibling.tag == .orderedList || sibling.tag == .unorderedList))
          ? sibling[0]
          : sibling;
    }
    if (node.parent.isRoot) return null; // nothing follows
    return _nextTopNode(node.parent); // escalate past the enclosing list
  }

  /// Mirror of [_nextTopNode], walking backwards.
  FormatusNode? _prevTopNode(FormatusNode node) {
    FormatusNode? sibling = node.previousSibling;
    if (sibling != null) {
      return (node.parent.isRoot &&
              (sibling.tag == .orderedList || sibling.tag == .unorderedList))
          ? sibling.children.last
          : sibling;
    }
    if (node.parent.isRoot) return null;
    return _prevTopNode(node.parent);
  }

  /// Delete line-break between sections or behind a list-item
  void _handleLineBreakDelete(int cursorOffset) {
    FormatusNode node = findNodeAtCursor(cursorOffset);
    FormatusNode top = node.topNode;

    FormatusNode? topLeft;
    FormatusNode? topRight;
    if (node.textIndex0 == 0) {
      topLeft = _prevTopNode(top);
      topRight = top;
    } else {
      topLeft = top;
      topRight = _nextTopNode(top);
    }
    if (topLeft == null || topRight == null) return; // nothing to merge

    //--- Move children of right top to left one
    for (FormatusNode child in List<FormatusNode>.from(topRight.children)) {
      topLeft.appendChild(child);
    }
    topRight.parent.children.removeAt(topRight.indexInParent);
  }

  Formatus? firstWhereOrNull(
    Iterable<Formatus> list,
    bool Function(Formatus element) test,
  ) {
    for (var element in list) {
      if (test(element)) return element;
    }
    return null;
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
  /// anchor at cursor index `curPos`.
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
    computeResults();
    needsUpdate = true;
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
        text: imagePlaceholderChar,
        ariaLabel: image.aria,
        attribute: image.src,
      );
      _insertChild(child: imageNode, nodeAtCursor: node);
    }
    computeResults();
    needsUpdate = true;
  }

  ///
  /// Entrypoint to apply (_apply = true_) or remove (_appy = false_) `format`
  /// on selected text-range.
  ///
  void updateInlineFormat(
    TextRange range,
    Formatus format,
    bool apply, {
    Color color = Colors.transparent,
  }) {
    if (range.isCollapsed) return;

    //--- collect all text-nodes in selected range
    final affected = collectNodesWithTextInRange(range);
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
  /// Wraps the content of the section at the cursor into a single
  /// list-item inside a new list, nested inside the existing section.
  ///
  /// * If the cursor is already inside a list-item of the *same* type as
  ///   [listFormat], the list is toggled off: replaced -- in its own
  ///   position among any sibling content of its enclosing section -- by
  ///   one paragraph per list-item, plus one paragraph each for any
  ///   leading/trailing content the section had alongside the list.
  /// * If already inside a list-item of a *different* type, the enclosing
  ///   list is retagged in place (ul <-> ol).
  /// * Otherwise, the section's content is wrapped into a new list.
  ///
  /// The cursor is repositioned afterwards to stay with the same text node
  /// it started in, at the same local offset within that node's text.
  ///
  void updateListFormat(TextRange range, Formatus listFormat) {
    FormatusNode anchor = findNodeAtCursor(range.start);
    int localOffset = anchor.textIndex0;
    FormatusNode top = anchor.topNode;

    if (top.tag == .listItem) {
      FormatusNode listNode = top.parent;
      if (listNode.tag == listFormat) {
        _unwrapList(listNode);
      } else {
        listNode.tag = listFormat;
      }
    } else {
      _wrapIntoList(top, listFormat);
    }

    computeResults();

    //--- Reposition cursor to follow the same text node through the mutation
    int newOffset = _offsetOfNode(anchor, localOffset);
    commons = commonColorAndFormats(TextRange.collapsed(newOffset));
  }

  /// Wraps `section`'s current children into a single list-item of a new list.
  void _wrapIntoList(FormatusNode section, Formatus listFormat) {
    FormatusNode listItem = FormatusNode(tag: .listItem);
    for (final child in List<FormatusNode>.from(section.children)) {
      listItem.appendChild(child);
    }
    if (listItem.isEmpty) {
      listItem.appendChild(FormatusNode.text());
    }
    FormatusNode listNode = FormatusNode(tag: listFormat)
      ..appendChild(listItem);
    section.clearChildren();
    section.appendChild(listNode);
  }

  /// Replaces `listNode` -- in place among any sibling content of its
  /// enclosing section -- with one paragraph per list-item, plus one
  /// paragraph each for any content the section had before/after the list.
  void _unwrapList(FormatusNode listNode) {
    FormatusNode section = listNode.section;
    Formatus sectionTag = section.tag;
    FormatusNode rootNode = section.parent;
    int rootIndex = section.indexInParent;

    int idx = listNode.indexInParent;
    List<FormatusNode> before = section.children.sublist(0, idx);
    List<FormatusNode> after = section.children.sublist(idx + 1);
    List<FormatusNode> items = List<FormatusNode>.from(listNode.children);

    FormatusNode buildPara(List<FormatusNode> content) {
      FormatusNode para = FormatusNode(tag: sectionTag);
      for (final child in content) {
        para.appendChild(child);
      }
      if (para.isEmpty) para.appendChild(FormatusNode.text());
      return para;
    }

    List<FormatusNode> newParas = [];
    if (before.isNotEmpty) newParas.add(buildPara(before));
    for (final item in items) {
      newParas.add(buildPara(List<FormatusNode>.from(item.children)));
    }
    if (after.isNotEmpty) newParas.add(buildPara(after));
    if (newParas.isEmpty) newParas.add(buildPara(const []));

    rootNode.children.removeAt(rootIndex);
    int insertAt = rootIndex;
    for (final para in newParas) {
      rootNode.insertChildAt(para, insertAt);
      insertAt++;
    }
  }

  /// Returns the absolute plainText offset of [node] (matched by identity)
  /// after a tree mutation + [computeResults], offset by [localOffset] and
  /// clamped to the node's own length. Falls back to 0 if the node can no
  /// longer be found (e.g. it got merged into a sibling during condensing).
  int _offsetOfNode(FormatusNode node, int localOffset) {
    for (final seg in results.segments) {
      if (identical(seg.leaf, node)) {
        return seg.start + localOffset.clamp(0, node.length);
      }
    }
    return 0;
  }

  ///
  /// Update format of section based on selection
  ///
  void updateSectionFormat(TextRange range, Formatus format) {
    //--- Determine first and last text-node from selection
    FormatusNode first = findNodeAtCursor(range.start);
    FormatusNode last = findNodeAtCursor(range.end);
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
      _handleLineBreakDelete(deltaText.nextRange.start);
      return computeResults();
    }

    //--- Immediately handle replacement of all text
    if (deltaText.isAll) {
      FormatusNode firstTextNode = findNodeAtCursor(0);
      Formatus sectionFormat =
          firstWhereOrNull(formats, (f) => f.isSection) ??
          firstTextNode.section.tag;
      _setupEmptyRoot();
      root[0].tag = sectionFormat;
      root[0][0].text = deltaText.textAdded;
      return computeResults();
    }

    FormatusNode node = findNodeAtCursor(deltaText.headLength);

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
  }

  /// `true` if `a` and `b` are adjacent siblings that can be merged into one
  bool _canMerge(FormatusNode a, FormatusNode b) {
    if (a.isStructural || b.isStructural) return false;
    if (a.isImage || b.isImage) return false;
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
/// Delta between previous and current text
///
class DeltaText {
  /// Returns `true` if all text is selected
  bool get isAll => _isAll;
  bool _isAll = false;

  bool get isAtEnd => _tailLength == 0;

  bool get isAtStart => _headLength == 0;

  bool get isInsert => type == DeltaTextType.insert;

  bool get isModified => type == DeltaTextType.none;

  /// Length of leading text in front of modification
  int get headLength => _headLength;
  int _headLength = -1;

  /// Current selection
  final TextRange nextRange;

  /// Length of previous text
  int get prevLength => _prevLength;
  int _prevLength = -1;

  /// Previous selection before change
  final TextRange prevRange;

  TextSelection get removedRange => TextSelection(
    baseOffset: headLength,
    extentOffset: headLength + textRemoved.length,
  );

  /// Length of trailing text behind modification
  int get tailLength => _tailLength;
  int _tailLength = -1;

  /// Offset into previous text to start of tail
  int get tailOffset => _tailOffset;
  int _tailOffset = -1;

  /// Text which is added
  String get textAdded => _textAdded;
  String _textAdded = '';

  /// Text which is removed
  String get textRemoved => _textRemoved;
  String _textRemoved = '';

  /// Type of modification
  DeltaTextType type = DeltaTextType.none;

  ///
  /// Computes unmodifiable delta text
  ///
  DeltaText({
    required String prevText,
    required this.prevRange,
    required String nextText,
    required this.nextRange,
  }) {
    _prevLength = prevText.length;
    //--- Text is unchanged
    if (prevText == nextText) {
      type = DeltaTextType.none;
      return;
    }

    //--- All text deleted
    if (nextText.isEmpty) {
      _isAll = true;
      type = DeltaTextType.delete;
      return;
    }

    //--- Computations
    _headLength = (nextRange.start < 0)
        ? 0
        : (prevRange.start < nextRange.start)
        ? prevRange.start
        : nextRange.start;
    int nextLen = nextText.length;
    int prevTailLen = _prevLength - (prevRange.end < 0 ? 0 : prevRange.end);
    int nextTailLen = nextLen - nextRange.end;
    _tailLength = (prevTailLen < nextTailLen) ? prevTailLen : nextTailLen;
    _tailOffset = _prevLength - _tailLength;
    _isAll = (prevRange.start == 0) && (prevRange.end >= _prevLength);

    //--- Insert
    if (_headLength + _tailLength == _prevLength) {
      type = DeltaTextType.insert;
      _textAdded = nextText.substring(_headLength, nextLen - _tailLength);
      return;
    }

    _textAdded = nextText.substring(_headLength, nextLen - _tailLength);
    _textRemoved = prevText.substring(_headLength, _prevLength - _tailLength);
    type = textAdded.isEmpty ? DeltaTextType.delete : DeltaTextType.update;
  }

  @override
  String toString() => isAll
      ? '${type.name} at all => added: "${textAdded.replaceAll('\n', '\\n')}"'
      : '${type.name} [$_headLength..${_prevLength - _tailLength}]'
            ' => ${textAdded.isEmpty ? '' : 'added: "${textAdded.replaceAll('\n', '\\n')}"'}'
            '${textRemoved.isEmpty ? '' : ' removed: "${textRemoved.replaceAll('\n', '\\n')}"'}';
}

enum DeltaTextType { delete, insert, none, update }

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
