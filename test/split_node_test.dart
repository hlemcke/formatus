import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  group('Split Node tests', () {
    test('Split node at start', () {
      //--- given
      String text = 'abc def';
      FormatusNode node = FormatusNode(tag: .text, text: text);

      //--- when
      FormatusNode result = node.split(.head);

      //--- then
      expect(result.text.length, 0);
      expect(node.text, text);
    });
    test('Split node at end', () {
      //--- given
      String text = 'abc def';
      FormatusNode node = FormatusNode(tag: .text, text: text)..textIndex1 = 99;

      //--- when
      FormatusNode result = node.split(.tail);

      //--- then
      expect(result.text.length, 0);
      expect(node.text, text);
    });
    test('Split node at head', () {
      //--- given
      String text = 'abc def';
      FormatusNode node = FormatusNode(tag: .text, text: text)..textIndex0 = 3;

      //--- when
      FormatusNode result = node.split(.head);

      //--- then
      expect(result.text, 'abc');
      expect(node.text, ' def');
    });
    test('Split node at tail', () {
      //--- given
      String text = 'abc def';
      FormatusNode node = FormatusNode(tag: .text, text: text)..textIndex1 = 4;

      //--- when
      FormatusNode result = node.split(.tail);

      //--- then
      expect(result.text, 'def');
      expect(node.text, 'abc ');
    });
  });
}
