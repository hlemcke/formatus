import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

import 'test_helper.dart';

void main() {
  /// Flutter color ARGB
  final Color orange = Color(0xFFff9800);

  /// HTML color RGBA
  final String orangeDiv = '<div style="color: #ff9800ff;">';

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

      //--- when
      Set<Formatus> selectedFormats = {Formatus.header1, Formatus.color};
      doc.updateText(deltaText, selectedFormats, color: orange);
      TreeHelper.printAll(doc, 'Appended orange X');

      //--- then
      expect(doc.childCount, 1);
      expect(doc.results.formatted, '<h1>First Line${orangeDiv}X</div></h1>');
      expect(doc.results.plainText, 'First LineX');
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 2);
      expect(textNodes[0].formats, [Formatus.header1]);
      expect(textNodes[0].text, 'First Line');
      expect(textNodes[1].formats, [Formatus.header1, Formatus.color]);
      expect(textNodes[1].text, 'X');
      expect(textNodes[1].findColor, orange);
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
      doc.updateInlineFormat(selection, Formatus.color, true, color: orange);
      TreeHelper.printAll(doc, 'added orange X');

      //--- then
      expect(doc.childCount, 1);
      expect(doc.results.formatted, '<h1>${orangeDiv}First</div> Line</h1>');
      expect(doc.results.plainText, 'First Line');
      expect(doc[0].tag, Formatus.header1);
      FormatusNode section = doc[0];
      expect(section.childCount, 2);
      expect(section[0].tag, Formatus.color);
      expect(section[0][0].text, 'First');
      expect(section[0][0].findColor, orange);
    });

    //---
    test('Apply color to second word in single section', () {
      //--- given
      String formatted = '<h1>First Line</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 6,
        extentOffset: 10,
      );

      //--- when
      doc.updateInlineFormat(selection, Formatus.color, true, color: orange);
      TreeHelper.printAll(doc, 'updated');

      //--- then
      expect(doc.childCount, 1);
      expect(doc.results.formatted, '<h1>First ${orangeDiv}Line</div></h1>');
      expect(doc.results.plainText, 'First Line');
      FormatusNode section = doc[0];
      expect(section.tag, Formatus.header1);
      expect(section.childCount, 2);
      expect(section[0].text, 'First ');
      expect(section[1].tag, Formatus.color);
      expect(section[1][0].text, 'Line');
    });

    //---
    test('Change color of already colored part', () {
      //--- given
      String formatted = '<p>Color ${orangeDiv}Orange</div></p>';
      String limeDiv = '<div style="color: #cddc39ff;">';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = const TextSelection(
        baseOffset: 9,
        extentOffset: 12,
      );

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateInlineFormat(
        selection,
        Formatus.color,
        true,
        color: Colors.lime,
      );
      TreeHelper.printAll(doc, 'updated');

      //--- then
      expect(doc.childCount, 1);
      expect(doc.results.plainText, 'Color Orange');
      expect(
        doc.results.formatted,
        '<p>Color ${orangeDiv}Ora</div>${limeDiv}nge</div></p>',
      );
      FormatusNode section = doc[0];
      expect(section.childCount, 3);
      expect(section[0].tag, Formatus.text);
      expect(section[0].text, 'Color ');
      expect(section[1][0].text, 'Ora');
      expect(section[2][0].text, 'nge');
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
      doc.updateInlineFormat(
        selection,
        Formatus.color,
        true,
        color: Colors.transparent,
      );
      TreeHelper.printAll(doc, 'updated');

      expect(doc.results.formatted, '<p>Color ${orangeDiv}Ora</div>nge</p>');
    });

    test('Change color of everything, even already colored part', () {
      //--- given
      String formatted =
          '<p>This is ${orangeDiv}Colored.</div> This is not.</p>';
      String limeDiv = '<div style="color: #cddc39ff;">';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      doc.updateInlineFormat(
        selection,
        Formatus.color,
        true,
        color: Colors.lime,
      );
      TreeHelper.printAll(doc, 'updated');

      //--- then
      expect(doc.childCount, 1);
      expect(doc.results.plainText, 'This is Colored. This is not.');
      expect(
        doc.results.formatted,
        '<p>${limeDiv}This is Colored. This is not.</div></p>',
      );
      FormatusNode section = doc[0];
      expect(section.tag, Formatus.paragraph);
      expect(section[0][0].text, 'This is Colored. This is not.');
      // expect(doc.textNodes[0].color, Colors.lime);
    });
  });

  ///
  group('Apply color to multiple nodes', () {
    //---
    test('Apply color to nested inlines', () {
      //--- given
      String formatted =
          '<p>This <b>is</b> ${orangeDiv}colored.</div> This is <i>not</i></p>';
      String limeDiv = '<div style="color: #cddc39ff;">';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TextSelection selection = TextSelection(
        baseOffset: 0,
        extentOffset: doc.results.plainText.length,
      );

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateInlineFormat(
        selection,
        Formatus.color,
        true,
        color: Colors.lime,
      );
      TreeHelper.printAll(doc, 'updated inline format');

      //--- then
      expect(doc.childCount, 1);
      expect(doc.results.plainText, 'This is colored. This is not');
      expect(
        doc.results.formatted,
        '''
<p><div style="color: #cddc39ff;">This </div><b>${limeDiv}is</div></b>$limeDiv colored. This is </div><i><div style="color: #cddc39ff;">not</div></i></p>''',
      );
    });
  });
}
