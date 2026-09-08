import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

import 'test_helper.dart';

void main() {
  group('Find nodes in single section tree', () {
    test('Find first node', () {
      //--- given
      FormatusDocument doc = TestHelper.buildSingleSectionTree();

      //--- when / then
      for (int cursor in [-1, 0, 1, 2]) {
        FormatusNode node = doc.findNodeAtCursor(cursor);
        expect(node.text, 'abc', reason: 'i=$cursor -> node=$node');
        expect(node.textIndex0, cursor < 0 ? 0 : cursor);
      }
    });
    test('Find last node', () {
      //--- given
      FormatusDocument doc = TestHelper.buildSingleSectionTree();
      TreeHelper.printAll(doc, 'find last node');

      //--- when / then
      for (int cursor in [8, 9, 10, 11, 99]) {
        FormatusNode node = doc.findNodeAtCursor(cursor);
        expect(node.text, 'ghi', reason: 'i=$cursor -> node=$node');
        expect(
          node.textIndex0,
          (cursor - 8).clamp(0, 3),
          reason: 'i=$cursor -> node=$node',
        );
      }
    });
    test('Find middle node', () {
      //--- given
      FormatusDocument doc = TestHelper.buildSingleSectionTree();

      //--- when / then
      for (int cursor in [3, 4, 5, 6, 7]) {
        FormatusNode node = doc.findNodeAtCursor(cursor);
        expect(node.text, ' def ', reason: 'i=$cursor -> node=$node');
        expect(
          node.textIndex0,
          (cursor - 3).clamp(0, 5),
          reason: 'i=$cursor -> node=$node',
        );
      }
    });
  });
}
