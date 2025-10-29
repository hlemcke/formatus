import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

final Color orange = Color(0xffff9800);
final String orangeDiv = '<div style="color: #ffff9800;">';

void main() {
  group('Apply format to single node', () {
    //---
    test('No text range -> no format update', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 6,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.underline);

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'Title Line');
    });

    //---
    test('Change format of first word to bold', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.bold);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[0].formats, [Formatus.header1, Formatus.bold]);
      expect(doc.textNodes[1].text, ' Line');
      expect(doc.textNodes[1].formats, [Formatus.header1]);
    });

    //---
    test('Set format of last word to bold', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 10,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.bold);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[1].text, 'Line');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.bold]);
    });

    //---
    test('Add format to middle word', () {
      //--- given
      String formatted = '<h1>Title middle Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 10,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.bold);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[1].text, 'midd');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.bold]);
      expect(doc.textNodes[2].text, 'le Line');
      expect(doc.textNodes[2].formats, [Formatus.header1]);
    });
  });

  ///
  group('Remove format from text range', () {
    test('Remove format from bold middle word', () {
      //--- given
      String prevHtml = '<p>Some <b>bold</b> text</p>';
      FormatusDocument doc = FormatusDocument(formatted: prevHtml);
      TextSelection selection = const TextSelection(
        baseOffset: 5,
        extentOffset: 9,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.bold);

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Some bold text');
    });
  });

  group('Apply format to multiple nodes', () {
    //---
    test('Make full text italic', () {
      //--- given
      String formatted = '<h1><b>Title</b> Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.italic);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].formats, [
        Formatus.header1,
        Formatus.bold,
        Formatus.italic,
      ]);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.italic]);
      expect(doc.textNodes[1].text, ' Line');
    });
    //---
    test('Change color of whole text having multiple inline formats', () {
      //--- given
      String formatted = '<h1><b>Title </b><i>Line </i><u>With </u>Color</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.color, color: orange);

      //--- then
      expect(doc.textNodes.length, 4);
      expect(
        doc.results.formattedText,
        '<h1><b>${orangeDiv}Title </div></b><i>${orangeDiv}Line </div></i>'
        '<u>${orangeDiv}With </div></u>${orangeDiv}Color</div></h1>',
      );
      //"Title "
      expect(doc.textNodes[0].formats, [
        Formatus.header1,
        Formatus.bold,
        Formatus.color,
      ]);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].color, orange);
      //"Line "
      expect(doc.textNodes[1].formats, [
        Formatus.header1,
        Formatus.italic,
        Formatus.color,
      ]);
      expect(doc.textNodes[1].text, 'Line ');
      expect(doc.textNodes[1].color, orange);
      //"With "
      expect(doc.textNodes[2].formats, [
        Formatus.header1,
        Formatus.underline,
        Formatus.color,
      ]);
      expect(doc.textNodes[2].text, 'With ');
      expect(doc.textNodes[2].color, orange);
      //"Color"
      expect(doc.textNodes[3].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[3].text, 'Color');
      expect(doc.textNodes[3].color, orange);
    });
    //---
    test('Change format of text containing a colored word', () {
      //--- given
      String formatted = '<h1>${orangeDiv}Title </div>Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.italic);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].formats, [
        Formatus.header1,
        Formatus.color,
        Formatus.italic,
      ]);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].color, orange);

      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.italic]);
      expect(doc.textNodes[1].text, 'Line');
    });

    //---
    test('Change paragraph with multiple formats to h1', () {
      //--- given
      String formatted =
          '<p><b>Title </b><i>Line </i><u>With </u>${orangeDiv}Color</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateSectionFormat(selection, Formatus.header1);

      //--- then
      expect(doc.textNodes.length, 4);
      //"Title "
      expect(doc.textNodes[0].formats, [Formatus.header1, Formatus.bold]);
      expect(doc.textNodes[0].text, 'Title ');
      //"Line "
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.italic]);
      expect(doc.textNodes[1].text, 'Line ');
      //"With "
      expect(doc.textNodes[2].formats, [Formatus.header1, Formatus.underline]);
      expect(doc.textNodes[2].text, 'With ');
      //"Color"
      expect(doc.textNodes[3].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[3].text, 'Color');
      expect(doc.textNodes[3].color, orange);
    });

    //---
    test('Make partially bold text full bold', () {
      //--- given
      String formatted =
          '<p><b>Title </b><i>Line </i><u>With </u>${orangeDiv}Color</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.bold);

      //--- then
      expect(doc.textNodes.length, 4);
      //"Title "
      expect(doc.textNodes[0].formats, [Formatus.paragraph, Formatus.bold]);
      expect(doc.textNodes[0].text, 'Title ');
      //"Line "
      expect(doc.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.italic,
        Formatus.bold,
      ]);
      expect(doc.textNodes[1].text, 'Line ');
      //"With "
      expect(doc.textNodes[2].formats, [
        Formatus.paragraph,
        Formatus.underline,
        Formatus.bold,
      ]);
      expect(doc.textNodes[2].text, 'With ');
      //"Color"
      expect(doc.textNodes[3].formats, [
        Formatus.paragraph,
        Formatus.color,
        Formatus.bold,
      ]);
      expect(doc.textNodes[3].text, 'Color');
      expect(doc.textNodes[3].color, orange);
    });

    //---
    test('Make partially italic text full italic', () {
      //--- given
      String formatted =
          '<p><b>Title </b><i>Line </i><u>With </u>${orangeDiv}Color</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.italic);

      //--- then
      expect(doc.textNodes.length, 4);
      //"Title "
      expect(doc.textNodes[0].formats, [
        Formatus.paragraph,
        Formatus.bold,
        Formatus.italic,
      ]);
      expect(doc.textNodes[0].text, 'Title ');
      //"Line "
      expect(doc.textNodes[1].formats, [Formatus.paragraph, Formatus.italic]);
      expect(doc.textNodes[1].text, 'Line ');
      //"With "
      expect(doc.textNodes[2].formats, [
        Formatus.paragraph,
        Formatus.underline,
        Formatus.italic,
      ]);
      expect(doc.textNodes[2].text, 'With ');
      //"Color"
      expect(doc.textNodes[3].formats, [
        Formatus.paragraph,
        Formatus.color,
        Formatus.italic,
      ]);
      expect(doc.textNodes[3].text, 'Color');
      expect(doc.textNodes[3].color, orange);
    });

    //---
    test('Make partially underlined text full underlined', () {
      //--- given
      String formatted =
          '<p><b>Title </b><i>Line </i><u>With </u>${orangeDiv}Color</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.underline);

      //--- then
      expect(doc.textNodes.length, 4);
      //"Title "
      expect(doc.textNodes[0].formats, [
        Formatus.paragraph,
        Formatus.bold,
        Formatus.underline,
      ]);
      expect(doc.textNodes[0].text, 'Title ');
      //"Line "
      expect(doc.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.italic,
        Formatus.underline,
      ]);
      expect(doc.textNodes[1].text, 'Line ');
      //"With "
      expect(doc.textNodes[2].formats, [
        Formatus.paragraph,
        Formatus.underline,
      ]);
      expect(doc.textNodes[2].text, 'With ');
      //"Color"
      expect(doc.textNodes[3].formats, [
        Formatus.paragraph,
        Formatus.color,
        Formatus.underline,
      ]);
      expect(doc.textNodes[3].text, 'Color');
      expect(doc.textNodes[3].color, orange);
    });

    //---
    test('Make partially colored text full colored', () {
      //--- given
      String formatted =
          '<p><b>Title </b><i>Line </i><u>With </u>${orangeDiv}Color</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.color, color: orange);

      //--- then
      expect(doc.textNodes.length, 4);
      //"Title "
      expect(doc.textNodes[0].formats, [
        Formatus.paragraph,
        Formatus.bold,
        Formatus.color,
      ]);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].color, orange);
      //"Line "
      expect(doc.textNodes[1].formats, [
        Formatus.paragraph,
        Formatus.italic,
        Formatus.color,
      ]);
      expect(doc.textNodes[1].text, 'Line ');
      expect(doc.textNodes[1].color, orange);
      //"With "
      expect(doc.textNodes[2].formats, [
        Formatus.paragraph,
        Formatus.underline,
        Formatus.color,
      ]);
      expect(doc.textNodes[2].text, 'With ');
      expect(doc.textNodes[2].color, orange);
      //"Color"
      expect(doc.textNodes[3].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[3].text, 'Color');
      expect(doc.textNodes[3].color, orange);
    });
  });
}
