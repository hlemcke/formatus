import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

import 'test_helper.dart';

void main() {
  group('Line-Break - Insertions - Sections only', () {
    test('Insert Line-Break at start of single section', () {
      //--- given
      String formatted = '<h1>abc</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = '\nabc';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 1, extentOffset: 1),
      );
      expect(deltaText.type, DeltaTextType.insert);
      expect(deltaText.textAdded, '\n');

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 1);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1></h1><p>abc</p>');
    });
    test('Append Line-Break to End', () {
      //--- given
      String formatted = '<h1>abc</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
      );
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateText(deltaText, {Formatus.header1});
      TreeHelper.printAll(doc, 'appended LF');

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 2);
      expect(doc.results.plainText, nextText);
    });
    test('Insert Line-Break at end of first section', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n\ndef';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
      );
      expect(deltaText.type, DeltaTextType.insert);
      expect(deltaText.textAdded, '\n');

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1>abc</h1><p></p><p>def</p>');
    });
    test('Insert Line-Break at start of second section', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abc\n\ndef';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 5, extentOffset: 5),
      );
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1>abc</h1><p></p><p>def</p>');
    });
    test('Insert Line-Break within first section', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'ab\nc\ndef';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
      );
      expect(deltaText.type, DeltaTextType.insert);
      expect(deltaText.textAdded, '\n');

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateText(deltaText, {Formatus.header1});
      TreeHelper.printAll(doc, 'updated');

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1>ab</h1><p>c</p><p>def</p>');
    });
  });
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
        nextSelection: const TextSelection(baseOffset: 1, extentOffset: 1),
      );
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 2);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1><b></b></h1><p><b>abc</b> def</p>');
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
        nextSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
      );
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1><b>abc</b></h1><p> def</p>');
    });

    ///
    test('Insert Line-Break within first inline', () {
      //--- given
      String formatted = '<h1><b>abc</b> def</h1>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'ab\nc def';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
      );
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 3);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1><b>ab</b></h1><p><b>c</b> def</p>');
    });
  });
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
        nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
      );
      expect(deltaText.type, DeltaTextType.delete);

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateText(deltaText, {Formatus.header1});
      TreeHelper.printAll(doc, 'deleted');

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1>abcdef</h1>');
      expect(textNodes.length, 1);
      expect(doc.results.plainText, nextText);
    });
    test('Backspace line-break between sections', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abcdef';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 4, extentOffset: 4),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
      );
      expect(deltaText.type, DeltaTextType.delete);

      //--- when
      doc.updateText(deltaText, {Formatus.header1});

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 1);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1>abcdef</h1>');
    });
    test('Delete text range containing linefeed', () {
      //--- given
      String formatted = '<h1>abc</h1><p>def</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      String nextText = 'abef';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 2, extentOffset: 5),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
      );
      expect(deltaText.type, DeltaTextType.delete);

      //--- when
      TreeHelper.printAll(doc, 'given');
      doc.updateText(deltaText, {Formatus.header1});
      TreeHelper.printAll(doc, 'updated');

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 1);
      expect(doc.results.plainText, nextText);
      expect(doc.results.formatted, '<h1>abef</h1>');
    });
  });
}
