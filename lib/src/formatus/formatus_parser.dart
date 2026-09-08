import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

///
class FormatusParser {
  /// Gets root node of parsing result
  FormatusNode get root => _root;
  FormatusNode _root = FormatusNode.root();

  /// Parses 'html' into a tree of [FormatusNode].
  /// Provides getter with _root_ node of the tree.
  FormatusParser({required String formatted}) {
    formatted = _cleanUpFormatted(formatted);
    if (!formatted.startsWith('<')) {
      formatted = '<p>$formatted </p>';
    }
    _root = _parseHtml(formatted);
  }

  /// Cleanup given text:
  ///
  /// * remove cr
  /// * remove lf
  /// * replace tab with space
  /// * replace multiple spaces with one space
  ///
  String _cleanUpFormatted(String formatted) => formatted
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll('\t', ' ')
      .replaceAll('  ', ' ')
      .trim();

  ///
  Map<String, String> _parseAttributes(String content) {
    final attrs = <String, String>{};
    int i = 0;
    while (i < content.length) {
      if (content[i] == ' ') {
        i++;
        continue;
      }
      int j = content.indexOf('=', i);
      if (j < 0) return attrs;
      String tagName = content.substring(i, j);
      i = j + 2;
      j = content.indexOf('"', i);
      String tagValue = content.substring(i, j);
      attrs[tagName] = tagValue;
    }
    return attrs;
  }

  ///
  Color _parseColor(String? style) {
    if (style == null) return Colors.transparent;
    if (!style.startsWith('color:')) return Colors.transparent;
    int idx = style.indexOf('#');
    if (idx < 0) return Colors.transparent;
    String value = style.substring(idx);

    final a = int.parse(value.substring(7, 9), radix: 16);
    final r = int.parse(value.substring(1, 3), radix: 16);
    final g = int.parse(value.substring(3, 5), radix: 16);
    final b = int.parse(value.substring(5, 7), radix: 16);
    return Color.fromARGB(a, r, g, b);
  }

  ///
  FormatusNode _parseHtml(String html) {
    final root = FormatusNode.root();
    final stack = <FormatusNode>[root];

    final buffer = StringBuffer();
    int i = 0;

    void flushText() {
      if (buffer.isEmpty) return;
      final text = buffer.toString();
      buffer.clear();

      // Discard text/whitespace found outside of block tags at the root level
      if (stack.last == root) return;

      final parent = stack.last;
      parent.appendChild(FormatusNode(tag: Formatus.text, text: text));
    }

    while (i < html.length) {
      final ch = html[i];

      if (ch == '<') {
        flushText();

        final end = html.indexOf('>', i + 1);
        if (end == -1) break;
        final tagContent = html.substring(i + 1, end).trim();
        i = end + 1;

        final parsedTag = _parseTag(tagContent);

        //--- Unknown tag: skip completely, no node, no stack change.
        //--- Its inner text still flushes into the current parent as usual.
        if (parsedTag == null) continue;

        //--- Closing tag
        if (parsedTag.isClosing) {
          final tag = parsedTag.formatus;
          while (stack.length > 1 && stack.last.tag != tag) {
            stack.removeLast();
          }
          if (stack.length > 1) stack.removeLast();
          continue;
        }

        final parent = stack.last;

        // <br> → lineFeed
        if (parsedTag.formatus == Formatus.lineFeed) {
          parent.appendChild(FormatusNode.lineBreak);
          continue;
        }

        // Create node
        final node = FormatusNode(
          tag: parsedTag.formatus,
          text: '',
          attribute: parsedTag.attribute,
          color: parsedTag.color,
          ariaLabel: parsedTag.ariaLabel,
        );

        parent.appendChild(node);

        // Push to stack if not self-closing
        if (!parsedTag.isSelfClosing && parsedTag.formatus != Formatus.image) {
          stack.add(node);
        }
      } else {
        buffer.write(ch);
        i++;
      }
    }

    flushText();
    return root;
  }

  /// Parses the raw content between `<` and `>` (without the brackets).
  /// Returns `null` if the tag name is unknown -> caller must skip it
  /// entirely without creating a node or touching the stack.
  _ParsedTag? _parseTag(String tagContent) {
    bool isClosing = tagContent.startsWith('/');
    if (isClosing) {
      tagContent = tagContent.substring(1).trim();
    }

    bool isSelfClosing = tagContent.endsWith('/');
    if (isSelfClosing) {
      tagContent = tagContent.substring(0, tagContent.length - 1).trim();
    }

    final parts = tagContent.split(RegExp(r'\s+'));
    final name = parts.first;
    final Formatus formatus = Formatus.find(name);

    //--- Unknown tag -> overread it entirely, keep its content
    if (formatus == Formatus.unknown) return null;

    final Map<String, String> attrs = _parseAttributes(
      tagContent.substring(name.length),
    );

    return _ParsedTag(
        formatus: formatus,
        isClosing: isClosing,
        isSelfClosing: isSelfClosing,
        attribute: formatus == Formatus.anchor
            ? (attrs['href'] ?? '')
            : formatus == Formatus.image
            ? (attrs['src'] ?? '')
            : '',
      )
      ..color = _parseColor(attrs['style'])
      ..ariaLabel = attrs['aria-label'] ?? '';
  }
}

///
///
class _ParsedTag {
  String ariaLabel = '';
  Color color = Colors.transparent;
  Formatus formatus;
  bool isClosing;
  bool isSelfClosing;

  String attribute;

  _ParsedTag({
    required this.formatus,
    this.isClosing = false,
    this.isSelfClosing = false,
    this.attribute = '',
  });
}
