import 'package:flutter_test/flutter_test.dart';
import 'package:formatus/formatus.dart';
import 'package:formatus/src/formatus/formatus_node.dart';

void main() {
  //--- Prepare root -> P -> B -> I -> "this is a text node"
  FormatusNode root = FormatusNode(format: Formatus.root);
  FormatusNode paragraph = FormatusNode(format: Formatus.paragraph);
  FormatusNode bold = FormatusNode(format: Formatus.bold);
  FormatusNode italic = FormatusNode(format: Formatus.italic);
  FormatusNode textNode = FormatusNode(text: 'this is a text node');
  root.addChild(paragraph);
  paragraph.addChild(bold);
  bold.addChild(italic);
  italic.addChild(textNode);
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
}
