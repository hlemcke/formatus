import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  DeltaFormat deltaFormatEmpty =
      DeltaFormat(textFormats: [], selectedFormats: {});
  String prevHtml = '';
  FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: '');

  ///
  group('Line-Break Insertions', () {
    setUp(() {
      prevHtml = '<h1>Title</h1><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
    });

    ///
    test('Insert Line-Break at start', () {
      expect(doc.root.children.length, 2);
      String nextText = '\nTitle\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 1, extentOffset: 1));
      expect(deltaText.isAtStart, true);
      expect(deltaText.isInsert, true);
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.previousText, ' $nextText');
      expect(doc.root.children[0].format, Formatus.paragraph);
      expect(doc.root.children[1].format, Formatus.header1);
      expect(doc.root.children[2].format, Formatus.header2);
    });

    ///
    test('Append Line-Break to End', () {
      String prevText = doc.previousText;
      String nextText = 'Title\nSentence with bold words\n';
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection: TextSelection(
              baseOffset: prevText.length, extentOffset: prevText.length),
          nextText: nextText,
          nextSelection: TextSelection(
              baseOffset: prevText.length + 1,
              extentOffset: prevText.length + 1));
      expect(deltaText.isAtEnd, true);
      expect(deltaText.isInsert, true);
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.previousText, '$nextText ');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.header2);
      expect(doc.root.children[2].format, Formatus.paragraph);
    });

    ///
    test('Append Line-Break to end of a top-level element', () {
      String nextText = 'Title\n\nSentence with bold words';
      int prevIndex = 'Title'.length;
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection:
              TextSelection(baseOffset: prevIndex, extentOffset: prevIndex),
          nextText: nextText,
          nextSelection: TextSelection(
              baseOffset: prevIndex + 1, extentOffset: prevIndex + 1));
      expect(deltaText.isInsert, true);
      expect(deltaText.isAtEnd, false, reason: 'At end must be false');
      expect(deltaText.isAtStart, false, reason: 'At start must be false');
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.previousText, 'Title\n \nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.paragraph);
      expect(doc.root.children[2].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text, ' ');
      expect(doc.textNodes[2].text, 'Sentence with ');
    });

    ///
    test('Insert Line-Break at start of a top-level element', () {
      String nextText = 'Title\n\nSentence with bold words';
      int prevIndex = 'Title\n'.length;
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection:
              TextSelection(baseOffset: prevIndex, extentOffset: prevIndex),
          nextText: nextText,
          nextSelection: TextSelection(
              baseOffset: prevIndex + 1, extentOffset: prevIndex + 1));
      expect(deltaText.isInsert, true);
      expect(deltaText.isAtEnd, false, reason: 'At end must be false');
      expect(deltaText.isAtStart, false, reason: 'At start must be false');
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.previousText, 'Title\n \nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.paragraph);
      expect(doc.root.children[2].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text, ' ');
      expect(doc.textNodes[2].text, 'Sentence with ');
    });

    ///
    test('Insert Line-Break within a top-level element', () {
      //--- given
      String nextText = 'Ti\ntle\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3));
      expect(deltaText.isInsert, true, reason: 'Its an insert');
      expect(deltaText.isAtEnd, false, reason: 'Not at end');
      expect(deltaText.isAtStart, false, reason: 'Not at start');

      //--- when
      doc.handleInsert(deltaText, deltaFormatEmpty);

      //--- then
      expect(doc.root.children.length, 3);
      expect(doc.previousText, 'Ti\ntle\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.paragraph);
      expect(doc.root.children[2].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Ti');
      expect(doc.textNodes[1].text, 'tle');
      expect(doc.textNodes[2].text.startsWith('Sentence'), true);
    });
  });

  ///
  group('Line-Break Deletions', () {
    test('Delete single line-break between top-level nodes', () {
      // --- given
      prevHtml =
          '<h1>Ti</h1><p>tle</p><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      expect(doc.textNodes.length, 5);
      expect(doc.root.children.length, 3);
      String nextText = 'Title\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.isInsert, false);
      expect(deltaText.isAtEnd, false, reason: 'Not at end');
      expect(deltaText.isAtStart, false);

      // --- when
      doc.handleDeleteAndUpdate(deltaText);

      // --- then
      expect(doc.root.children.length, 2,
          reason: 'only 2 top-level elements remain');
      expect(doc.previousText, 'Title\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text.startsWith('Sentence'), true);
    });
    test('Backspace single line-break between top-level nodes', () {
      // --- given
      prevHtml =
          '<h1>Ti</h1><p>tle</p><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      expect(doc.textNodes.length, 5);
      expect(doc.root.children.length, 3);
      String nextText = 'Title\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.isInsert, false);
      expect(deltaText.isAtEnd, false, reason: 'Not at end');
      expect(deltaText.isAtStart, false);

      // --- when
      doc.handleDeleteAndUpdate(deltaText);

      // --- then
      expect(doc.root.children.length, 2,
          reason: 'only 2 top-level elements remain');
      expect(doc.previousText, 'Title\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text.startsWith('Sentence'), true);
    });

    ///
    test('Delete line-break in text range', () {
      // --- given
      prevHtml = '<h1>Title</h1><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument.fromHtml(htmlBody: prevHtml);
      String nextText = 'Titence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.previousText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 9),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.isInsert, false);
      expect(deltaText.isAtEnd, false, reason: 'Not at end');
      expect(deltaText.isAtStart, false);

      // --- when
      doc.handleDeleteAndUpdate(deltaText);

      // --- then
      expect(doc.root.children.length, 1,
          reason: 'only 1 top-level element remain');
      expect(doc.previousText, nextText);
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.textNodes.length, 3);
      expect(doc.textNodes[0].text, 'Titence with ');
      expect(doc.textNodes[1].text, 'bold');
      expect(doc.textNodes[2].text, ' words');
    });
  });
}
