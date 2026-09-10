import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  final Color red = Color(0xffff0000);
  final String redDiv = '<div style="color: #ff0000ff;">';
  const Color blue = Color(0xff0000ff);
  final String blueDiv = '<div style="color: #0000ffff;">';

  group('commonFormatsAndColor with cursor position', () {
    test('move cursor over multiple nodes', () {
      //--- given
      final html =
          '<h1>head1</h1><p>para<ul>'
          '<li>One</li><li>Two <b>bold</b></li></ul>tail</p>';
      FormatusDocument doc = FormatusDocument(formatted: html);
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      //--- text excl. key-index. plainText = "head1¶para¶• One¶• Two bold¶tail"
      Map<int, String> texts = {
        6: 'head1',
        11: 'para',
        17: 'One',
        23: 'Two ',
        28: 'bold',
        32: 'tail',
      };
      List<int> breakPoints = texts.keys.toList();
      breakPoints.sort();
      expect(breakPoints.length + 2, textNodes.length);
      String prefix = '\n$unorderedListPrefix';
      expect(
        doc.results.plainText,
        'head1\npara${prefix}One${prefix}Two bold\ntail',
      );
      debugPrint('breaks at = $breakPoints');
      TreeHelper.printAll(doc, 'setup');

      //--- when / then
      int maxLen = doc.results.plainText.length;
      for (int curPos = 0; curPos < maxLen; curPos++) {
        int key = breakPoints.firstWhere((o) => curPos < o);
        FormatusNode node = doc.findNodeAtCursor(curPos);
        expect(
          node.text,
          texts[key],
          reason: '$curPos -> $key -> ${texts[key]} but is: ${node.text}',
        );
      }
    });
  });
  group('commonFormatsAndColor with selection-range', () {
    test('returns correct formats and color for a single unformatted node', () {
      //--- given
      final html = '<p>Hello World</p>';
      final doc = FormatusDocument(formatted: html);
      final range = TextRange(start: 0, end: 5);

      FormatusCommons commons = doc.commonColorAndFormats(range);

      expect(commons.formats, <Formatus>{.paragraph});
      expect(commons.color, Colors.transparent);
    });

    test('selection is within a single formatted node', () {
      //--- given
      final html = '<p>${blueDiv}Hello</div> World</p>';
      final doc = FormatusDocument(formatted: html);
      final range = TextRange(start: 0, end: 4);

      //--- when
      FormatusCommons commons = doc.commonColorAndFormats(range);

      //--- then
      expect(commons.formats, <Formatus>{.paragraph, .color});
      expect(commons.color, blue);
    });

    test('color shared across multiple nodes', () {
      // <b><i style="color: #ff0000ff;">Hello </i><i style="color: #ff0000ff;">World</i></b>
      final html = '<p>$redDiv<i>Hello </i><i>World</i></div></p>';
      final doc = FormatusDocument(formatted: html);
      final TextRange range = TextRange(start: 0, end: 11);

      // Select "Hello World" spanning both <i> nodes inside <b>
      FormatusCommons commons = doc.commonColorAndFormats(range);

      expect(commons.formats, <Formatus>{.paragraph, .color, .italic});
      expect(commons.color, red);
    });

    test('nodes have partially overlapping formats', () {
      final html = '<p><b>Hello </b><i>World</i></p>';
      final doc = FormatusDocument(formatted: html);
      final range = TextRange(start: 0, end: 11);

      FormatusCommons commons = doc.commonColorAndFormats(range);

      // Intersection of {bold} and {italic} should be empty
      expect(commons.formats, <Formatus>{.paragraph});
      expect(commons.color, Colors.transparent);
    });

    test('retains only shared formats across nodes', () {
      // <b><i>Hello </i></b><b>World</b>
      final html = '<p><b><i>Hello </i></b><b>World</b></p>';
      final doc = FormatusDocument(formatted: html);
      TreeHelper.printAll(doc, 'optimized');

      // Selection covers "Hello " (bold + italic) and "World" (bold)
      final range = TextRange(start: 0, end: 11);
      FormatusCommons commons = doc.commonColorAndFormats(range);

      // Only bold is common to both
      expect(commons.formats, <Formatus>{.paragraph, .bold});
      expect(commons.color, Colors.transparent);
    });

    test(
      'returns Colors.transparent when selecting across different colors',
      () {
        // Red "Hello " and Blue "World"
        final html =
            '<p><span style="color: #ff0000ff;">Hello </span>'
            '<span style="color: #0000ffff;">World</span></p>';
        final doc = FormatusDocument(formatted: html);
        final range = TextRange(start: 0, end: 11);
        FormatusCommons commons = doc.commonColorAndFormats(range);

        expect(commons.color, Colors.transparent);
      },
    );

    test(
      'returns Colors.transparent if one node in selection has no color',
      () {
        // Red "Hello " and Default "World"
        final html =
            '<p><span style="color: #ff0000ff;">Hello </span>World</p>';
        final doc = FormatusDocument(formatted: html);
        final range = TextRange(start: 0, end: 11);

        FormatusCommons commons = doc.commonColorAndFormats(range);

        expect(commons.color, Colors.transparent);
      },
    );

    test(
      'handles multi-paragraph selection spanning multiple block elements',
      () {
        // <h1><b style="color: #0000ffff;">Heading</b></h1><p><b style="color: #0000ffff;">Paragraph</b></p>
        final html =
            '<h1><b style="color: #0000ffff;">Heading</b></h1>'
            '<p><b style="color: #0000ffff;">Paragraph</b></p>';
        final doc = FormatusDocument(formatted: html);
        // Select from "Heading" across paragraph break to "Paragraph"
        final range = TextRange(start: 0, end: 16);

        FormatusCommons commons = doc.commonColorAndFormats(range);

        expect(commons.formats, contains(Formatus.bold));
        expect(commons.color, blue);
      },
    );

    test('handles cursor-like collapsed selection gracefully', () {
      final html = '<p><b><i style="color: #ff0000ff;">Test</i></b></p>';
      final doc = FormatusDocument(formatted: html);
      // Selection at offset 2 (collapsed cursor)
      final range = TextRange.collapsed(2);

      FormatusCommons commons = doc.commonColorAndFormats(range);

      expect(commons.formats, containsAll([Formatus.bold, Formatus.italic]));
      expect(commons.color, red);
    });
  });
}
