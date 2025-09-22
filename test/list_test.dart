import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Parsing Ordered List tests', () {
    //---
    test('Parsing ordered list with 2 items enclosed in paragraphs', () {
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
        'Ordered list\n First element\n Second one\n... more text',
      );
    });

    //---
    test('Parsing ordered list with inline formats followed by P', () {
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
        ' First element\n Second one\n Item three\nTrailing paragraph',
      );
      expect(doc.textNodes[0].formats, [Formatus.orderedList, Formatus.bold]);
      expect(doc.textNodes[1].isLineFeed, true);
      expect(doc.textNodes[2].formats, [Formatus.orderedList]);
      expect(doc.textNodes[2].text, 'Second ');
      expect(doc.textNodes[3].formats, [Formatus.orderedList, Formatus.color]);
      expect(doc.textNodes[3].text, 'one');
      expect(doc.textNodes[3].color, orange);
    });
  });

  group('Line breaks in Ordered List', () {
    //---
    test('Inserting linebreak at start of list-item', () {
      //--- given
      String formatted = '''
<p>Ordered</p>
<ol><li>First</li><li>Second</li></ol>
''';
      String prevText = 'Ordered\n First\n Second';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      expect(doc.textNodes.length, 5);
      expect(doc.results.formattedText, formatted.replaceAll('\n', ''));
      expect(doc.results.plainText, prevText);

      //--- given
      String nextText = 'Ordered\n \nFirst\n Second';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 9, extentOffset: 9),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 10, extentOffset: 10),
      );

      //--- when
      doc.updateText(deltaText, {Formatus.orderedList});

      //--- then
      expect(deltaText.type, DeltaTextType.insert);
      expect(doc.results.textSpan.children?.length, 7);
      expect(doc.results.plainText, 'Ordered\n \n First\n Second');
      expect(
        doc.results.formattedText,
        '<p>Ordered</p><ol><li></li><li>First</li><li>Second</li></ol>',
      );
    });
  });
}
