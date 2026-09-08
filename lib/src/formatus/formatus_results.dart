import 'package:flutter/material.dart';

import '../../formatus.dart';
import 'formatus_node.dart';

///
/// Computes `formatted`, `plainText`, `textSpan4Editor`, `textSpan4Viewer`
/// and `segments` from a [FormatusNode] tree (`output.root`), writing all
/// of them directly into the given [FormatusOutput]. Range, formats and
/// color on `output` are left untouched -- [FormatusDocument] fills those
/// in separately via `commonFormatsAndColor`.
///
class FormatusResults {
  static const String lineFeed = '\n';

  /// The output being populated in place
  final FormatusOutput output;

  FormatusResults({required this.output});

  /// Running write-position into `output.plainText` while [_computeNode]
  /// walks the tree. Reset at the start of every [compute] call.
  int _position = 0;

  ///
  /// Recomputes [output] from `output.root` in a single tree walk:
  /// `formatted` / `plainText` / `textSpan4Editor` / `textSpan4Viewer` and
  /// `segments` (the position map used by `findNodeAtCursor` and
  /// `collectNodesWithTextInRange`) are all built together in
  /// [_computeNode], so a leaf's cursor indices are reset and its segment
  /// is recorded at the exact moment its text is appended -- both always
  /// agree on position by construction.
  ///
  void compute() {
    _position = 0;
    output.plainText = '';
    output.formatted = '';
    output.textSpan4Editor = const TextSpan(text: '');
    output.textSpan4Viewer = const TextSpan(text: '');

    final segments = <FormatusSegment>[];
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    _computeNode(output.root, editorChildren, viewerChildren, segments);

    output.textSpan4Editor = TextSpan(children: editorChildren);
    output.textSpan4Viewer = TextSpan(children: viewerChildren);
    output.segments = segments;
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

  void _computeNode(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
    List<FormatusSegment> segments,
  ) {
    //--- Leaf nodes (text / anchor / image) are the only ones that
    //--- directly consume plainText positions -- reset their cursor
    //--- indices and record their segment right here, at the exact spot
    //--- their content is written, instead of in two separate passes.
    if (node.isLeaf) {
      node.textIndex0 = -1;
      node.textIndex1 = -1;
      final int start = _position;

      if (node.tag == .image) {
        _handleImage(node, editorOut, viewerOut);
      } else if (node.tag == .text) {
        _handleText(node, editorOut, viewerOut);
      } else {
        _handleInline(node, editorOut, viewerOut, segments); // anchor
      }

      segments.add(FormatusSegment.leaf(node, start, start + node.length));
      _position += node.length;
      return;
    }

    switch (node.tag) {
      case .header1:
      case .header2:
      case .header3:
      case .paragraph:
        return _handleSection(node, editorOut, viewerOut, segments);

      case .color:
        return _handleColor(node, editorOut, viewerOut, segments);

      case .listItem:
        return _handleListItem(node, editorOut, viewerOut, segments);

      case .orderedList:
      case .unorderedList:
        return _handleList(node, editorOut, viewerOut, segments);

      case .root:
        return _handleRoot(node, editorOut, viewerOut, segments);

      case .subscript:
        return _handleSubscript(node, editorOut, viewerOut);

      case .superscript:
        return _handleSuperscript(node, editorOut, viewerOut);

      default:
        _handleInline(node, editorOut, viewerOut, segments);
        break;
    }
  }

  void _handleColor(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
    List<FormatusSegment> segments,
  ) {
    output.formatted += node.toOpening;
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren, segments);
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
    output.formatted += node.toClosing;
  }

