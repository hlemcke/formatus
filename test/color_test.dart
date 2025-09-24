import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  final Color orange = Color(0xffff9800);
  final String orangeDiv = '<div style="color: #ffff9800;">';

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
      expect(doc.textNodes.length, 2);
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'First Line');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[1].text, 'X');
      expect(doc.textNodes[1].color, orange);
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
      expect(
        doc.results.formattedText,
        '<h1>${orangeDiv}First</div> Line</h1>',
      );
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
        '<h1>First ${orangeDiv}Line</div></h1>',
      );
      expect(doc.results.plainText, 'First Line');
      expect(doc.textNodes[0].formats, [Formatus.header1]);
      expect(doc.textNodes[0].text, 'First ');
      expect(doc.textNodes[1].formats, [Formatus.header1, Formatus.color]);
      expect(doc.textNodes[1].text, 'Line');
      expect(doc.textNodes[1].color, orange);
    });

    //---
    test('Change color of already colored part', () {
      //--- given
      String formatted = '<p>Color ${orangeDiv}Orange</div></p>';
      String limeDiv = '<div style="color: #ffcddc39;">';
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
      expect(
        doc.results.formattedText,
        '<p>Color ${orangeDiv}Ora</div>${limeDiv}nge</div></p>',
      );
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Color ');
      expect(doc.textNodes[1].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[1].text, 'Ora');
      expect(doc.textNodes[1].color, orange);
      expect(doc.textNodes[2].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[2].text, 'nge');
      expect(doc.textNodes[2].color, Colors.lime);
    });

    //---
    test('Clear trailing part of colored text', () {
      //--- given
      String formatted = '<p>Color ${orangeDiv}Orange</div></p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 12,
      );

      //--- when
      doc.updateInlineFormat(selection, {Formatus.paragraph});

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, 'Color Orange');
      expect(doc.textNodes[0].formats, [Formatus.paragraph]);
      expect(doc.textNodes[0].text, 'Color ');
      expect(doc.textNodes[1].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[1].text, 'Ora');
      expect(doc.textNodes[1].color, orange);
      expect(doc.textNodes[2].formats, [Formatus.paragraph]);
      expect(doc.textNodes[2].text, 'nge');
      expect(doc.textNodes[2].color, Colors.transparent);
      expect(
        doc.results.formattedText,
        '<p>Color ${orangeDiv}Ora</div>nge</p>',
      );
    });

    test('Change color of everything, even already colored part', () {
      //--- given
      String formatted =
          '<p>This is ${orangeDiv}Colored.</div> This is not.</p>';
      String limeDiv = '<div style="color: #ffcddc39;">';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 29,
      );

      //--- when
      doc.updateInlineFormat(selection, {
        Formatus.paragraph,
        Formatus.color,
      }, color: Colors.lime);

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.results.plainText, 'This is Colored. This is not.');
      expect(
        doc.results.formattedText,
        '<p>${limeDiv}This is Colored. This is not.</div></p>',
      );
      expect(doc.textNodes[0].formats, [Formatus.paragraph, Formatus.color]);
      expect(doc.textNodes[0].text, 'This is Colored. This is not.');
      expect(doc.textNodes[0].color, Colors.lime);
    });
  });

  ///
  group('Apply color to multiple nodes', () {
    //---
    test('Apply color to nested inlines', () {
      //--- given
      String formatted =
          '<p>This <b>is</b> ${orangeDiv}Colored.</div> This is <i>not</i></p>';
      String limeDiv = '<div style="color: #ffcddc39;">';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(selection, {
        Formatus.paragraph,
        Formatus.color,
      }, color: Colors.lime);

      //--- then
      expect(doc.textNodes.length, 7);
      expect(doc.results.plainText, 'This is Colored. This is not');
      expect(
        doc.results.formattedText,
        '''<p>${limeDiv}This <b>is</b> Colored. This is <i>not</i></p>''',
      );
    });
  });
}
