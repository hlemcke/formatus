import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_document.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  group('Create Subtree Tests', () {
    test('createSubTree with only a top-level element', () {
      FormatusNode node =
          FormatusDocument.createSubTree('words', [Formatus.paragraph]);
      expect(node.path.length, 2);
      expect(node.format, Formatus.text);
      expect(node.top.format, Formatus.paragraph);
    });

    ///
    test('createSubTree with 3 elements', () {
      FormatusNode node = FormatusDocument.createSubTree(
          'words', [Formatus.paragraph, Formatus.bold, Formatus.underline]);
      expect(node.path.length, 4);
      expect(node.format, Formatus.text);
      expect(node.top.format, Formatus.paragraph);
      expect(node.path[1].format, Formatus.bold);
      expect(node.path[2].format, Formatus.underline);
    });
  });

  ///
  group('findFirstDifferentNode', () {
    FormatusNode node = FormatusDocument.createSubTree('words',
        [Formatus.root, Formatus.paragraph, Formatus.bold, Formatus.underline]);

    ///
    test('First diff node is top-level', () {
      FormatusNode diffNode =
          FormatusDocument.getFirstDifferentNode(node, [Formatus.header2]);
      expect(diffNode.format, Formatus.paragraph);
    });

    ///
    test('First diff node is underline', () {
      FormatusNode diffNode = FormatusDocument.getFirstDifferentNode(
          node, [Formatus.paragraph, Formatus.bold]);
      expect(diffNode.format, Formatus.underline);
    });
  });
}
