import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  final Color orange = Colors.orange;
  final String orangeDiv = '<div style="color: #FFFF9800">';

  group('Apply color to text range', () {
    //---
    test('Append single orange character to all text', () {
      //--- given
      String formatted = '<h1>First Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = '${doc.results.plainText}X';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: TextSelection(baseOffset: 10, extentOffset: 10),
        nextText: nextText,
        nextSelection: TextSelection(baseOffset: 11, extentOffset: 11),
      );
      Set<Formatus> selectedFormats = {Formatus.header1, Formatus.color};

      //--- when
      doc.updateText(deltaText, selectedFormats, color: orange);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(
        doc.results.formattedText,
        '<h1>First Line${orangeDiv}X</div></h1>',
      );
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
      TextSelection selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      );

      //--- when
      doc.updateInlineFormat(selection, {
        Formatus.header1,
        Formatus.color,
      }, color: orange);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(doc.results.formattedText, '<h1>$orangeDiv>First</div> Line</h1>');
      expect(doc.results.plainText, 'First Line');
      expect(doc.textNodes[0].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[0].text, 'First');
      expect(doc.textNodes[0].color, orange);
      expect(doc.textNodes[1].formats, [Formatus.header1]);
      expect(doc.textNodes[1].text, ' Line');
    });

    //---
    test('Apply color to second word in first section', () {
      //--- given
      String formatted = '<h1>First Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 10,
      );

      //--- when
      doc.updateInlineFormat(selection, {
        Formatus.header1,
        Formatus.color,
      }, color: orange);

      //--- then
      expect(doc.textNodes.length, 2);
      expect(
        doc.results.formattedText,
        '<h1>First <color $orange>Line</color></h1>',
      );
      expect(doc.results.plainText, 'First Line');
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'First ');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[1].text, 'Line');
      expect(doc.textNodes[1].attribute, orange);
    });

    //---
    test('Change color in already colored part', () {
      //--- given
      String formatted = '<p>Color ${orangeDiv}Orange</div></p>';
      String limeDiv = '<div style="color: 0xFFcddc39">';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 12,
      );

      //--- when
      doc.updateInlineFormat(selection, {
        Formatus.paragraph,
        Formatus.color,
      }, color: Colors.lime);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, 'Color Orange');
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Color ');
      expect(doc.textNodes[1].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[1].text, 'Ora');
      expect(doc.textNodes[1].attribute, orange);
      expect(doc.textNodes[2].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[2].text, 'nge');
      expect(doc.textNodes[2].color, Colors.lime);
      expect(
        doc.results.formattedText,
        '<p>Color ${orangeDiv}Ora</div>${limeDiv}nge</div></p>',
      );
    });

    //---
    test('Clear colored part', () {
      //--- given
      Color orange = Colors.orange;
      String formatted = '<p>Color ${orangeDiv}Orange</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 12,
      );

      //--- when
      doc.updateInlineFormat(selection, {Formatus.paragraph}, color: orange);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, 'Color Orange');
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Color ');
      expect(doc.textNodes[1].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[1].text, 'Ora');
      expect(doc.textNodes[1].attribute, orange);
      expect(doc.textNodes[2].formats, [Formatus.paragraph]);
      expect(doc.textNodes[2].text, 'nge');
      expect(doc.textNodes[2].attribute.isEmpty, true);
      expect(
        doc.results.formattedText,
        '<p>Color ${orangeDiv}Ora</div>nge</p>',
      );
    });
  });
}
