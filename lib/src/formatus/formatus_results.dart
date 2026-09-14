import 'package:flutter/material.dart';

import '../../formatus.dart';
import 'formatus_node.dart';

///
/// Computes output fields from tree.
///
class FormatusResults {
  static const String lineFeed = '\n';

  /// Formatted text for persistency
  String formatted = '';

  /// Plain text with line-breaks for Flutter [TextField]
  String plainText = '';

  /// Segments laid out exactly as `plainText`. Maps to nodes with text
  List<FormatusSegment> segments = [];

  /// [TextSpan] for [TextField]. Children are sections separated by `\n`
  TextSpan textSpan4Editor = TextSpan(text: '');

  /// [TextSpan] for [FormatusViewer]. Children are sections separated by `\n`
  TextSpan textSpan4Viewer = TextSpan(text: '');

  ///
  /// Computes multiple output fields from given `tree`:
  ///
  /// * `formatted` → HTML string for persistency
  /// * `plainText` → text with line-breaks for Flutter [TextField]
  /// * `segments` → internally used to find nodes with text
  /// * `textSpan4Editor` → rendered input for Flutter [TextField]
  /// * `textSpan4Viewer` → rendered input for [FormatusViewer]
  /// and `textSpan4Viewer` from a [FormatusNode] tree.
  ///
  FormatusResults({required FormatusNode tree}) {
    compute(tree);
  }

  ///
  /// Computes output fields from in a single tree walk:
  ///
  void compute(FormatusNode tree) {
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];

    _computeNode(tree, editorChildren, viewerChildren);

