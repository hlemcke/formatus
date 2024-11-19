import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_node.dart';
import 'package:formatus/src/formatus/formatus_tree.dart';

void main() {
  group('Create Subtree Tests', () {
    test('createSubTree with only a top-level element', () {
      List<FormatusNode> textNodes = [];
      FormatusNode node =
          FormatusTree.createSubTree(textNodes, 'words', [Formatus.paragraph]);
      expect(node.path.length, 2);
      expect(node.format, Formatus.text);
      expect(node.top.format, Formatus.paragraph);
    });

    ///
    test('createSubTree with 3 elements', () {
      List<FormatusNode> textNodes = [];
      FormatusNode node = FormatusTree.createSubTree(textNodes, 'words',
          [Formatus.paragraph, Formatus.bold, Formatus.underline]);
      expect(node.path.length, 4);
      expect(node.format, Formatus.text);
      expect(node.top.format, Formatus.paragraph);
      expect(node.path[1].format, Formatus.bold);
      expect(node.path[2].format, Formatus.underline);
    });
  });

  ///
  group('findFirstDifferentNode', () {
    List<FormatusNode> textNodes = [];
    FormatusNode node = FormatusTree.createSubTree(textNodes, 'words',
        [Formatus.root, Formatus.paragraph, Formatus.bold, Formatus.underline]);

    ///
    test('First diff node is top-level', () {
      FormatusNode diffNode =
          FormatusTree.getFirstDifferentNode(node, [Formatus.header2]);
      expect(diffNode.format, Formatus.paragraph);
    });

    ///
    test('First diff node is underline', () {
      FormatusNode diffNode = FormatusTree.getFirstDifferentNode(
          node, [Formatus.paragraph, Formatus.bold]);
      expect(diffNode.format, Formatus.underline);
    });
  });
}
