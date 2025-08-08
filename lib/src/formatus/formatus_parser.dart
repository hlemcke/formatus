import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

class FormatusParser {
  ///
  /// Cleanup given text by:
  ///
  /// * remove cr
  /// * remove lf
  /// * replace tab with space
  /// * replace multiple spaces with one space
  ///
  String cleanUpFormatted(String formatted) => formatted
      .replaceAll('\r', '')
      .replaceAll('\n', '')
      .replaceAll('\t', ' ')
      .replaceAll('  ', ' ');

  ///
  /// Parses `formatted` text and returns list of text-nodes
  ///
  List<FormatusNode> parse(String formatted) {
    formatted = cleanUpFormatted(formatted);
    List<FormatusNode> nodes = [];
    if (formatted.isEmpty) {
      FormatusNode node = FormatusNode(formats: [Formatus.paragraph], text: '');
      nodes.add(node);
      return nodes;
    }
    int offset = 0;
    while (offset < formatted.length) {
      //--- Insert line-break between sections
      if (offset > 0) {
        nodes.add(FormatusNode.lineBreak);
      }
      //--- skip any characters between sections
      offset = formatted.indexOf('<', offset);
      if (offset < 0) break;
      offset = _parseSection(formatted, offset, nodes);
    }
    return nodes;
  }

  String extractWord(String text, int offset) {
    RegExp regExp = RegExp(r'[a-zA-Z0-9]');
    int index = offset;
    while (index < text.length) {
      if (!text[index].contains(regExp)) break;
      index++;
    }
    return text.substring(offset, index);
  }

  ///
  /// Parses an opening html element, all its children and the closing element.
  ///
  /// Returns the offset into `htmlBody` of the first character following the
  /// closing element.
  ///
  int _parseSection(String body, int offset, List<FormatusNode> nodes) {
    List<Formatus> formats = [];
    while (offset < body.length) {
      _ParsedTag? tag = _parseTag(body, offset);
      if (tag == null) {
        return body.length;
      }
      if (tag.isClosing) {
        //--- Create empty section tag
        if ((formats.length == 1) &&
            (nodes.isEmpty || (nodes.last.section != formats[0]))) {
          //--- toList() creates a new instance. Else removeLast destroys it
          nodes.add(FormatusNode(formats: formats.toList(), text: ''));
        }
        if (formats.isNotEmpty) formats.removeLast();
        if (formats.isEmpty) return tag.offset;
      } else {
        //--- Insert line break if this is another <li>
        if (nodes.isNotEmpty &&
            tag.formatus == Formatus.listItem &&
            nodes.last.section.isList) {
          nodes.add(FormatusNode.lineBreak);
        }
        formats.add(tag.formatus);
      }
      offset = tag.offset;

      //--- create new node if it contains text
      if (offset < body.length) {
        int end = body.indexOf('<', offset);
        if (end > offset) {
          FormatusNode node = FormatusNode(
            formats: formats.toList(),
            text: body.substring(offset, end),
          );
          node.attribute = tag.attribute;
          node.color = tag.color;
          nodes.add(node);
          offset = end;
        }
      }
    }
    return body.length;
  }

  ///
  /// Parses a single tag starting with "<" until ">".
  ///
  /// The returned [_ParsedTag] contains the new node and the
  /// offset to first character following the closing ">".
  ///
  _ParsedTag? _parseTag(String htmlBody, int offset) {
    int i = htmlBody.indexOf('<', offset);
    if (i < 0) {
      return null;
    }
    int j = htmlBody.indexOf('>', i + 1);
    if (j < 0) {
      throw FormatException('Missing ">" in tag ${htmlBody.substring(i)}');
    }
    _ParsedTag tag = _ParsedTag();
    tag.offset = j + 1;
    String content = htmlBody.substring(i + 1, j).trim();
    if (content.startsWith('/')) {
      tag.isClosing = true;
      tag.formatus = Formatus.find(content.substring(1));
    } else {
      _parseTagBody(tag, content);
    }
    return tag;
  }

  void _parseTagBody(_ParsedTag tag, String content) {
    int k = content.indexOf(' ');
    String tagName = (k < 0) ? content : content.substring(0, k);
    tag.formatus = Formatus.find(tagName);

    //--- tag has attribute, color or deprecated color
    if (k > 0) {
      if (tag.formatus == Formatus.color) {
        k = content.indexOf('#');
        String hexColor = content.substring(k + 1, content.length - 1);
        tag.color = colorFromHex(hexColor);
      }
      // TODO remove this else block after 2025-12-31
      else if (tag.formatus == Formatus.colorDeprecated) {
        tag.formatus = Formatus.color;
        k = content.indexOf('0x');
        String hexColor = content.substring(k + 2, content.length);
        tag.color = colorFromHex(hexColor);
      } else {
        tag.attribute = content.substring(k + 1);
      }
    }
  }
}

///
/// Result of parsing a single tag
///
class _ParsedTag {
  String attribute = '';
  Color color = Colors.transparent;
  Formatus formatus = Formatus.placeHolder;
  bool isClosing = false;
  int offset = -1;

  _ParsedTag();

  @override
  String toString() =>
      '<${isClosing ? "/" : ""}${formatus.key}'
      '${attribute.isEmpty ? "" : " $attribute"}> offset=$offset';
}