    textSpan4Editor = TextSpan(children: editorChildren);
    textSpan4Viewer = TextSpan(children: viewerChildren);
  }

  ///
  /// Standalone position-map builder, kept for callers that need a fresh
  /// map *without* a full [compute] pass -- namely `FormatusDocument`,
  /// which calls this mid-mutation (`findNodeAtCursor`,
  /// `collectNodesWithTextInRange`) while the tree is still being
  /// restructured, before spans/formatted text are rebuilt.
  ///
  static List<FormatusSegment> buildSegments(FormatusNode root) {
    final segments = <FormatusSegment>[];
    int computed = 0;

    void addSeparator() {
      segments.add(FormatusSegment.separator(computed));
      computed++;
    }

    void walk(FormatusNode node) {
      if (node.isLeaf) {
        segments.add(
          FormatusSegment.leaf(node, computed, computed + node.length),
        );
        computed += node.length;
        return;
      }

      if (node.tag == .orderedList || node.tag == .unorderedList) {
        addSeparator(); // leading '\n' before the list's first item
        for (final child in node.children) {
          walk(child);
        }
        return;
      }

      if (node.tag == .listItem) {
        //--- prefix ("• " / "12. ") occupies its own span but is never
        //--- itself a leaf -- skip it before descending into children
        segments.add(
          FormatusSegment.prefix(node, computed, computed + node.text.length),
        );
        computed += node.text.length;
        for (final child in node.children) {
          walk(child);
        }
        addSeparator(); // trailing '\n' after this item's content
        return;
      }

      for (final child in node.children) {
        walk(child);
      }
    }

    for (int i = 0; i < root.childCount; i++) {
      walk(root[i]);
      //--- '\n' only goes *between* root sections, never after the last
      if (i < root.childCount - 1) addSeparator();
    }

    return segments;
  }

  /// Recursive tree walker depth-first
  void _computeNode(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    //--- Leaf nodes: text / anchor / image
    if (node.isLeaf) {
      return _handleLeaf(node, editorOut, viewerOut);
    }

    switch (node.tag) {
      case .header1:
      case .header2:
      case .header3:
      case .paragraph:
        return _handleSection(node, editorOut, viewerOut);

      case .color:
        return _handleColor(node, editorOut, viewerOut);

      case .listItem:
        return _handleListItem(node, editorOut, viewerOut);

      case .orderedList:
      case .unorderedList:
        return _handleList(node, editorOut, viewerOut);

      case .root:
        return _handleRoot(node, editorOut, viewerOut);

      case .subscript:
        return _handleSubscript(node, editorOut, viewerOut);

      case .superscript:
        return _handleSuperscript(node, editorOut, viewerOut);

      default:
        _handleInline(node, editorOut, viewerOut);
        break;
    }
  }

  void _handleAnchor(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    formatted += node.text;
    editorOut.add(TextSpan(text: node.text, style: node.tag.style));
    viewerOut.add(
      FormatusAnchorSpan(
        anchor: FormatusAnchor(href: node.attribute, name: node.text),
        style: node.tag.style,
        text: node.text,
      ),
    );
  }

  void _handleColor(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    formatted += node.toOpening;
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren);
    }

    Color color = node.color;
    editorOut.add(
      TextSpan(
        style: TextStyle(color: color),
        children: editorChildren,
      ),
    );
    viewerOut.add(
      TextSpan(
        style: TextStyle(color: color),
        children: viewerChildren,
      ),
    );
    formatted += node.toClosing;
  }

  void _handleImage(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    String src = node.attribute;
    editorOut.add(
      TextSpan(
        text: imagePlaceholderChar,
        style: TextStyle(color: Colors.deepPurpleAccent),
      ),
    );
    viewerOut.add(WidgetSpan(child: Image.network(src, height: 20)));
  }

  void _handleInline(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    formatted += node.toOpening;
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren);
    }
    editorOut.add(TextSpan(style: node.tag.style, children: editorChildren));
    viewerOut.add(TextSpan(style: node.tag.style, children: viewerChildren));
    formatted += node.toClosing;
    plainText += node.text;
  }

  /// Handles leaves: anchor, image, text
  void _handleLeaf(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    node.textIndex0 = -1;
    node.textIndex1 = -1;
    formatted += node.toOpening;
    final int start = plainText.length;
    if (node.tag == .anchor) {
      _handleAnchor(node, editorOut, viewerOut);
    } else if (node.tag == .image) {
      _handleImage(node, editorOut, viewerOut);
    } else if (node.tag == .text) {
      formatted += node.text;
      editorOut.add(TextSpan(text: node.text));
      viewerOut.add(TextSpan(text: node.text));
    } else {
      formatted += node.text;
      _handleInline(node, editorOut, viewerOut);
    }
    formatted += node.toClosing;
    plainText += node.text;
    segments.add(FormatusSegment.leaf(node, start, start + node.length));
  }

  /// Handle opening of ordered or unordered list
  void _handleList(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    formatted += node.toOpening;
    //--- Do not build 2 consecutive LFs. Only emit a separator segment
    //--- when a '\n' was actually written, so segments and plainText
    //--- can never drift apart here.
    if (!plainText.endsWith('\n')) {
      final int start = plainText.length;
      plainText += '\n';
      editorOut.add(const TextSpan(text: '\n'));
      viewerOut.add(const TextSpan(text: '\n'));
      segments.add(FormatusSegment.separator(start));
    }
    node.orderedListNumber = 0;
    for (final child in node.children) {
      _computeNode(child, editorOut, viewerOut);
    }
    formatted += node.toClosing;
  }

  void _handleListItem(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];

    if (node.parent.tag == .unorderedList) {
      node.text = unorderedListPrefix;
    } else {
      node.parent.orderedListNumber++;
      node.text = '${node.parent.orderedListNumber}. ';
    }
    formatted += node.toOpening;

    //--- prefix ("• " / "12. ") occupies its own span but is never
    //--- itself a leaf
    int start = plainText.length;
    plainText += node.text;
    segments.add(FormatusSegment.prefix(node, start, start + node.text.length));

    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren);
    }
    editorOut.add(TextSpan(text: node.text));
    editorOut.add(TextSpan(children: editorChildren));
    editorOut.add(TextSpan(text: '\n'));
    viewerOut.add(TextSpan(text: node.text));
    viewerOut.add(TextSpan(children: viewerChildren));
    viewerOut.add(TextSpan(text: '\n'));

    //--- trailing '\n' after this item's content
    formatted += node.toClosing;
    start = plainText.length;
    plainText += '\n';
    segments.add(FormatusSegment.separator(start));
  }

  void _handleRoot(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    for (int i = 0; i < node.children.length; i++) {
      _computeNode(node.children[i], editorOut, viewerOut);
      // Insert line feed only between section children, never after the
      // final one or root
      if (i < node.children.length - 1) {
        final int start = plainText.length;
        plainText += '\n';
        editorOut.add(const TextSpan(text: '\n'));
        viewerOut.add(const TextSpan(text: '\n'));
        segments.add(FormatusSegment.separator(start));
      }
    }
  }

  void _handleSection(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    formatted += node.toOpening;
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren);
    }

    editorOut.add(TextSpan(style: node.tag.style, children: editorChildren));
    viewerOut.add(TextSpan(style: node.tag.style, children: viewerChildren));
    formatted += node.toClosing;
  }

  void _handleSubscript(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    String text = _buildScript(node);
    editorOut.add(
      TextSpan(
        text: text,
        style: const TextStyle(fontFeatures: [FontFeature.subscripts()]),
      ),
    );
    viewerOut.add(
      WidgetSpan(
        child: Transform.translate(
          offset: const Offset(0, 4),
          child: Text(
            text,
            textScaler: TextScaler.linear(node.parent.tag.scaleFactor * 0.7),
          ),
        ),
      ),
    );
    formatted += node.toClosing;
  }

  void _handleSuperscript(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    String text = _buildScript(node);
    editorOut.add(
      TextSpan(
        text: text,
        style: const TextStyle(fontFeatures: [FontFeature.superscripts()]),
      ),
    );
    viewerOut.add(
      WidgetSpan(
        child: Transform.translate(
          offset: const Offset(0, -4),
          child: Text(
            text,
            textScaler: TextScaler.linear(node.parent.tag.scaleFactor * 0.7),
          ),
        ),
      ),
    );
    formatted += node.toClosing;
  }

  String _buildScript(FormatusNode node) {
    formatted += node.toOpening;
    FormatusNode textChild = node.children[0];
    String text = textChild.text;
    plainText += text;
    int start = plainText.length;
    segments.add(FormatusSegment.leaf(textChild, start, start + node.length));
    return text;
  }
}
