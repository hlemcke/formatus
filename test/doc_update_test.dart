import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

import 'test_helper.dart';

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
        prevSelection: TextSelection(
          baseOffset: 0,
          extentOffset: prevText.length,
        ),
        nextText: newText,
        nextSelection: TextSelection(
          baseOffset: 0,
          extentOffset: newText.length,
        ),
      );

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateText(deltaText, {Formatus.header1});
      TreeHelper.printAll(doc, 'updated');

      //--- then
      expect(deltaText.isAll, true);
      expect(deltaText.type, DeltaTextType.update);
      final textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 1);
      expect(doc[0].tag, Formatus.header1);
      expect(textNodes[0].text, newText);
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
        prevSelection: TextSelection(
          baseOffset: 0,
          extentOffset: prevText.length,
        ),
        nextText: newText,
        nextSelection: TextSelection(
          baseOffset: 0,
          extentOffset: newText.length,
        ),
      );

      //--- when
      doc.updateText(deltaText, {Formatus.paragraph});
      TreeHelper.printAll(doc, 'updated');

      //--- then
      expect(deltaText.isAll, true);
      expect(deltaText.type, DeltaTextType.update);
      final textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 1);
      expect(textNodes[0].formats, {Formatus.paragraph});
      expect(textNodes[0].text, newText);
    });
  });
}
