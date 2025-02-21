import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  //---
  group('Node-list test', () {
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
  });

  //---
  group('Tree Tests == results computations', () {
    //---
    test('Compute results for single section', () {
      //--- given
      String formatted = '''<h1>abc<b> def<u> ghi</u></b><i> jkl</i> mno</h1>
      <p><b>pqr </b>stu</p>''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.results.plainText, 'abc def ghi jkl mno\npqr stu');
      expect(
          doc.results.formattedText,
          '<h1>abc<b> def<u> ghi</u></b><i> jkl</i>'
          ' mno</h1><p><b>pqr </b>stu</p>');
      expect(doc.results.textSpan.children?.length, 3);
    });

    ///
    test('Compute results for inline with color blue', () {
      //--- given
      String formatted = '<p>abc <color 0xFF0000ff>def</color></p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.results.plainText, 'abc def');
      expect(doc.results.formattedText,
          '<p>abc <color 0xFF0000ff>def</color></p>');
    });
  });
}
