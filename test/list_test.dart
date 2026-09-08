import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  group('Parsing Ordered List tests', () {
    //---
    test('Parsing ordered list with 2 items enclosed in paragraphs', () {
      //--- given
      String formatted = '''
<p>Ordered list
<ol><li>First element</li><li>Second one</li></ol>
... more text</p>
''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TreeHelper.printAll(doc, 'updated');

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 6);
      expect(doc.results.formatted, formatted.replaceAll('\n', ''));
      expect(
        doc.results.plainText,
        'Ordered list\n1. First element\n2. Second one\n... more text',
      );
    });

    //---
    test('Parsing ordered list with inline formats followed by P', () {
      //--- given
      final Color orange = Color(0xffff9800);
      final String orangeDiv = '<div style="color: #ff9800ff;">';
      String formatted =
          '''
<p><ol><li><b>First element</b></li>
<li>Second ${orangeDiv}one</div></li>
<li><u><i>Item</i> three</u></li></ol></p>
<p>Trailing paragraph</p>
''';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      TreeHelper.printAll(doc, 'parsed');

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 9);
      expect(doc.results.formatted, formatted.replaceAll('\n', ''));
      expect(
        doc.results.plainText,
        '\n1. First element\n2. Second one\n3. Item three\n\nTrailing paragraph',
      );
      expect(textNodes[0].formats, <Formatus>{
        .paragraph,
        .orderedList,
        .listItem,
      });
      expect(textNodes[0].text, '1. ');
      expect(textNodes[1].formats, <Formatus>{
        .paragraph,
        .orderedList,
        .listItem,
        .bold,
      });
      expect(textNodes[1].text, 'First element');
      expect(textNodes[2].text, '2. ');
      expect(textNodes[3].text, 'Second ');
      expect(textNodes[4].tag, Formatus.text);
      expect(textNodes[4].findColor, orange);
      expect(textNodes[4].text, 'one');
      expect(textNodes[5].text, '3. ');
      expect(textNodes[6].text, 'Item');
    });
  });

  group('Cursor Positioning', () {
    test('Move cursor through list', () {
      //--- given
      String formatted =
          '<p>Ordered<ol><li>First</li><li>Second</li></ol>Tail</p>';
      FormatusDocument doc = FormatusDocument(formatted: formatted);
      Map<int, String> texts = {
        8: 'Ordered',
        17: 'First',
        27: 'Second',
        32: 'Tail',
      };
      List<int> breakPoints = texts.keys.toList();
      breakPoints.sort();
      print('breaks at = $breakPoints');
      TreeHelper.printAll(doc, 'move cursor through list');

      //--- when / then
      expect(TreeHelper.printPlainText(doc), 'Ordered¶1. First¶2. Second¶Tail');
      for (int curPos = -1; curPos < doc.results.plainText.length; curPos++) {
        int key = breakPoints.firstWhere((o) => curPos < o);
        FormatusNode node = doc.findNodeAtCursor(curPos);
        expect(
          node.text,
          texts[key],
          reason: '$curPos -> $key -> ${texts[key]} but is: ${node.text}',
        );
      }
    });
  });

  group('Line breaks in Ordered List', () {
    test('Insert linebreak at start of first list-item', () {
      //--- given
      String formatted = '''
<p>Ordered<ol><li>First</li><li>Second</li></ol></p>''';
      String prevText = 'Ordered\n1. First\n2. Second\n';

      //--- when
      FormatusDocument doc = FormatusDocument(formatted: formatted);

      //--- then
      List<FormatusNode> textNodes = doc.collectAllNodesWithText;
      expect(textNodes.length, 5);
      expect(doc.results.formatted, formatted.replaceAll('\n', ''));
      expect(doc.results.plainText, prevText);

      //--- given
      String nextText = 'Ordered\n\n1. First\n2. Second\n';
      DeltaText deltaText = DeltaText(
        prevText: doc.results.plainText,
        prevSelection: const TextSelection(baseOffset: 8, extentOffset: 8),
        nextText: nextText,
        nextSelection: const TextSelection(baseOffset: 9, extentOffset: 9),
      );

      //--- when
      doc.updateText(deltaText, {Formatus.orderedList});
      TreeHelper.printAll(doc, 'text updated');

      //--- then
      expect(deltaText.type, DeltaTextType.insert);
      expect(doc.results.textSpan4Editor.children?.length, 1);
      expect(doc.results.plainText, 'Ordered\n1. \n2. First\n3. Second\n');
      expect(
        doc.results.formatted,
        '<p>Ordered<ol><li></li><li>First</li><li>Second</li></ol></p>',
      );
    });
  });
}
