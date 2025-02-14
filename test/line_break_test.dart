import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  DeltaFormat deltaFormatEmpty =
      DeltaFormat(textFormats: [], selectedFormats: {});
  String prevHtml = '';
  FormatusDocument doc = FormatusDocument(body: '');

  ///
  group('Line-Break Insertions', () {
    setUp(() {
      prevHtml = '<h1>Title</h1><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument(body: prevHtml);
    });

    ///
    test('Insert Line-Break at start', () {
      expect(doc.root.children.length, 2);
      String nextText = '\nTitle\nSentence with bold words';
      DeltaText delta = DeltaText(
          prevText: doc.plainText,
          prevSelection: const TextSelection(baseOffset: 0, extentOffset: 0),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 1, extentOffset: 1));
      expect(delta.position, DeltaTextPosition.start);
      expect(delta.type, DeltaTextType.insert);

      doc.handleInsert(delta, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.plainText, nextText);
      expect(doc.root.children[0].format, Formatus.paragraph);
      expect(doc.root.children[1].format, Formatus.header1);
      expect(doc.root.children[2].format, Formatus.header2);
    });

    ///
    test('Append Line-Break to End', () {
      String prevText = doc.plainText;
      String nextText = 'Title\nSentence with bold words\n';
      DeltaText deltaText = DeltaText(
          prevText: prevText,
          prevSelection: TextSelection(
              baseOffset: prevText.length, extentOffset: prevText.length),
          nextText: nextText,
          nextSelection: TextSelection(
              baseOffset: prevText.length + 1,
              extentOffset: prevText.length + 1));
      expect(deltaText.position, DeltaTextPosition.end);
      expect(deltaText.type, DeltaTextType.insert);
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.plainText, nextText);
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.header2);
      expect(doc.root.children[2].format, Formatus.paragraph);
    });

    ///
    test('Append Line-Break to end of a top-level element', () {
      String nextText = 'Title\n\nSentence with bold words';
      int prevIndex = 'Title'.length;
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection:
              TextSelection(baseOffset: prevIndex, extentOffset: prevIndex),
          nextText: nextText,
          nextSelection: TextSelection(
              baseOffset: prevIndex + 1, extentOffset: prevIndex + 1));
      expect(deltaText.position, DeltaTextPosition.middle);
      expect(deltaText.type, DeltaTextType.insert);
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.plainText, 'Title\n\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.paragraph);
      expect(doc.root.children[2].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text, '');
      expect(doc.textNodes[2].text, 'Sentence with ');
    });

    ///
    test('Insert Line-Break at start of a top-level element', () {
      String nextText = 'Title\n\nSentence with bold words';
      int prevIndex = 'Title\n'.length;
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection:
              TextSelection(baseOffset: prevIndex, extentOffset: prevIndex),
          nextText: nextText,
          nextSelection: TextSelection(
              baseOffset: prevIndex + 1, extentOffset: prevIndex + 1));
      expect(deltaText.position, DeltaTextPosition.middle);
      expect(deltaText.type, DeltaTextType.insert);
      doc.handleInsert(deltaText, deltaFormatEmpty);
      expect(doc.root.children.length, 3);
      expect(doc.plainText, 'Title\n\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.paragraph);
      expect(doc.root.children[2].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text, '');
      expect(doc.textNodes[2].text, 'Sentence with ');
    });

    ///
    test('Insert Line-Break within a top-level element', () {
      //--- given
      String nextText = 'Ti\ntle\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 3, extentOffset: 3));
      expect(deltaText.position, DeltaTextPosition.middle);
      expect(deltaText.type, DeltaTextType.insert);

      //--- when
      doc.handleInsert(deltaText, deltaFormatEmpty);

      //--- then
      expect(doc.root.children.length, 3);
      expect(doc.plainText, 'Ti\ntle\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.paragraph);
      expect(doc.root.children[2].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Ti');
      expect(doc.textNodes[1].text, 'tle');
      expect(doc.textNodes[2].text.startsWith('Sentence'), true);
    });
  });
  group('Line-Break Deletions', () {
    test('Delete single line-break between top-level nodes', () {
      // --- given
      prevHtml =
          '<h1>Ti</h1><p>tle</p><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument(body: prevHtml);
      expect(doc.textNodes.length, 5);
      expect(doc.root.children.length, 3);
      String nextText = 'Title\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 2),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.position, DeltaTextPosition.middle);
      expect(deltaText.type, DeltaTextType.delete);

      // --- when
      doc.handleDeleteAndUpdate(deltaText);

      // --- then
      expect(doc.root.children.length, 2,
          reason: 'only 2 top-level elements remain');
      expect(doc.plainText, 'Title\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text.startsWith('Sentence'), true);
    });
    test('Backspace single line-break between top-level nodes', () {
      // --- given
      prevHtml =
          '<h1>Ti</h1><p>tle</p><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument(body: prevHtml);
      expect(doc.textNodes.length, 5);
      expect(doc.root.children.length, 3);
      String nextText = 'Title\nSentence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection: const TextSelection(baseOffset: 3, extentOffset: 3),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.position, DeltaTextPosition.middle);
      expect(deltaText.type, DeltaTextType.delete);

      // --- when
      doc.handleDeleteAndUpdate(deltaText);

      // --- then
      expect(doc.root.children.length, 2,
          reason: 'only 2 top-level elements remain');
      expect(doc.plainText, 'Title\nSentence with bold words');
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.root.children[1].format, Formatus.header2);
      expect(doc.textNodes[0].text, 'Title');
      expect(doc.textNodes[1].text.startsWith('Sentence'), true);
    });

    ///
    test('Delete line-break in text range', () {
      // --- given
      prevHtml = '<h1>Title</h1><h2>Sentence with <b>bold</b> words</h2>';
      doc = FormatusDocument(body: prevHtml);
      String nextText = 'Titence with bold words';
      DeltaText deltaText = DeltaText(
          prevText: doc.plainText,
          prevSelection: const TextSelection(baseOffset: 2, extentOffset: 9),
          nextText: nextText,
          nextSelection: const TextSelection(baseOffset: 2, extentOffset: 2));
      expect(deltaText.position, DeltaTextPosition.middle);
      expect(deltaText.type, DeltaTextType.delete);

      // --- when
      doc.handleDeleteAndUpdate(deltaText);

      // --- then
      expect(doc.root.children.length, 1,
          reason: 'only 1 top-level element remain');
      expect(doc.plainText, nextText);
      expect(doc.root.children[0].format, Formatus.header1);
      expect(doc.textNodes.length, 3);
      expect(doc.textNodes[0].text, 'Titence with ');
      expect(doc.textNodes[1].text, 'bold');
      expect(doc.textNodes[2].text, ' words');
    });
  });
}
