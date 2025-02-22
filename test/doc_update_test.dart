import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Document - update text in selected range', () {
    test('update all in single section', () {
      //--- given
      String formatted = '<h1>Title Line</h1>';
      String newText = 'Formatus';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String prevText = doc.results.plainText;
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection:
              TextSelection(baseOffset: 0, extentOffset: prevText.length),
          nextText: newText,
          nextSelection:
              TextSelection(baseOffset: 0, extentOffset: newText.length));

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, null);

      //--- then
      expect(deltaText.isAll, true);
      expect(deltaText.type, DeltaTextType.update);
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, newText);
    });

    //---
    test('update all - three sections', () {
      //--- given
      String formatted = '<h1>Title Line</h1><p>Second</p><h3>third</h3>';
      String newText = 'Formatus';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String prevText = doc.results.plainText;
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection:
              TextSelection(baseOffset: 0, extentOffset: prevText.length),
          nextText: newText,
          nextSelection:
              TextSelection(baseOffset: 0, extentOffset: newText.length));

      //--- when
      doc.updateText(deltaText, {Formatus.paragraph}, null);

      //--- then
      expect(deltaText.isAll, true);
      expect(deltaText.type, DeltaTextType.update);
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, newText);
    });
  });
}
