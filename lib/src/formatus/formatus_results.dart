import 'package:flutter/material.dart';

import 'formatus_model.dart';
import 'formatus_node.dart';

///
/// Results to update formatted text and [TextField]
///
class FormatusResults {
  static const String lineFeed = '\n';

  /// Formatted text for storage
  String formattedText = '';

  /// `true` produces [textSpan] for [FormatusViewer]
  bool forViewer;

  /// Plain text for [TextEditingController]
  String plainText = '';

  /// List of text nodes as input for results
  List<FormatusNode> textNodes;

  /// _root_ [TextSpan] for [TextField]. Children are sections separated by `\n`
  TextSpan textSpan = TextSpan(text: '');

  /// -1 = no list, 0 = unordered, > 0 ordered. Set at first `ol` or `ul`
  int _listItemNumber = -1;

  /// Type of list or none
  Formatus _listType = Formatus.noList;

  ///
  /// Must be called after `textNodes` were modified
  ///
  FormatusResults({required this.textNodes, this.forViewer = false}) {
    build();
  }

  void build() {
    List<ResultNode> path = [];
    List<TextSpan> sections = [];
    int indexToLastEqualFormat = -1;
    _combineSimilarNodes();

    //--- Loop text nodes ---
    for (int nodeIndex = 0; nodeIndex < textNodes.length; nodeIndex++) {
      FormatusNode node = textNodes[nodeIndex];

      //--- compute index into [path] of last equal format
      indexToLastEqualFormat = _indexToLastEqualFormat(nodeIndex, path);

      // --- remove and close trailing path entries
      Formatus nextNodesFormat = (nodeIndex < textNodes.length - 1)
          ? textNodes[nodeIndex + 1].section
          : Formatus.placeHolder;
      while (path.length - 1 > indexToLastEqualFormat) {
        _removeLastPathEntry(path, sections, nextNodesFormat);
      }

      // --- append additional node formats to path
      for (int i = indexToLastEqualFormat + 1; i < node.formats.length; i++) {
        _appendNodeFormatToPath(path, node, i);
      }

      //--- Append [InlineSpan] according to texts typography
      _appendSpan(node, path);
      formattedText += node.isLineFeed ? '' : node.text;
      plainText += node.text;
    }

    // --- remove and close trailing path entries
    while (path.isNotEmpty) {
      _removeLastPathEntry(path, sections, Formatus.placeHolder);
    }
    //--- wrap all section [TextSpan] into a root [TextSpan]
    textSpan = TextSpan(children: sections, style: Formatus.root.style);
  }

  /// Appends format at index [i] of [node] to [path] and extends `formattedText`
  void _appendNodeFormatToPath(
    List<ResultNode> path,
    FormatusNode node,
    int i,
  ) {
    ResultNode resultNode = ResultNode()..formatus = node.formats[i];
    path.add(resultNode);
    if (resultNode.formatus == Formatus.color) {
      resultNode.color = node.color;
    } else if (resultNode.isList) {
      if (_listType == Formatus.noList) {
        _listType = resultNode.formatus;
      }
      _listItemNumber = resultNode.formatus == Formatus.unorderedList
          ? 0
          : (_listItemNumber <= 0)
          ? 1
          : _listItemNumber + 1;
      plainText += ' ';
      resultNode.spans.add(
        resultNode.formatus == Formatus.orderedList
            ? WidgetSpan(child: Text('\u2022 '))
            : WidgetSpan(child: Text('$_listItemNumber. ')),
      );
    }
    if (node.isLineFeed) return;
    if (_listType.isList && (node.section != _listType)) {
      formattedText += '</${_listType.key}>';
      _listType = Formatus.noList;
    }
    if (resultNode.isList) {
      if (_listType == Formatus.noList) {
        _listType = node.section;
        formattedText += '<${_listType.key}>';
      }
      formattedText += '<li';
    } else {
      formattedText += '<${resultNode.formatus.key}';
    }
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

  ///
  /// Appends [WidgetSpan] for _subscript_ and _superscript_
  /// if `forViewer == true`. Else appends [TextSpan].
  ///
  /// TODO change this when Flutter supports subscript and superscript in [TextSpan]
  ///
  void _appendSpan(FormatusNode node, List<ResultNode> path) {
    if (node.isSubscript) {
      return _appendSpanSubscript(path, node);
    } else if (node.isSuperscript) {
      return _appendSpanSuperscript(path, node);
    }
    path.last.spans.add(TextSpan(text: node.text));
  }

  void _appendSpanSubscript(List<ResultNode> path, FormatusNode node) {
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

  void _appendSpanSuperscript(List<ResultNode> path, FormatusNode node) {
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

  void _combineSimilarNodes() {
    for (int i = textNodes.length - 1; i > 0; i--) {
      if (textNodes[i].isSimilar(textNodes[i - 1])) {
        textNodes[i - 1].text += textNodes[i].text;
        textNodes.removeAt(i);
      }
    }
  }

  /// Computes index into [path] of last equal format.
  /// Returns -1 if even the section has changed e.g. when reached a linefeed
  int _indexToLastEqualFormat(int nodeIndex, List<ResultNode> path) {
    FormatusNode node = textNodes[nodeIndex];

    //--- handle linefeed
    if (node.isLineFeed) {
      return -1;
    }

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

  void _removeLastPathEntry(
    List<ResultNode> path,
    List<TextSpan> sections,
    Formatus nextNodesFormat,
  ) {
    ResultNode removed = path.removeLast();

    //--- Create span from removed node
    Color color = (removed.formatus == Formatus.color)
        ? removed.color
        : Colors.transparent;
    TextStyle? style = (color == Colors.transparent)
        ? removed.formatus.style
        : TextStyle(color: color);
    TextSpan span = TextSpan(children: removed.spans, style: style);

    //--- Attach span
    if (path.isEmpty) {
      sections.add(span);
    } else {
      path.last.spans.add(span);
    }

    //--- Close node in html output
    if (removed.formatus.isList) {
      formattedText += '</li>';
      if (removed.formatus != nextNodesFormat) {
        formattedText += '</${removed.formatus.key}>';
        _listType = Formatus.noList;
      }
    } else if (removed.formatus != Formatus.lineFeed) {
      formattedText += '</${removed.formatus.key}>';
    }
  }
}

///
/// Internal class only used by [FormatusDocument.computeResults()]
///
class ResultNode {
  String attribute = '';
  Color color = Colors.transparent;
  Formatus formatus = Formatus.placeHolder;

  bool get isList => formatus.isList;

  /// Used to fill text in [TextField] or [TextFormField]
  List<InlineSpan> spans = [];

  @override
  String toString() => '<${formatus.key}> ${spans.length}';
}
