import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_controller_impl.dart';
import 'package:formatus/src/formatus/formatus_node.dart';
import 'package:formatus/src/formatus/formatus_tree.dart';

void main() {
  //--- Prepare root -> P -> B -> I -> "this is a text node"
  FormatusNode root = FormatusNode(format: Formatus.root);
  FormatusNode paragraph = FormatusNode(format: Formatus.paragraph);
  FormatusNode bold = FormatusNode(format: Formatus.bold);
  FormatusNode italic = FormatusNode(format: Formatus.italic);
  FormatusNode textNode = FormatusNode(text: 'this is a text node');
  List<FormatusNode> textNodes = [];
  FormatusTree.appendChild(textNodes, root, paragraph);
  FormatusTree.appendChild(textNodes, paragraph, bold);
  FormatusTree.appendChild(textNodes, bold, italic);
  FormatusTree.appendChild(textNodes, italic, textNode);
  group('Format difference tests', () {
    test('same formats', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
        Formatus.bold
      };
      DeltaFormat deltaFormat = DeltaFormat(
          textFormats: textNode.formatsInPath,
          selectedFormats: selectedFormats);
      expect(deltaFormat.hasDelta, false);
    });

    ///
    test('formats added', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
        Formatus.underline,
        Formatus.bold
      };
      DeltaFormat deltaFormat = DeltaFormat(
          textFormats: textNode.formatsInPath,
          selectedFormats: selectedFormats);
      expect(deltaFormat.hasDelta, true);
      expect(deltaFormat.added, {Formatus.underline});
    });

    ///
    test('formats removed', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
      };
      DeltaFormat deltaFormat = DeltaFormat(
          textFormats: textNode.formatsInPath,
          selectedFormats: selectedFormats);
      expect(deltaFormat.hasDelta, true);
      expect(deltaFormat.removed, {Formatus.bold});
    });

    ///
    test('formats added and removed', () {
      Set<Formatus> selectedFormats = {
        Formatus.paragraph,
        Formatus.italic,
        Formatus.underline,
      };
      DeltaFormat deltaFormat = DeltaFormat(
          textFormats: textNode.formatsInPath,
          selectedFormats: selectedFormats);
      expect(deltaFormat.hasDelta, true);
      expect(deltaFormat.added, {Formatus.underline});
      expect(deltaFormat.removed, {Formatus.bold});
    });
  });
  group('DeltaFormat factory constructors', () {
    test('DeltaFormat.added', () {
      Set<Formatus> formats = {
        Formatus.header1,
        Formatus.bold,
        Formatus.italic
      };
      DeltaFormat deltaFormat = DeltaFormat.added(
          selectedFormats: formats, added: Formatus.underline);
      expect(deltaFormat.added, {Formatus.underline});
      expect(deltaFormat.removed, <Formatus>{});
      expect(
          deltaFormat.same, [Formatus.header1, Formatus.bold, Formatus.italic]);
    });
    test('DeltaFormat.removed', () {
      Set<Formatus> formats = {
        Formatus.header1,
        Formatus.bold,
        Formatus.italic
      };
      DeltaFormat deltaFormat =
          DeltaFormat.removed(selectedFormats: formats, removed: Formatus.bold);
      expect(deltaFormat.added, <Formatus>{});
      expect(deltaFormat.removed, {Formatus.bold});
      expect(deltaFormat.same, [Formatus.header1, Formatus.italic]);
    });
  });
}
