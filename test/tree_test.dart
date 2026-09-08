import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

import 'test_helper.dart';

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
      expect(doc.results.formatted, formatted);
      expect(doc.results.plainText, 'abc def ghi');
      expect(doc.childCount, 1);
    });

    //---
    test('In front of line-break must return previous node', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.childCount, 2);
    });

    //---
    test('Two empty paragraphs must return correct node', () {
      //--- given
      String formatted = '<h1>abc</h1><p></p><p></p><h2>def</h2>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.childCount, 4);
    });
  });

  //---
  group('Tree Tests == section results', () {
    test('Compute results for two sections', () {
      //--- given
      String formatted =
          '<h1>abc<b> def<u> ghi</u></b><i> jkl</i> mno</h1>'
          '<p><b>pqr </b>stu</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.childCount, 2);
      expect(doc.results.formatted, formatted);
      expect(doc.results.plainText, 'abc def ghi jkl mno\npqr stu');
    });

    //---
    test('Compute results for long text', () {
      //--- given
      String formatted = '''<h1>Formatus</h1>
      <h2>Features <u>underline</u></h2>
      <p>Line 3 with <b>bold and <i>nested</i></b> words</p>''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TreeHelper.printAll(doc, 'parsed');

      //--- then
      expect(doc.childCount, 3);
      expect(
        doc.results.formatted,
        '<h1>Formatus</h1>'
        '<h2>Features <u>underline</u></h2>'
        '<p>Line 3 with <b>bold and <i>nested</i></b> words</p>',
      );
      expect(
        doc.results.plainText,
        'Formatus\nFeatures underline\n'
        'Line 3 with bold and nested words',
      );
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
      expect(doc.childCount, 1);
      expect(doc.results.formatted, formatted);
      expect(doc.results.plainText, 'all italic bold plain');
    });
  });
}
