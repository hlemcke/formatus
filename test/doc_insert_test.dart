import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  ///
  group('Document - Insert with same format', () {
    ///
    test('Insert single char into empty text with same format', () {
      //--- given
      String formatted = '';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String prevText = doc.results.plainText;
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: 'X',
          nextSelection: TextSelection(baseOffset: 1, extentOffset: 1));

      //--- when
      doc.updateText(deltaText, {Formatus.paragraph}, null);

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.results.plainText, 'X');
      expect(doc.results.formattedText, '<p>X</p>');
    });

    ///
    test('Insert single char at start with same format', () {
      //--- given
      String formatted = '<h1>abc <b>def <u>ghi</u></b> <i>jkl</i> mno</h1>'
          '<p><b>pqr</b> stu</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.textNodes.length, 9);
      String prevText = doc.results.plainText;
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: 'X$prevText',
          nextSelection: TextSelection(baseOffset: 1, extentOffset: 1));

      //--- when
      doc.updateText(deltaText, {Formatus.paragraph}, null);

      //--- then
      expect(doc.textNodes.length, 10);
      expect(doc.results.plainText, 'X$prevText');
      expect(doc.results.formattedText, '<p>X</p>$formatted');
    });

    ///
    test('Insert single char at end of first section', () {
      //--- given
      String formatted = '''<h1>abc</h1><p>def</p>''';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.textNodes.length, 3);
      String prevText = doc.results.plainText;
      String nextText = 'abcX\ndef';
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: TextSelection(baseOffset: 4, extentOffset: 4));

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, null);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abcX</h1><p>def</p>');
    });

    ///
    test('Insert single char at end of all text', () {
      //--- given
      String formatted = '''<h1>abc</h1><p>def</p>''';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.textNodes.length, 3);
      String prevText = doc.results.plainText;
      String nextText = 'abc\ndefX';
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 7, extentOffset: 7),
          nextText: nextText,
          nextSelection: TextSelection(baseOffset: 8, extentOffset: 8));

      //--- when
      doc.updateText(deltaText, {Formatus.paragraph}, null);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abc</h1><p>defX</p>');
    });

    ///
    test('Insert single char inside first section', () {
      //--- given
      String formatted = '''<h1>abc</h1><p>def</p>''';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.textNodes.length, 3);
      String prevText = doc.results.plainText;
      String nextText = 'abXc\ndef';
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: TextSelection(baseOffset: 3, extentOffset: 3));

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, null);

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abXc</h1><p>def</p>');
    });

    ///
    test('Insert single char inside first inline with same format', () {
      //--- given
      String formatted = '''<h1>abc <b>bold</b></h1><p>def</p>''';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.textNodes.length, 4);
      String prevText = doc.results.plainText;
      String nextText = 'abc boXld\ndef';
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 6, extentOffset: 6),
          nextText: nextText,
          nextSelection: TextSelection(baseOffset: 7, extentOffset: 7));

      //--- when
      doc.updateText(deltaText, {Formatus.header1, Formatus.bold}, null);

      //--- then
      expect(doc.textNodes.length, 4);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abc <b>boXld</b></h1><p>def</p>');
    });
  });

  ///
  group('Document - Insert with different format', () {
    ///
    test('Insert single char inside first inline with different format', () {
      //--- given
      String formatted = '''<h1>abc <b>bold</b></h1><p>def</p>''';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      expect(doc.textNodes.length, 4);
      String prevText = doc.results.plainText;
      String nextText = 'abc boXld\ndef';
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(baseOffset: 6, extentOffset: 6),
          nextText: nextText,
          nextSelection: TextSelection(baseOffset: 7, extentOffset: 7));

      //--- when
      doc.updateText(deltaText, {Formatus.header1, Formatus.underline}, null);

      //--- then
      expect(doc.textNodes.length, 6);
      expect(doc.results.plainText, nextText);
      expect(
          doc.results.formattedText,
          '<h1>abc <b>bo</b><u>X</u>'
          '<b>ld</b></h1><p>def</p>');
    });
  });
}
