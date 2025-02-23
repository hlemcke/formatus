import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Apply color to text range', () {
    //---
    test('Append character with color to all text', () {
      //--- given
      String formatted = '<h1>First Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = '${doc.results.plainText}X';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: TextSelection(baseOffset: 10, extentOffset: 10),
          nextText: nextText,
          nextSelection: TextSelection(baseOffset: 11, extentOffset: 11));
      String orange = FormatusColor.orange.key;
      Set<Formatus> selectedFormats = {Formatus.header1, Formatus.color};

      //--- when
      doc.updateText(deltaText, selectedFormats, orange);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.results.formattedText,
          '<h1>First Line<color $orange>X</color></h1>');
      expect(doc.results.plainText, 'First LineX');
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'First Line');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[1].text, 'X');
      expect(doc.textNodes[1].attribute, orange);
    });

    //---
    test('Apply color to first word in first section', () {
      //--- given
      String formatted = '<h1>First Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection =
          const TextSelection(baseOffset: 0, extentOffset: 5);
      String orange = FormatusColor.orange.key;

      //--- when
      doc.updateInlineFormat(
          selection, {Formatus.header1, Formatus.color}, orange);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.results.formattedText,
          '<h1><color $orange>First</color> Line</h1>');
      expect(doc.results.plainText, 'First Line');
      expect(doc.textNodes[0].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[0].text, 'First');
      expect(doc.textNodes[0].attribute, orange);
      expect(doc.textNodes[1].formats, [Formatus.header1]);
      expect(doc.textNodes[1].text, ' Line');
    });

    //---
    test('Apply color to second word in first section', () {
      //--- given
      String formatted = '<h1>First Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection =
          const TextSelection(baseOffset: 6, extentOffset: 10);
      String orange = FormatusColor.orange.key;

      //--- when
      doc.updateInlineFormat(
          selection, {Formatus.header1, Formatus.color}, orange);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.results.formattedText,
          '<h1>First <color $orange>Line</color></h1>');
      expect(doc.results.plainText, 'First Line');
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'First ');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[1].text, 'Line');
      expect(doc.textNodes[1].attribute, orange);
    });
  });
}
