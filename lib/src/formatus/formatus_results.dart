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
    int orderedListNumber = 0;

    //--- Condense similar nodes
    results._joinSimilarNodes(textNodes);

    //--- Loop text nodes
    for (FormatusNode node in textNodes) {
      //--- Loop formats of text node to remove or append _ResultNode
      for (int i = 0; i < node.formats.length; i++) {
        Formatus nodeFormat = node.formats[i];
        //--- Remove trailing path entries if this format is different
        if (results._isAlike(path, node, i) == false) {
          while (path.length > i) {
            results._reducePath(path, sections);
          }
        }
        //--- Append path-entry if this is an additional format
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
        results._reducePath(path, sections);
      }

      //--- Append [InlineSpan] according to texts typography
      orderedListNumber = results._appendSpanToPath(
          node, forViewer, path, sections, orderedListNumber);
      results.formattedText += node.isLineBreak ? '' : node.text;
      results.plainText += node.text;
    }
    while (path.isNotEmpty) {
      results._reducePath(path, sections);
    }
    results.textSpan = TextSpan(children: sections, style: Formatus.root.style);
    return results;
  }

  ///
  /// Appends [WidgetSpan] for _subscript_ and _superscript_
  /// if `forViewer == true`. Else appends [TextSpan].
  ///
  /// TODO change this when Flutter supports subscript and superscript in [TextSpan]
  ///
  int _appendSpanToPath(FormatusNode node, bool forViewer,
      List<_ResultNode> path, List<TextSpan> sections, int orderedListNumber) {
    if (node.section == Formatus.orderedList) {
      orderedListNumber++;
      path.last.spans.add(WidgetSpan(
          child: Transform.translate(
        offset: Offset(0, 2),
        child: Text('$orderedListNumber. '),
      )));
    } else {
      orderedListNumber = 0;
    }
    if (node.isSubscript) {
      double scaleFactor = path[0].formatus.scaleFactor * 0.7;
      path.last.spans.add(forViewer
          ? WidgetSpan(
              child: Transform.translate(
                  offset: Offset(0, 4),
                  child: Text(
                    node.text,
                    textScaler: TextScaler.linear(scaleFactor),
                  )))
          : TextSpan(
              text: node.text,
              style: TextStyle(fontFeatures: [FontFeature.subscripts()])));
    } else if (node.isSuperscript) {
      double scaleFactor = path[0].formatus.scaleFactor * 0.7;
      path.last.spans.add(forViewer
          ? WidgetSpan(
              child: Transform.translate(
                  offset: Offset(0, -4),
                  child: Text(
                    node.text,
                    textScaler: TextScaler.linear(scaleFactor),
                  )))
          : TextSpan(
              text: node.text,
              style: TextStyle(fontFeatures: [FontFeature.superscripts()])));
    } else {
      path.last.spans.add(TextSpan(text: node.text));
    }
    return orderedListNumber;
  }

  ///
  /// Returns `true` if `path` and `node` have same formats and attribute
  ///
  bool _isAlike(List<_ResultNode> path, FormatusNode node, int i) =>
      (path.length > i) &&
      (path[i].formatus == node.formats[i]) &&
      ((path[i].formatus.withAttribute == false) ||
          (path[i].attribute == node.attribute));

  ///
  /// Joins nodes having same format and same attribute
  /// by appending text of next node to current one then deleting next one.
  ///
  void _joinSimilarNodes(List<FormatusNode> textNodes) {
    int nodeIndex = 0;
    while (nodeIndex < textNodes.length - 1) {
      if (textNodes[nodeIndex].isSimilar(textNodes[nodeIndex + 1])) {
        textNodes[nodeIndex].text += textNodes[nodeIndex + 1].text;
        textNodes.removeAt(nodeIndex + 1);
        continue;
      }
      nodeIndex++;
    }
  }

  ///
  /// Remove last element from path and close tags
  ///
  void _reducePath(List<_ResultNode> path, List<TextSpan> sections) {
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
      formattedText += '</${path.last.formatus.key}>';
    }
    path.removeLast();
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
