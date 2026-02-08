import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

class FormatusParser {
  late final String _formatted;
  final List<FormatusNode> _nodes = [];
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
  /// Returns offset into `htmlBody` to the first character following the
  /// closing element.
  ///
  int _parseSection(int offset) {
    List<Formatus> formats = [];
    while (offset < _formatted.length) {
      _ParsedTag? tag = _parseTag(offset);
      if (tag == null) return _formatted.length;

      //--- Handle opening and closing only if tag is known
      if (tag.isKnown) {
        if (tag.isClosing) {
          _handleClosingTag(tag, formats);
          if (formats.isEmpty) return tag.offset;
        } else {
          _handleOpeningTag(tag, formats);
        }
      }
      offset = tag.offset;
      offset = _extractTextNode(tag, formats, offset);
    }
    return _formatted.length;
  }

  int _extractTextNode(_ParsedTag tag, List<Formatus> formats, int offset) {
    int end = _formatted.indexOf('<', offset);
    if (end > offset) {
      String text = _formatted.substring(offset, end).replaceAll(lessThan, '<');

      //--- Unknown tag => append text to previous node
      if (tag.isNotKnown) {
        //--- Formatted starts with unknown tag => wrap with <p>
        if (_nodes.isEmpty) {
          _nodes.add(FormatusNode(formats: [Formatus.paragraph], text: ''));
          formats.add(Formatus.paragraph);
        }
        _nodes.last.text += text;
        return end;
      }

      //--- Known tag => create new node
      FormatusNode node = FormatusNode(formats: formats.toList(), text: text);
      node.attribute = tag.attribute;
      node.color = tag.color;
      _nodes.add(node);
      return end;
    }
    return offset;
  }

  void _handleClosingTag(_ParsedTag tag, List<Formatus> formats) {
    if ((formats.length == 1) &&
        (_nodes.isEmpty || (_nodes.last.section != formats[0]))) {
      _nodes.add(FormatusNode(formats: formats.toList(), text: ''));
    }

    if (tag.formatus.isList) {
      _listType = Formatus.noList;
    }

    if (formats.isNotEmpty) formats.removeLast();
  }

  void _handleOpeningTag(_ParsedTag tag, List<Formatus> formats) {
    //--- Delay adding ol or ul until li found
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

  ///
  /// Parses a single tag starting with "<" until ">".
  ///
  /// The returned [_ParsedTag] contains the new node and the
  /// offset to first character following the closing ">".
  ///
  _ParsedTag? _parseTag(int offset) {
    int i = _formatted.indexOf('<', offset);
    if (i < 0) return null;
    int j = _formatted.indexOf('>', i + 1);
    if (j < 0) {
      throw FormatException('Missing ">" in tag ${_formatted.substring(i)}');
    }
    _ParsedTag tag = _ParsedTag();

    //--- Handle tag content
    tag.offset = j + 1;
    String content = _formatted.substring(i + 1, j).trim();
    if (content.startsWith('/')) {
      tag.isClosing = true;
      tag.formatus = Formatus.find(content.substring(1));
    } else {
      _parseOpeningTag(tag, content);
    }
    return tag;
  }

  void _parseOpeningTag(_ParsedTag tag, String content) {
    int k = content.indexOf(' ');
    String tagName = (k < 0) ? content : content.substring(0, k);
    tag.formatus = Formatus.find(tagName);

    //--- tag has attribute, color or deprecated color
    if (k > 0) {
      if (tag.formatus == Formatus.color) {
        k = content.indexOf('#');
        String hexColor = content.substring(k + 1, content.length - 1);
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

  /// Index into _formatted_ to first char behind ">"
  int offset = -1;

  _ParsedTag();

  bool get isKnown => formatus != Formatus.text;

  bool get isNotKnown => formatus == Formatus.text;

  @override
  String toString() =>
      '<${isClosing ? "/" : ""}${formatus.key}'
      '${attribute.isEmpty ? "" : " $attribute"}> offset=$offset';
}
