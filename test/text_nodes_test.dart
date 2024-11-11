import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  ///
  String printReason(FormatusDocument doc, int cursor) {
    String plain = doc.toPlainText();
    int from = (cursor > 6) ? cursor - 5 : 0;
    int to = (cursor < plain.length - 6) ? cursor + 5 : plain.length;
    return '${plain.substring(from, cursor)}|$cursor|${plain.substring(cursor, to)}';
  }

  ///
  group('Node by index', () {
    String nestedHtml =
        '<h1>Title <i>italic</i></h1><p>Word <b>bold <u>under</u></b></p>';
    FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: nestedHtml);

    ///
    test('Element should be: "Title " with path h1', () {
      List<int> cursors = [0, 4, 5];
      for (int cursor in cursors) {
        int nodeIndex = doc.computeTextNodeIndex(cursor);
        FormatusNode node = doc.textNodes[nodeIndex];
        expect(node.text, 'Title ', reason: '$cursor');
        expect(node.path[0].format, Formatus.header1);
      }
    });

    ///
    test('Element should be: "italic" with path h1 / i', () {
      List<int> cursors = [6, 7, 11, 12];
      for (int cursor in cursors) {
        int nodeIndex = doc.computeTextNodeIndex(cursor);
        FormatusNode node = doc.textNodes[nodeIndex];
        expect(node.text, 'italic', reason: printReason(doc, cursor));
        expect(node.path[0].format, Formatus.header1);
        expect(node.path[1].format, Formatus.italic);
      }
    });

    ///
    test('Element should be: "under" at p / b / u', () {
      List<int> cursors = [23, 24, 27];
      for (int cursor in cursors) {
        int nodeIndex = doc.computeTextNodeIndex(cursor);
        FormatusNode node = doc.textNodes[nodeIndex];
        expect(node.text, 'under', reason: printReason(doc, cursor));
        expect(node.path[0].format, Formatus.paragraph);
        expect(node.path[1].format, Formatus.bold);
        expect(node.path[2].format, Formatus.underline);
      }
    });
  });

  ///
  group('Insertions', () {
    String easyParagraph = '<p>Words <b>bold</b> <u>underline</u></p>';

    ///
    test('Insert "X" at end of "bold" -> should become bold also', () {
      int indexEndOfBold = 'Words bold'.length;
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: easyParagraph);
      DeltaFormat deltaFormat =
          DeltaFormat(textFormats: [], selectedFormats: {});
      DeltaText deltaText = DeltaText(
          prevSelection: TextSelection(
              baseOffset: indexEndOfBold, extentOffset: indexEndOfBold),
          prevText: doc.previousText,
          nextSelection: TextSelection(
              baseOffset: indexEndOfBold + 1, extentOffset: indexEndOfBold + 1),
          nextText: 'Words boldX underline');
      doc.handleInsert(deltaText, deltaFormat);
      int nodeIndex = doc.computeTextNodeIndex(10);
      FormatusNode textNode = doc.textNodes[nodeIndex];
      expect('boldX', textNode.text);
    });

    ///
    test('Insert "X" at start of "bold" -> should become bold also', () {
      int indexStartOfBold = 'Words '.length;
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: easyParagraph);
      DeltaFormat deltaFormat =
          DeltaFormat(textFormats: [], selectedFormats: {});
      DeltaText deltaText = DeltaText(
          prevSelection: TextSelection(
              baseOffset: indexStartOfBold, extentOffset: indexStartOfBold),
          prevText: doc.previousText,
          nextSelection: TextSelection(
              baseOffset: indexStartOfBold + 1,
              extentOffset: indexStartOfBold + 1),
          nextText: 'Words Xbold underline');
      doc.handleInsert(deltaText, deltaFormat);
      int nodeIndex = doc.computeTextNodeIndex(7);
      FormatusNode textNode = doc.textNodes[nodeIndex];
      expect('Xbold', textNode.text);
    });
  });
}
