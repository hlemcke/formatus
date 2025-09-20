import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

///
/// Results to update formatted text and [TextField]
///
class FormatusResults {
  String formattedText = '';

  /// -1 = no list, 0 = unordered, > 0 ordered
  int listItemNumber = -1;
  String plainText = '';
  TextSpan textSpan = TextSpan(text: '');

  FormatusResults();

  ///
  /// Must be called after `textNodes` are updated
  ///
  factory FormatusResults.fromNodes(
    List<FormatusNode> textNodes,
    bool forViewer,
  ) {
    FormatusResults results = FormatusResults();
    results.build(textNodes, forViewer);
    return results;
  }

  void build(List<FormatusNode> textNodes, bool forViewer) {
    List<_ResultNode> path = [];
    List<TextSpan> sections = [];

    //--- Loop text nodes
    for (int nodeIndex = 0; nodeIndex < textNodes.length; nodeIndex++) {
      FormatusNode node = textNodes[nodeIndex];
      int indexToLastEqualFormat = _indexToLastEqualFormat(path, node);

      //--- If linebreak and next one is also <ol> or <ul> then only close <li>
      if (node.isLineBreak &&
          nodeIndex < textNodes.length - 1 &&
          textNodes[nodeIndex + 1].section.isList) {
        indexToLastEqualFormat = 0;
      }
      // --- Same node => append text to previous one and remove this one
      else if (_appendTextToPreviousNodeIfEqual(
        path,
        textNodes,
        nodeIndex,
        indexToLastEqualFormat,
      )) {
        nodeIndex--;
        continue;
      }

      // --- remove and close trailing path entries
      while (path.length - 1 > indexToLastEqualFormat) {
        _removeLastPathEntry(path, sections);
      }

      // --- append additional node formats to path
      for (int i = indexToLastEqualFormat + 1; i < node.formats.length; i++) {
        _appendNodeFormatToPath(path, node, i);
      }

      //--- Append [InlineSpan] according to texts typography
      _appendSpan(node, forViewer, path, sections);
      formattedText += node.isLineBreak ? '' : node.text;
      plainText += (listItemNumber >= 0) ? ' ${node.text}' : node.text;
      // plainText += (listItemNumber == 0)
      //     ? '\u2022 ${node.text}'
      //     : (listItemNumber > 0)
      //     ? '$listItemNumber. ${node.text}'
      //     : node.text;
    }
    // --- remove and close trailing path entries
    while (path.isNotEmpty) {
      _removeLastPathEntry(path, sections);
    }
    //--- wrap all section [TextSpan] into a root [TextSpan]
    textSpan = TextSpan(children: sections, style: Formatus.root.style);
  }

  /// Appends format of [node] to [path] and extends `formattedText`
  void _appendNodeFormatToPath(
    List<_ResultNode> path,
    FormatusNode node,
    int i,
  ) {
    _ResultNode resultNode = _ResultNode()..formatus = node.formats[i];
    path.add(resultNode);
    if (resultNode.formatus == Formatus.color) {
      resultNode.color = node.color;
    }
    if (node.isNotLineBreak) {
      formattedText += '<${resultNode.formatus.key}';
      if (resultNode.formatus == Formatus.anchor) {
        formattedText += ' '; // space between "<a"
      }
      if (i + 1 == node.formats.length) {
        formattedText += node.attribute;
        formattedText += node.hasColor
            ? ' style="color: #${hexFromColor(node.color)};"'
            : '';
      }
      formattedText += '>';
    }
  }

  ///
  /// Appends [WidgetSpan] for _subscript_ and _superscript_
  /// if `forViewer == true`. Else appends [TextSpan].
  ///
  /// TODO change this when Flutter supports subscript and superscript in [TextSpan]
  ///
  void _appendSpan(
    FormatusNode node,
    bool forViewer,
    List<_ResultNode> path,
    List<TextSpan> sections,
  ) {
    if (node.isAnchor) {
      return _appendSpanAnchor(path, node);
    } else if (node.isSubscript) {
      return _appendSpanSubscript(path, node, forViewer);
    } else if (node.isSuperscript) {
      return _appendSpanSuperscript(path, node, forViewer);
    } else if (node.section == Formatus.orderedList) {
      return _appendSpanOrdered(path, node);
    } else if (node.section == Formatus.unorderedList) {
      return _appendSpanUnordered(path, node);
    } else if (node.isNotLineBreak) {
      listItemNumber = -1;
    }
    path.last.spans.add(TextSpan(text: node.text));
  }

