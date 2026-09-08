import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

import 'test_helper.dart';

void main() {
  group('Split Tree tests', () {
    test('Insert item at start of list', () {
      //--- given
      FormatusDocument doc = TestHelper.buildTreeWithList();
      TreeHelper.printAll(doc, 'given');

      //--- when / then
      for (int cursor in [4, 5, 6, 7]) {
        FormatusDocument doc = TestHelper.buildTreeWithList();
        FormatusNode node = doc.findNodeAtCursor(cursor);
        doc.insertAtCursor(node, '\n', {}, Colors.transparent);
        TreeHelper.printAll(doc, 'inserted $cursor');

        //--- then
        expect(doc.childCount, 1, reason: 'root only has single <p>');
        FormatusNode p = doc[0];
        expect(p[0].tag, Formatus.text);
        expect(p[0].text, 'abc');
        expect(p[1].tag, Formatus.orderedList);
        FormatusNode ol = p[1];
        expect(ol.childCount, 3);
        expect(ol[0].tag, Formatus.listItem);
        expect(p[2].tag, Formatus.text);
        expect(p[2].text, 'def');
      }
    });
  });
}
