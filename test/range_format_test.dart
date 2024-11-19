import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Apply format to text range', () {
    test('No selection -> no format update', () {
      //--- given
      String prevHtml = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      DeltaFormat deltaFormat = DeltaFormat(
          selectedFormats: {Formatus.header1},
          textFormats: [Formatus.paragraph]);
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 6);

      //--- when
      doc.updateFormatOfSelection(deltaFormat, selection);

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'Title Line');
    });
    test('Add format to first word', () {
      //--- given
      String prevHtml = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      DeltaFormat deltaFormat = DeltaFormat(
          selectedFormats: {Formatus.header1, Formatus.bold},
          textFormats: [Formatus.header1]);
      TextSelection selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);

      //--- when
      doc.updateFormatOfSelection(deltaFormat, selection);

      //--- then
      expect(doc.root.children.length, 1);
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1, Formatus.bold]);
      expect(doc.textNodes[1].text, ' Line');
      expect(doc.textNodes[1].formatsInPath, [Formatus.header1]);
    });
    test('Add format to last word', () {
      //--- given
      String prevHtml = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      DeltaFormat deltaFormat = DeltaFormat(
          selectedFormats: {Formatus.header1, Formatus.bold},
          textFormats: [Formatus.header1]);
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 10);

      //--- when
      doc.updateFormatOfSelection(deltaFormat, selection);

      //--- then
      expect(doc.root.children.length, 1);
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
      expect(doc.textNodes[1].text, 'Line');
      expect(doc.textNodes[1].formatsInPath, [Formatus.header1, Formatus.bold]);
    });
    test('Add format to middle word', () {
      //--- given
      String prevHtml = '<h1>Title middle Line</h1>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      DeltaFormat deltaFormat = DeltaFormat(
          selectedFormats: {Formatus.header1, Formatus.bold},
          textFormats: [Formatus.header1]);
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 10);

      //--- when
      doc.updateFormatOfSelection(deltaFormat, selection);

      //--- then
      expect(doc.root.children.length, 1);
      expect(doc.root.children[0].children.length, 3);
      expect(doc.textNodes.length, 3);
      expect(doc.textNodes[0].text, 'Title ');
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
      expect(doc.textNodes[1].text, 'midd');
      expect(doc.textNodes[1].formatsInPath, [Formatus.header1, Formatus.bold]);
      expect(doc.textNodes[2].text, 'le Line');
      expect(doc.textNodes[2].formatsInPath, [Formatus.header1]);
    });
  });

  group('Remove format from text range', () {
    test('Remove format from middle word', () {
      //--- given
      String prevHtml = '<p>Some <b>bold</b> text</p>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      DeltaFormat deltaFormat = DeltaFormat(
          selectedFormats: {Formatus.paragraph},
          textFormats: [Formatus.paragraph, Formatus.bold]);
      TextSelection selection =
          const TextSelection(baseOffset: 5, extentOffset: 9);

      //--- when
      doc.updateFormatOfSelection(deltaFormat, selection);

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formatsInPath, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Some bold text');
    });
  });
}