  void _appendSpanAnchor(List<_ResultNode> path, FormatusNode node) {
    // path.last.spans.add(WidgetSpan(child: Text(node.text)));
    path.last.spans.add(TextSpan(text: node.text));
  }

  /// Build [TextSpan] for number and [WidgetSpan] for viewer
  void _appendSpanOrdered(List<_ResultNode> path, FormatusNode node) {
    listItemNumber = (listItemNumber <= 0) ? 1 : listItemNumber + 1;
    path.last.spans.add(WidgetSpan(child: Text('$listItemNumber. ')));
    path.last.spans.add(TextSpan(text: node.text));
  }

  void _appendSpanUnordered(List<_ResultNode> path, FormatusNode node) {
    listItemNumber = 0;
    path.last.spans.add(WidgetSpan(child: Text('\u2022 ')));
    path.last.spans.add(TextSpan(text: node.text));
  }

  void _appendSpanSubscript(
    List<_ResultNode> path,
    FormatusNode node,
    bool forViewer,
  ) {
    double scaleFactor = path[0].formatus.scaleFactor * 0.7;
    path.last.spans.add(
      forViewer
          ? WidgetSpan(
              child: Transform.translate(
                offset: Offset(0, 4),
                child: Text(
                  node.text,
                  textScaler: TextScaler.linear(scaleFactor),
                ),
              ),
            )
          : TextSpan(
              text: node.text,
              style: TextStyle(fontFeatures: [FontFeature.subscripts()]),
            ),
    );
  }

  void _appendSpanSuperscript(
    List<_ResultNode> path,
    FormatusNode node,
    bool forViewer,
  ) {
    double scaleFactor = path[0].formatus.scaleFactor * 0.7;
    path.last.spans.add(
      forViewer
          ? WidgetSpan(
              child: Transform.translate(
                offset: Offset(0, -4),
                child: Text(
                  node.text,
                  textScaler: TextScaler.linear(scaleFactor),
                ),
              ),
            )
          : TextSpan(
              text: node.text,
              style: TextStyle(fontFeatures: [FontFeature.superscripts()]),
            ),
    );
  }

  bool _appendTextToPreviousNodeIfEqual(
    List<_ResultNode> path,
    List<FormatusNode> textNodes,
    int nodeIndex,
    int indexToLastEqualFormat,
  ) {
    FormatusNode node = textNodes[nodeIndex];
    if ((indexToLastEqualFormat + 1 != path.length) ||
        (indexToLastEqualFormat + 1 != node.formats.length) ||
        (node.attribute != path.last.attribute) ||
        (node.color != path.last.color)) {
      return false;
    }
    textNodes[nodeIndex - 1].text += node.text;
    textNodes.removeAt(nodeIndex);
    return true;
  }

  /// Computes index into [path] of last equal format.
  /// Returns -1 if even the section has changed
  int _indexToLastEqualFormat(List<_ResultNode> path, FormatusNode node) {
    if (node.isLineBreak) return -1;
    int i = 0;
    while (true) {
      if (i >= path.length || i >= node.formats.length) break;
      if (path[i].formatus != node.formats[i]) break;
      if ((i == path.length - 1) && (i == node.formats.length - 1)) {
        if (path[i].attribute != node.attribute) break;
        if (path[i].color != node.color) break;
      }
      i++;
    }
    return i - 1;
  }

  void _removeLastPathEntry(List<_ResultNode> path, List<TextSpan> sections) {
    Color color = (path.last.formatus == Formatus.color)
        ? path.last.color
        : Colors.transparent;
    TextStyle? style = (color == Colors.transparent)
        ? path.last.formatus.style
        : TextStyle(color: color);
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
  Color color = Colors.transparent;
  Formatus formatus = Formatus.placeHolder;

  /// Used to fill text in [TextField] or [TextFormField]
  List<InlineSpan> spans = [];

  @override
  String toString() => '<${formatus.key}> ${spans.length}';
}
