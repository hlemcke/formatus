import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  ///
  group('Document - Delete single character', () {
    ///
    test('Delete first character', () {
      //--- given
      String formatted = '<h1>formatus</h1><p>second</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.childCount, 2);
      String prevText = doc.results.plainText;
      DeltaText deltaText = DeltaText(
        prevText: prevText,
        prevRange: TextSelection(baseOffset: 0, extentOffset: 0),
        nextText: prevText.substring(1),
        nextRange: TextSelection(baseOffset: 0, extentOffset: 0),
      );

      //--- when
      doc.updateText(deltaText, {Formatus.header1});
      TreeHelper.printAll(doc, 'First char removed');

      //--- then
      expect(doc.childCount, 2);
      expect(doc.results.plainText, prevText.substring(1));
      expect(doc.results.formatted, '<h1>${formatted.substring(5)}');
    });
  });

  ///
  group('Document - Delete range of characters', () {});
}
