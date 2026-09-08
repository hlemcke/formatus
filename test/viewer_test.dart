import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  group('Formatus-Viewer - Display lists', () {
    test('Ordered list', () {
      String input =
          '<p>Please <b>fix</b> these words: <ol><li>first</li>'
          '<li>second</li></ol> in letter</p>';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: input);

      //--- then
      expect(doc.results.formatted, input);
      expect(
        doc.results.plainText,
        'Please fix these words: \n1. first\n2. second\n in letter',
      );
      FormatusNode node = doc.root;
      expect(node.children.length, 1);
      expect(node[0].tag, Formatus.paragraph);
    });
  });
}
