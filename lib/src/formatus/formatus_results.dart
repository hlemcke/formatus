import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

///
/// Results to update formatted text and [TextField]
///
class FormatusResults {
  String plainText = '';
  String formattedText = '';
  TextSpan textSpan = TextSpan(text: '');

  FormatusResults();

  ///
  /// Must be called after `textNodes` are updated
  ///
  factory FormatusResults.fromNodes(
      List<FormatusNode> textNodes, bool forViewer) {
    FormatusResults results = FormatusResults();
    List<_ResultNode> path = [];
    List<TextSpan> sections = [];

    //--- Remove last elements from path and close tags
    void reducePath() {
      TextStyle? style = (path.last.formatus == Formatus.color)
          ? TextStyle(
              color: Color(int.tryParse(path.last.attribute) ?? 0xFFFFFFFF))
          : path.last.formatus.style;
      TextSpan span = TextSpan(children: path.last.spans, style: style);
      if (path.length < 2) {
        sections.add(span);
      } else {
        path[path.length - 2].spans.add(span);
      }
      if (path.last.formatus != Formatus.lineBreak) {
        results.formattedText += '</${path.last.formatus.key}>';
      }
      path.removeLast();
    }

    //--- Condense similar nodes
    results._joinNodesWithSameFormat(textNodes);

    //--- Loop text nodes
    for (FormatusNode node in textNodes) {
      //--- Loop formats of text node
      for (int i = 0; i < node.formats.length; i++) {
        Formatus nodeFormat = node.formats[i];
        if ((path.length > i) && (path[i].formatus != nodeFormat)) {
          while (path.length > i) {
            reducePath();
          }
        }
        if (path.length < i + 1) {
          path.add(_ResultNode()
            ..formatus = nodeFormat
            ..attribute = node.attribute);
          if (node.isNotLineBreak) {
            results.formattedText += '<${nodeFormat.key}'
                '${nodeFormat.withAttribute ? " ${node.attribute}" : ""}>';
          }
        }
      }
      //--- Cleanup additional path elements
      while (path.length > node.formats.length) {
        reducePath();
      }

      //--- Append [InlineSpan] according to texts typography
      if (node.isSubscript) {
        path.last.spans.add(forViewer
            ? WidgetSpan(
                child: Transform.translate(
                    offset: Offset(0, 4),
                    child: Text(node.text, textScaler: TextScaler.linear(0.7))))
            : TextSpan(
                text: node.text,
                style: TextStyle(fontFeatures: [FontFeature.subscripts()])));
      } else if (node.isSuperscript) {
        path.last.spans.add(forViewer
            ? WidgetSpan(
                child: Transform.translate(
                    offset: Offset(0, -4),
                    child: Text(node.text, textScaler: TextScaler.linear(0.7))))
            : TextSpan(
                text: node.text,
                style: TextStyle(fontFeatures: [FontFeature.superscripts()])));
      } else {
        path.last.spans.add(TextSpan(text: node.text));
      }
      results.formattedText += node.isLineBreak ? '' : node.text;
      results.plainText += node.text;
    }
    while (path.isNotEmpty) {
      reducePath();
    }
    results.textSpan = TextSpan(children: sections, style: Formatus.root.style);
    return results;
  }

  ///
  /// Joins nodes having same format and same attribute
  /// by appending text of next node to current one then deleting next one.
  ///
  void _joinNodesWithSameFormat(List<FormatusNode> textNodes) {
    int nodeIndex = 0;
    while (nodeIndex < textNodes.length - 1) {
      if (textNodes[nodeIndex]
              .hasSameFormats(textNodes[nodeIndex + 1].formats.toSet()) &&
          (textNodes[nodeIndex].attribute ==
              textNodes[nodeIndex + 1].attribute)) {
        textNodes[nodeIndex].text += textNodes[nodeIndex + 1].text;
        textNodes.removeAt(nodeIndex + 1);
        continue;
      }
      nodeIndex++;
    }
  }
}

///
/// Internal class only used by [FormatusDocument.computeResults()]
///
class _ResultNode {
  String attribute = '';
  Formatus formatus = Formatus.placeHolder;

  /// Used to fill text in [TextField] or [TextFormField]
  List<InlineSpan> spans = [];

  @override
  String toString() => '<${formatus.key}> ${spans.length}';
}
