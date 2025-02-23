import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Apply format to text range', () {
    //---
    test('No selection -> no format update', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 6);

      //--- when
      doc.updateInlineFormat(selection, {Formatus.underline}, '');

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'Title Line');
    });

    //---
    test('Change format of first word', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);

      //--- when
      doc.updateInlineFormat(selection, {Formatus.header1, Formatus.bold}, '');

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[0].formats, [Formatus.header1, Formatus.bold]);
      expect(doc.textNodes[1].text, ' Line');
      expect(doc.textNodes[1].formats, [Formatus.header1]);
    });

    //---
    test('Change format of last word', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 10);

      //--- when
      doc.updateInlineFormat(selection, {Formatus.header1, Formatus.bold}, '');

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
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 10);

      //--- when
      doc.updateInlineFormat(selection, {Formatus.header1, Formatus.bold}, '');

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
    test('Remove format from middle word', () {
      //--- given
      String prevHtml = '<p>Some <b>bold</b> text</p>';
      FormatusDocument doc = FormatusDocument(formatted: prevHtml);
      TextSelection selection =
          const TextSelection(baseOffset: 5, extentOffset: 9);

      //--- when
      doc.updateInlineFormat(selection, {Formatus.paragraph}, '');

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Some bold text');
    });
  });
}
