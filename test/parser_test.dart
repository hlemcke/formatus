import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_node.dart';
import 'package:formatus/src/formatus/formatus_parser.dart';

void main() {
  group('ParserTests', () {
    //---
    test('parse single section', () {
      //--- given
      String formatted = '<h1>some text</h1>';
      FormatusParser parser = FormatusParser();

      //--- when
      List<FormatusNode> nodes = parser.parse(formatted);

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
      FormatusParser parser = FormatusParser();

      //--- when
      List<FormatusNode> nodes = parser.parse(formatted);

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
      FormatusParser parser = FormatusParser();

      //--- when
      List<FormatusNode> nodes = parser.parse(formatted);

      //--- then
      expect(nodes.length, 3);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Formatus');
      expect(nodes[1].isLineBreak, true);
      expect(nodes[2].formats, [Formatus.header2]);
      expect(nodes[2].text, 'Features');
    });

    //---
    test('parse three sections with inlines', () {
      //--- given
      String formatted = '''<h1>Formatus</h1>
      <h2>Features <u>underline</u></h2>
      <p>Line 3 with <b>bold and <i>nested</i></b> words</p>''';
      FormatusParser parser = FormatusParser();

      //--- when
      List<FormatusNode> nodes = parser.parse(formatted);

      //--- then
      expect(nodes.length, 9);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'Formatus');
      expect(nodes[1].isLineBreak, true);
      expect(nodes[2].formats, [Formatus.header2]);
      expect(nodes[2].text, 'Features ');
      expect(nodes[3].formats, [Formatus.header2, Formatus.underline]);
      expect(nodes[3].text, 'underline');
      expect(nodes[4].isLineBreak, true);
      expect(nodes[5].formats, [Formatus.paragraph]);
      expect(nodes[5].text, 'Line 3 with ');
      expect(nodes[6].formats, [Formatus.paragraph, Formatus.bold]);
      expect(nodes[6].text, 'bold and ');
      expect(nodes[7].formats,
          [Formatus.paragraph, Formatus.bold, Formatus.italic]);
      expect(nodes[7].text, 'nested');
      expect(nodes[8].formats, [Formatus.paragraph]);
      expect(nodes[8].text, ' words');
    });

    //---
    test('parse tree structure', () {
      //--- given
      String formatted = '''<h1>abc<b> def<u> ghi</u></b><i> jkl</i> mno</h1>
      <p><b>pqr </b>stu</p>''';
      FormatusParser parser = FormatusParser();

      //--- when
      List<FormatusNode> nodes = parser.parse(formatted);

      //--- then
      expect(nodes.length, 8);
      expect(nodes[0].formats, [Formatus.header1]);
      expect(nodes[0].text, 'abc');
      expect(nodes[1].formats, [Formatus.header1, Formatus.bold]);
      expect(nodes[1].text, ' def');
      expect(nodes[2].formats,
          [Formatus.header1, Formatus.bold, Formatus.underline]);
      expect(nodes[2].text, ' ghi');
      expect(nodes[3].formats, [Formatus.header1, Formatus.italic]);
      expect(nodes[3].text, ' jkl');
      expect(nodes[4].formats, [Formatus.header1]);
      expect(nodes[4].text, ' mno');
      expect(nodes[5].isLineBreak, true);
      expect(nodes[6].formats, [Formatus.paragraph, Formatus.bold]);
      expect(nodes[6].text, 'pqr ');
      expect(nodes[7].formats, [Formatus.paragraph]);
      expect(nodes[7].text, 'stu');
    });
  });
}
