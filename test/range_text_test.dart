import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Change text in selected range', () {
    test('replace at all - single node', () {
      //--- given
      String prevHtml = '<h1>Title Line</h1>';
      String newText = 'Formatus';
      FormatusDocument doc = FormatusDocument(body: prevHtml);
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection:
              TextSelection(baseOffset: 0, extentOffset: doc.plainText.length),
          nextText: newText,
          nextSelection:
              TextSelection(baseOffset: 0, extentOffset: newText.length));

      //--- when
      doc.handleDeleteAndUpdate(deltaText);

      //--- then
      expect(deltaText.position, DeltaTextPosition.all);
      expect(deltaText.type, DeltaTextType.update);
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
      expect(doc.textNodes[0].text, newText);
    });

    //---
    test('replace at all - three nodes', () {
      //--- given
      String prevHtml = '<h1>Title Line</h1><p>Second</p><h3>third</h3>';
      String newText = 'Formatus';
      FormatusDocument doc = FormatusDocument(body: prevHtml);
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection:
              TextSelection(baseOffset: 0, extentOffset: doc.plainText.length),
          nextText: newText,
          nextSelection:
              TextSelection(baseOffset: 0, extentOffset: newText.length));

      //--- when
      doc.handleDeleteAndUpdate(deltaText);

      //--- then
      expect(deltaText.position, DeltaTextPosition.all);
      expect(deltaText.type, DeltaTextType.update);
      expect(doc.textNodes.length, 1);
      expect(doc.textNodes[0].formatsInPath, [Formatus.header1]);
      expect(doc.textNodes[0].text, newText);
    });
  });
}
