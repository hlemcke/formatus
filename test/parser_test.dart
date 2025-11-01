import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_node.dart';
import 'package:formatus/src/formatus/formatus_parser.dart';

void main() {
  group('Parser: Single Section tests', () {
    //---
    test('parse single section', () {
      //--- given
      String formatted = '<h1>some text</h1>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 1);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'some text');
    });

    //---
    test('parse single section with 2 inlines', () {
      //--- given
      String formatted =
          '<h1>Formatus <b>Features</b> with <i>italic</i> words</h1>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 5);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Formatus ');
      expect(nodes[1].formats, [Formatus.header1, Formatus.bold]);
      expect(nodes[1].text, 'Features');
      expect(nodes[2].formats, [Formatus.header1]);
      expect(nodes[2].text, ' with ');
      expect(nodes[3].formats, [Formatus.header1, Formatus.italic]);
      expect(nodes[3].text, 'italic');
      expect(nodes[4].formats, [Formatus.header1]);
      expect(nodes[4].text, ' words');
    });

    //---
    test('parse two sections without inlines', () {
      //--- given
      String formatted = '<h1>Formatus</h1><h2>Features</h2>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 3);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Formatus');
      expect(nodes[1].isLineFeed, true);
      expect(nodes[2].formats, [Formatus.header2]);
      expect(nodes[2].text, 'Features');
    });

    //---
    test('parse three sections with inlines', () {
      //--- given
      String formatted = '''<h1>Formatus</h1>
      <h2>Features <u>underline</u></h2>
      <p>Line 3 with <b>bold and <i>nested</i></b> words</p>''';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 9);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Formatus');
      expect(nodes[1].isLineFeed, true);
      expect(nodes[2].formats, [Formatus.header2]);
      expect(nodes[2].text, 'Features ');
      expect(nodes[3].formats, [Formatus.header2, Formatus.underline]);
      expect(nodes[3].text, 'underline');
      expect(nodes[4].isLineFeed, true);
      expect(nodes[5].formats, [Formatus.paragraph]);
      expect(nodes[5].text, 'Line 3 with ');
      expect(nodes[6].formats, [Formatus.paragraph, Formatus.bold]);
      expect(nodes[6].text, 'bold and ');
      expect(nodes[7].formats, [
        Formatus.paragraph,
        Formatus.bold,
        Formatus.italic,
      ]);
      expect(nodes[7].text, 'nested');
      expect(nodes[8].formats, [Formatus.paragraph]);
      expect(nodes[8].text, ' words');
    });

    //---
    test('parse tree structure', () {
      //--- given
      String formatted = '''<h1>abc<b> def<u> ghi</u></b><i> jkl</i> mno</h1>
      <p><b>pqr </b>stu</p>''';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 8);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'abc');
      expect(nodes[1].formats, [Formatus.header1, Formatus.bold]);
      expect(nodes[1].text, ' def');
      expect(nodes[2].formats, [
        Formatus.header1,
        Formatus.bold,
        Formatus.underline,
      ]);
      expect(nodes[2].text, ' ghi');
      expect(nodes[3].formats, [Formatus.header1, Formatus.italic]);
      expect(nodes[3].text, ' jkl');
      expect(nodes[4].formats, [Formatus.header1]);
      expect(nodes[4].text, ' mno');
      expect(nodes[5].isLineFeed, true);
      expect(nodes[6].formats, [Formatus.paragraph, Formatus.bold]);
      expect(nodes[6].text, 'pqr ');
      expect(nodes[7].formats, [Formatus.paragraph]);
      expect(nodes[7].text, 'stu');
    });

    //---
    test('parse color blue', () {
      //--- given
      String blueDiv = '<div style="color: #FF0000ff">';
      String formatted = '<p>abc ${blueDiv}def</div></p>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 2);
      expect(nodes[0].formats, [Formatus.paragraph]);
      expect(nodes[0].text, 'abc ');
      expect(nodes[1].formats, [Formatus.paragraph, Formatus.color]);
      expect(nodes[1].text, 'def');
      expect(nodes[1].color, Color(0xFF0000ff));
    });

    //---
    test('parse color blue from deprecated format', () {
      //--- given
      String formatted = '<p>abc <color 0xFF0000ff>blue</color></p>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 2);
      expect(nodes[0].formats, [Formatus.paragraph]);
      expect(nodes[0].text, 'abc ');
      expect(nodes[1].formats, [Formatus.paragraph, Formatus.color]);
      expect(nodes[1].text, 'blue');
      expect(nodes[1].color, Color(0xFF0000ff));
    });

    //---
    test('parse subscript', () {
      //--- given
      String formatted = '<p>abc <sub>def</sub> ghi</p>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 3);
      expect(nodes[0].formats, [Formatus.paragraph]);
      expect(nodes[0].text, 'abc ');
      expect(nodes[1].formats, [Formatus.paragraph, Formatus.subscript]);
      expect(nodes[1].text, 'def');
      expect(nodes[2].formats, [Formatus.paragraph]);
      expect(nodes[2].text, ' ghi');
    });

    //---
    test('parse superscript at start', () {
      //--- given
      String formatted = '<p><super>abc</super> def</p>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 2);
      expect(nodes[0].formats, [Formatus.paragraph, Formatus.superscript]);
      expect(nodes[0].text, 'abc');
      expect(nodes[1].formats, [Formatus.paragraph]);
      expect(nodes[1].text, ' def');
    });

    //---
    test('parse superscript in second inline', () {
      //--- given
      String formatted = '<p>abc <super>def</super> ghi</p>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 3);
      expect(nodes[0].formats, [Formatus.paragraph]);
      expect(nodes[0].text, 'abc ');
      expect(nodes[1].formats, [Formatus.paragraph, Formatus.superscript]);
      expect(nodes[1].text, 'def');
      expect(nodes[2].formats, [Formatus.paragraph]);
      expect(nodes[2].text, ' ghi');
    });

    //---
    test('parse long example', () {
      //--- given
      String formatted = '''
<h1>Formatus Features</h1>
<h2>Text with <b>bold</b>, <i>italic</i> and <u>underlined</u> words</h2>.
<p>Third line <i>contains <s>nested</s> and</i> <u>under<b>line</b>d</u> text.</p>
''';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      int i = 0;
      expect(nodes.length, 19);
      expect(nodes[i].formats, [Formatus.header1]);
      expect(nodes[i++].text, 'Formatus Features');
      expect(nodes[i++].isLineFeed, true);
      expect(nodes[i].formats, [Formatus.header2]);
      expect(nodes[i++].text, 'Text with ');
      expect(nodes[i].formats, [Formatus.header2, Formatus.bold]);
      expect(nodes[i++].text, 'bold');
      expect(nodes[i].formats, [Formatus.header2]);
      expect(nodes[i++].text, ', ');
      // TODO append expects for remaining nodes
    });
  });

  group('Parser: List tests', () {
    //---
    test('Parse ol with one item', () {
      //--- given
      String formatted = '<ol><li>Single element</li></ol>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 1);
      expect(nodes[0].formats, [Formatus.orderedList]);
      expect(nodes[0].text, 'Single element');
    });

    //---
    test('Parse ul with 2 items', () {
      //--- given
      String formatted = '<ul><li>First</li><li>Second</li></ul>';

      //--- when
      FormatusParser parser = FormatusParser(formatted: formatted);
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 3);
      expect(nodes[0].formats, [Formatus.unorderedList]);
      expect(nodes[0].text, 'First');
      expect(nodes[1].formats, [Formatus.lineFeed]);
      expect(nodes[2].formats, [Formatus.unorderedList]);
      expect(nodes[2].text, 'Second');
    });

    //---
    test('Parse ol with two items prefixed with H1', () {
      //--- given
      String formatted = '<h1>Title</h1><ol><li>First</li><li>Second</li></ol>';

      //--- when
      FormatusParser parser = FormatusParser(formatted: formatted);
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 5);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Title');
      expect(nodes[1].formats, [Formatus.lineFeed]);
      expect(nodes[2].formats, [Formatus.orderedList]);
      expect(nodes[2].text, 'First');
      expect(nodes[3].formats, [Formatus.lineFeed]);
      expect(nodes[4].formats, [Formatus.orderedList]);
      expect(nodes[4].text, 'Second');
    });

    //---
    test('Parse ul with two items suffixed with P', () {
      //--- given
      String formatted = '<ul><li>First</li><li>Second</li></ul><p>para</p>';

      //--- when
      FormatusParser parser = FormatusParser(formatted: formatted);
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 5);
      expect(nodes[0].formats, [Formatus.unorderedList]);
      expect(nodes[0].text, 'First');
      expect(nodes[1].formats, [Formatus.lineFeed]);
      expect(nodes[2].formats, [Formatus.unorderedList]);
      expect(nodes[2].text, 'Second');
      expect(nodes[3].formats, [Formatus.lineFeed]);
      expect(nodes[4].formats, [Formatus.paragraph]);
      expect(nodes[4].text, 'para');
    });

    //---
    test('Parse ul with two items prefixed with h1 and suffixed with P', () {
      //--- given
      String formatted = '''
      <h1>Title</h1><ul><li>First</li><li>Second</li></ul><p>para</p>''';

      //--- when
      FormatusParser parser = FormatusParser(formatted: formatted);
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 7);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Title');
      expect(nodes[1].formats, [Formatus.lineFeed]);
      expect(nodes[2].formats, [Formatus.unorderedList]);
      expect(nodes[2].text, 'First');
      expect(nodes[3].formats, [Formatus.lineFeed]);
      expect(nodes[4].formats, [Formatus.unorderedList]);
      expect(nodes[4].text, 'Second');
      expect(nodes[5].formats, [Formatus.lineFeed]);
      expect(nodes[6].formats, [Formatus.paragraph]);
      expect(nodes[6].text, 'para');
    });
  });

  group('Parser: test unknown tags and broken structure', () {
    test('Parse tag em inside section p', () {
      //--- given
      String formatted = '<p>Para with <em>emphasized</em> text</p>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 1);
      expect(nodes[0].formats, [Formatus.paragraph]);
      expect(nodes[0].text, 'Para with emphasized text');
    });
    test('Parse only tag em', () {
      //--- given
      String formatted = '<em>Emphasized with <b>bold</b> text</em>';
      FormatusParser parser = FormatusParser(formatted: formatted);

      //--- when
      List<FormatusNode> nodes = parser.parse();

      //--- then
      expect(nodes.length, 3);
      expect(nodes[0].formats, [Formatus.paragraph]);
      expect(nodes[0].text, 'Emphasized with ');
      expect(nodes[1].formats, [Formatus.paragraph, Formatus.bold]);
      expect(nodes[1].text, 'bold');
      expect(nodes[2].formats, [Formatus.paragraph]);
      expect(nodes[2].text, ' text');
    });
  });
}
