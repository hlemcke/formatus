import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Reformat text range', () {
    test('No selection -> no format update', () {
      String prevHtml = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      doc.updateFormatOfSelection(Formatus.italic, true,
          const TextSelection(baseOffset: 6, extentOffset: 6));
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
    });
    test('Add format to single word', () {
      String prevHtml = '<h1>Title Line</h1>';
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      doc.updateFormatOfSelection(Formatus.italic, true,
          const TextSelection(baseOffset: 6, extentOffset: 10));
      expect(doc.root.children.length, 1);
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
      expect(
          doc.textNodes[1].formatsInPath, [Formatus.header1, Formatus.italic]);
    });
  });
}
