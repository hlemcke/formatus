import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Ordered list tests', () {
    //---
    test('Ordered list with 2 items enclosed in paragraphs', () {
      //--- given
      String formatted = '''
<p>Ordered list</p>
<ol><li>First element</li><li>Second one</li></ol>
<p>... more text</p>
''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 7);
      expect(doc.results.formattedText, formatted.replaceAll('\n', ''));
      expect(
        doc.results.plainText,
        'Ordered list\nFirst element\nSecond one\n... more text',
      );
    });

    //---
    test('Ordered list with 3 items following H1', () {
      //--- given
      String formatted = '''
<h1>Ordered H1</h1>
<ol><li>First element</li><li>Second one</li><li>Item three</li></ol>
''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 7);
      expect(doc.results.formattedText, formatted.replaceAll('\n', ''));
      expect(
        doc.results.plainText,
        'Ordered H1\nFirst element\nSecond one\nItem three',
      );
    });

    //---
    test('Ordered list with inline formats followed by P', () {
      //--- given
      final Color orange = Color(0xffff9800);
      final String orangeDiv = '<div style="color: #ffff9800;">';
      String formatted =
          '''
<ol><li><b>First element</b></li>
<li>Second ${orangeDiv}one</div></li>
<li><u><i>Item</i> three</u></li></ol>
<p>Trailing paragraph</p>
''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 9);
      expect(doc.results.formattedText, formatted.replaceAll('\n', ''));
      expect(
        doc.results.plainText,
        'First element\nSecond one\nItem three\nTrailing paragraph',
      );
      expect(doc.textNodes[0].formats, [
        Formatus.orderedList,
        Formatus.listItem,
        Formatus.bold,
      ]);
      expect(doc.textNodes[1].isLineBreak, true);
      expect(doc.textNodes[2].formats, [
        Formatus.orderedList,
        Formatus.listItem,
      ]);
      expect(doc.textNodes[2].text, 'Second ');
      expect(doc.textNodes[3].formats, [
        Formatus.orderedList,
        Formatus.listItem,
        Formatus.color,
      ]);
      expect(doc.textNodes[3].text, 'one');
      expect(doc.textNodes[3].color, orange);
    });
  });
}
