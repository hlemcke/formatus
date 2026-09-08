import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

import 'test_helper.dart';

void main() {
  group('FormatusDocument.updateInlineFormat', () {
    test('split second word in nested subtree', () {
      //--- given
      String html = '<b>leading <i>bolditalic</i> trailing</b>';

      //--- when -> make "bold" only bold
      FormatusDocument doc = FormatusDocument(formatted: html);
      TextSelection selection = TextSelection(baseOffset: 8, extentOffset: 12);
      doc.updateInlineFormat(selection, Formatus.italic, false);
      TreeHelper.printAll(doc, 'inline format updated');

      expect(doc.childCount, 1);
      FormatusNode rootChild = doc[0];
      expect(rootChild[0].text, 'leading bold');
      expect(rootChild.formats, <Formatus>{.bold});
      expect(rootChild[1].tag, Formatus.italic);
      expect(rootChild[1][0].text, 'italic');
    });
  });
}
