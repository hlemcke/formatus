import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  ///
  String printReason(FormatusDocument doc, int cursor) {
    doc.computeNodeResults();
    String plain = doc.plainText;
    int from = (cursor > 6) ? cursor - 5 : 0;
    int to = (cursor < plain.length - 6) ? cursor + 5 : plain.length;
    return '${plain.substring(from, cursor)}|$cursor|${plain.substring(cursor, to)}';
  }

  ///
  group('Node by index', () {
    String nestedHtml =
        '<h1>Title <i>italic</i></h1><p>Word <b>bold <u>under</u></b></p>';
    FormatusDocument doc = FormatusDocument(body: nestedHtml);

    ///
    test('Element should be "Title " with path h1', () {
      List<int> cursors = [0, 4, 5];
      for (int cursor in cursors) {
        int nodeIndex = doc.computeNodeIndex(cursor);
        FormatusNode node = doc.textNodes[nodeIndex];
        expect(node.text, 'Title ', reason: '$cursor');
        expect(node.path[0].format, Formatus.header1);
      }
    });

    ///
    test('Element should be: "italic" with path h1 / i', () {
      List<int> cursors = [6, 7, 11, 12];
      for (int cursor in cursors) {
        int nodeIndex = doc.computeNodeIndex(cursor);
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
        int nodeIndex = doc.computeNodeIndex(cursor);
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
      FormatusDocument doc = FormatusDocument(body: easyParagraph);
      DeltaFormat deltaFormat =
          DeltaFormat(textFormats: [], selectedFormats: {});
      DeltaText deltaText = DeltaText(
          prevSelection: TextSelection(
              baseOffset: indexEndOfBold, extentOffset: indexEndOfBold),
          prevText: doc.plainText,
          nextSelection: TextSelection(
              baseOffset: indexEndOfBold + 1, extentOffset: indexEndOfBold + 1),
          nextText: 'Words boldX underline');
      doc.handleInsert(deltaText, deltaFormat);
      expect(doc.textNodes.length, 4);
      expect(doc.textNodes[0].text, 'Words ');
      expect(doc.textNodes[1].text, 'boldX');
      expect(doc.textNodes[2].text, ' ');
      expect(doc.textNodes[3].text, 'underline');
    });

    ///
    test('Insert "X" at start of "bold" -> should become bold also', () {
      int indexStartOfBold = 'Words '.length;
      FormatusDocument doc = FormatusDocument(body: easyParagraph);
      DeltaFormat deltaFormat =
          DeltaFormat(textFormats: [], selectedFormats: {});
      DeltaText deltaText = DeltaText(
          prevSelection: TextSelection(
              baseOffset: indexStartOfBold, extentOffset: indexStartOfBold),
          prevText: doc.plainText,
          nextSelection: TextSelection(
              baseOffset: indexStartOfBold + 1,
              extentOffset: indexStartOfBold + 1),
          nextText: 'Words Xbold underline');
      doc.handleInsert(deltaText, deltaFormat);
      expect(doc.textNodes.length, 4);
      expect(doc.textNodes[0].text, 'Words ');
      expect(doc.textNodes[1].text, 'Xbold');
      expect(doc.textNodes[2].text, ' ');
      expect(doc.textNodes[3].text, 'underline');
    });
  });
}
