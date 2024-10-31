import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_document.dart';

void main() {
  group('Insertions', () {
    String easyParagraph = '<p>Words <b>bold</b> <u>underline</u></p>';

    ///
    test('Insert "X" at end of "bold" -> should become bold also', () {
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: easyParagraph);
      int nodeIndex = doc.textNodes.indexOfCharIndex(10);
      print(
          '${doc.textNodes.length} nodes, nodeIndex=$nodeIndex node="${doc.textNodes[nodeIndex].text}"');
      DeltaText diff = doc.update('Words boldX underline');
      print('${doc.toHtml()}');
    });

    ///
    test('Insert "X" at start of "bold" -> should become bold also', () {
      FormatusDocument doc = FormatusDocument.fromHtml(htmlBody: easyParagraph);
      int nodeIndex = doc.textNodes.indexOfCharIndex(6);
      print(
          '${doc.textNodes.length} nodes, nodeIndex=$nodeIndex node="${doc.textNodes[nodeIndex].text}"');
      DeltaText diff = doc.update('Words Xbold underline');
      print('${doc.toHtml()}');
    });
  });
}
