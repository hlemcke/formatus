import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  //---
  group('Node identification test', () {
    //---
    test('Find first three nodes', () {
      //--- given
      String formatted = '<p>abc <b>def</b> ghi</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      for (int i = 0; i < 4; i++) {
        expect(doc.computeMeta(i).nodeIndex, 0, reason: '$i must return 0');
      }
      for (int i = 4; i < 8; i++) {
        expect(doc.computeMeta(i).nodeIndex, 1, reason: '$i must return 1');
      }
      for (int i = 8; i < 11; i++) {
        expect(doc.computeMeta(i).nodeIndex, 2, reason: '$i must return 2');
      }
    });

    //---
    test('In front of line-break must return previous node', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 3);
      for (int i = 0; i < 4; i++) {
        expect(doc.computeMeta(i).nodeIndex, 0, reason: '$i must return 0');
      }
      for (int i = 4; i < 7; i++) {
        expect(doc.computeMeta(i).nodeIndex, 2, reason: '$i must return 2');
      }
    });

    //---
    test('Two empty paragraphs must return correct node', () {
      //--- given
      Map<int, int> nodeByIndex = {
        0: 0,
        1: 0,
        2: 0,
        3: 0,
        4: 2,
        5: 4,
        6: 6,
        7: 6,
        8: 6,
        9: 6,
      };
      String formatted = '<h1>abc</h1><p></p><p></p><h2>def</h2>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 7);
      for (int i = 0; i < nodeByIndex.length; i++) {
        expect(
          doc.computeMeta(i).nodeIndex,
          nodeByIndex[i],
          reason: '$i must return ${nodeByIndex[i]}',
        );
      }
    });
  });

  //---
  group('Tree Tests == section results', () {
    //---
    test('Compute results for two sections', () {
      //--- given
      String formatted =
          '<h1>abc<b> def<u> ghi</u></b><i> jkl</i> mno</h1>'
          '<p><b>pqr </b>stu</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 8);
      expect(doc.results.formattedText, formatted);
      expect(doc.results.plainText, 'abc def ghi jkl mno\npqr stu');
      expect(doc.results.textSpan.children?.length, 3);
    });

    //---
    test('Compute results for long text', () {
      //--- given
      String formatted = '''<h1>Formatus</h1>
      <h2>Features <u>underline</u></h2>
      <p>Line 3 with <b>bold and <i>nested</i></b> words</p>''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 9);
      expect(
        doc.results.formattedText,
        '<h1>Formatus</h1>'
        '<h2>Features <u>underline</u></h2><p>Line 3 with '
        '<b>bold and <i>nested</i></b> words</p>',
      );
      expect(
        doc.results.plainText,
        'Formatus\nFeatures underline\n'
        'Line 3 with bold and nested words',
      );
    });
  });

  //---
  group('Tree Tests == color results', () {
    ///
    test('Results for first inline with deprecated color blue', () {
      //--- given
      String divBlue = '<div style="color: #ff0000ff;">';
      String formatted = '<p><color 0xFF0000ff>abc</color> def</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.results.plainText, 'abc def');
      expect(doc.results.formattedText, '<p>${divBlue}abc</div> def</p>');
    });

    ///
    test('Results for second inline with deprecated color blue', () {
      //--- given
      String divBlue = '<div style="color: #ff0000ff;">';
      String formatted = '<p>abc <color 0xFF0000ff>def</color> ghi</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, 'abc def ghi');
      expect(doc.results.formattedText, '<p>abc ${divBlue}def</div> ghi</p>');
    });
  });

  //---
  group('Tree Tests == deep nested inlines', () {
    ///
    test('One section with many inlines at start', () {
      String formatted = '<p><b><i><u>all</u> italic</i> bold</b> plain</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 4);
      expect(doc.results.formattedText, formatted);
      expect(doc.results.plainText, 'all italic bold plain');
      expect(doc.results.textSpan.children?.length, 1);
    });
  });
}
