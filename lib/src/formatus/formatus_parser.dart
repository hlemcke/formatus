import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

class FormatusParser {
  late String _formatted;
  List<FormatusNode> _nodes = [];
  Formatus _listType = Formatus.noList;

  FormatusParser({required String formatted}) {
    _formatted = _cleanUpFormatted(formatted);
    if (formatted.isEmpty) {
      FormatusNode node = FormatusNode(formats: [Formatus.paragraph], text: '');
      _nodes.add(node);
    }
  }

  ///
  /// Parses `formatted` text from constructor into list of [FormatusNode]
  ///
  List<FormatusNode> parse() {
    if (_nodes.isNotEmpty) return _nodes;
    int offset = 0;
    while (offset < _formatted.length) {
      //--- Insert line-break between sections
      if (_nodes.isNotEmpty && _nodes.last.isNotLineFeed) {
        _nodes.add(FormatusNode.lineBreak);
      }
      //--- skip any characters between sections
      offset = _formatted.indexOf('<', offset);
      if (offset < 0) break;
      offset = _parseSection(offset);
    }
    if (_nodes.last.isLineFeed) {
      _nodes.removeLast();
    }
    return _nodes;
  }

  /// Cleanup given text by:
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
      .replaceAll('  ', ' ');

  /// Parses an opening html section element, all children and its closing.
  ///
  /// Returns offset into `htmlBody` of the first character following the
  /// closing element.
  ///
  int _parseSection(int offset) {
    List<Formatus> formats = [];
    while (offset < _formatted.length) {
      _ParsedTag? tag = _parseTag(_formatted, offset);
      if (tag == null) {
        return _formatted.length;
      }
      if (tag.isClosing) {
        //--- Create empty section tag
        if ((formats.length == 1) &&
            (_nodes.isEmpty || (_nodes.last.section != formats[0]))) {
          //--- toList() creates a new instance. removeLast() destroys it
          _nodes.add(FormatusNode(formats: formats.toList(), text: ''));
        }
        if (tag.formatus.isList) {
          _listType = Formatus.noList;
        } else if (tag.formatus == Formatus.listItem) {
          return tag.offset;
        }
        if (formats.isNotEmpty) formats.removeLast();
        if (formats.isEmpty) return tag.offset;
      } else {
        //--- Opening tag ---
        if (tag.formatus.isList) {
          _listType = tag.formatus;
        } else if (tag.formatus == Formatus.listItem) {
          if (formats.isEmpty) {
            formats.add(_listType);
          }
        } else {
          formats.add(tag.formatus);
        }
      }
      offset = tag.offset;

      //--- create new node if it contains text
      if (offset < _formatted.length) {
        int end = _formatted.indexOf('<', offset);
        if (end > offset) {
          FormatusNode node = FormatusNode(
            formats: formats.toList(),
            text: _formatted.substring(offset, end),
          );
          node.attribute = tag.attribute;
          node.color = tag.color;
          _nodes.add(node);
          offset = end;
        }
      }
    }
    return _formatted.length;
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
