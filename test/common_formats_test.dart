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
      String formatted =
          '<h1>head1</h1><p>para<ul>'
          '<li>One</li><li>Two <b>bold</b></li></ul>tail</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
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
      print('breaks at = $breakPoints');
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
      final doc = FormatusDocument(formatted: '<p>Hello World</p>');
      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 5);

      doc.commonFormatsAndColor(doc.results);

      expect(doc.results.formats, <Formatus>{.paragraph});
      expect(doc.results.color, Colors.transparent);
    });

    test('selection is within a single formatted node', () {
      //--- given
      final doc = FormatusDocument(
        formatted: '<p>${blueDiv}Hello</div> World</p>',
      );

      //--- when
      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 4);
      doc.commonFormatsAndColor(doc.results);

      //--- then
      expect(doc.results.formats, <Formatus>{.paragraph, .color});
      expect(doc.results.color, blue);
    });

    test('color shared across multiple nodes', () {
      // <b><i style="color: #ff0000ff;">Hello </i><i style="color: #ff0000ff;">World</i></b>
      final doc = FormatusDocument(
        formatted: '<p>$redDiv<i>Hello </i><i>World</i></div></p>',
      );

      // Select "Hello World" spanning both <i> nodes inside <b>
      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 11);

      doc.commonFormatsAndColor(doc.results);

      expect(doc.results.formats, <Formatus>{.paragraph, .color, .italic});
      expect(doc.results.color, red);
    });

    test('nodes have partially overlapping formats', () {
      final doc = FormatusDocument(
        formatted: '<p><b>Hello </b><i>World</i></p>',
      );

      // Selection covers "Hello " (bold) and "World" (italic)
      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 11);

      doc.commonFormatsAndColor(doc.results);

      // Intersection of {bold} and {italic} should be empty
      expect(doc.results.formats, <Formatus>{.paragraph});
      expect(doc.results.color, Colors.transparent);
    });

    test('retains only shared formats across nodes', () {
      // <b><i>Hello </i></b><b>World</b>
      final doc = FormatusDocument(
        formatted: '<p><b><i>Hello </i></b><b>World</b></p>',
      );
      TreeHelper.printAll(doc, 'optimized');

      // Selection covers "Hello " (bold + italic) and "World" (bold)
      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 11);

      doc.commonFormatsAndColor(doc.results);

      // Only bold is common to both
      expect(doc.results.formats, <Formatus>{.paragraph, .bold});
      expect(doc.results.color, Colors.transparent);
    });

    test('returns Colors.transparent when selecting across different colors', () {
      // Red "Hello " and Blue "World"
      final doc = FormatusDocument(
        formatted:
            '<p><span style="color: #ff0000ff;">Hello </span><span style="color: #0000ffff;">World</span></p>',
      );

      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 11);

      doc.commonFormatsAndColor(doc.results);

      expect(doc.results.color, Colors.transparent);
    });

    test(
      'returns Colors.transparent if one node in selection has no color',
      () {
        // Red "Hello " and Default "World"
        final doc = FormatusDocument(
          formatted:
              '<p><span style="color: #ff0000ff;">Hello </span>World</p>',
        );

        doc.results.range = TextSelection(baseOffset: 0, extentOffset: 11);

        doc.commonFormatsAndColor(doc.results);

        expect(doc.results.color, Colors.transparent);
      },
    );

    test('handles multi-paragraph selection spanning multiple block elements', () {
      // <h1><b style="color: #0000ffff;">Heading</b></h1><p><b style="color: #0000ffff;">Paragraph</b></p>
      final doc = FormatusDocument(
        formatted:
            '<h1><b style="color: #0000ffff;">Heading</b></h1><p><b style="color: #0000ffff;">Paragraph</b></p>',
      );

      // Select from "Heading" across paragraph break to "Paragraph"
      doc.results.range = TextSelection(baseOffset: 0, extentOffset: 16);

      doc.commonFormatsAndColor(doc.results);

      expect(doc.results.formats, contains(Formatus.bold));
      expect(doc.results.color, blue);
    });

    test('handles cursor-like collapsed selection gracefully', () {
      final doc = FormatusDocument(
        formatted: '<p><b><i style="color: #ff0000ff;">Test</i></b></p>',
      );

      // Selection at offset 2 (collapsed cursor)
      doc.results.range = TextSelection(baseOffset: 2, extentOffset: 2);

      final result = doc.commonFormatsAndColor(doc.results);

      expect(
        doc.results.formats,
        containsAll([Formatus.bold, Formatus.italic]),
      );
      expect(doc.results.color, red);
    });
  });
}
