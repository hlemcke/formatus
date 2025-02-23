import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  //
  group('Line-Break - Insertions - Sections only', () {
    //---
    test('Insert Line-Break at start of sections', () {
      //--- given
      String formatted = '<h1>abc</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = '\nabc';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 1, extentOffset: 1));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, nextText);
    });

    //---
    test('Append Line-Break to End', () {
      //--- given
      String formatted = '<h1>abc</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, nextText);
    });

    // Different [DeltaText]. Cursor at end of first section
    test('Insert Line-Break at end of a section', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n\ndef';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 5);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abc</h1><p></p><p>def</p>');
    });

    //--- Different [DeltaText]. Cursor at start of second section
    test('Insert Line-Break at start of a section', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n\ndef';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 5, extentOffset: 5));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 5);
      expect(doc.results.plainText, nextText);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abc</h1><p></p><p>def</p>');
    });

    //---
    test('Insert Line-Break within a section', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'ab\nc\ndef';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 5);
      expect(doc.results.plainText, nextText);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>ab</h1><h1>c</h1><p>def</p>');
    });
  });

  //
  group('Line-Break - Insertions - Inlines only', () {
    //---
    test('Insert Line-Break at start of first inline in first section', () {
      //--- given
      String formatted = '<h1><b>abc</b> def</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = '\nabc def';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 1, extentOffset: 1));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 4);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<p></p><h1><b>abc</b> def</h1>');
    });

    //---
    test('Insert Line-Break at end of first inline in first section', () {
      //--- given
      String formatted = '<h1><b>abc</b> def</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n def';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1><b>abc</b></h1><h1> def</h1>');
    });
    test('Insert Line-Break within first inline', () {
      //--- given
      String formatted = '<h1><b>abc</b> def</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'ab\nc def';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3));
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 4);
      expect(doc.results.plainText, nextText);
      expect(
          doc.results.formattedText, '<h1><b>ab</b></h1><h1><b>c</b> def</h1>');
    });
  });

  //---
  group('Line-Break - Deletions', () {
    test('Delete line-break between sections', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abcdef';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3));
      expect(deltaText.type, DeltaTextType.delete);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abcdef</h1>');
    });

    //---
    test('Backspace line-break between sections', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abcdef';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3));
      expect(deltaText.type, DeltaTextType.delete);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abcdef</h1>');
    });

    //
    test('Delete line-break in text range', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abef';
      DeltaText deltaText = DeltaText(
          prevText: doc.results.plainText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 5),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.type, DeltaTextType.delete);

      //--- when
      doc.updateText(deltaText, {Formatus.header1}, '');

      //--- then
      expect(doc.textNodes.length, 1);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formattedText, '<h1>abef</h1>');
    });
  });
}
