import 'formatus_document.dart';
import 'formatus_model.dart';
import 'text_helper.dart';

class FormatusParser {
  ///
  /// Parses `htmlBody` and returns a root-node.
  ///
  FormatusNode parse(String htmlBody, List<FormatusNode> textNodes) {
    FormatusNode body = FormatusNode(format: Formatus.body);
    if (htmlBody.isEmpty) {
      FormatusNode node = FormatusNode()..format = Formatus.paragraph;
      body.children.add(node);
      FormatusNode textNode = FormatusNode()..format = Formatus.text;
      node.addChild(textNode);
    } else {
      int offset = 0;
      while (offset < htmlBody.length) {
        offset = _parseTag(htmlBody, offset, body, textNodes);
      }
    }
    return body;
  }

  ///
  /// Parses a single element starting with "<" until ">".
  ///
  /// The returned [_ParsedNode] contains the new node and the
  /// offset to first character following the closing ">".
  ///
  _ParsedNode? _parseElement(String htmlBody, int offset) {
    //--- skip blanks between top-level tags
    int i = htmlBody.indexOf('<', offset);
    if (i < 0) {
      return null;
    }
    int j = htmlBody.indexOf('>', i + 1);
    if (j < 0) {
      throw FormatException('Missing ">" in tag ${htmlBody.substring(i)}');
    }

    String nodeText = htmlBody.substring(i + 1, j);
    nodeText = nodeText.trim();
    String tagName = TextHelper.extractWord(htmlBody, i + 1);
    List<String> parts = nodeText.split(' ');
    parts.removeAt(0); // remove tagName

    //--- Create node
    FormatusNode newNode = FormatusNode(format: Formatus.find(tagName));

    //--- parse attributes
    for (String part in parts) {
      List<String> kv = part.split("=");
      newNode.attributes[kv[0]] = TextHelper.stripQuotes(kv[1]);
    }

    return _ParsedNode(node: newNode, offset: j + 1);
  }

  ///
  /// Parses an opening html element, all children and the closing element.
  ///
  /// Returns the offset into `htmlBody` of the first character following the
  /// closing element.
  ///
  int _parseTag(String htmlBody, int offset, FormatusNode parent,
      List<FormatusNode> textNodes) {
    _ParsedNode? parsedNode = _parseElement(htmlBody, offset);
    if (parsedNode == null) return htmlBody.length;
    FormatusNode node = parsedNode.node;
    parent.addChild(node);

    //--- loop all content into text or nested inline until closing element
    offset = parsedNode.offset;
    while (offset < htmlBody.length) {
      if (htmlBody[offset] == '<') {
        //--- Closing tag
        if (htmlBody[offset + 1] == '/') {
          while (offset < htmlBody.length && htmlBody[offset] != '>') {
            offset++;
          }
          return offset + 1;
        }
        //--- Opening tag -> must be a nested inline tag
        offset = _parseTag(htmlBody, offset, node, textNodes);
      } else {
        offset = _parseText(htmlBody, offset, node, textNodes);
      }
    }
    return offset;
  }

  ///
  /// Creates a new text node and attaches it to given `parent`.
  /// Advances offset to next `<`.
  ///
  int _parseText(String htmlBody, int offset, FormatusNode parent,
      List<FormatusNode> textNodes) {
    int initialOffset = offset;
    while ((offset < htmlBody.length) && (htmlBody[offset] != '<')) {
      offset++;
    }
    FormatusNode textNode = FormatusNode()..format = Formatus.text;
    textNode.text = htmlBody.substring(initialOffset, offset);
    parent.addChild(textNode);
    textNodes.add(textNode);
    return offset;
  }
}

/// Parser often need both node and resulting text offset
class _ParsedNode {
  FormatusNode node;
  int offset;

  _ParsedNode({
    required this.node,
    required this.offset,
  });
}