  void _handleImage(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    String src = node.attribute;
    output.formatted += node.toOpening;
    output.plainText += imagePlaceholderChar;
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
    List<FormatusSegment> segments,
  ) {
    output.formatted += node.toOpening;
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren, segments);
    }
    editorOut.add(TextSpan(style: node.tag.style, children: editorChildren));
    viewerOut.add(TextSpan(style: node.tag.style, children: viewerChildren));
    output.formatted += node.toClosing;
    //--- No-op for wrapper nodes (bold/italic/...) whose own `text` is
    //--- empty; for anchor (no children) this is what actually appends
    //--- its content -- the enclosing leaf branch in [_computeNode]
    //--- accounts for exactly this many characters via `node.length`.
    output.plainText += node.text;
  }

  /// Handle opening ordered or unordered list
  void _handleList(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
    List<FormatusSegment> segments,
  ) {
    output.formatted += node.toOpening;
    //--- Do not build 2 consecutive LFs. Only emit a separator segment
    //--- when a '\n' was actually written, so segments and plainText
    //--- can never drift apart here.
    if (!output.plainText.endsWith('\n')) {
      output.plainText += '\n';
      editorOut.add(const TextSpan(text: '\n'));
      viewerOut.add(const TextSpan(text: '\n'));
      segments.add(FormatusSegment.separator(_position));
      _position++;
    }
    node.orderedListNumber = 0;
    for (final child in node.children) {
      _computeNode(child, editorOut, viewerOut, segments);
    }
    output.formatted += node.toClosing;
  }

  void _handleListItem(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
    List<FormatusSegment> segments,
  ) {
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];

    if (node.parent.tag == .unorderedList) {
      node.text = unorderedListPrefix;
    } else {
      node.parent.orderedListNumber++;
      node.text = '${node.parent.orderedListNumber}. ';
    }
    output.formatted += node.toOpening;

    //--- prefix ("• " / "12. ") occupies its own span but is never
    //--- itself a leaf
    final int prefixStart = _position;
    output.plainText += node.text;
    _position += node.text.length;
    segments.add(FormatusSegment.prefix(node, prefixStart, _position));

    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren, segments);
    }
    output.formatted += node.toClosing;

    //--- trailing '\n' after this item's content
    output.plainText += '\n';
    segments.add(FormatusSegment.separator(_position));
    _position++;

    editorOut.add(TextSpan(text: node.text));
    editorOut.add(TextSpan(children: editorChildren));
    viewerOut.add(TextSpan(text: node.text));
    viewerOut.add(TextSpan(children: viewerChildren));
    editorOut.add(const TextSpan(text: '\n'));
    viewerOut.add(const TextSpan(text: '\n'));
  }

  void _handleRoot(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
    List<FormatusSegment> segments,
  ) {
    for (int i = 0; i < node.children.length; i++) {
      _computeNode(node.children[i], editorOut, viewerOut, segments);
      // Insert line feed only between section children, never after the
      // final one or root
      if (i < node.children.length - 1) {
        output.plainText += '\n';
        editorOut.add(const TextSpan(text: '\n'));
        viewerOut.add(const TextSpan(text: '\n'));
        segments.add(FormatusSegment.separator(_position));
        _position++;
      }
    }
  }

  void _handleSection(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
    List<FormatusSegment> segments,
  ) {
    output.formatted += '<${node.tag.key}>';
    final editorChildren = <InlineSpan>[];
    final viewerChildren = <InlineSpan>[];
    for (final child in node.children) {
      _computeNode(child, editorChildren, viewerChildren, segments);
    }

    editorOut.add(TextSpan(style: node.tag.style, children: editorChildren));
    viewerOut.add(TextSpan(style: node.tag.style, children: viewerChildren));
    output.formatted += '</${node.tag.key}>';
  }

  void _handleSubscript(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    editorOut.add(
      TextSpan(
        text: node.text,
        style: const TextStyle(fontFeatures: [FontFeature.subscripts()]),
      ),
    );
    viewerOut.add(
      WidgetSpan(
        child: Transform.translate(
          offset: const Offset(0, 4),
          child: Text(
            node.text,
            textScaler: TextScaler.linear(node.parent.tag.scaleFactor * 0.7),
          ),
        ),
      ),
    );
  }

  void _handleSuperscript(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    editorOut.add(
      TextSpan(
        text: node.text,
        style: const TextStyle(fontFeatures: [FontFeature.superscripts()]),
      ),
    );
    viewerOut.add(
      WidgetSpan(
        child: Transform.translate(
          offset: const Offset(0, -4),
          child: Text(
            node.text,
            textScaler: TextScaler.linear(node.parent.tag.scaleFactor * 0.7),
          ),
        ),
      ),
    );
  }

  void _handleText(
    FormatusNode node,
    List<InlineSpan> editorOut,
    List<InlineSpan> viewerOut,
  ) {
    output.plainText += node.text;
    output.formatted += node.text;
    editorOut.add(TextSpan(text: node.text));
    viewerOut.add(TextSpan(text: node.text));
  }
}
