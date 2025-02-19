import 'formatus_model.dart';
import 'formatus_node.dart';

class FormatusParser {
  ///
  /// Parses `htmlBody` and returns the list of text-nodes
  ///
  List<FormatusNode> parse(String htmlBody) {
    List<FormatusNode> nodes = [];
    if (htmlBody.isEmpty) {
      FormatusNode node = FormatusNode(formats: [Formatus.paragraph], text: '');
      nodes.add(node);
      return nodes;
    }
    int offset = 0;
    while (offset < htmlBody.length) {
      //--- Insert line-break between sections
      if (offset > 0) {
        nodes.add(FormatusNode.lineBreak);
      }
      //--- skip any characters between sections
      offset = htmlBody.indexOf('<', offset);
      if (offset < 0) break;
      offset = _parseSection(htmlBody, offset, nodes);
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
      _ParsedTag? section = _parseTag(body, offset);
      if (section == null) {
        return body.length;
      }
      if (section.isClosing) {
        formats.removeLast();
        if (formats.isEmpty) return section.offset;
      } else {
        formats.add(section.formatus);
      }
      offset = section.offset;

      //--- If followed by text then create new node
      if (offset < body.length) {
        int end = body.indexOf('<', offset);
        if (end > offset) {
          FormatusNode node = FormatusNode(
              formats: formats.toList(), text: body.substring(offset, end));
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
    } else {
      List<String> parts = content.split(' ');
      tag.formatus = Formatus.find(parts[0]);
      tag.attributes.addAll(parts.sublist(1));
    }
    return tag;
  }
}

///
/// Result of parsing a single tag
///
class _ParsedTag {
  List<String> attributes = [];
  Formatus formatus = Formatus.placeHolder;
  bool isClosing = false;
  int offset = -1;

  _ParsedTag();

  @override
  String toString() =>
      '<${isClosing ? "/" : ""}${formatus.key}> offset=$offset';
}
